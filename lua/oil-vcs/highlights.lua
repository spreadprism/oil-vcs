local M = {}

local PREFIX = require("oil-vcs.opts").PLUGIN_PREFIX

local default_highlights = {
	[PREFIX .. "Added"] = { link = "Added" },
	[PREFIX .. "Modified"] = { link = "DiagnosticWarn" },
	[PREFIX .. "Renamed"] = { link = "DiagnosticWarn" },
	[PREFIX .. "Untracked"] = { link = "NonText" },
	[PREFIX .. "Ignored"] = { link = "NonText" },
}

---@param opts oil-vcs.Opts
---Add highlight groups if they do not already exist and if they are in the defaults
function M.setup(opts)
	for _, hl in pairs(opts.hl) do
		local name, hl_opts = hl, default_highlights[hl]
		if hl_opts ~= nil then
			if vim.fn.hlexists(name) == 0 then
				vim.api.nvim_set_hl(0, hl, hl_opts)
			end
		end
	end
end

local NAMESPACE = vim.api.nvim_create_namespace(PREFIX .. "Highlights")

local timer = vim.loop.new_timer()
---@param bufnr? integer
---@param force? boolean
function M.apply(bufnr, force)
	local opts = require("oil-vcs.opts").opts()

	if force then -- HACK: prob a better way to do this
	elseif timer and timer:is_active() then
		return
	end

	if timer then
		timer:stop()
		timer:start(opts.apply_debounce, 0, function()
			timer:stop()
		end)
	end

	local oil = require("oil")
	local buf = bufnr or vim.api.nvim_get_current_buf()

	M.clear(buf)

	local current_dir = oil.get_current_dir(buf)

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	for i, line in ipairs(lines) do
		local entry = oil.get_entry_on_line(buf, i)
		if entry then
			local path
			if entry.type == "file" then
				path = vim.fs.joinpath(current_dir, entry.name)
			elseif entry.type == "directory" then
				path = vim.fs.joinpath(current_dir, entry.name) .. "/"
			end

			local status = require("oil-vcs.provider").status(path)
			if status then
				local hl, symbol = opts.hl[status], opts.symbols[status]
				if hl and symbol then
					vim.api.nvim_buf_set_extmark(buf, NAMESPACE, i, 0, {
						hl_group = hl,
						virt_text = { { symbol .. " ", hl } },
						virt_text_pos = "eol",
					})
				end
			end
		end
	end
end

---@param bufnr integer
function M.clear(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, NAMESPACE, 0, -1)
end

return M

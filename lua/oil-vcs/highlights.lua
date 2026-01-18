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

local cache = {}

---@param bufnr? integer
function M.update_buffer(bufnr)
	local opts = require("oil-vcs.opts").opts()
	local oil = require("oil")
	local buf = bufnr or vim.api.nvim_get_current_buf()

	local current_dir = oil.get_current_dir(buf)

	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	vim.api.nvim_buf_clear_namespace(buf, NAMESPACE, 0, -1)

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
			local id = cache[buf] and cache[buf][path]
			if status then -- INFO: apply status
				local hl, symbol = opts.hl[status], opts.symbols[status]
				if hl and symbol then
					local name_start = line:find(entry.name, 1, true)
					if name_start then
						local end_col = name_start + #entry.name
						if entry.type == "file" then
							end_col = end_col - 1
						end

						local extmark_opts = {
							end_col = end_col,
							hl_group = hl,
							virt_text = { { symbol .. " ", hl } },
							virt_text_pos = "eol",
						}

						if id then
							extmark_opts.id = id
							vim.api.nvim_buf_set_extmark(buf, NAMESPACE, i - 1, name_start - 1, extmark_opts)
						else
							id = vim.api.nvim_buf_set_extmark(buf, NAMESPACE, i - 1, name_start - 1, extmark_opts)
						end

						cache[buf] = cache[buf] or {}
						cache[buf][path] = id
					end
				end
			else -- INFO: clear since no status
				if id then
					vim.api.nvim_buf_del_extmark(buf, NAMESPACE, id)
					cache[buf][path] = nil
				end
			end
		else
			vim.api.nvim_buf_clear_namespace(buf, NAMESPACE, i, i + 1)
		end
	end
end

return M

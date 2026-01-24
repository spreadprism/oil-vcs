local M = {}

local PREFIX = require("oil-vcs.opts").PLUGIN_PREFIX

local default_highlights = {
	[PREFIX .. "Added"] = { fg = "#9ece6a" },
	[PREFIX .. "Modified"] = { fg = "#e0af68" },
	[PREFIX .. "Renamed"] = { fg = "#cba6f7" },
	[PREFIX .. "Untracked"] = { fg = "#7aa2f7" },
	[PREFIX .. "Ignored"] = { fg = "#565F89" },
	[PREFIX .. "Deleted"] = { fg = "#f7768e" },
	[PREFIX .. "Conflict"] = { fg = "#f7768e" },
	[PREFIX .. "PartialStage"] = { fg = "#66AAD1" },
}

function M.setup()
	local opts = require("oil-vcs.opts").opts
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

---@param bufnr? integer
function M.update_oil_buffer(bufnr)
	local opts = require("oil-vcs.opts").opts
	local oil = require("oil")
	local buf = bufnr or vim.api.nvim_get_current_buf()

	local current_dir = oil.get_current_dir(buf)

	if not current_dir then
		return
	end

	vim.api.nvim_buf_clear_namespace(buf, NAMESPACE, 0, -1)

	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
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
			if status then -- INFO: apply status
				local hl, symbol = opts.hl[status], opts.symbols[status]
				if hl and symbol then
					local name_start = line:find(entry.name, 1, true)
					if name_start then
						local end_col = name_start + #entry.name - (entry.type == "file" and 1 or 0)

						local virt_text = nil
						if opts.symbols_on_dir or entry.type == "file" then
							virt_text = { { symbol .. " ", hl } }
						end

						vim.api.nvim_buf_set_extmark(buf, NAMESPACE, i - 1, name_start - 1, {
							end_col = end_col,
							hl_group = hl,
							virt_text = virt_text,
							virt_text_pos = "eol",
						})
					end
				end
			end
		end
	end
end

return M

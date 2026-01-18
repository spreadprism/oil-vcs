local M = {}

local GROUP_NAME = require("oil-vcs.opts").PLUGIN_PREFIX

---@param opts oil-vcs.Opts
function M.setup(opts)
	local autocmd = type(opts.autocmd) == "function" and opts.autocmd() or opts.autocmd

	if not autocmd then
		return
	end

	local group = vim.api.nvim_create_augroup(GROUP_NAME, { clear = true })
	local highlights = require("oil-vcs.highlights")
	local provider = require("oil-vcs.provider")

	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = opts.user_events,
		callback = function(_)
			provider.refresh()
		end,
	})

	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = { "OilActionsPost" },
		callback = function(_)
			provider.refresh() -- TODO: only refresh on dir changed
		end,
	})

	vim.api.nvim_create_autocmd({ "FileType" }, {
		group = group,
		pattern = { "oil" },
		callback = function()
			local buffer = vim.api.nvim_get_current_buf()
			vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
				group = group,
				buffer = buffer,
				callback = function()
					provider.refresh(buffer)
					vim.schedule(function()
						highlights.update_buffer(buffer)
					end)
				end,
			})

			vim.api.nvim_create_autocmd({
				"InsertLeave",
				"TextChanged",
				"FocusGained",
				"WinEnter",
				"BufWinEnter",
			}, {
				group = group,
				buffer = buffer,
				callback = function()
					vim.schedule(function()
						highlights.update_buffer(buffer)
					end)
				end,
			})
		end,
	})
end

return M

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

	vim.api.nvim_create_autocmd("BufEnter", {
		group = group,
		pattern = "oil://*",
		callback = function(args)
			vim.schedule(function()
				highlights.apply(args.buf)
			end)
		end,
	})

	local timer = nil
	vim.api.nvim_create_autocmd({ "FocusGained", "WinEnter", "BufWinEnter" }, {
		group = group,
		pattern = "oil://*",
		callback = function(args)
			if not timer then
				vim.schedule(function()
					highlights.apply(args.buf)
				end)
			end

			if timer then
				timer:close()
			end

			timer = vim.defer_fn(function()
				timer = nil
			end, 300)
		end,
	})
end

return M

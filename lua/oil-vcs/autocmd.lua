local M = {}

local GROUP_NAME = require("oil-vcs.opts").PLUGIN_PREFIX

---@param opts oil-vcs.Opts
function M.setup(opts)
	local autocmd = type(opts.autocmd) == "function" and opts.autocmd() or opts.autocmd

	if not autocmd then
		return
	end

	local group = vim.api.nvim_create_augroup(GROUP_NAME, { clear = true })
	local vcs = require("oil-vcs.highlights")

	vim.api.nvim_create_autocmd("BufEnter", {
		group = group,
		pattern = "oil://*",
		callback = function(args)
			vcs.apply(args.buf)
		end,
	})

	vim.api.nvim_create_autocmd("BufLeave", {
		group = group,
		pattern = "oil://*",
		callback = function(args)
			vcs.clear(args.buf)
		end,
	})

	vim.api.nvim_create_autocmd({ "BufWritePost", "TextChanged", "TextChangedI" }, {
		group = group,
		pattern = "oil://*",
		callback = function(args)
			vcs.apply(args.buf, true)
		end,
	})
end

return M

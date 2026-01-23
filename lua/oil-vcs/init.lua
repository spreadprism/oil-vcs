local M = {}

local init = false
---@param opts? oil-vcs.Opts
function M.setup(opts)
	if init then
		return
	end
	require("oil-vcs.opts").setup(opts)
	require("oil-vcs.highlights").setup()
	require("oil-vcs.autocmd").setup()
	init = true
end

M.Status = require("oil-vcs.types").Status

return M

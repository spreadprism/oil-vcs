local M = {}

local init = false
---@param user_opts? oil-vcs.Opts
function M.setup(user_opts)
	if init then
		return
	end
	local opts = require("oil-vcs.opts").setup(user_opts)
	require("oil-vcs.highlights").setup(opts)
	require("oil-vcs.autocmd").setup(opts)
	init = true
end

M.Status = require("oil-vcs.types").Status
M.refresh = require("oil-vcs.provider").refresh
M.apply = require("oil-vcs.highlights").apply
M.clear = require("oil-vcs.highlights").clear

return M

local M = {}

---@param user_opts? oil-vcs.Opts
function M.setup(user_opts)
	local opts = require("oil-vcs.opts").setup(user_opts)
	require("oil-vcs.provider").setup(opts)
	require("oil-vcs.highlights").setup(opts)
	require("oil-vcs.autocmd").setup(opts)
end

M.Status = require("oil-vcs.types").Status
M.refresh = require("oil-vcs.provider").refresh
M.apply = require("oil-vcs.highlights").apply
M.clear = require("oil-vcs.highlights").clear

return M

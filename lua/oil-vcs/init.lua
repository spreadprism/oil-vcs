local M = {}

---@param user_opts? oil-vcs.Opts
function M.setup(user_opts)
	local opts = require("oil-vcs.opts").setup(user_opts)
	require("oil-vcs.highlights").setup(opts)
end

return M

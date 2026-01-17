local M = {}

---@param user_opts? oil-vcs.Opts
function M.setup(user_opts)
	local opts = require("oil-vcs.opts").setup(user_opts)
	require("oil-vcs.provider").setup(opts)
	require("oil-vcs.highlights").setup(opts)
	require("oil-vcs.autocmd").setup(opts)
	local refresh = require("oil.actions").refresh
	local orig_refresh = refresh.callback
	refresh.callback = function(...)
		require("oil-vcs.provider").refresh(function()
			require("oil-vcs.highlights").apply(nil, true)
		end)
		orig_refresh(...)
	end
end

M.Status = require("oil-vcs.types").Status
M.refresh = require("oil-vcs.provider").refresh
M.apply = require("oil-vcs.highlights").apply
M.clear = require("oil-vcs.highlights").clear

return M

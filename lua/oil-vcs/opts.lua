local M = {}

local types = require("oil-vcs.types")

local Status = types.Status

---@class oil-vcs.Opts
---@field symbols table<oil-vcs.Status, string> Symbols used to represent different VCS statuses
---@field hl table<oil-vcs.Status, string> Highlight groups for different VCS statuses
local default_opts = {
	symbols = {
		[Status.Added] = "+",
		[Status.Modified] = "~",
		[Status.Untracked] = "?",
		[Status.Ignored] = "!",
	},
	hl = {
		[Status.Added] = "OilVcsAdded",
		[Status.Modified] = "OilVcsModified",
		[Status.Untracked] = "OilVcsUntracked",
		[Status.Ignored] = "OilVcsIgnored",
	},
}

local opts = default_opts

---@param user_opts? oil-vcs.Opts
---@return oil-vcs.Opts
function M.setup(user_opts)
	opts = vim.tbl_deep_extend("force", default_opts, user_opts or {})
	return opts
end

---@return oil-vcs.Opts
function M.opts()
	return vim.fn.deepcopy(opts, true)
end

return M

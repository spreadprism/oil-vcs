local M = {}
M.PLUGIN_PREFIX = "OilVcs"

local types = require("oil-vcs.types")

local Status = types.Status

---@class oil-vcs.Opts
---@field cwd string | fun(): string
---@field user_events string[] List of user events that trigger a VCS status refresh
---@field symbols table<oil-vcs.Status, string> Symbols used to represent different VCS statuses
---@field hl table<oil-vcs.Status, string> Highlight groups for different VCS statuses
---@field providers oil-vcs.ProviderInitiator[] List of VCS providers to use
local default_opts = {
	cwd = function()
		return vim.fn.getcwd()
	end,
	user_events = {},
	providers = {
		require("oil-vcs.provider.git"),
	},
	symbols = {
		[Status.Added] = "+",
		[Status.Modified] = "~",
		[Status.Untracked] = "?",
		[Status.Ignored] = "!",
		[Status.Deleted] = "-",
		[Status.Renamed] = "→",
		[Status.Conflict] = "C",
		[Status.PartialStage] = "PS",
	},
	hl = {
		[Status.Added] = "OilVcsAdded",
		[Status.Modified] = "OilVcsModified",
		[Status.Untracked] = "OilVcsUntracked",
		[Status.Ignored] = "OilVcsIgnored",
		[Status.Deleted] = "OilVcsDeleted",
		[Status.Renamed] = "OilVcsRenamed",
		[Status.Conflict] = "OilVcsConflict",
		[Status.PartialStage] = "OilVcsPartialStage",
	},
}

M.opts = default_opts

---@param user_opts? oil-vcs.Opts
---@return oil-vcs.Opts
function M.setup(user_opts)
	M.opts = vim.tbl_deep_extend("force", default_opts, user_opts or {})
	return M.opts
end

return M

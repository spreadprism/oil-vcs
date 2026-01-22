local M = {}

---@enum oil-vcs.Status
M.Status = {
	Added = "added",
	Modified = "modified",
	Untracked = "untracked",
	Ignored = "ignored",
	Renamed = "renamed",
	Deleted = "deleted",
	Conflict = "conflict",
	PartialStage = "partial_stage",
}

return M

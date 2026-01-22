---@type oil-vcs.ProviderInitiator
local M = {}

---@alias oil-vcs.GitCache table<string, oil-vcs.Status>

---@class oil-vcs.GitProvider : oil-vcs.Provider
---@field cache oil-vcs.GitCache The cached status of files in the repository
---@field first boolean
local GitProvider = {}

---@param root string
function M.new(root)
	local self = setmetatable({}, { __index = GitProvider })
	self.root = root
	self.cache = {}
	self.first = true
	return self
end

local Status = require("oil-vcs.types").Status

---@alias statusDetector fun(status: string, first:string, last:string): boolean
---@type statusDetector[]
local status = {
	[Status.Ignored] = function(status, _, _)
		return status == "!!"
	end,
	[Status.Untracked] = function(status, _, _)
		return status == "??"
	end,
	[Status.Conflict] = function(status, _, _)
		return vim.tbl_contains({ "UU", "AA", "DD", "AU", "UA", "DU", "UD" }, status)
	end,
	[Status.PartialStage] = function(status, _, _)
		return vim.tbl_contains({ "MM", "MD", "AM", "AD" }, status)
	end,
	[Status.Modified] = function(_, first, last)
		return first == "M" or last == "M"
	end,
	[Status.Added] = function(_, first, _)
		return first == "A"
	end,
	[Status.Renamed] = function(_, first, _)
		return first == "R"
	end,
	[Status.Deleted] = function(_, first, last)
		return first == "D" or last == "D"
	end,
}

---@param path string
---@return oil-vcs.Status|nil
function GitProvider:status(path)
	if self.first then
		self:refresh()
		self.first = false
	end
	return self.cache[path]
end

---@param root string
---@return table<string, oil-vcs.Status>
local function git_status(root)
	local tbl = {}
	vim.system({ "git", "status", "--porcelain", "--ignored" }, { cwd = root }, function(obj)
		if obj.code ~= 0 then
			return
		end

		local lines = vim.split(obj.stdout, "\n")

		for _, line in ipairs(lines) do
			local s1, s2, path = string.match(line, "^(.)(.) (.+)$")
			if s1 and s2 and path then
				for status_name, detector in pairs(status) do
					if detector(s1 .. s2, s1, s2) then
						tbl[vim.fs.joinpath(root, path)] = status_name
						break
					end
				end
			end
		end
	end):wait()
	return tbl
end

---@param root string
---@param tbl table<string, oil-vcs.Status>
---@return table<string, oil-vcs.Status>
local function propagate_status(root, tbl)
	---@type table<string, oil-vcs.Status>
	local new_tbl = {}

	for path, status in pairs(tbl) do
		if vim.tbl_contains({ Status.Added, Status.Untracked, Status.Modified }, status) then
			local dir = vim.fs.dirname(path)
			while dir ~= root and dir ~= "" and dir ~= "/" do
				if not new_tbl[dir] then
					new_tbl[dir .. "/"] = status
				end
				dir = vim.fs.dirname(dir)
			end
		end
	end

	return vim.tbl_extend("force", new_tbl, tbl)
end

function GitProvider:refresh()
	local status = git_status(self.root)
	status = propagate_status(self.root, status)
	self.cache = status
end

function M.detect(path)
	local output = vim.fn.system(string.format("cd %s && git rev-parse --show-toplevel", path))

	output = vim.trim(output)
	return vim.v.shell_error == 0, output
end

return M

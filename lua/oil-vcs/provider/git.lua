---@type oil-vcs.ProviderInitiator
local M = {}
-- TODO: add refresh timer

---@alias oil-vcs.GitCache table<string, oil-vcs.Status>

---@class oil-vcs.GitProvider : oil-vcs.Provider
---@field cache oil-vcs.GitCache The cached status of files in the repository
local GitProvider = {
	cache = {},
}

---@param root string
function M.new(root)
	local self = setmetatable({}, { __index = GitProvider })
	self.root = root
	self.cache = {}
	self:refresh()
	return self
end

local Status = require("oil-vcs.types").Status

---@type table<string, oil-vcs.Status | table<string, oil-vcs.Status>>
local status_match = {
	["M"] = Status.Modified, -- (M*)
	["A"] = Status.Added, -- (A*)
	["?"] = Status.Untracked, --(?*)
	["!"] = Status.Ignored, -- (?*)
	[" "] = { -- ( *)
		["M"] = Status.Modified, -- ( M)
		["A"] = Status.Added, -- ( A)
	},
}

---@param path string
---@return oil-vcs.Status|nil
function GitProvider:status(path)
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
				local status = status_match[s1]
				if type(status) == "table" then
					status = status[s2]
				end

				if status then
					tbl[vim.fs.joinpath(root, path)] = status
				end
			end
		end
	end):wait()
	return tbl
end

---@param tbl table<string, oil-vcs.Status>
---@return table<string, oil-vcs.Status>
local function propagate_status(tbl)
	-- TODO: implement
	return tbl
end

function GitProvider:refresh()
	local status = git_status(self.root)
	status = propagate_status(status)
	self.cache = status
end

function M.detect(path)
	path = vim.fs.abspath(path)

	if not vim.fn.isdirectory(path) then
		path = vim.fs.dirname(path)
	end

	local output = vim.fn.system(string.format("cd %s && git rev-parse --show-toplevel", path))

	output = vim.trim(output)
	return vim.v.shell_error == 0, output
end

return M

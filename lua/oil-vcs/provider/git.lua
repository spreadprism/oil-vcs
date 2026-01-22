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

---@param path string
---@return oil-vcs.Status|nil
function GitProvider:status(path)
	if self.first then
		self:refresh()
		self.first = false
	end
	return self.cache[path]
end

---@param line string
---@return oil-vcs.Status|nil
---@return string|nil
local function parse_status_porcelain(line)
	local X, Y, path = string.match(line, "^(.)(.) (.+)$")
	if not (X and Y and path) then
		return nil, nil
	end

	local status = nil

	if X == Y and X == "!" then
		status = Status.Ignored
	elseif X == Y and X == "?" then
		status = Status.Untracked
	elseif vim.tbl_contains({ "UU", "AA", "DD", "AU", "UA", "DU", "UD" }, X .. Y) then
		status = Status.Conflict
	elseif vim.tbl_contains({ "MM", "MD", "AM", "AD" }, X .. Y) then
		status = Status.PartialStage
	elseif X == "M" or Y == "M" then
		status = Status.Modified
	elseif X == "R" then
		status = Status.Renamed
	elseif X == "D" or Y == "D" then
		status = Status.Deleted
	end

	return status, path
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
			local status, path = parse_status_porcelain(line)
			if status then
				tbl[vim.fs.joinpath(root, path)] = status
				if vim.tbl_contains({ Status.Added, Status.Untracked, Status.Modified }, status) then
					local dir = vim.fs.dirname(path)
					while dir ~= root and dir ~= "" and dir ~= "/" do
						-- TODO: add status priority list
						if not tbl[dir] then
							tbl[dir .. "/"] = status
						end
						dir = vim.fs.dirname(dir)
					end
				end
			end
		end
	end):wait()
	return tbl
end

function GitProvider:refresh()
	self.cache = git_status(self.root)
end

function M.detect(path)
	local output = vim.fn.system(string.format("cd %s && git rev-parse --show-toplevel", path))

	output = vim.trim(output)
	return vim.v.shell_error == 0, output
end

return M

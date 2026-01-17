---@alias oil-vcs.GitCache table<string, oil-vcs.Status>

---@class oil-vcs.GitProvider : oil-vcs.Provider
---@field root string The root directory of the Git repository
---@field cache oil-vcs.GitCache The cached status of files in the repository
local M = {
	root = "",
	cache = {},
}

local Status = require("oil-vcs.types").Status

---@type table<string, oil-vcs.Status | table<string, oil-vcs.Status>>
local status_match = {
	["M"] = Status.Modified,
	["A"] = Status.Added,
	["?"] = Status.Untracked,
	["!"] = Status.Ignored,
}

function M:status(path)
	local status = self.cache[path]

	if status then
		return status
	end
end

---@param callback fun(cache?: oil-vcs.GitCache)
function M:load_status(callback)
	vim.system({ "git", "status", "--porcelain", "--ignored" }, { cwd = self.root }, function(obj)
		if obj.code ~= 0 then
			callback(nil)
			return
		end

		local cache = {}

		local lines = vim.split(obj.stdout, "\n")

		for _, line in ipairs(lines) do
			local s1, s2, path = string.match(line, "^(.)(.) (.+)$")
			if s1 and s2 and path then
				local status = status_match[s1]
				if type(status) == "table" then
					status = status[s2]
				end

				if status then
					cache[path] = status
				end
			end
		end

		callback(cache)
	end)
end

---@param cache oil-vcs.GitCache The cached status of files in the repository
---@return oil-vcs.GitCache
function M:propagate_status(cache)
	return cache
end

function M:refresh()
	self:load_status(function(cache)
		if cache then
			self.cache = self:propagate_status(cache)
		end
	end)
end

function M:detect(path)
	local output = vim.fn.system(string.format("cd %s && git rev-parse --show-toplevel", path))
	return vim.v.shell_error == 0, output
end

function M:setup(path)
	self.root = path
	self:refresh()
end

return M

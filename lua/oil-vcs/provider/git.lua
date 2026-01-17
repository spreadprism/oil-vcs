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
	["M"] = Status.Modified, -- (M*)
	["A"] = Status.Added, -- (A*)
	["?"] = Status.Untracked, --(?*)
	["!"] = Status.Ignored, -- (?*)
	[" "] = { -- ( *)
		["M"] = Status.Modified, -- ( M)
		["A"] = Status.Added, -- ( A)
	},
}

function M:status(path)
	local status = M.cache[path]

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
					cache[vim.fs.joinpath(M.root, path)] = status
				end
			end
		end

		callback(cache)
	end)
end

---@param cache oil-vcs.GitCache The cached status of files in the repository
---@return oil-vcs.GitCache
function M:propagate_status(cache)
	-- TODO: implement
	return cache
end

---@param callback? fun()
function M:refresh(callback)
	M:load_status(function(cache)
		if cache then
			M.cache = M:propagate_status(cache)
		end
		if callback then
			callback()
		end
	end)
end

function M:detect(path)
	local output = vim.fn.system(string.format("cd %s && git rev-parse --show-toplevel", path))
	return vim.v.shell_error == 0, output
end

function M:setup(path)
	M.root = path
	M:refresh()
end

return M

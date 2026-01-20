---@type oil-vcs.ProviderInitiator
local M = {}

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

function GitProvider:refresh_defer()
	if self.timer then
		self.timer:stop()
	else
		self.timer = vim.loop.new_timer()
	end

	local callback = vim.schedule_wrap(function()
		self.timer:stop()
		self.timer:close()
		self.timer = nil
		self:refresh()
	end)
	self.timer:start(2000, 0, callback)
end

function M.detect(path)
	local output = vim.fn.system(string.format("cd %s && git rev-parse --show-toplevel", path))

	output = vim.trim(output)
	return vim.v.shell_error == 0, output
end

return M

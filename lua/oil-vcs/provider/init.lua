---@class oil-vcs.ProviderInitiator
---@field new fun(root: string): oil-vcs.Provider creates a new provider for the given root directory
---@field detect fun(path: string): (boolean, string) detects if the given path can be handled by this provider, returns (true, root) if it can

---@class oil-vcs.Provider
---@field root string root directory of the provider
---@field refresh fun(self)
---@field status fun(self, path: string): oil-vcs.Status|nil

local M = {}

---@type table<string, oil-vcs.Provider>
M.providers = {}

---@param path string
local function init_provider(path)
	local opts = require("oil-vcs.opts").opts()

	for _, initiator in pairs(opts.providers) do
		local can_handle, root = initiator.detect(path)
		vim.print({ can_handle = can_handle, root = root })
		if can_handle and root then
			local provider = initiator.new(root)
			M.providers[root] = provider
			return provider
		end
	end
end

---@param path string
---@overload fun(bufnr: integer): oil-vcs.Provider|nil
---@return oil-vcs.Provider|nil
local function get_provider(path)
	if type(path) == "number" then
		local buf = path
		local current_dir = require("oil").get_current_dir(buf)
		if not current_dir then
			return nil
		end
		path = current_dir
	end

	path = vim.fs.abspath(path)

	if vim.fn.isdirectory(path) == 0 then
		path = vim.fs.dirname(path)
	end

	for _, provider in pairs(M.providers) do
		if vim.startswith(path, provider.root) then
			return provider
		end
	end

	return init_provider(path)
end

---@param path? string
---@overload fun(bufnr?: integer)
function M.refresh(path)
	if path then
		local provider = get_provider(path)
		if provider then
			provider:refresh()
		end
	else
		for _, provider in pairs(M.providers) do
			provider:refresh()
		end
	end
end

---@param path string
function M.status(path)
	local provider = get_provider(path)
	if provider then
		return provider:status(path)
	end
end

return M

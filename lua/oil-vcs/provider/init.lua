---@class oil-vcs.Provider
---@field refresh fun(self, callback: fun()|nil)
---@field status fun(self, path: string): oil-vcs.Status|nil
---@field detect fun(self, path: string): boolean, string
---@field setup fun(self, path: string)

local M = {}

---@type oil-vcs.Provider
local provider

local timer = vim.loop.new_timer()

---@param opts oil-vcs.Opts
function M.setup(opts)
	local cwd = type(opts.cwd) == "function" and opts.cwd() or opts.cwd

	for _, p in ipairs(opts.providers) do
		---@diagnostic disable-next-line: param-type-mismatch
		if p:detect(cwd) then
			provider = p
			break
		end
	end

	if not provider then
		return
	end

	---@diagnostic disable-next-line: param-type-mismatch
	provider.setup(opts, cwd)
	timer:start(opts.cache_delay, opts.cache_delay, function()
		M.refresh()
	end)
end

function M.refresh(callback)
	if provider then
		provider:refresh(callback)
	end
end

function M.status(path)
	if provider then
		return provider:status(path)
	end
end

return M

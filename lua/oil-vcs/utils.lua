local M = {}

---@param cmd string
---@param path string?
---@return boolean, string
function M.system(cmd, path)
	if path then
		cmd = string.format("cd %s && %s", path, cmd) -- TODO: validate
	end
	local output = vim.fn.system(cmd)
	return vim.v.shell_error == 0, output
end

---@param cmd string
---@param path string
---@param callback
function M.system_defer(cmd, cwd string, callback)
	vim.system(cmd, {

	}, callback)
end

return M

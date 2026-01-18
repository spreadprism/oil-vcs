local M = {}

local GROUP_NAME = require("oil-vcs.opts").PLUGIN_PREFIX

local group = vim.api.nvim_create_augroup(GROUP_NAME, { clear = true })
local highlights = require("oil-vcs.highlights")
local provider = require("oil-vcs.provider")

local function user_autocmd()
	local opts = require("oil-vcs.opts").opts()

	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = opts.user_events,
		callback = function(_)
			provider.refresh()
		end,
	})
end
local function oil_autocmd()
	-- INFO: refresh
	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = { "OilActionsPost" },
		callback = function(_)
			provider.refresh() -- TODO: only refresh on dir actions paths
		end,
	})

	-- INFO: update buffer
	vim.api.nvim_create_autocmd({ "FileType" }, {
		group = group,
		pattern = { "oil" },
		callback = function()
			local buffer = vim.api.nvim_get_current_buf()

			vim.api.nvim_create_autocmd({
				"TextYankPost",
			}, {
				group = group,
				buffer = buffer,
				pattern = "*",
				callback = function()
					vim.schedule(function()
						highlights.update_buffer(buffer)
					end)
				end,
			})
			vim.api.nvim_create_autocmd({
				"BufModifiedSet",
				"BufEnter",
				"TextChanged",
				"TextChangedI",
			}, {
				group = group,
				buffer = buffer,
				callback = function()
					vim.schedule(function()
						highlights.update_buffer(buffer)
					end)
				end,
			})
		end,
	})
end
local function neogit_autocmd()
	-- INFO: refresh
	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = {
			"NeogitStatusRefreshed",
			"NeogitCommitComplete",
			"NeogitPullComplete",
		},
		callback = function(_)
			provider.refresh() -- TODO: only refresh on dir actions paths
		end,
	})
	vim.api.nvim_create_autocmd({ "FileType" }, {
		group = group,
		pattern = { "NeogitStatus" },
		callback = function()
			local buffer = vim.api.nvim_get_current_buf()

			vim.api.nvim_create_autocmd("BufLeave", {
				group = group,
				buffer = buffer,
				callback = function()
					provider.refresh()
				end,
			})
		end,
	})
end

---@param opts oil-vcs.Opts
function M.setup(opts)
	local autocmd = type(opts.autocmd) == "function" and opts.autocmd() or opts.autocmd

	if not autocmd then
		return
	end

	user_autocmd()
	oil_autocmd()

	if pcall(require, "neogit") then
		neogit_autocmd()
	end
end

return M

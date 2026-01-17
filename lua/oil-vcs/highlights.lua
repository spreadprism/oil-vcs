local M = {}

local default_highlights = {
	OilVcsAdded = { link = "Added" },
	OilVcsModified = { link = "DiagnosticWarn" },
	OilVcsRenamed = { link = "DiagnosticWarn" },
	OilVcsUntracked = { link = "NonText" },
	OilVcsIgnored = { link = "NonText" },
}

---@param opts oil-vcs.Opts
---Add highlight groups if they do not already exist and if they are in the defaults
function M.setup(opts)
	for _, hl in pairs(opts.hl) do
		local name, hl_opts = hl, default_highlights[hl]
		if hl_opts ~= nil then
			if vim.fn.hlexists(name) == 0 then
				vim.api.nvim_set_hl(0, hl, hl_opts)
			end
		end
	end
end

return M

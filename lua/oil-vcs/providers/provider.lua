---@meta

---@class oil-vcs.Provider
---@field refresh fun(self)
---@field status fun(self, path: string): oil-vcs.Status|nil
---@field detect fun(self, path: string): boolean, string
---@field setup fun(self, path: string)

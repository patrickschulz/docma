local M = {}

local pl = {
    pretty = require "pl.pretty",
}

local meta = {}
meta.__index = meta

function M.create(level)
    local self = {
        level = level
    }
    setmetatable(self, meta)
    return self
end

function meta.log(self, msg)
    if self.level then
        print(msg)
    end
end

function meta.log_table(self, t)
    local msg = pl.pretty.write(t)
    self:log(msg)
end

return M

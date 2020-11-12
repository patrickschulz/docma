local M = {}

local pretty = require "pl.pretty"
local path = string.format("%s/.knowledge/docconfig.lua", os.getenv("HOME"))

function M.load()
    local status, config = pcall(dofile, path)
    if status then
        return config
    else
        return {}
    end
end

function M.save(t)
    local str = "return " .. pretty.write(t)
    local file = io.open(path, "w")
    if not file then
        error("could not open config file for writing")
    end
    file:write(str)
    file:close()
end

return M

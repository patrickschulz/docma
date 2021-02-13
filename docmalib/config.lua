local M = {}

local pretty = require "pl.pretty"
local path = string.format("%s/.docma/config.lua", os.getenv("HOME"))
local docpath = string.format("%s/.docma/docconfig.lua", os.getenv("HOME"))

local function merge(t1, t2)
    for k, v in pairs(t2) do
        t1[k] = v
    end
end

function M.load()
    local ret = {}
    -- document configuration
    do
        local status, config = pcall(dofile, docpath)
        if status then
            merge(ret, config)
        end
    end
    -- general configuration (overwrites docconfig)
    do
        local status, config = pcall(dofile, path)
        if status then
            merge(ret, config)
        end
    end
    return ret
end

function M.save(t)
    local tosave = {
        last_documents = t.last_documents,
        last_search = t.last_search,
    }
    local str = "return " .. pretty.write(tosave)
    local file = io.open(docpath, "w")
    if not file then
        error("could not open config file for writing")
    end
    file:write(str)
    file:close()
end

return M

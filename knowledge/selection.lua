local M = {}

local interface = require "knowledge.interface"

function M.choose(data)
    local result = {}
    if #data > 1 then
        local index = interface.show(data)
        for _, i in ipairs(index) do
            table.insert(result, data[i])
        end
    else
        table.insert(result, data[1])
    end
    return result
end

return M

local M = {}

local pl = {
    stringx = require "pl.stringx",
}

function M.get_string(prompt)
    local prompt = prompt or "Enter a string: "
    io.write(prompt)
    local str = io.read("l")
    return str
end

function M.get_multiple_strings(prompt)
    local prompt = prompt or "Enter a list of strings (one string per line). An empty line ends the input"
    print(prompt)
    local strs = {}
    repeat
        local str = M.get_string("> ")
        table.insert(strs, str)
    until str == ""
    table.remove(strs) -- last added string is empty
    return strs
end

function M.get_index_number(numres)
    local index = {}
    local found = false
    while not found do
        io.write(string.format("Enter a number, a list of numbers or a range (< %s): ", numres + 1))
        local str = io.read("l")
        if str == "" then
            return {}
        end
        if string.match(str, "%-") then -- range
            local min, max = string.match(str, "(%d+)%s*%-%s*(%d+)")
            for i = tonumber(min), tonumber(max) do
                table.insert(index, i)
            end
            found = true
        elseif string.match(str, ",") then -- list
            local strnums = pl.stringx.split(str, ",")
            for _, i in ipairs(strnums) do
                table.insert(index, tonumber(i))
            end
            found = true
        else
            table.insert(index, tonumber(str))
            found = true
        end
    end
    return index
end

return M

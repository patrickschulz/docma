local M = {}

local pl = {
    stringx = require "pl.stringx",
    tablex  = require "pl.tablex",
    text    = require "pl.text"
}

function M.remove_duplicate_entries(tab)
    local hash = {}
    local res = {}

    for _, v in ipairs(tab) do
        if not hash[v] then
            table.insert(res, v)
            hash[v] = true
        end
    end
    return res
end

function M.append(t1, t2)
    for _, v in ipairs(t2) do
        table.insert(t1, v)
    end
end

function M.tabcon(data, sep, pre, post, newline)
    local pre = pre or ""
    local post = post or ""
    local sep = sep or ", "
    if newline then
        sep = sep .. "\n"
    end
    local fun = function(str)
        return string.format("%s%s%s", pre, str, post)
    end
    local processed = pl.tablex.map(fun, data)
    local tabstr = table.concat(processed, sep)
    if newline then
        tabstr = "\n" .. pl.text.indent(tabstr, 4)
    end
    return tabstr
end

function M.indent(str)
    local lines = {}
    for line in pl.stringx.lines(str) do
        table.insert(lines, string.format("    %s", line))
    end
    return table.concat(lines, "\n")
end

function utf8.format(fmt, ...)
    local args, strings, pos = {...}, {}, 0
    for spec in fmt:gmatch'%%.-([%a%%])' do
        pos = pos + 1
        local s = args[pos]
        if spec == 's' and type(s) == 'string' and s ~= '' then
            table.insert(strings, s)
            args[pos] = '\1'..('\2'):rep(utf8.len(s)-1)
        end
    end
    return (
    fmt:format(table.unpack(args))
    :gsub('\1\2*', function() return table.remove(strings, 1) end)
    )
end

return M

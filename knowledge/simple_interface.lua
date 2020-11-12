local M = {}

local input = require "knowledge.input"
local color = require "knowledge.color"

local function get_authors(authors)
    local c = "violet"
    if #authors > 1 then
        return color.text(authors[1] .. " et al", c)
    else
        return color.text(authors[1], c)
    end
end

local function get_title(title)
    return color.text(title, "green")
end

local function print_entry(document, options)
    local options = options or {}
    local prefix = options.prefix
    local suffix = options.suffix

    if prefix then
        io.write(prefix)
    end

    local authorstr = get_authors(document.authors)
    local titlestr = get_title(document.title)
    local width = 40
    local fmt = string.format("%%-%ds   %%s", width + string.len(authorstr) - utf8.len(authorstr))
    io.write(string.format(fmt, authorstr, titlestr))

    if suffix then
        io.write(suffix)
    end
    io.write("\n")
end

function M.enable_color(c)
    color.use(c)
end

local function sort(data, what)
    local comp
    if what == "title" then
        comp = function(lhs, rhs) 
            return lhs.title < rhs.title
        end
    elseif what == "author" then
        comp = function(lhs, rhs) 
            return lhs.authors[1] < rhs.authors[1]
        end
    elseif what == "date" then
        comp = function(lhs, rhs) 
            local left = tonumber(lhs.date or (lhs.bibtex and lhs.bibtex.year) or 0)
            local right = tonumber(rhs.date or (rhs.bibtex and rhs.bibtex.year) or 0)
            return left < right
        end
    else
        return
    end
    table.sort(data, comp)
end

function M.show(data)
    --sort(data, sortcrit)
    for i, document in ipairs(data) do
        print_entry(document, { prefix = string.format("[%2d] ", i) })
    end
    local index = input.get_index_number(#data)
    return index
end

return M

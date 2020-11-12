local M = {}

local pl = {
    tablex  = require "pl.tablex",
    stringx = require "pl.stringx",
    list    = require "pl.List",
    utils   = require "pl.utils"
}

local input = require "knowledge.input"
local load  = require "knowledge.load"

local write = true -- used for debugging

local function sanitize(title)
    local replacements = {
        ["/"] = " "
    }
    return string.gsub(title, ".", replacements)
end

-- this function processes individual bibtex entries, based on their key (author, title, etc.)
-- unknown or unused keys are just passed, without any processing
-- With this, more features can be added without breaking anything. If a key has no processing functions, nothing happens
local function process(key, value)
    local lookup = {
        author = function(v) return pl.list.new(pl.stringx.split(v, " and ")) end,
        keywords = function(v) return pl.list.new(pl.stringx.split(v, ";")) end,
        month = function(v) 
            if string.match(v, "^%d+$") then 
                return v 
            else
                local months = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }
                return pl.tablex.index_map(months)[v] -- reverse table and return numerical index
            end
        end,
    }
    local f = lookup[key]
    if f then
        return lookup[key](value)
    else
        return value
    end
end

local function bibtexentrytitle(author, year)
    local pattern = "(%w+)$"
    local lastname = string.match(author, pattern)
    return string.lower(lastname .. year)
end

local function update_datafile(entry)
    if write then
        local data = load.read_datafile("data.lua")
        table.insert(data, entry)
        load.write_datafile(data, "data.lua")
    end
end

function M.set_nowrite(nowrite)
    write = not nowrite
end

function M.interactive(path)
    local title = input.get_string("Enter title: ")
    local authors = input.get_multiple_strings("Enter authors (one per line): ")
    local keywords = input.get_multiple_strings("Enter keywords (one per line): ")
    local entry = {
        title = title,
        authors = authors,
        keywords = keywords,
        path = path
    }

    update_datafile(entry)
end

local function parse_bibtex(bibtexfile)
    local str = pl.utils.readfile(bibtexfile)

    local pubtype, content = string.match(str, "@(%w+)(%b{})")
    -- remove outer braces from content
    content = string.sub(content, 2, -2)

    local bibref = { }
    for key, value in string.gmatch(content, "(%w+)%s*=%s*(%b{})") do
        value = string.gsub(value, "[{}]", "") -- remove ALL braces
        if value ~= "" then
            bibref[key] = process(key, value)
        end
    end

    local entry = {
        title    = bibref.title,
        authors  = bibref.author,
        keywords = bibref.keywords or {},
        path     = string.format("%s.pdf", sanitize(bibref.title)),
        pubtype  = string.lower(pubtype),
        unread   = true,
        bibtex   = bibref
    }

    return entry
end

function M.bibtex(bibtexfile, pdffilename)
    local entry = parse_bibtex(bibtexfile)

    -- rename pdf file
    if write then
        os.rename(pdffilename, entry.path)
    end

    update_datafile(entry)

    return entry
end

return M

local M = {}

local pl = {
    pretty = require "pl.pretty"
}

local util = require "docmalib.util"

local function create_citekey(document)
    local year = document.bibtex.year
    local lastname
    if string.match(document.authors[1], ",") then -- lastname, surname
        lastname = string.match(document.authors[1], "^(%w+),")
    else
        lastname = string.match(document.authors[1], "(%w+)$")
    end
    return string.format("%s%s", string.lower(lastname), year)
end

local function format_bibtex(document)
    local bib = document.bibtex
    local bodyt = {}
    local indent = "    "
    for k, v in pairs(bib) do
        if k ~= "author" then -- use document author
            local line = string.format("%s%s = {%s}", indent, k, v)
            table.insert(bodyt, line)
        end
    end
    -- insert authors
    table.insert(bodyt, string.format("%sauthor = {%s}", indent, util.tabcon(document.authors, " and ", "{", "}")))
    local body = table.concat(bodyt, ",\n")
    local citekey = create_citekey(document)
    return string.format("@%s{%s,\n%s\n}", document.pubtype or "UNKNOWN", citekey, body)
end

local function format_simple(document)
    local typ = document.pubtype or "UNKNOWN"
    local content = {
        string.format("@%s{%s", typ, document.authors[1]),
        string.format("    title = { %s }", document.title),
        string.format("    author = { %s }", table.concat(document.authors, ", ")),
        "}"
    }
    return table.concat(content, ",\n")
end

function M.print_bibtex(results, filename)
    local file = io.open(filename, "a+")
    for _, document in ipairs(results) do
        local fmtfun
        if document.bibtex then
            fmtfun = format_bibtex
        else
            fmtfun = format_simple
        end
        file:write("\n")
        file:write(fmtfun(document))
    end
    file:close()
end

function M.print_entry(results)
    for _, document in ipairs(results) do
        pl.pretty.dump(document)
    end
end

return M

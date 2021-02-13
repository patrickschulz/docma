-- general entry-handling functions
local M = {}

local pl = {
    text = require "pl.text"
}

local util = require "docmalib.util"

local function export_bibtex(entry)
    if not entry.bibtex then
        return ""
    end
    local lines = {}
    for k, v in pairs(entry.bibtex) do
        if k ~= "author" then -- author information is in main entry
            table.insert(lines, string.format('    %s = "%s"', k, v))
        end
    end
    bib = string.format("bibtex = {\n%s\n}", table.concat(lines, ",\n"))
    return bib
end

local function export_main(entry)
    local lines = {
        string.format("title = %q", entry.title),
        string.format("authors = { %s }", util.tabcon(entry.authors, ",", '"', '"')),
        string.format("keywords = { %s }", util.tabcon(entry.keywords, ",", '"', '"')),
        string.format("path = %q", entry.path),
    }
    if entry.unread then
        table.insert(lines, string.format("unread = %s", entry.unread))
    end
    if entry.pubtype then
        table.insert(lines, string.format("pubtype = %q", entry.pubtype))
    end
    return table.concat(lines, ",\n")
end

function M.export_single(entry)
    local main = export_main(entry)
    local bibtex = export_bibtex(entry)
    local full = util.indent(main)
    if bibtex ~= "" then
        full = full .. ",\n" .. util.indent(bibtex)
    end
    return string.format("{\n%s\n}", full)
end

function M.export_all(data)
    local entries = {}
    for _, document in ipairs(data) do
        local estr = M.export_single(document)
        table.insert(entries, util.indent(estr))
    end
    return table.concat(entries, ",\n")
end

return M

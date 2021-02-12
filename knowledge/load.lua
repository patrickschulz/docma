local M = {}

local pl = {
    tablex = require "pl.tablex",
    path   = require "pl.path",
    util   = require "pl.utils",
    text   = require "pl.text",
    dir    = require "pl.dir",
    list   = require "pl.List",
}

local util = require "knowledge.util"
local entry = require "knowledge.entry"

local databasepaths = {
    string.format("%s/.knowledge/data", os.getenv("HOME"))
}

local function datadirs(root)
    local paths = {}
    for root, dirs in pl.dir.walk(root) do
        if #dirs == 0 then
            table.insert(paths, root)
        end
    end
    local index = 0
    local it = function()
        index = index + 1
        return paths[index]
    end
    return it
end

local function datafiles(root)
    local files = pl.dir.getallfiles(root, "*/data.lua")
    local index = 0
    local it = function()
        index = index + 1
        local file = files[index]
        return file, pl.path.dirname(file or "")
    end
    return it
end

local function load_datafile(fullpath)
    local str = pl.util.readfile(fullpath)
    local fun, msg = load("return " .. str)
    if not fun then
        print(string.format("error in file '%s'", fullpath))
        print(string.format(" -> %s", msg))
        return
    end
    return fun()
end

local function process_data(data, root)
    for _, entry in ipairs(data) do
        entry.authors = pl.list.new(entry.authors)
        -- check if path is relative, if yes, prepend root
        if not pl.path.isabs(entry.path) then
            entry.savepath = entry.path -- save for restoration when exporting
            entry.path = pl.path.join(root, entry.path)
        end
        if entry.bibtex and entry.bibtex.author then
            entry.bibtex.author = pl.list.new(entry.bibtex.author)
        end
    end
end

local function find_orphans(root, documents)
    local notfound = {}
    local files = pl.dir.getfiles(root, "*.pdf")
    for k, v in ipairs(files) do
        if not pl.tablex.find_if(documents, function(entry, file) return entry.path == file end, v) then
            table.insert(notfound, v)
        end
    end
    return notfound
end

local function find_dead_links(root, documents)
    for _, entry in ipairs(documents) do

    end
end

function M.read_datafile(fullpath, verbose)
    if not pl.path.exists(fullpath) then 
        return
    end
    local data = load_datafile(fullpath)
    if not data then return end

    local root = pl.path.dirname(fullpath)
    if verbose then
        print(string.format("read datafile in %s with %d entries", root, #data))
    end

    process_data(data, root)

    return data
end

function M.write_datafile(data, filename)
    local datastr = entry.export_all(data)

    local file = io.open(filename, "w")
    file:write(string.format("{\n%s\n}\n", datastr))
    file:close()
end

function M.read_data(datafilename, verbose, onlylocal)
    local documents = {}

    if onlylocal then
        local cd = pl.path.currentdir()
        local fullpath = pl.path.join(cd, datafilename)
        local data = M.read_datafile(fullpath, verbose)
        if data then
            util.append(documents, data)
        end
    else
        for _, dbpath in ipairs(databasepaths) do
            for fullpath, root in datafiles(dbpath) do
                local data = M.read_datafile(fullpath, verbose)
                if data then
                    util.append(documents, data)
                end
            end
        end
    end

    return documents 
end

function M.check_all(datafilename)
    for _, dbpath in ipairs(databasepaths) do
        for root in datadirs(dbpath) do
            local fullpath = string.format("%s/data.lua", root)
            if not pl.path.exists(fullpath) then
                print(string.format("leaf directory contains no data file: %s", root))
            end
        end
    end
    for _, dbpath in ipairs(databasepaths) do
        for fullpath, root in datafiles(dbpath) do
            local status, data = pcall(load_datafile, fullpath)
            if not status then
                print(string.format("syntax error in %q", fullpath))
                print(string.format(" -> %s", data))
            else
                -- check if datafile can be processed and exported
                local process, msg = pcall(process_data, data, root)
                if not process then
                    print(string.format("data malformed for processing in %q (%s)", fullpath, msg))
                end
                local export = pcall(entry.export_all, data)
                if not export then
                    print(string.format("data malformed for export in %q", fullpath))
                end

                -- check orphaned pdf files
                local notfound = find_orphans(root, data)
                for _, v in ipairs(notfound) do
                    print(string.format("document not in datafile: %s", v))
                end
            end
        end
    end
end

return M

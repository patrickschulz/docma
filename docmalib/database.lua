local M = {}

local pl = {
    tablex = require "pl.tablex",
    path   = require "pl.path",
    util   = require "pl.utils",
    text   = require "pl.text",
    dir    = require "pl.dir",
    list   = require "pl.List",
}

local util = require "docmalib.util"
local entry = require "docmalib.entry"

local databasepaths = {
    string.format("%s/.docma/data", os.getenv("HOME"))
}
local datafilename = "data.lua"

function M.set_datafilename(dfn)
    datafilename = dfn
end

local function load_datafile(fullpath)
    local str = pl.util.readfile(fullpath)
    local fun, msg = load("return " .. str)
    if not fun then
        print(string.format("error in file '%s'", fullpath))
        print(string.format(" -> %s", msg))
        return
    end
    local data = fun()
    for _, entry in ipairs(data) do
        entry.datafilepath = fullpath
    end
    return data
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

function M.update_database()

end

function M.set_local()
    databasepaths = {
        pl.path.currentdir()
    }
end

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
    local files = pl.dir.getallfiles(root, string.format("*/%s", datafilename))
    local index = 0
    local it = function()
        index = index + 1
        local file = files[index]
        return file, pl.path.dirname(file or "")
    end
    return it
end


function M.read_data(verbose, onlylocal)
    local documents = {}
    for _, dbpath in ipairs(databasepaths) do
        for fullpath, root in datafiles(dbpath) do
            local data = M.read_datafile(fullpath, verbose)
            if data then
                util.append(documents, data)
            end
        end
    end
    return documents 
end

function M.check_all()
    for _, dbpath in ipairs(databasepaths) do
        for root in datadirs(dbpath) do
            local fullpath = string.format("%s/%s", root, datafilename)
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

local function has_keyword(document, keyword)
    -- escape minus/dash (this is an active character in string.match)
    keyword = string.gsub(keyword, "%-", "%%-")
    for _, kw in ipairs(document.keywords) do
        if string.match(string.lower(kw), string.lower(keyword)) then
            return true
        end
    end
end

local function has_author(document, key)
    for _, author in ipairs(document.authors) do
        if string.match(string.lower(author), string.lower(key)) then
            return true
        end
    end
end

local function has_title(document, title)
    return string.match(string.lower(document.title), string.lower(title))
end

local function has_tag(document, tag)
    return string.match(document.tag or "", tag)
end

local function check_document(document, key)
    local check = nil
    if key.author then
        check = check or has_author(document, key.key)
    end
    if key.title then
        check = check or has_title(document, key.key)
    end
    if key.keyword then
        check = check or has_keyword(document, key.key)
    end
    if key.tag then
        check = check or has_tag(document, key.key)
    end
    return check
end

local function has_keys(document, keys, comp)
    local ret = comp == "and"
    for _, key in ipairs(keys) do
        if not check_document(document, key) then
            return not ret
        end
    end
    return ret
end

function M.parse_keys(keys, title, author, keyword, tag)
    local new = {}
    -- if all keys are nil, then treat all as true
    if not (title or author or keyword or tag) then
        title   = true
        author  = true
        keyword = true
        tag     = true
    end
    for _, key in ipairs(keys) do
        table.insert(new, 
            {
                key = key,
                title = title,
                author = author,
                keyword = keyword,
                tag = tag
            }
        )
    end
    return new
end

local function matches_rating(document, rating)
    local dr = document.rating or 0
    return dr >= rating
end

local function unread_status(document, unread)
    return not unread or document.unread
end

local function fits_date(document, datespec)
    local date = document.date or (document.bibtex and document.bibtex.year) -- TODO: check more than only the year
    if date then
        local opt, year = string.match(datespec, "([<>=]+)%s*(%d+)") -- TODO: implement a better parser
        if opt == ">" then 
            return date > year
        elseif opt == "<" then
            return date < year
        elseif opt == ">=" then 
            return date >= year
        elseif opt == "<=" then
            return date <= year
        else
            print("unknown opt:", opt)
        end
    end
    return true
end

function M.search(documents, keys, grep, rating, unread, comp, date)
    local results = {}
    for _, document in ipairs(documents) do
        if has_keys(document, keys, comp) 
        and matches_rating(document, rating) 
        and unread_status(document, unread) 
        and fits_date(document, date)
        then
            table.insert(results, document)
        end
    end
    results = util.remove_duplicate_entries(results)
    if grep ~= "" then
        local t = results
        results = {}
        for _, document in ipairs(t) do
            local path = document.path
            local cmd = string.format("pdfgrep -ic %s '%s'", grep, path)
            local p = io.popen(cmd)
            local numfound = tonumber(p:read())
            if numfound > 0 then
                table.insert(results, document)
            end
        end
    end
    return results
end

return M

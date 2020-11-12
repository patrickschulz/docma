local M = {}

local util = require "knowledge.util"

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

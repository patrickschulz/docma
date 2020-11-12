local M = {}

local pl = {
    dir = require "pl.dir"
}

function M.show_last_search(config)
    if config.last_search then
        for _, key in ipairs(config.last_search) do
            print(key)
        end
    end
end

function M.show_last_documents(config)
    if config.last_documents then
        for _, document in ipairs(config.last_documents) do
            print(document.title)
        end
    end
end

function M.copy(documents)
    for _, document in ipairs(documents) do
        local fullpath = document.path
        pl.dir.copyfile(fullpath, ".")
    end
end

function M.show_path(documents)
    for _, document in ipairs(documents) do
        print(document.path)
    end
end

return M

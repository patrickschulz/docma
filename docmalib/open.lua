local M = {}

local viewer = "zathura --fork" -- fallback solution

function M.set_viewer(v)
    if v then
        viewer = v
    end
end

function M.open_pdf(path)
    local cmd = string.format("%s %q > /dev/null", viewer, path)
    os.execute(cmd)
end

function M.open_documents(results)
    for _, document in ipairs(results) do
        local path = document.path
        M.open_pdf(path)
    end
end

return M

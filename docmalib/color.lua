local M = {}

local use = true
local colorcodes = {
    black     = string.char(27) .. "[30m",
    red       = string.char(27) .. "[1;31m",
    green     = string.char(27) .. "[32m",
    yellow    = string.char(27) .. "[1;33m",
    blue      = string.char(27) .. "[34m",
    violet    = string.char(27) .. "[35m",
    lightblue = string.char(27) .. "[36m",
    white     = string.char(27) .. "[37m",
    reset     = string.char(27) .. "[0m"
}

function M.use(b)
    use = b
end

function M.text(text, color)
    if use then
        return colorcodes[color] .. text .. colorcodes["reset"]
    else
        return text
    end
end

return M

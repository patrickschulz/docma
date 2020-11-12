local curses = require "curses"
local color = require "color"
local util = require "util"

local M = {}

local function _sort(state, data)
    local comp
    local what = state.sort
    if state.issorted then return end
    state.issorted = true
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

local function get_authors(document)
    if #document.authors > 1 then
        return document.authors[1] .. " et al"
    else
        return document.authors[1]
    end
end

local function get_title(document)
    return document.title
end

local function get_entry_line(document, options)
    local options = options or {}
    local prefix = options.prefix
    local suffix = options.suffix

    local res = {}

    if prefix then
        table.insert(res, prefix)
    end

    local authorstr = get_authors(document.authors)
    local titlestr = get_title(document.title)
    local width = 40
    local fmt = string.format("%%-%ds   %%s", width + string.len(authorstr) - utf8.len(authorstr))
    table.insert(res, string.format(fmt, authorstr, titlestr))

    if suffix then
        table.insert(res, suffix)
    end
    return table.concat(res)
end

local function limit_string(str, max)
    return string.sub(str, 1, utf8.offset(str, max))
end

local function fix_string(str, width, contchar, fill)
    local str = tostring(str)
    local contchar = contchar or "~"
    local fill = fill or " "
    str = str .. string.rep(fill, math.max(width - #str, 0))
    if utf8.len(str) > width then
        str = string.sub(str, 1, utf8.offset(str, width) - #contchar) .. contchar
    end
    return str
end

local function _assemble_line(state, parts, factors, totalwidth, skip)
    local t = {}
    local skip = skip or 1
    local totalwidth = (totalwidth or state.linewidth) - (#parts - 1) * skip
    for i = 1, #parts do
        table.insert(t, fix_string(parts[i], math.floor(totalwidth * factors[i])))
    end
    return table.concat(t, string.rep(" ", skip))
end

local function _draw_title(state)
    local x = state.margin
    local y = state.titlelines - 1
    local width = state.cols - 3 * state.margin
    local str = _assemble_line(state, { "Authors", "Title" }, { state.authorfactor, 1 - state.authorfactor })
    state.screen:mvaddstr(y, x + 4, str) -- compensate x for the displayed number (not present in the title line)
end

local function _draw_lines(state, data)
    local x = state.margin
    local y = state.titlelines
    for i = state.startline, state.endline do
        if state.marked[i] then
            state.screen:mvaddstr(y, 0, "*")
        else
            state.screen:mvaddstr(y, 0, " ")
        end
        local label = string.format("%2d: ", i)
        local line = _assemble_line(state, 
            { get_authors(data[i]), get_title(data[i]) }, 
            { state.authorfactor, 1 - state.authorfactor }, 
            state.cols + 1 - #label - 2 * state.margin -- +1: one-off?, -4: space for numeric label
        )
        local str = string.format("%s%s", label, line)
        if y == state.currentline then
            state.screen:attron(curses.A_STANDOUT )
        end
        state.screen:mvaddstr(y, x, str)
        state.screen:attroff(curses.A_STANDOUT )
        y = y + 1
    end
end

local function _draw_info(state, document)
    local y = state.rows + state.skip + 1
    state.screen:move(y - 1, 1)
    state.screen:hline(curses.ACS_HLINE, state.cols - 2)
    local width = math.floor(state.cols - state.cols * state.helpfactor - state.margin - 12 - 10)
    -- clear info box
    for i = 1, state.infolines - 1 do
        state.screen:mvaddstr(y + i, state.margin, string.format("%-12s%s", "", fix_string("", width)))
    end
    -- draw info
    if state.info == "bibtex" then
        state.screen:mvaddstr(y + 0, state.margin, string.format("%-12s", "Bibtex"))
        if document.bibtex then
            state.screen:mvaddstr(y + 1, state.margin, string.format("%s", document.pubtype))
            local i = 2
            for k, v in pairs(document.bibtex) do
                if i >= state.infolines then break end
                state.screen:mvaddstr(y + i, state.margin, string.format("%-12s%s", fix_string(k, 12), fix_string(v, width)))
                i = i + 1
            end
        end
    elseif state.info == "info" then
        local authors = util.tabcon(document.authors)
        state.screen:mvaddstr(y + 0, state.margin, string.format("%-12s", "Entry Data"))
        state.screen:mvaddstr(y + 1, state.margin, string.format("%-12s%s", "Authors:", fix_string(authors, width)))
        state.screen:mvaddstr(y + 2, state.margin, string.format("%-12s%s", "Keywords:", "bar"))
        state.screen:mvaddstr(y + 3, state.margin, string.format("%-12s%s", "Path:", fix_string(document.path, width)))
    elseif state.info == "debug" then
        state.screen:mvaddstr(y + 0, state.margin, string.format("%-15s", "Debug"))
        state.screen:mvaddstr(y + 1, state.margin, string.format("%-15s%d", "startline:", state.startline))
        state.screen:mvaddstr(y + 2, state.margin, string.format("%-15s%d", "endline:", state.endline))
        state.screen:mvaddstr(y + 3, state.margin, string.format("%-15s%d", "currentline:", state.currentline))
        state.screen:mvaddstr(y + 4, state.margin, string.format("%-15s%d", "rows:", state.rows))
        state.screen:mvaddstr(y + 5, state.margin, string.format("%-15s%d", "total rows:", curses.lines()))
        state.screen:mvaddstr(y + 6, state.margin, string.format("%-15s%d", "infolines:", state.infolines))
        state.screen:mvaddstr(y + 7, state.margin, string.format("%-15s%d", "datalen:", state.datalen))
        state.screen:mvaddstr(y + 8, state.margin, string.format("%-15s%d", "skip:", state.skip))
        state.screen:mvaddstr(y + 9, state.margin, string.format("%-15s%s", "sort:", state.sort))
    elseif state.info == "entry" then
        state.screen:mvaddstr(y + 0, state.margin, string.format("%-15s", "Entry"))
        state.screen:mvaddstr(y + 1, state.margin, string.format("%-15s%d", "startline:", state.startline))
        state.screen:mvaddstr(y + 2, state.margin, string.format("%-15s%d", "endline:", state.endline))
        state.screen:mvaddstr(y + 3, state.margin, string.format("%-15s%d", "currentline:", state.currentline))
        state.screen:mvaddstr(y + 4, state.margin, string.format("%-15s%d", "rows:", state.rows))
        state.screen:mvaddstr(y + 5, state.margin, string.format("%-15s%d", "total rows:", curses.lines()))
        state.screen:mvaddstr(y + 6, state.margin, string.format("%-15s%d", "infolines:", state.infolines))
        state.screen:mvaddstr(y + 7, state.margin, string.format("%-15s%d", "datalen:", state.datalen))
        state.screen:mvaddstr(y + 8, state.margin, string.format("%-15s%d", "skip:", state.skip))
    end
end

local function _draw_help(state)
    if state.displayhelp then
        local x = math.floor(state.cols * (1 - state.helpfactor))
        local y = state.rows + state.skip + 1
        local helpstr = {
            "   h    - show this help",
            "   s    - change sorting",
            "   j    - scroll down",
            "   k    - scroll up",
            "   m    - mark/unmark",
            "<enter> - confirm selection",
            "   q    - quit without selection",
            "   b    - show bibtex data",
            "   i    - show regular entry data",
            "   d    - show debugging information",
        }
        for i, line in ipairs(helpstr) do
            state.screen:mvaddstr(y + i - 1, x, line)
        end
    end
end

local function _change_sort(state)
    state.issorted = false
    if state.sort == "title" then
        state.sort = "author"
    elseif state.sort == "author" then
        state.sort = "date"
    elseif state.sort == "date" then
        state.sort = "title"
    else
        state.sort = "author"
    end
end

local function _scroll_down(state)
    state.currentline = state.currentline + 1
    if state.currentline > state.datalen then
        state.currentline = state.currentline - 1
    end
    if state.currentline > state.rows then
        state.startline = math.min(state.startline + 1, state.datalen - state.rows + 1)
        state.endline = math.min(state.endline + 1, state.datalen)
        state.currentline = state.currentline - 1
    end
end

local function _scroll_up(state)
    state.currentline = state.currentline - 1
    if state.currentline < 1 then
        state.startline = math.max(state.startline - 1, 1)
        state.endline = math.max(state.endline - 1, math.min(state.datalen, state.rows))
        state.currentline = state.currentline + 1
    end
end

local function _reset_state(state)
    state.currentline = 1 -- lines are numbered starting from 1
    state.rows        = curses.lines() - (state.titlelines + state.infolines + state.skip)
    state.cols        = curses.cols()
    state.endline     = math.min(state.datalen, state.rows)
    state.linewidth   = state.cols - 3 * state.margin
end

local function _resize_event(state)
    _reset_state(state)
    state.screen:clear()
end

local function _mark(state)
    state.marked[state.startline + state.currentline - 1] = not state.marked[state.startline + state.currentline - 1]
    _scroll_down(state)
end

local function _show_bibtex(state)
    state.info = "bibtex"
end

local function _show_info(state)
    state.info = "info"
end

local function _show_debug(state)
    state.info = "debug"
end

local function _toggle_help(state)
    state.displayhelp = not state.displayhelp
    if not displayhelp then
        state.screen:clear()
    end
end

local function _show_entry(state)
    state.info = "entry"
end

local function _input(state)
    local code = state.screen:getch()

    if code == 410 then _resize_event(state)  end
    if code == 13 then return "index"         end

    local ch
    if code < 256 then ch = string.char(code) end
    if ch == "s" then _change_sort(state)     end
    if ch == "q" then return "quit"           end
    if ch == "j" then _scroll_down(state)     end
    if ch == "k" then _scroll_up(state)       end
    if ch == "m" then _mark(state)            end
    if ch == "b" then _show_bibtex(state)     end
    if ch == "i" then _show_info(state)       end
    if ch == "h" then _toggle_help(state)     end
    if ch == "d" then _show_debug(state)      end
    if ch == "e" then _show_entry(state)      end
end

local function _get_current_index(state)
    return state.currentline + state.startline - 1
end

local function _show(data)
    local state = {
        screen          = curses.initscr(),
        titlelines      = 1,    -- number of title lines
        startline       = 1,
        infolines       = 10,   -- lines of space for info
        skip            = 1,    -- skip line between list and info
        margin          = 3,    -- left and right margin
        helpfactor      = 0.20, -- space for help display on the right
        authorfactor    = 0.15, -- space for authors in the list display
        displayhelp     = true, -- start with displayed help
        marked          = {},   -- list of marked documents
        datalen         = #data,
        info            = "info",
        sort            = "title",
        issorted        = false,
    }
    _reset_state(state)
    curses.cbreak()    -- disable line buffering
    curses.echo(false) -- don't echo characters
    curses.nl(false)   -- disable newline
    curses.curs_set(0) -- hide cursor
    while true do
        _sort(state, data)
        _draw_title(state)
        _draw_lines(state, data)
        _draw_info(state, data[_get_current_index(state)])
        _draw_help(state)
        state.screen:refresh()

        local status = _input(state)
        if status == "index" then
            curses.endwin()
            local index = {}
            for idx = 1, state.datalen do
                if state.marked[idx] then
                    table.insert(index, idx)
                end
            end
            if #index > 0 then
                return index
            else
                return { _get_current_index(state) }
            end
        elseif status == "quit" then
            curses.endwin()
            break
        end
    end
end

function M.enable_color(c)
    color.use(c)
end

function M.show(data)
    -- To display Lua errors, we must close curses to return to normal terminal mode, and then write the error to stdout.
    local function err(err)
        curses.endwin()
        print "Caught an error:"
        print(debug.traceback(err, 2))
        os.exit(1)
    end

    local status, index = xpcall(_show, err, data)
    if status then
        return index or {}
    end
end

return M

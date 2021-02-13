local status, module = pcall(require, "docmalib.curses_interface")
if status then
    return module
end

-- fallback solution
return require "docmalib.simple_interface"

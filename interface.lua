local status, module = pcall(require, "curses_interface")
if status then
    return module
end

-- fallback solution
return require "simple_interface"

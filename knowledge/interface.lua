local status, module = pcall(require, "knowledge.curses_interface")
if status then
    return module
end

-- fallback solution
return require "knowledge.simple_interface"

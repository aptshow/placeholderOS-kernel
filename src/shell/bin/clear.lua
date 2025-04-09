-- Clear command for clearing the terminal screen
return {
    name = "clear",
    description = "Clears the terminal screen",
    required_permission = "basic",
    required_group = "guest",
    help = "Usage: clear\n\n" ..
           "Clears the terminal screen and resets the cursor position.",
    
    execute = function(...)
        term.clear()
        term.setCursorPos(1, 1)
    end
}
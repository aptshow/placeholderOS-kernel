-- Logout command for signing out of the current session
return {
    name = "logout",
    description = "Logs out the current user and returns to the login screen",
    required_permission = "basic",
    required_group = "guest",
    help = "Usage: logout\n\n" ..
           "Logs out the current user and returns to the login screen.",
    
    execute = function(shell, ...)
        print("Logging out...")
        
        if shell and type(shell) == "table" and type(shell.exit) == "function" then
            shell.exit()
        else
            -- Fallback - set global logout flag
            _G._LOGOUT_REQUESTED = true
        end
        
        return true
    end
}
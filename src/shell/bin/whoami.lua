-- whoami command - shows the current user information
return {
    name = "whoami",
    description = "Shows the current user information",
    required_permission = "basic",
    required_group = "guest",   -- Lowest level group that should have access
    help = "Usage: whoami\n\n" ..
           "Displays information about the currently logged in user.",
    
    execute = function(shellEnv, ...)
        if shellEnv and shellEnv.currentUser then
            print("User: " .. shellEnv.currentUser.name)
            print("Group: " .. shellEnv.currentUser.group)
            
            print("Permissions:")
            for _, perm in ipairs(shellEnv.currentUser.permissions) do
                print("  - " .. perm)
            end
            
            return true
        elseif _G.CURRENT_USER then
            print("User: " .. _G.CURRENT_USER)
            
            if _G.SHELL_USER then
                print("Group: " .. (_G.SHELL_USER.group or "unknown"))
                
                if _G.SHELL_USER.permissions then
                    print("Permissions:")
                    for _, perm in ipairs(_G.SHELL_USER.permissions) do
                        print("  - " .. perm)
                    end
                end
            else
                print("Group: unknown")
                print("Permissions: unknown")
            end
            
            return true
        else
            print("Cannot determine current user. Please contact system administrator.")
            return false
        end
    end
}
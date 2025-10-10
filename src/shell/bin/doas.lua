local doas = {}

doas.name = "doas"
doas.description = "Execute commands with elevated privileges as another user"
doas.help = "Usage: doas <user> <command> [args...]\n\n" ..
           "Execute a command with the privileges of the specified user.\n" ..
           "This allows administrators to run commands as other users.\n\n" ..
           "Examples:\n" ..
           "  doas admin ps          - Run ps as admin\n" ..
           "  doas system reboot     - Run reboot as system user\n" ..
           "  doas user whoami       - Run whoami as regular user"

function doas.execute(shell, target_user, command, ...)
    if not target_user or not command then
        print("Usage: doas <user> <command> [args...]")
        return false
    end
    
    if shell.currentUser.group ~= "admin" and shell.currentUser.group ~= "trusteddaniel" then
        print("doas: Permission is denied. This incident will be reported.")
        return false
    end
    
    local cmd = _G.kernel.commands[command]
    
    local elevated_shell = {
        currentUser = {
            name = target_user,
            group = target_user,
            permissions = {"basic", "admin", "system", "trusted"}
        },
        username = target_user
    }
    
    if type(cmd.execute) == "function" then
        local args = {...}
        local success, err = pcall(function()
            return cmd.execute(elevated_shell, table.unpack(args))
        end)
        
        if not success then
            print("doas: command failed: " .. tostring(err))
            return false
        end
        return true
    else
        print("doas: command is not executable")
        return false
    end
end

doas.required_permission = "admin"
doas.required_group = "admin"

return doas
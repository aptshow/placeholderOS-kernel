local system = {}

system.name = "system"
system.description = "System administration and information commands"
system.help = "Usage: system <subcommand>\n\n" ..
             "Provides system administration and information commands.\n\n" ..
             "Subcommands:\n" ..
             "  info       - Display basic system information\n" ..
             "  processes  - List all system processes\n" ..
             "  users      - List all system users\n\n" ..
             "Examples:\n" ..
             "  system info      - Show OS version, uptime, current user\n" ..
             "  system processes - List all running processes\n" ..
             "  system users     - Show user accounts and groups"

function system.execute(shell, subcommand, ...)
    if not subcommand then
        print("Usage: system <command>")
        print("Available commands: info, processes, users")
        return false
    end
    
    if subcommand == "info" then
        print("=== System Information ===")
        print("OS: placeholderOS")
        print("Kernel: placeholderKernel")
        print("Version: " .. (_G.metadata and _G.metadata.version or "Unknown"))
        print("Uptime: " .. os.time() .. " seconds")
        print("Current User: " .. shell.currentUser.name)
        print("User Group: " .. shell.currentUser.group)
        return true
        
    elseif subcommand == "processes" then
        local process = _G.kernel.process
        local processes = process.list()
        print("=== System Processes ===")
        print("Total processes: " .. #processes)
        for _, proc in ipairs(processes) do
            print(string.format("PID %d: %s (%s) - %s", 
                proc.pid, proc.name, proc.user, proc.state))
        end
        return true
        
    elseif subcommand == "users" then
        print("=== System Users ===")
        local users = _G.users or {}
        for username, userinfo in pairs(users) do
            print(string.format("%s (%s) - %s", 
                username, userinfo.group, 
                userinfo.password == "noshell" and "No shell access" or "Shell access"))
        end
        return true
        
    else
        print("Unknown system command: " .. subcommand)
        return false
    end
end

system.required_permission = "system"
system.required_group = "admin"

return system
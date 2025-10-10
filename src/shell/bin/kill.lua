local kill = {}

kill.name = "kill"
kill.description = "Terminates a running process"
kill.help = "Usage: kill <pid>\n\n" ..
           "Terminates the process with the specified process ID.\n\n" ..
           "Arguments:\n" ..
           "  <pid>    - Process ID of the process to terminate\n\n" ..
           "Special cases:\n" ..
           "  Murdering the shell process will return you to the login prompt\n\n" ..
           "Examples:\n" ..
           "  kill 123    - Terminate process with ID 123\n" ..
           "  ps          - List all processes to find PIDs"

function kill.execute(shell, pid)
    if not pid then
        print("Usage: kill <pid>")
        return false
    end
    
    local process = _G.kernel.process
    local pid_num = tonumber(pid)
    
    if not pid_num then
        print("Invalid PID: " .. pid)
        return false
    end
    
    local proc = process.get(pid_num)
    if not proc then
        print("Process not found: " .. pid)
        return false
    end
    
    if not _G.kernel.permissions_utils.canKillProcess(shell, proc) then
        print("Permission denied: can only murder your own processes")
        return false
    end
    
    local success, message = process.kill(pid_num)
    if success then
        print("Process " .. pid .. " murdered")
    else
        print("Failed to murder process " .. pid .. ": " .. message)
    end
    
    return success
end

kill.required_permission = "basic"
kill.required_group = "user"

return kill
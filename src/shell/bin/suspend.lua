local suspend = {}

suspend.name = "suspend"
suspend.description = "Suspends a running process"
suspend.help = "Usage: suspend <pid>\n\n" ..
              "Suspends a running process, pausing its execution.\n\n" ..
              "Arguments:\n" ..
              "  <pid>    - Process ID of the process to suspend\n\n" ..
              "Notes:\n" ..
              "  - You can only suspend processes you own (unless you're admin)\n" ..
              "  - Only running processes can be suspended\n" ..
              "  - The shell process cannot be suspended\n" ..
              "  - Use 'resume <pid>' to resume a suspended process\n\n" ..
              "Examples:\n" ..
              "  suspend 123   - Suspend process with ID 123\n" ..
              "  resume 123    - Resume the suspended process\n" ..
              "  ps            - Check process states"

function suspend.execute(shell, pid)
    if not pid then
        print("Usage: suspend <pid>")
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
    
    -- Special handling for shell process
    if proc.name == "shell" then
        print("Cannot suspend shell process. This would make the system unresponsive")
        return false
    end
    
    if proc.user ~= shell.currentUser.name and shell.currentUser.group ~= "admin" then
        print("Permission denied: can only suspend your own processes")
        return false
    end
    
    local success, message = process.suspend(pid_num)
    if success then
        print("Process " .. pid .. " suspended")
    else
        print("Failed to suspend process " .. pid .. ": " .. message)
    end
    
    return success
end

suspend.required_permission = "basic"
suspend.required_group = "user"

return suspend
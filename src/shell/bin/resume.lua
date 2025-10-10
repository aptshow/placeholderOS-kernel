local resume = {}

resume.name = "resume"
resume.description = "Resumes a suspended process"
resume.help = "Usage: resume <pid>\n\n" ..
             "Resumes a process that was previously suspended.\n\n" ..
             "Arguments:\n" ..
             "  <pid>    - Process ID of the suspended process\n\n" ..
             "Notes:\n" ..
             "  - You can only resume processes you own (unless you're admin)\n" ..
             "  - Only suspended processes can be resumed\n\n" ..
             "Examples:\n" ..
             "  resume 123    - Resume process with ID 123\n" ..
             "  suspend 123   - Suspend a process first\n" ..
             "  ps            - Check process states"

function resume.execute(shell, pid)
    if not pid then
        print("Usage: resume <pid>")
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
    
    if proc.user ~= shell.currentUser.name and shell.currentUser.group ~= "admin" then
        print("Permission denied: can only resume your own processes")
        return false
    end
    
    local success, message = process.resume(pid_num)
    if success then
        print("Process " .. pid .. " resumed")
    else
        print("Failed to resume process " .. pid .. ": " .. message)
    end
    
    return success
end

resume.required_permission = "basic"
resume.required_group = "user"

return resume
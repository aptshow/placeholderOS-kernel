local jobs = {}

jobs.name = "jobs"
jobs.description = "Lists background jobs for the current user"
jobs.help = "Usage: jobs\n\n" ..
           "Displays a list of background processes owned by the current user.\n\n" ..
           "Columns:\n" ..
           "  PID      - Process ID\n" ..
           "  COMMAND  - Command/process name\n" ..
           "  STATE    - Current process state\n\n" ..
           "Notes:\n" ..
           "  - Only shows processes owned by you\n" ..
           "  - Excludes system processes like the shell\n" ..
           "  - Use 'ps' to see all processes including system ones\n\n" ..
           "Examples:\n" ..
           "  jobs         - List your background jobs\n" ..
           "  test &       - Start a background job\n" ..
           "  kill <pid>   - Stop a background job"

function jobs.execute(shell, ...)
    local process = _G.kernel.process
    
    print("Background jobs:")
    print("PID\tCOMMAND\t\tSTATE")
    print("---\t-------\t\t-----")
    
    local processes = process.list()
    local jobCount = 0
    
    for _, proc in ipairs(processes) do
        -- Only show processes owned by current user (excluding system processes and murdered ones)
        if proc.user == shell.currentUser.name and proc.name ~= "shell" and proc.state ~= "murdered" and proc.state ~= "dead" then
            print(string.format("%d\t%s\t\t%s", proc.pid, proc.name, proc.state))
            jobCount = jobCount + 1
        end
    end
    
    if jobCount == 0 then
        print("No background jobs")
    end
    
    return true
end

jobs.required_permission = "basic"
jobs.required_group = "user"

return jobs
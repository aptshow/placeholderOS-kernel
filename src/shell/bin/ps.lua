local ps = {}

ps.name = "ps"
ps.description = "Lists all running processes"
ps.help = "Usage: ps\n\n" ..
         "Displays a list of all running processes in the system.\n\n" ..
         "Columns:\n" ..
         "  PID      - Process ID\n" ..
         "  NAME     - Process name\n" ..
         "  USER     - User who owns the process\n" ..
         "  STATE    - Current process state (ready/running/suspended/dead)\n" ..
         "  CREATED  - Time when process was created\n\n" ..
         "Also shows the currently running process if applicable."

function ps.execute(shell, ...)
    local process = _G.kernel.process
    local scheduler = _G.kernel.scheduler
    
    print("PID\tNAME\t\tUSER\t\tSTATE\t\tCREATED")
    print("---\t----\t\t----\t\t-----\t\t-------")
    
    local processes = process.list()
    for _, proc in ipairs(processes) do
        local created = os.date("%H:%M:%S", proc.created_time)
        print(string.format("%d\t%s\t\t%s\t\t%s\t\t%s", 
            proc.pid, 
            proc.name, 
            proc.user, 
            proc.state, 
            created))
    end
    
    local current_pid = scheduler.current_process()
    if current_pid then
        print("\nCurrent running process: " .. current_pid)
    end
    
    return true
end

ps.required_permission = "basic"
ps.required_group = "user"

return ps
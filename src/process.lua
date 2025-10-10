local process = {}

local tasks = {}
local users = {}

local PROCESS_STATES = {
    READY = "ready",
    RUNNING = "running", 
    SUSPENDED = "suspended",
    DEAD = "dead",
    MURDERED = "murdered"
}

local processes = {}
local next_pid = 1

local current_process = nil

function process.create(func, name, user, permissions)
    local pid = next_pid
    next_pid = next_pid + 1
    
    local co = coroutine.create(func)
    
    processes[pid] = {
        pid = pid,
        coroutine = co,
        name = name or ("process_" .. pid),
        user = user or "system",
        permissions = permissions or {},
        state = PROCESS_STATES.READY,
        created_time = os.time(),
        last_run_time = 0
    }
    
    return pid
end

function process.get(pid)
    return processes[pid]
end

function process.list()
    local proc_list = {}
    for pid, proc in pairs(processes) do
        table.insert(proc_list, {
            pid = proc.pid,
            name = proc.name,
            user = proc.user,
            state = proc.state,
            created_time = proc.created_time
        })
    end
    return proc_list
end

function process.kill(pid)
    local proc = processes[pid]
    if not proc then
        return false, "Process not found"
    end
    
    if proc.state ~= PROCESS_STATES.DEAD and proc.state ~= PROCESS_STATES.MURDERED then
        proc.state = PROCESS_STATES.MURDERED
        proc.killed_time = os.time()
    end
    
    return true, "Process murdered"
end

function process.suspend(pid)
    local proc = processes[pid]
    if not proc then
        return false, "Process not found"
    end
    
    if proc.state == PROCESS_STATES.RUNNING then
        proc.state = PROCESS_STATES.SUSPENDED
        return true, "Process suspended"
    end
    
    return false, "Process not running"
end

function process.resume(pid)
    local proc = processes[pid]
    if not proc then
        return false, "Process not found"
    end
    
    if proc.state == PROCESS_STATES.SUSPENDED then
        proc.state = PROCESS_STATES.READY
        return true, "Process resumed"
    end
    
    return false, "Process not suspended"
end

function process._run(pid)
    local proc = processes[pid]
    if not proc then
        return false
    end
    
    if not proc.coroutine then
        current_process = proc
        proc.state = PROCESS_STATES.RUNNING
        proc.last_run_time = os.time()
        current_process = nil
        return true, "System process"
    end
    
    if proc.state ~= PROCESS_STATES.READY and proc.state ~= PROCESS_STATES.MURDERED then
        return false
    end
    
    current_process = proc
    proc.state = PROCESS_STATES.RUNNING
    proc.last_run_time = os.time()
    
    local success, result = coroutine.resume(proc.coroutine)
    
    if coroutine.status(proc.coroutine) == "dead" then
        proc.state = PROCESS_STATES.DEAD
        proc.exit_code = success and 0 or 1
        proc.exit_message = success and "Normal exit" or tostring(result)
    elseif proc.state == PROCESS_STATES.MURDERED then
        proc.state = PROCESS_STATES.DEAD
        proc.exit_code = 1
        proc.exit_message = "Murdered"
        process._cleanup(proc.pid)
    else
        proc.state = PROCESS_STATES.READY
    end
    
    current_process = nil
    return success, result
end

function process.current()
    return current_process
end

function process.yield()
    if current_process then
        coroutine.yield()
    end
end

function process.sleep(seconds)
    local end_time = os.time() + seconds
    while os.time() < end_time do
        process.yield()
    end
end

function process.addTask(name, func, permissions)
    tasks[name] = {
        func = func,
        permissions = permissions or {}
    }
end

function process.executeTask(name, user_permissions)
    local task = tasks[name]
    if not task then
        return false, "Task not found"
    end

    for _, perm in ipairs(task.permissions) do
        if not user_permissions[perm] then
            return false, "Permission denied: " .. perm
        end
    end

    local success, err = pcall(task.func)
    if not success then
        return false, "Task execution failed: " .. err
    end

    return true, "Task executed successfully"
end

function process.addUser(username, permissions)
    if users[username] then
        return false, "User already exists"
    end
    users[username] = {
        permissions = permissions or {}
    }
    return true, "User added successfully"
end

function process.hasPermission(username, permission)
    local user = users[username]
    if not user then
        return false, "User not found"
    end
    return user.permissions[permission] == true
end

function process.assignPermission(username, permission)
    local user = users[username]
    if not user then
        return false, "User not found"
    end
    user.permissions[permission] = true
    return true, "Permission assigned successfully"
end

function process.listTasks()
    local task_list = {}
    for name, _ in pairs(tasks) do
        table.insert(task_list, name)
    end
    return task_list
end

function process.listUsers()
    local user_list = {}
    for username, _ in pairs(users) do
        table.insert(user_list, username)
    end
    return user_list
end

function process._cleanup(pid)
    processes[pid] = nil
end

function process.register_system_process(name, user, permissions)
    local pid = next_pid
    next_pid = next_pid + 1
    
    processes[pid] = {
        pid = pid,
        coroutine = nil,
        name = name or ("system_process_" .. pid),
        user = user or "system",
        permissions = permissions or {},
        state = PROCESS_STATES.RUNNING,
        created_time = os.time(),
        last_run_time = os.time()
    }
    
    return pid
end

return process
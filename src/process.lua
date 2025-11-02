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
local MAX_PROCESSES = 500

local function write_debug_file(msg)
    pcall(function()
        if fs and fs.open then
            local f = fs.open("/kernel_debug.txt", "a")
            if f then f.writeLine(tostring(msg)) f.close() end
        else
            local ok, io = pcall(function() return io end)
            if ok and io and io.open then
                local f2 = io.open("/kernel_debug.txt", "a")
                if f2 then f2:write(tostring(msg) .. "\n") f2:close() end
            end
        end
    end)
end

local current_process = nil

function process.create(func, name, user, permissions)
    -- Safety: prevent runaway process creation
    if (next_pid - 1) >= MAX_PROCESSES then
        write_debug_file("process.create: PID limit reached: " .. tostring(MAX_PROCESSES))
        return nil, "PID limit reached"
    end
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
    write_debug_file(string.format("process.create: pid=%s name=%s user=%s", tostring(pid), tostring(name), tostring(user)))
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
        write_debug_file("process._run: process not found pid=" .. tostring(pid))
        return false
    end
    
    if not proc.coroutine then
        current_process = proc
        proc.state = PROCESS_STATES.RUNNING
        proc.last_run_time = os.time()
        write_debug_file("process._run: running system process pid=" .. tostring(pid))
        current_process = nil
        return true, "System process"
    end
    
    if proc.state ~= PROCESS_STATES.READY and proc.state ~= PROCESS_STATES.MURDERED then
        return false
    end
    
    current_process = proc
    proc.state = PROCESS_STATES.RUNNING
    proc.last_run_time = os.time()
    write_debug_file("process._run: resuming coroutine pid=" .. tostring(pid) .. " name=" .. tostring(proc.name))

    local success, result = coroutine.resume(proc.coroutine)

    -- Log result/exception
    if not success then
        write_debug_file("process._run: coroutine error pid=" .. tostring(pid) .. " err=" .. tostring(result))
    end

    if coroutine.status(proc.coroutine) == "dead" then
        proc.state = PROCESS_STATES.DEAD
        proc.exit_code = success and 0 or 1
        proc.exit_message = success and "Normal exit" or tostring(result)
        write_debug_file("process._run: process exited pid=" .. tostring(pid) .. " code=" .. tostring(proc.exit_code) .. " msg=" .. tostring(proc.exit_message))
    elseif proc.state == PROCESS_STATES.MURDERED then
        proc.state = PROCESS_STATES.DEAD
        proc.exit_code = 1
        proc.exit_message = "Murdered"
        write_debug_file("process._run: process murdered pid=" .. tostring(pid))
        process._cleanup(proc.pid)
    else
        proc.state = PROCESS_STATES.READY
        write_debug_file("process._run: coroutine yielded pid=" .. tostring(pid))
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
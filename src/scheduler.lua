local scheduler = {}

local process = require("src.process")

local TIME_SLICE = 0.1
local IDLE_TIME = 0.05

local running = false
local ready_queue = {}
local current_pid = nil

local function enqueue_process(pid)
    for _, queued_pid in ipairs(ready_queue) do
        if queued_pid == pid then
            return
        end
    end
    table.insert(ready_queue, pid)
end

local function dequeue_process()
    if #ready_queue > 0 then
        return table.remove(ready_queue, 1)
    end
    return nil
end

local function refresh_ready_queue()
    local all_processes = process.list()
    for _, proc_info in ipairs(all_processes) do
        if proc_info.state == "ready" then
            enqueue_process(proc_info.pid)
        end
    end
end

local function scheduler_loop()
    while running do
        refresh_ready_queue()
        
        local next_pid = dequeue_process()
        
        if next_pid then
            current_pid = next_pid
            
            local start_time = os.time()
            local success, result = process._run(next_pid)
            
            local proc = process.get(next_pid)
            if proc and proc.state == "ready" then
                enqueue_process(next_pid)
            end
            
            current_pid = nil
            
            local elapsed = os.time() - start_time
            if elapsed < TIME_SLICE then
                os.sleep(TIME_SLICE - elapsed)
            end
        else
            os.sleep(IDLE_TIME)
        end
        
        local all_processes = process.list()
        for _, proc_info in ipairs(all_processes) do
            if proc_info.state == "dead" or proc_info.state == "murdered" then
                local proc = process.get(proc_info.pid)
                if proc and os.time() - (proc.exit_time or proc.last_run_time or proc.killed_time or 0) > 5 then
                    process._cleanup(proc_info.pid)
                end
            end
        end
    end
end

function scheduler.start()
    if running then
        return false, "Scheduler already running"
    end
    
    running = true
    
    local scheduler_co = coroutine.create(scheduler_loop)
    coroutine.resume(scheduler_co)
    
    return true, "Scheduler started"
end

function scheduler.stop()
    if not running then
        return false, "Scheduler not running"
    end
    
    running = false
    return true, "Scheduler stopped"
end

function scheduler.is_running()
    return running
end

function scheduler.current_process()
    return current_pid
end

function scheduler.yield()
    process.yield()
end

function scheduler.spawn(func, name, user, permissions)
    local pid = process.create(func, name, user, permissions)
    if pid then
        enqueue_process(pid)
        return pid
    end
    return nil, "Failed to create process"
end

function scheduler.tick()
    -- In GUI mode we may prefer to drive the scheduler via tick() without
    -- starting the full background scheduler. Ensure running is true so
    -- tick() actually processes ready jobs.
    if not running then
        running = true
    end
    
    refresh_ready_queue()
    
    local next_pid = dequeue_process()
    
    if next_pid then
        current_pid = next_pid
        
        local success, result = process._run(next_pid)
        
        local proc = process.get(next_pid)
        if proc and proc.state == "ready" then
            enqueue_process(next_pid)
        end
        
        current_pid = nil
    end
    
    -- Cleanup dead/murdered processes
    local all_processes = process.list()
    for _, proc_info in ipairs(all_processes) do
        if proc_info.state == "dead" or proc_info.state == "murdered" then
            local proc = process.get(proc_info.pid)
            if proc and os.time() - (proc.exit_time or proc.last_run_time or proc.killed_time or 0) > 5 then
                process._cleanup(proc_info.pid)
            end
        end
    end
end

return scheduler
-- Kernel API for placeholderOS
-- This module provides access to kernel functions for GUI and other applications

local kernel = {}

-- ensure secure loader is loaded in API contexts
pcall(function() require("src.api.secure_loader") end)

local process_lib = require("src.process")
local scheduler = require("src.scheduler")
local perms = require("src.perms")

-- Helper: get calling process and its permissions
local function get_caller()
    local cur = process_lib.current()
    if not cur then
        -- Called from kernel context (allow by default)
        return {
            user = "system",
            permissions = { admin = true, system = true }
        }
    end
    -- Normalize permissions into a map for easy lookup
    local perm_map = {}
    if type(cur.permissions) == "table" then
        -- permissions may be an array or map
        for k, v in pairs(cur.permissions) do
            if type(k) == "number" then
                perm_map[v] = true
            else
                perm_map[k] = v
            end
        end
    end
    return { user = cur.user, permissions = perm_map }
end

local function has_perm(caller, perm)
    if not caller or not caller.permissions then return false end
    return caller.permissions[perm] == true or caller.permissions["admin"] == true or caller.permissions["trusted"] == true
end

-- Safe process management wrappers
function kernel.create_process(func, name, user, permissions)
    local caller = get_caller()
    -- allow creating processes only for self or if caller has admin/system permission
    if user and user ~= caller.user and not has_perm(caller, "admin") and not has_perm(caller, "system") then
        return nil, "Permission denied: cannot create process for other user"
    end
    -- If permissions were provided, ensure caller may grant them (must already have them or be admin/system/trusted)
    if permissions and type(permissions) == "table" then
        local perm_map = {}
        for k, v in pairs(permissions) do
            if type(k) == "number" then
                perm_map[v] = true
            else
                perm_map[k] = v
            end
        end
        if not (has_perm(caller, "admin") or has_perm(caller, "trusted") or has_perm(caller, "system")) then
            for p, _ in pairs(perm_map) do
                if not caller.permissions[p] then
                    return nil, "Permission denied: cannot grant permission '" .. tostring(p) .. "'"
                end
            end
        end
    end

    return process_lib.create(func, name, user or caller.user, permissions)
end

function kernel.register_system_process(name, user, permissions)
    local caller = get_caller()
    if not has_perm(caller, "system") then
        return nil, "Permission denied: register_system_process requires 'system' permission"
    end
    return process_lib.register_system_process(name, user, permissions)
end

function kernel.kill_process(pid)
    local caller = get_caller()
    local proc = process_lib.get(pid)
    if not proc then return false, "Process not found" end
    if proc.user ~= caller.user and not has_perm(caller, "admin") then
        return false, "Permission denied: cannot kill other user's process"
    end
    return process_lib.kill(pid)
end

function kernel.suspend_process(pid)
    local caller = get_caller()
    local proc = process_lib.get(pid)
    if not proc then return false, "Process not found" end
    if proc.user ~= caller.user and not has_perm(caller, "admin") then
        return false, "Permission denied: cannot suspend other user's process"
    end
    return process_lib.suspend(pid)
end

function kernel.resume_process(pid)
    local caller = get_caller()
    local proc = process_lib.get(pid)
    if not proc then return false, "Process not found" end
    if proc.user ~= caller.user and not has_perm(caller, "admin") then
        return false, "Permission denied: cannot resume other user's process"
    end
    return process_lib.resume(pid)
end

function kernel.get_process(pid)
    local caller = get_caller()
    local proc = process_lib.get(pid)
    if not proc then return nil end
    -- don't expose internal permission tables to unprivileged callers
    local safe = {
        pid = proc.pid,
        name = proc.name,
        user = proc.user,
        state = proc.state,
        created_time = proc.created_time,
        last_run_time = proc.last_run_time
    }
    if has_perm(caller, "admin") then
        safe.permissions = proc.permissions
    end
    return safe
end

function kernel.list_processes()
    -- process_lib.list already returns non-sensitive summary information
    return process_lib.list()
end

-- Scheduler management (restrict start/stop to admin)
function kernel.start_scheduler()
    local caller = get_caller()
    if not has_perm(caller, "admin") then
        return false, "Permission denied: start_scheduler requires admin"
    end
    return scheduler.start()
end

function kernel.stop_scheduler()
    local caller = get_caller()
    if not has_perm(caller, "admin") then
        return false, "Permission denied: stop_scheduler requires admin"
    end
    return scheduler.stop()
end

function kernel.tick()
    return scheduler.tick()
end

-- Permissions
function kernel.check_permission(username, permission)
    return perms.hasPermission(username, permission)
end

function kernel.get_user_permissions(user)
    return perms.listPermissions(user)
end

function kernel.assign_user_permission(username, permission)
    local caller = get_caller()
    if not has_perm(caller, "admin") then
        return false, "Permission denied: assign_user_permission requires admin"
    end
    return perms.assignPermission(username, permission)
end

-- Kernel initialization
kernel.init = function(options)
    options = options or {}
    -- Initialize kernel components
    print("Kernel API initialized")
    
    -- Set boot flags
    if options.no_shell then
        _G._DISABLE_SHELL = true
    else
        _G._DISABLE_SHELL = false
    end
end

-- Run kernel with options
kernel.run = function(options)
    options = options or {}
    kernel.init(options)
    
    if options.no_shell then
        local main = require("src.main")
        main.run_gui()
    else
        local main = require("src.main")
        main.run()
    end
end

return kernel

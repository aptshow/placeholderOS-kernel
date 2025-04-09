local process = {}

local tasks = {}

local users = {}

function process.addTask(name, func, permissions)
    tasks[name] = {
        func = func,
        permissions = permissions or {}
    }
end

-- Function to execute a task if permissions are met
function process.executeTask(name, user_permissions)
    local task = tasks[name]
    if not task then
        return false, "Task not found"
    end

    -- Check perms
    for _, perm in ipairs(task.permissions) do
        if not user_permissions[perm] then
            return false, "Permission denied: " .. perm
        end
    end

    -- Execute the task
    local success, err = pcall(task.func)
    if not success then
        return false, "Task execution failed: " .. err
    end

    return true, "Task executed successfully"
end

-- Function to add a new user
function process.addUser(username, permissions)
    if users[username] then
        return false, "User already exists"
    end
    users[username] = {
        permissions = permissions or {}
    }
    return true, "User added successfully"
end

-- Function to check if a user has a specific permission
function process.hasPermission(username, permission)
    local user = users[username]
    if not user then
        return false, "User not found"
    end
    return user.permissions[permission] == true
end

-- Function to assign a permission to a user
function process.assignPermission(username, permission)
    local user = users[username]
    if not user then
        return false, "User not found"
    end
    user.permissions[permission] = true
    return true, "Permission assigned successfully"
end

-- Function to list all tasks
function process.listTasks()
    local task_list = {}
    for name, _ in pairs(tasks) do
        table.insert(task_list, name)
    end
    return task_list
end

-- Function to list all users
function process.listUsers()
    local user_list = {}
    for username, _ in pairs(users) do
        table.insert(user_list, username)
    end
    return user_list
end

return process
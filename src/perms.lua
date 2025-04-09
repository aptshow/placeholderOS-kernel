local perms = {}

local users = {}
local groups = {}

-- Function to add a permission group
function perms.addGroup(groupName, parentGroup)
    if groups[groupName] then
        return false, "Group already exists"
    end
    
    groups[groupName] = {
        permissions = {},
        parent = parentGroup or nil
    }
    return true, "Group added successfully"
end

-- Function to assign a permission to a group
function perms.assignGroupPermission(groupName, permission)
    local group = groups[groupName]
    if not group then
        return false, "Group not found"
    end
    group.permissions[permission] = true
    return true, "Permission assigned to group successfully"
end

-- Helper function to check if a group has a permission (including inheritance)
local function checkGroupPermission(groupName, permission)
    local group = groups[groupName]
    if not group then
        return false
    end
    
    -- Check if the group has the permission directly
    if group.permissions[permission] then
        return true
    end
    
    -- Check parent group if it exists (inheritance)
    if group.parent and groups[group.parent] then
        return checkGroupPermission(group.parent, permission)
    end
    
    return false
end

-- Function to list all groups
function perms.listGroups()
    local group_list = {}
    for groupName, _ in pairs(groups) do
        table.insert(group_list, groupName)
    end
    return group_list
end

-- Function to list all permissions of a group (including inherited)
function perms.listGroupPermissions(groupName)
    local group = groups[groupName]
    if not group then
        return false, "Group not found"
    end
    
    local result = {}
    
    -- Add direct permissions
    for permission, _ in pairs(group.permissions) do
        result[permission] = "direct"
    end
    
    -- Add inherited permissions
    if group.parent and groups[group.parent] then
        local parentPerms, err = perms.listGroupPermissions(group.parent)
        if type(parentPerms) == "table" then
            for permission, source in pairs(parentPerms) do
                if not result[permission] then
                    result[permission] = "inherited from " .. group.parent
                end
            end
        end
    end
    
    return result
end

-- Function to add a new user with a group
function perms.addUser(username, password, groupName)
    if users[username] then
        return false, "User already exists"
    end
    
    users[username] = {
        permissions = {},
        password = password or "",
        group = groupName or nil
    }
    return true, "User added successfully"
end

-- Function to assign a user to a group
function perms.assignUserGroup(username, groupName)
    local user = users[username]
    if not user then
        return false, "User not found"
    end
    
    if groupName and not groups[groupName] then
        return false, "Group not found"
    end
    
    user.group = groupName
    return true, "User assigned to group successfully"
end

-- Function to assign a permission to a user
function perms.assignPermission(username, permission)
    local user = users[username]
    if not user then
        return false, "User not found"
    end
    user.permissions[permission] = true
    return true, "Permission assigned successfully"
end

-- Function to check if a user has a specific permission
function perms.hasPermission(username, permission)
    local user = users[username]
    if not user then
        return false, "User not found"
    end
    
    -- Check direct user permission
    if user.permissions[permission] then
        return true
    end
    
    -- Check group permission if user belongs to a group
    if user.group then
        return checkGroupPermission(user.group, permission)
    end
    
    return false
end

-- Function to list all users
function perms.listUsers()
    local user_list = {}
    for username, user in pairs(users) do
        table.insert(user_list, {
            name = username,
            group = user.group or "none"
        })
    end
    return user_list
end

-- Function to list all permissions of a user
function perms.listPermissions(username)
    local user = users[username]
    if not user then
        return false, "User not found"
    end
    
    local result = {}
    
    -- Add direct permissions
    for permission, _ in pairs(user.permissions) do
        result[permission] = "direct"
    end
    
    -- Add group permissions
    if user.group then
        local groupPerms, err = perms.listGroupPermissions(user.group)
        if type(groupPerms) == "table" then
            for permission, source in pairs(groupPerms) do
                if not result[permission] then
                    result[permission] = "from group: " .. user.group
                end
            end
        end
    end
    
    return result
end

-- Function to get a user by username
function perms.getUser(username)
    local user = users[username]
    if user then
        return true, user
    else
        return false, nil
    end
end

-- Function to get a group by name
function perms.getGroup(groupName)
    local group = groups[groupName]
    if group then
        return true, group
    else
        return false, nil
    end
end

return perms
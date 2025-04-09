local utils = {}

-- Check if a user has a specific permission
function utils.hasPermission(permission)
    if not currentUser then
        return false
    end
    
    -- TrustedDaniel users have all permissions
    if currentUser.group == "trusteddaniel" then
        return true
    end
    
    -- Check specific permissions for non-admin users
    for _, perm in ipairs(currentUser.permissions) do
        if perm == permission then
            return true
        end
    end
    
    return false
end

-- Check if a user belongs to a specific group
function utils.hasGroup(group)
    if not currentUser then
        return false
    end
    
    -- Admin users can access any group's commands
    if currentUser.group == "admin" then
        return true
    end
    
    -- Normal group checking
    return currentUser.group == group
end

return utils
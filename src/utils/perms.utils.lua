local utils = {}

function utils.canKillProcess(shell, proc)
    if not shell.currentUser then
        return false
    end
    
    if shell.currentUser.group == "admin" or shell.currentUser.group == "trusteddaniel" then
        return true
    end
    
    return proc.user == shell.currentUser.name
end

return utils
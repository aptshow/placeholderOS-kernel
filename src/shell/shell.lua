local shell = {}
local commands = {}

local perms, process
local success, result = pcall(function() return require("src.perms") end)
if success then perms = result else print("Warning: Could not load permissions module") end
success, result = pcall(function() return require("src.process") end)
if success then process = result else print("Warning: Could not load process module") end

shell.currentUser = nil

local function checkPermission(permission)
    if not shell.currentUser then
        if _G.currentUser then
            shell.currentUser = _G.currentUser
        else
            print("Cannot determine current user. Please contact system administrator.")
            return false
        end
    end

    if shell.currentUser.group == "admin" then
        return true
    end

    if shell.currentUser.permissions then
        for _, perm in ipairs(shell.currentUser.permissions) do
            if perm == permission then
                return true
            end
        end
    end
    
    return false
end

local function checkGroup(group)
    if not shell.currentUser then
        if _G.currentUser then
            shell.currentUser = _G.currentUser
        else
            print("Cannot determine current user. Please contact system administrator.")
            return false
        end
    end

    if shell.currentUser.group == "admin" then
        return true
    end

    return shell.currentUser.group == group
end

local function loadCommands()
    local binPath
    
    local currentFile = debug.getinfo(1).source:sub(2)  -- Remove the leading '@'
    local currentDir = fs.getDir(currentFile)
    binPath = fs.combine(currentDir, "bin")

    
    print("Loading commands from: " .. binPath)
    local files = fs.list(binPath)
    local loadedCount = 0
    
    for _, file in ipairs(files) do
        if file:match("%.lua$") then
            local commandName = file:gsub("%.lua$", "")
            local commandPath = fs.combine(binPath, file)
            
            if fs.exists(commandPath) then
                local success, command = pcall(function() return dofile(commandPath) end)
                
                if success and type(command) == "table" then
                    commands[commandName] = command
                    
                    -- Register command permissions if available
                    if perms and command.required_permission then
                        local baseGroup = command.required_group or "guest"
                        
                        -- Only admin-specific commands should require admin directly
                        if command.required_permission:match("^admin%.") then
                            baseGroup = "admin"
                        end
                        
                        -- Assign permission to the base group
                        if perms.assignGroupPermission then
                            perms.assignGroupPermission(baseGroup, command.required_permission)
                        end
                    end
                    
                    loadedCount = loadedCount + 1
                else
                    print("Failed to load command: " .. commandName .. " - " .. tostring(command))
                end
            else
                print("Command file not found: " .. commandPath)
            end
        end
    end
    
    print("Successfully loaded " .. loadedCount .. " commands")
end

-- Create shell environment to be passed to commands
local function createShellEnv()
    local shellEnv = {}
    
    shellEnv.exit = function()
        _G._LOGOUT_REQUESTED = true
    end
    
    -- Add current user info
    shellEnv.currentUser = shell.currentUser
    shellEnv.username = shell.currentUser and shell.currentUser.name or "unknown"
    
    return shellEnv
end

-- Execute a command
local function executeCommand(shellEnv, input)
    -- Split input into command and arguments
    local parts = {}
    for word in input:gmatch("%S+") do
        table.insert(parts, word)
    end
    
    local commandName = table.remove(parts, 1)
    if not commandName then return end
    
    local command = commands[commandName]
    if command then
        -- Check if the user has permission to execute this command
        local requiredPerm = command.required_permission
        local hasPermission = true
        
        if requiredPerm then
            -- Special case: admin users always have permission
            if shell.currentUser and shell.currentUser.group == "admin" then
                hasPermission = true
            else
                -- Check permission
                hasPermission = checkPermission(requiredPerm)
            end
        end
        
        if not hasPermission then
            print("Permission denied: " .. requiredPerm .. " permission required")
            return false
        end
        
        -- Check group requirements if any
        if command.required_group and not checkGroup(command.required_group) then
            print("Permission denied: " .. command.required_group .. " group required")
            return false
        end
        
        -- Set up kernel object for commands that need it
        _G.kernel = {
            version = "1.0.0",
            name = "placeholderOS",
            user = shell.currentUser,
            permissions = perms,
            process = process
        }
        
        -- Execute the command
        if type(command.execute) == "function" then
            -- Make sure we're passing the shell environment as the first parameter
            local success, err = pcall(function()
                return command.execute(shellEnv, table.unpack(parts))
            end)
            
            if not success then
                print("Error executing command: " .. tostring(err))
                return false
            end
            return true
        else
            print("Command is not executable")
            return false
        end
    else
        print("Unknown command: " .. commandName)
        
        -- Show available commands
        print("Available commands:")
        local sortedCommands = {}
        for cmd in pairs(commands) do
            table.insert(sortedCommands, cmd)
        end
        table.sort(sortedCommands)
        for _, cmd in ipairs(sortedCommands) do
            print("- " .. cmd)
        end
        
        return false
    end
end

-- Main shell loop
local function run()
    local running = true
    
    loadCommands()
    
    -- Reset global logout flag if it exists
    _G._LOGOUT_REQUESTED = false
    
    if _G.currentUser then
        shell.currentUser = _G.currentUser
    else
        print("Warning: No user logged in?")
    end
    
    -- Create shell environment once
    local shellEnv = createShellEnv()
    
    while running do
        -- Read user input
        local username = shell.currentUser and shell.currentUser.name or "guest"
        write(username .. "@PlaceholderOS> ")
        local input = io.read()
        
        if input and #input > 0 then
            executeCommand(shellEnv, input)
        end
        
        -- Check if logout was requested
        if _G._LOGOUT_REQUESTED == true then
            running = false
        end
    end
    
    print("Shell terminated")
    return true
end

-- Initialization function
function shell.init(user)
    if user then
        shell.currentUser = user
    end
end

function shell.start(username)
    if username then
        _G.CURRENT_USER = username
        
        if perms and perms.getUser then
            local success, user = pcall(perms.getUser, username)
            if success and user then
                shell.currentUser = user
                _G.SHELL_USER = user
            end
        end
    end

    -- Check if the user logged in with password "noshell"
    if _G.currentUser and _G.currentUser.password == "noshell" then
        print("This account has no shell access.")
        print("Press any key to log out...")
        os.pullEvent("key")
        return
    end
    
    -- Run the shell
    run()
end

return shell
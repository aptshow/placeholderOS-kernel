local shell = {}
local commands = {}

local perms, process
local success, result = pcall(function() return require("src.perms") end)
if success then perms = result else print("Warning: Could not load permissions module") end
success, result = pcall(function() return require("src.process") end)
if success then process = result else print("Warning: Could not load process module") end

-- Define permissions utils inline to avoid require issues
local perms_utils = {
    canKillProcess = function(shell, proc)
        if not shell.currentUser then
            return false
        end
        
        if shell.currentUser.group == "admin" or shell.currentUser.group == "trusteddaniel" then
            return true
        end
        
        return proc.user == shell.currentUser.name
    end
}

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
    
    local currentFile = debug.getinfo(1).source:sub(2)
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
                    
                    if perms and command.required_permission then
                        local baseGroup = command.required_group or "guest"
                        
                        -- Only admin-specific commands should require admin directly
                        if command.required_permission:match("^admin%.") then
                            baseGroup = "admin"
                        end
                        
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

local function createShellEnv()
    local shellEnv = {}
    
    shellEnv.exit = function()
        _G._LOGOUT_REQUESTED = true
    end
    
    shellEnv.currentUser = shell.currentUser
    shellEnv.username = shell.currentUser and shell.currentUser.name or "unknown"
    
    return shellEnv
end

local function executeCommand(shellEnv, input)
    local parts = {}
    for word in input:gmatch("%S+") do
        table.insert(parts, word)
    end
    
    -- Check for background execution (&)
    local background = false
    if #parts > 0 and parts[#parts] == "&" then
        background = true
        table.remove(parts, #parts)  -- Remove the &
    end
    
    local commandName = table.remove(parts, 1)
    if not commandName then return end
    
    local command = commands[commandName]
    if command then
        local requiredPerm = command.required_permission
        local hasPermission = true
        
        if requiredPerm then
            if shell.currentUser and shell.currentUser.group == "admin" then
                hasPermission = true
            else
                hasPermission = checkPermission(requiredPerm)
            end
        end
        
        if not hasPermission then
            print("Permission denied: " .. requiredPerm .. " permission required")
            return false
        end
        
        if command.required_group and not checkGroup(command.required_group) then
            print("Permission denied: " .. command.required_group .. " group required")
            return false
        end
        
        _G.kernel = {
            version = "1.0.0",
            name = "placeholderOS",
            user = shell.currentUser,
            permissions = perms,
            permissions_utils = perms_utils,
            process = process,
            scheduler = require("src.scheduler"),
            commands = commands
        }
        
        if type(command.execute) == "function" then
            if background then
                local commandFunc = function()
                    local success, err = pcall(function()
                        return command.execute(shellEnv, table.unpack(parts))
                    end)
                    if not success then
                        print("Background command '" .. commandName .. "' failed: " .. tostring(err))
                    end
                end
                
                local scheduler = _G.kernel.scheduler
                local pid = scheduler.spawn(commandFunc, commandName, shell.currentUser.name, shell.currentUser.permissions)
                
                if pid then
                    print("[" .. pid .. "] " .. commandName)
                    return true
                else
                    print("Failed to start background process")
                    return false
                end
            else
                local success, err = pcall(function()
                    return command.execute(shellEnv, table.unpack(parts))
                end)
                
                if not success then
                    print("Error executing command: " .. tostring(err))
                    return false
                end
                return true
            end
        else
            print("Command is not executable")
            return false
        end
    else
        print("Unknown command: " .. commandName)
        
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

    if _G.currentUser and _G.currentUser.password == "noshell" then
        print("This account has no shell access.")
        print("Press any key to log out...")
        os.pullEvent("key")
        return
    end
    
    loadCommands()
    
    _G._LOGOUT_REQUESTED = false
    
    if _G.currentUser then
        shell.currentUser = _G.currentUser
    else
        print("Warning: No user logged in?")
    end
    
    -- Display initial prompt
    local username_prompt = shell.currentUser and shell.currentUser.name or "guest"
    write(username_prompt .. "@PlaceholderOS> ")
end

local input_buffer = ""
local input_complete = false

function shell.handle_key_event(key)
    if key == keys.enter then
        input_complete = true
        print()
        return true
    elseif key == keys.backspace then
        if #input_buffer > 0 then
            input_buffer = string.sub(input_buffer, 1, -2)
            write("\b \b")
        end
    end
    return false
end

function shell.handle_char_event(char)
    input_buffer = input_buffer .. char
    write(char)
    return false
end

function shell.process_input()
    if input_complete and #input_buffer > 0 then
        local result = executeCommand(createShellEnv(), input_buffer)
        input_buffer = ""
        input_complete = false
        
        local username = shell.currentUser and shell.currentUser.name or "guest"
        write(username .. "@PlaceholderOS> ")
        
        return result
    elseif input_complete then
        input_buffer = ""
        input_complete = false
        local username = shell.currentUser and shell.currentUser.name or "guest"
        write(username .. "@PlaceholderOS> ")
    end
    return true
end

function shell.reset_input()
    input_buffer = ""
    input_complete = false
end

function shell.is_input_complete()
    return input_complete
end

function shell.get_input_buffer()
    return input_buffer
end

return shell
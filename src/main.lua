-- Main program for placeholderOS
-- This file handles login and shell execution

term.clear()
term.setCursorPos(1, 1)

local shell = require("src.shell.shell")
local scheduler = require("src.scheduler")

print("Initializing process scheduler...")
-- Don't start the background scheduler loop since we're handling ticks manually

-- Default user groups and permissions
-- "admin" group has administrative and system-level permissions
-- "user" group has basic user-level permissions
-- "guest" group has limited permissions
-- "trusteddaniel" group is a special case with all permissions, including trusted and system-level
-- "trusted" group has all permissions but is not considered an admin
-- "system" group has permissions for system-level operations
-- "trusteddaniel" is the highest-level user and has all permissions
-- To disable shell login for a user, set their password to "noshell"

local users = {
   trusteddaniel = {
        password = "noshell",
        group = "trusteddaniel",
        permissions = {"basic", "admin", "system", "trusted"}
    }, 
    admin = {
        password = "",
        group = "admin",
        permissions = {"basic", "admin", "system"}
    },
    user = {
        password = "",
        group = "user",
        permissions = {"basic", "user"}
    },
    guest = {
        password = "",
        group = "guest",
        permissions = {"basic"}
    }
}

-- Current user session
local currentUser = nil

local function displayLogin()
    term.clear()
    term.setCursorPos(1, 1)
    print("=============================")
    print("   placeholderKernel Login   ")
    print("=============================")
end

local function loginPrompt()
    term.write("Username: ")
    local username = read()
    term.write("Password: ")
    local password = read("*")
    
    if users[username] and users[username].password == password then
        currentUser = {
            name = username,
            group = users[username].group,
            permissions = users[username].permissions
        }
        return true, username
    else
        return false, nil
    end
end

-- Main OS loop
local function main()
    while true do
        -- Reset global user first to ensure clean state
        _G.currentUser = nil

        displayLogin()
        local success, username = loginPrompt()

        if success then
            term.clear()
            term.setCursorPos(1, 1)
            print("===================================")
            print("")
            print("Welcome, " .. username)
            print("Group: " .. currentUser.group)
            print("Type 'help' for a list of commands")
            print("Kernel Version: " .. (_G.metadata and _G.metadata.version or "Unknown"))
            print("")
            print("===================================")

            _G.currentUser = {
                name = username,
                group = users[username].group,
                permissions = users[username].permissions,
                password = users[username].password
            }

            -- Initialize shell (not as a process)
            if shell.init then
                shell.init(_G.currentUser)
            end
            shell.start(username)
            
            -- Register shell as a system process for tracking
            local process = require("src.process")
            local shell_pid = process.register_system_process("shell", username, users[username].permissions)
            print("Shell registered with PID " .. shell_pid)

            -- Main event loop that handles shell input and scheduler
            while true do
                -- Run scheduler tick for background processes
                scheduler.tick()

                -- Handle events
                local event = {os.pullEvent()}
                
                if event[1] == "terminate" then
                    break
                elseif event[1] == "key" then
                    local success, result = pcall(function() return shell.handle_key_event(event[2]) end)
                    if success and result then
                        -- Key event was processed, check if input is complete
                        pcall(function() shell.process_input() end)
                    end
                elseif event[1] == "char" then
                    pcall(function() shell.handle_char_event(event[2]) end)
                end

                -- Check if logout was requested
                if _G._LOGOUT_REQUESTED then
                    break
                end
                
                -- Check if shell process has been murdered
                local shell_proc = process.get(shell_pid)
                if shell_proc and shell_proc.state == "murdered" then
                    break
                end
            end

            currentUser = nil
            _G.currentUser = nil
            os.sleep(1)
        else
            print("Login failed. Please try again.")
            os.sleep(2)
        end
    end
end

-- Start the main OS loop
local function run()
    main()
end

return {
    run = run
}
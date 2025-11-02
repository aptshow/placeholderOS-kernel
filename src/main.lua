-- Main program for placeholderOS
-- This file handles login and shell execution

term.clear()
term.setCursorPos(1, 1)

-- Load secure loader early to protect internal modules from unprivileged requires
-- Ensure our in-world bootstrap runs (adds /src to package.path and preloads key modules)
pcall(function() require("src.init") end)
pcall(function() require("src.api.secure_loader") end)

-- Helper: append a debug message to a persistent log file so we can inspect runtime
local function write_debug_file(msg)
    local ok, io = pcall(function() return io end)
    local timestamp = tostring(os and os.time and os.time() or "?")
    local line = ("[%s] %s"):format(timestamp, tostring(msg))
    if ok and io and io.open then
        local fok, f = pcall(io.open, "/kernel_debug.txt", "a")
        if fok and f then
            pcall(function() f:write(line .. "\n") f:close() end)
            return true
        end
    end
    -- Fallback to fs.open if available (ComputerCraft)
    if fs and fs.open then
        local ff = fs.open("/kernel_debug.txt", "a")
        if ff then
            pcall(function() ff.writeLine(line) ff.close() end)
            return true
        end
    end
    return false
end

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
    -- ensure `process` and `shell_pid` have proper scope for the main loop
    local process = nil
    local shell_pid = nil

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

            -- Check if shell is disabled (for GUI mode)
            if not _G._DISABLE_SHELL then
                -- Initialize shell (not as a process)
                if shell.init then
                    shell.init(_G.currentUser)
                end
                shell.start(username)

                -- Register shell as a system process for tracking
                -- Declare `process` and `shell_pid` in this outer scope so the event loop can access them
                process = process or require("src.process")
                shell_pid = process.register_system_process("shell", username, users[username].permissions)
                print("Shell registered with PID " .. tostring(shell_pid))
            end

            -- Main event loop that handles shell input and scheduler
            while true do
                -- Run scheduler tick for background processes
                scheduler.tick()

                -- Handle events
                local event = {os.pullEvent()}
                
                if event[1] == "terminate" then
                    break
                elseif not _G._DISABLE_SHELL then
                    -- Only handle shell events if shell is enabled
                    if event[1] == "key" then
                        local success, result = pcall(function() return shell.handle_key_event(event[2]) end)
                        if success and result then
                            -- Key event was processed, check if input is complete
                            pcall(function() shell.process_input() end)
                        end
                    elseif event[1] == "char" then
                        pcall(function() shell.handle_char_event(event[2]) end)
                    end
                end

                -- Check if logout was requested
                if _G._LOGOUT_REQUESTED then
                    break
                end
                
                -- Check if shell process has been murdered (only if shell exists)
                if not _G._DISABLE_SHELL and process and shell_pid then
                    local shell_proc = process.get(shell_pid)
                    if shell_proc and shell_proc.state == "murdered" then
                        break
                    end
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

-- Run in GUI mode without shell
local function run_gui()
    _G._DISABLE_SHELL = true
    -- Skip login and directly start kernel
    term.clear()
    term.setCursorPos(1, 1)
    print("Welcome to placeholderOS Kernel!")
    -- NOTE: removed auto-launch of DaniX here to avoid recursive re-entry and
    -- accidental repeated process creation. Use the DaniX starter script to
    -- create the desktop process instead (run /DaniX/start.lua).
    -- Scheduler will be driven by scheduler.tick() in the GUI loop below
    
    -- Main event loop without shell
    -- NOTE: do not pull events here — letting the kernel pull events would steal
    -- input from GUI processes. Instead run scheduler ticks and sleep so processes
    -- can call os.pullEvent() themselves and receive input.
    while true do
        -- Run scheduler tick for background processes
        scheduler.tick()

        -- Small sleep so we don't busy-loop
        os.sleep(0.05)
    end
end

-- Expose users to other modules (DaniX) so they can validate credentials without duplicating state
-- Expose users to other modules (DaniX) so they can validate credentials without duplicating state
_G.users = users
_G.USERS = users

return {
    run = run,
    run_gui = run_gui
}
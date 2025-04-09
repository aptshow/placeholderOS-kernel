-- Main program for placeholderOS
-- This file handles login and shell execution

term.clear()
term.setCursorPos(1, 1)

local shell = require("src.shell.shell")

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
    
    -- Check if user exists and password matches
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
            
            -- Set global current user for other modules to access
            _G.currentUser = {
                name = username,
                group = users[username].group,
                permissions = users[username].permissions,
                password = users[username].password 
            }
            
            -- Initialize the shell with the current user
            if shell.init then
                shell.init(_G.currentUser)
            end
            
            -- Start the shell
            shell.start()
            
            -- When shell.start() returns, we've logged out
            -- Reset current user and continue the loop to show login again
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
main()
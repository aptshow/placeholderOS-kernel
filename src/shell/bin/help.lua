-- Help command - provides help information for commands
return {
    name = "help",
    description = "Provides help information for available commands",
    required_permission = "basic",
    required_group = "guest",
    help = "Usage: help [command]\n\n" ..
           "Without arguments, lists all available commands.\n" ..
           "With a command name, shows detailed help for that command.",
    
    execute = function(shellEnv, commandName)
        -- Get a list of all commands
        local commands = {}
        
        -- Get bin path relative to this file
        local currentFile = debug.getinfo(1).source:sub(2)  -- Remove the leading '@'
        local currentDir = fs.getDir(currentFile)
        local binPath = fs.combine(fs.getDir(currentDir), "bin")
        
        if not fs.exists(binPath) or not fs.isDir(binPath) then
            print("Warning: Could not find command directory at " .. binPath)
            return false
        end
        
        -- List all command files
        local files = fs.list(binPath)
        for _, file in ipairs(files) do
            if file:match("%.lua$") then
                local cmdName = file:gsub("%.lua$", "")
                local cmdPath = fs.combine(binPath, file)
                
                if fs.exists(cmdPath) then
                    local success, cmd = pcall(function() return dofile(cmdPath) end)
                    if success and type(cmd) == "table" then
                        commands[cmdName] = cmd
                    end
                end
            end
        end
        
        -- If no command specified, list all commands
        if not commandName then
            print("Available commands:")
            print("------------------")
            
            -- Sort commands alphabetically
            local sortedCommands = {}
            for name, _ in pairs(commands) do
                table.insert(sortedCommands, name)
            end
            table.sort(sortedCommands)
            
            -- Display each command with its description
            for _, name in ipairs(sortedCommands) do
                local cmd = commands[name]
                local desc = ""
                
                if cmd and type(cmd) == "table" and cmd.description then
                    desc = cmd.description
                end
                
                print(name .. " - " .. tostring(desc))
            end
            
            print("\nType 'help <command>' for more information about a specific command.")
        else
            -- Show help for specific command
            local command = commands[commandName]
            
            if command and type(command) == "table" then
                print("Help for command: " .. commandName)
                print("------------------")
                
                if command.description then
                    print("Description: " .. command.description)
                end
                
                if command.help then
                    print("\n" .. command.help)
                else
                    print("\nNo detailed help available.")
                end
                
                if command.required_permission then
                    print("\nRequired permission: " .. command.required_permission)
                end
                
                if command.required_group then
                    print("Required group: " .. command.required_group)
                end
            else
                print("No help available for '" .. commandName .. "'. Command not found.")
            end
        end
        
        return true
    end
}
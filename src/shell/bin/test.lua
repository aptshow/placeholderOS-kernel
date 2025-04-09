-- Simple test command to verify command execution
return {
    name = "test",
    description = "Test command execution",
    required_permission = "basic",
    required_group = "guest",
    help = "Usage: test\n\n" ..
           "Test command to verify that command execution is working.",
    
    execute = function(shellEnv, ...)
        print("Test command executed successfully!")
        print("Shell environment received:")
        if shellEnv then
            print("  - Type: " .. type(shellEnv))
            if type(shellEnv) == "table" then
                for k, v in pairs(shellEnv) do
                    if type(v) == "table" then
                        print("  - " .. k .. ": <table>")
                    else
                        print("  - " .. k .. ": " .. tostring(v))
                    end
                end
            end
        else
            print("  - No shell environment received")
        end
        
        print("Arguments received:")
        local args = {...}
        if #args > 0 then
            for i, arg in ipairs(args) do
                print("  " .. i .. ": " .. tostring(arg))
            end
        else
            print("  No arguments received")
        end
        
        return true
    end
}
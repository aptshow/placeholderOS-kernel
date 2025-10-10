return {
    name = "test",
    description = "Test command execution",
    required_permission = "basic",
    required_group = "guest",
    help = "Usage: test\n\n" ..
           "Test command to verify that command execution is working.",
    
    execute = function(shellEnv, ...)
        print("Test command started!")
        local process = _G.kernel.process
        
        for i = 1, 5 do
            print("Test iteration " .. i .. " at " .. os.time())
            process.sleep(1) 
        end
        
        print("Test command completed!")
        return true
    end
}
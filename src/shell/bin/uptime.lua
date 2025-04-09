-- Shows the uptime of the system in minutes, hours or seconds.

return {

    name = "uptime",
    description = "Displays the system's uptime.",
    required_permission = "basic",
    required_group = "guest",
    help = "Usage: uptime [-argument] \n\n" ..
           "Prints the system's uptime. -h for hour format \n\n" ..
           "-m for minutes, -s for seconds",

    execute = function(...)

        local args = {...}

        if not args[2] then
            print ("No arguments!")
            print (" -h for hours, -m for minutes, -s for seconds.")
            return
        elseif #args[1] > 1 then
            print ("Too many arguments!")
            print (" -h for hours, -m for minutes, -s for seconds.")
            return
        end
        
        local uptime = math.floor(os.clock())
        
        if args[2] == "-h" then
            uptime = math.floor(uptime / 3600)
            print("Running for", uptime, "Hours")
        elseif args[2] == "-m" then
            uptime = math.floor(uptime / 60)
            print("Running for", uptime, "Minutes")
        elseif args[2] == "-s" then
            uptime = math.floor(uptime)
            print("Running for", uptime, "Seconds")
        else
            print ("Invalid argument!")
            print (" -h for hours, -m for minutes, -s for seconds.")
            return
        end
    end

}

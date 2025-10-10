local bg = {}

bg.name = "bg"
bg.description = "Shows information about background command execution"
bg.help = "Usage: bg\n\n" ..
         "Displays information about how to run commands in the background.\n\n" ..
         "To run a command in the background, append '&' to the command:\n" ..
         "  command &\n\n" ..
         "Examples:\n" ..
         "  test &        - Run test command in background\n" ..
         "  jobs          - List background jobs\n" ..
         "  kill <pid>    - Stop a background process"

function bg.execute(shell, ...)
    print("Usage: command &")
    print("Runs a command in the background")
    print("Example: test &")
    print("Use 'jobs' to list background processes")
    print("Use 'kill <pid>' to stop background processes")
    return true
end

bg.required_permission = "basic"
bg.required_group = "user"

return bg
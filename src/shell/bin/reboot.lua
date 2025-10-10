local reboot = {}

reboot.name = "reboot"
reboot.description = "Reboots the system"
reboot.help = "Usage: reboot\n\n" ..
             "Initiates a system reboot, restarting the kernel.\n\n" ..
             "This command will:\n" ..
             "  1. Display a countdown message\n" ..
             "  2. Log out the current user\n" ..
             "  3. Return to the login screen\n\n" ..
             "Note: This simulates a reboot by logging out the user.\n" ..
             "In a real system, this would restart the entire OS."

function reboot.execute(shell, ...)
    print("System reboot initiated...")
    
    print("Restarting kernel in 3 seconds...")
    os.sleep(1)
    print("Restarting kernel in 2 seconds...")
    os.sleep(1)
    print("Restarting kernel in 1 seconds...")
    os.sleep(1)
    
    _G._LOGOUT_REQUESTED = true
    
    print("System rebooted successfully!")
    return true
end

reboot.required_permission = "system"
reboot.required_group = "admin"

return reboot
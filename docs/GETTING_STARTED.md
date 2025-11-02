# Getting Started with placeholderOS Kernel

## Running the Kernel

### Normal Mode (with Shell)
```lua
local kernel = require("src.kernel")
kernel.run()  -- or kernel.run({no_shell = false})
```

### GUI Mode (without Shell)
```lua
local kernel = require("src.kernel")
kernel.run({no_shell = true})
```

### Advanced Usage
```lua
local kernel = require("src.kernel")

-- Initialize with options
kernel.init({no_shell = true})

-- Do additional setup here
kernel.start_scheduler()

-- Then run
kernel.run()  -- Will use the options from init()
```

## Creating a Simple GUI Application

1. Create a new Lua file (e.g., `my_gui.lua`)
2. Require the kernel API
3. Define your GUI logic
4. Start the kernel in GUI mode

```lua
-- my_gui.lua
local kernel = require("src.kernel")

-- Start kernel in GUI mode with boot flag
kernel.run({no_shell = true})

-- Define your GUI process
local function gui_process()
    while true do
        -- Your GUI code here
        -- Handle user input, draw interface, etc.
        os.sleep(0.1)
    end
end

-- Create and start your GUI process
local pid = kernel.create_process(gui_process, "my_gui", "user", {"basic"})
```

## User Accounts

The kernel includes several built-in user accounts:

- `trusteddaniel`: Highest privilege user (password: "noshell")
- `admin`: Administrative user (password: "")
- `user`: Standard user (password: "")
- `guest`: Limited user (password: "")

## Permissions

Available permission levels:
- `basic`: Basic system access
- `user`: User-level operations
- `admin`: Administrative functions
- `system`: System-level operations
- `trusted`: Trusted operations

## Process States

Processes can be in these states:
- `ready`: Waiting to run
# Getting Started with placeholderOS Kernel

This quickstart describes how to use the kernel API. Note: public APIs now live under `src/api/`. `require("src.kernel")` remains a compatible shim that returns the same API.

## Running the Kernel

### Normal Mode (with Shell)
```lua
local kernel = require("src.kernel") -- shim to src.api.kernel
kernel.run()  -- or kernel.run({no_shell = false})
```

### GUI Mode (without Shell)
```lua
local kernel = require("src.kernel")
kernel.run({no_shell = true})
```

### Advanced Usage
```lua
local kernel = require("src.kernel")

-- Initialize with options
kernel.init({no_shell = true})

-- Do additional setup here (requires proper permissions)
kernel.start_scheduler()

-- Then run
kernel.run()  -- Will use the options from init()
```

## Creating a Simple GUI Application

1. Create a new Lua file (e.g., `my_gui.lua`)
2. Require the kernel API (`require("src.kernel")`)
3. Define your GUI logic
4. Start the kernel in GUI mode

Example:

```lua
-- my_gui.lua
local kernel = require("src.kernel")

-- Start kernel in GUI mode with boot flag
kernel.run({no_shell = true})

-- Define your GUI process
local function gui_process()
    while true do
        -- Your GUI code here
        -- Handle user input, draw interface, etc.
        os.sleep(0.1)
    end
end

-- Create and start your GUI process (may fail with permission errors)
local pid, err = kernel.create_process(gui_process, "my_gui", "user", {"basic"})
if not pid then
    error("failed to create GUI process: " .. tostring(err))
end
```

## Protected internal modules

The kernel ships with a secure loader at `src/api/secure_loader.lua` that prevents unprivileged programs from requiring internal modules such as `src.utils`. If you are developing internal modules that should remain private, add their module names or patterns to the `protected_patterns` table in that file. Kernel code and privileged processes may still access protected modules.

## User Accounts

The kernel ships with several example built-in user accounts (see `src/main.lua`):

- `trusteddaniel`: Highest privilege user (password: "noshell")
- `admin`: Administrative user
- `user`: Standard user
- `guest`: Limited user

Passwords in the sample configuration are intentionally blank or simple for development; replace them before production use.

## Permissions

Key permission levels used in the kernel:

- `basic`: Basic system access
- `user`: User-level operations
- `admin`: Administrative functions
- `system`: System-level operations
- `trusted`: Trusted operations

Only `admin`/`system`/`trusted` callers may perform elevated actions through the kernel API wrappers.

## Process States

Processes can be in these states:

- `ready`: Waiting to run
- `running`: Currently executing
- `suspended`: Paused
- `dead`: Terminated normally
- `murdered`: Force-killed

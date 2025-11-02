# Kernel API Reference

This document provides detailed reference for the placeholderOS kernel API functions.

## Initialization and Boot

### `kernel.init(options)`
Initializes the kernel with boot flags.

**Parameters:**
- `options` (table, optional): Boot configuration options
  - `no_shell` (boolean): If true, disables the default shell interface

### `kernel.run(options)`
Initializes and starts the kernel with boot flags.

**Parameters:**
- `options` (table, optional): Boot configuration options (same as `kernel.init()`)

## Process Management

### `kernel.create_process(func, name, user, permissions)`
Creates a new process.

**Parameters:**
- `func` (function): The coroutine function to run
- `name` (string): Process name
- `user` (string): Owner username
- `permissions` (table): Array of permission strings

**Returns:** Process ID (number)

### `kernel.get_process(pid)`
Gets process information.

**Parameters:**
- `pid` (number): Process ID

**Returns:** Process table or nil

### `kernel.list_processes()`
Lists all processes.

**Returns:** Array of process info tables

### `kernel.kill_process(pid)`
Kills a process.

**Parameters:**
- `pid` (number): Process ID to kill
# Kernel API Reference

This document describes the public kernel API. The runtime implementation now lives at `src/api/kernel.lua`. For backward compatibility, `require("src.kernel")` continues to work and returns the same API (a small shim requires the new module).

Important: the kernel API is guarded. Many functions will return (nil, err) or (false, err) when the calling process does not have the required permission. Callers should always check return values for errors.

## High-level notes

- API location: `src/api/` (public APIs live here). Internal modules remain under `src/`.
- Permission model: kernel wrapper functions enforce permission checks. `admin`, `system`, and `trusted` are elevated roles. Normal callers cannot perform actions on other users' processes or grant permissions they don't have.
- Backwards compatibility: code that does `local kernel = require("src.kernel")` will continue to work (the shim forwards to `src.api.kernel`).

## Initialization and Boot

### `kernel.init(options)`
Initializes the kernel with boot flags.

Parameters:
- `options` (table, optional): Boot configuration options
  - `no_shell` (boolean): If true, disables the default shell interface

Returns: nothing

### `kernel.run(options)`
Initializes and starts the kernel with boot flags.

Parameters:
- `options` (table, optional): Boot configuration options (same as `kernel.init()`)

Returns: nothing

## Process Management

All process management functions perform permission checks. They may return an error string when the caller lacks necessary permissions.

### `kernel.create_process(func, name, user, permissions)`
Creates a new process.

Parameters:
- `func` (function): The coroutine function to run
- `name` (string): Process name
- `user` (string): Owner username (optional; defaults to caller's user)
- `permissions` (table): Array or map of permission strings (optional)

Returns: `pid` (number) on success, or `nil, err` on failure. Common failures include permission-denied when creating a process for another user or granting permissions the caller does not have.

### `kernel.register_system_process(name, user, permissions)`
Registers a system process. Requires `system` permission.

Parameters:
- `name` (string): Process name
- `user` (string): Owner username
- `permissions` (table): Permission array

Returns: `pid` (number) on success, or `nil, err` on failure.

### `kernel.get_process(pid)`
Gets process information. Unprivileged callers receive a safe summary. Admin callers see the full permissions table.

Parameters:
- `pid` (number): Process ID

Returns: process info table or `nil` if not found.

### `kernel.list_processes()`
Lists all processes.

Returns: Array of process info tables.

### `kernel.kill_process(pid)`
Kills a process. A caller may only kill their own processes unless they have `admin`.

Parameters:
- `pid` (number): Process ID to kill

Returns: `true` on success, or `false, err` on failure.

### `kernel.suspend_process(pid)` / `kernel.resume_process(pid)`
Suspend or resume processes. Same permission rules as `kill_process`.

Parameters:
- `pid` (number): Process ID

Returns: `true` on success, or `false, err` on failure.

## Scheduler Management

### `kernel.start_scheduler()` / `kernel.stop_scheduler()`
Start/stop the scheduler. These operations require `admin` permission.

Returns: `true` on success, or `false, err`.

### `kernel.tick()`
Runs one scheduler tick (for manual control). No elevated permissions required.

Returns: scheduler tick result (implementation-defined).

## Permissions

### `kernel.check_permission(username, permission)`
Checks whether the named user has a permission.

Parameters:
- `username` (string): Username to check
- `permission` (string): Permission name

Returns: boolean

### `kernel.get_user_permissions(user)`
Gets the permissions for a user.

Parameters:
- `user` (string): Username

Returns: table mapping permission -> source or boolean

### `kernel.assign_user_permission(username, permission)`
Assigns a permission to a user. Requires `admin`.

Parameters:
- `username` (string)
- `permission` (string)

Returns: `true` on success, or `false, err`.

## Examples

Create a process and handle permission errors:

```lua
local kernel = require("src.kernel") -- shim to src.api.kernel

local pid, err = kernel.create_process(function()
    while true do os.sleep(1) end
end, "myproc", "user", {"basic"})

if not pid then
    print("Failed to create process:", err)
end
```

This reference focuses on the public API surface. For internal wiring and module implementation see `src/` (internal modules like `src.process`, `src.scheduler`, and `src.perms`).

## Protected internal modules

By default, all `src.*` modules are protected except for `src.api.*` and the kernel shim `src.kernel`. This means user programs should only rely on public APIs under `src.api` and should not require `src.*` internal modules directly. To change this policy, edit `src/api/secure_loader.lua`.
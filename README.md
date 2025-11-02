# placeholderOS-kernel (ALPHA)

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
![Version](https://img.shields.io/badge/version-1.0.0--alpha-red)
![Status](https://img.shields.io/badge/status-alpha-red)

> **NOTICE:** This project is currently in ALPHA. Expect bugs, incomplete features, and significant changes between versions.

placeholderOS is a custom operating system designed for [CC: Tweaked](https://tweaked.cc), the popular Minecraft mod that adds programmable computers to the game. This project aims to provide a kernel for the OS.

## About

placeholderOS-kernel is being developed by **APT SHOW INCORPORATED** as an experimental platform for exploring security concepts and user management within ComputerCraft. The kernel manages the core functionality of the OS, including:

- **Multi-user Authentication**: Secure user accounts with permission levels
- **Permission Groups**: Tiered access system (guest, user, admin, trusted, system)
- **Command Shell Interface**: Built in streamlined command processing
- **Modular Architecture**: Designed for easy extension
- **Kernel API**: Programmatic access to kernel functions for GUI applications

## Documentation

- [Getting Started](./docs/GETTING_STARTED.md) - Basic setup and usage guide
- [API Reference](./docs/API_REFERENCE.md) - Complete function reference

## Kernel API

The kernel provides a Lua API for programmatic access to core functions. This allows GUI applications and other programs to interact with the kernel directly.

### Basic Usage

```lua
local kernel = require("src.kernel")

-- Start kernel with shell (default)
kernel.run()

-- Start kernel without shell (GUI mode)
kernel.run({no_shell = true})

-- Or using separate init and run
kernel.init({no_shell = true})
kernel.run()
```

### Boot Flags

The `kernel.init()` and `kernel.run()` functions accept an options table with boot flags:

- `no_shell` (boolean): Disable the default shell interface. When true, the kernel runs without the login/shell system, suitable for GUI applications.

```lua
-- Example: Start kernel in GUI mode
kernel.run({no_shell = true})
```

### Process Management

```lua
-- Create a new process
local pid = kernel.create_process(func, "process_name", "user", {"basic"})

-- Get process information
local proc = kernel.get_process(pid)

-- List all processes
local processes = kernel.list_processes()

-- Kill a process
kernel.kill_process(pid)

-- Suspend/resume processes
kernel.suspend_process(pid)
kernel.resume_process(pid)
```

### Scheduler Control

```lua
-- Start/stop the scheduler
# placeholderOS-kernel (ALPHA)

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
![Version](https://img.shields.io/badge/version-1.0.0--alpha-red)
![Status](https://img.shields.io/badge/status-alpha-red)

> **NOTICE:** This project is currently in ALPHA. Expect bugs, incomplete features, and significant changes between versions.

placeholderOS is a custom operating system designed for [CC: Tweaked](https://tweaked.cc), the popular Minecraft mod that adds programmable computers to the game. This project provides a kernel for the OS.

## About

placeholderOS-kernel is an experimental platform for exploring security concepts and user management within ComputerCraft. The kernel manages core OS functionality including authentication, permissions, and process scheduling.

Key features:

- Multi-user authentication and permission groups
- Command shell interface
- Modular architecture and a guarded Kernel API

## Project layout

- `src/` — internal modules (process, scheduler, perms, etc.)
- `src/api/` — public, guarded APIs for programs (e.g., `src/api/kernel.lua`)
- `docs/` — documentation

For backward compatibility, `require("src.kernel")` still works (it loads a shim that forwards to `src/api/kernel.lua`).

## Protected internal modules

By default the project now protects all modules under `src.*` from being required by unprivileged programs. The only exceptions are public APIs under `src.api.*` and the kernel shim `src.kernel`. This is enforced by `src/api/secure_loader.lua` which overrides `require` at runtime.

Kernel code and privileged processes (admin/system/trusted) can still require protected modules. To change the policy, edit `src/api/secure_loader.lua` — you can broaden or narrow protection, or switch to a whitelist approach if desired.

## Documentation

- [Getting Started](./docs/GETTING_STARTED.md)
- [API Reference](./docs/API_REFERENCE.md)

## Kernel API (summary)

The kernel provides a guarded Lua API for programmatic access to core functions. API consumers should always handle errors returned from kernel wrapper functions because permission checks may reject operations.

Basic usage:

```lua
local kernel = require("src.kernel") -- shim to src.api.kernel

-- Start kernel with shell (default)
kernel.run()

-- Start kernel without shell (GUI mode)
kernel.run({no_shell = true})
```

Process management and scheduler control are available via the kernel API. Many operations require `admin`, `system`, or `trusted` permissions; see `docs/API_REFERENCE.md` for details.

## GUI Support

The kernel supports GUI applications by running without the default shell (use `kernel.run({no_shell = true})`). GUI apps can create processes and interact with the kernel API but must respect permission restrictions.

Example GUI usage is shown in `docs/GETTING_STARTED.md`.

## Current State

This project is in ALPHA; expect API changes. The kernel skeleton, login flow, and permission system are present and actively being improved.

## License

This project is licensed under the [GNU Affero General Public License v3.0](./LICENSE).

## Contact

Open an issue on this repository for questions or feature requests.

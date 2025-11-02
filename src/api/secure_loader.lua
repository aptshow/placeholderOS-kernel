-- Secure loader: overrides `require` to prevent unprivileged processes from loading protected modules
-- Protected modules (by pattern) can only be required by kernel context or processes with admin/system/trusted perms

local original_require = require
-- Ensure the repository `src` folder is on package.path so require('src.xxx') resolves
pcall(function()
    package.path = (package.path or "") .. ";/src/?.lua;/src/?/init.lua"
end)
-- Protect everything under `src.` by default except `src.api.*` and `src.kernel`
local function is_protected(name)
    if not name then return false end
    -- allow public API modules under src.api and the kernel shim
    if string.match(name, "^src%.api%..+") or name == "src.api.secure_loader" or name == "src.kernel" then
        return false
    end
    -- protect anything starting with src.
    if string.match(name, "^src%.") then
        return true
    end
    return false
end

-- Lazy-load process lib (may not be available immediately during early boot)
local process_lib = nil
local function get_process_lib()
    if process_lib then return process_lib end
    local ok, res = pcall(original_require, "src.process")
    if ok then process_lib = res end
    return process_lib
end

local function caller_is_privileged()
    local proc_lib = get_process_lib()
    if not proc_lib then
        -- No process lib available yet; assume kernel context
        return true
    end
    local cur = proc_lib.current()
    if not cur then
        -- Kernel context
        return true
    end
    -- normalize perms
    local perm_map = {}
    if type(cur.permissions) == "table" then
        for k, v in pairs(cur.permissions) do
            if type(k) == "number" then perm_map[v] = true else perm_map[k] = v end
        end
    end
    return perm_map.admin == true or perm_map.system == true or perm_map.trusted == true
end

-- Override global require
-- Keep the original available as `original_require` in this module
_G.require = function(name)
    if is_protected(name) then
        if not caller_is_privileged() then
            error("Access denied: module '" .. tostring(name) .. "' is protected and cannot be required from this context")
        end
    end
    return original_require(name)
end

return true

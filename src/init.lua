-- Bootstrap for in-world execution: ensure repository /src is on package.path
-- and preload essential modules so child processes can require them.
pcall(function()
    package.path = (package.path or "") .. ";/src/?.lua;/src/?/init.lua"
end)

-- Load secure loader to protect internal modules and to set up require override
pcall(function() require("src.api.secure_loader") end)

-- Preload the kernel shim so require("src.kernel") resolves in child processes
local ok, k = pcall(require, "src.kernel")
if ok and k then
    pcall(function() package.loaded["src.kernel"] = k end)
    pcall(function() package.preload["src.kernel"] = function() return k end end)
end

-- Write a small debug entry so we know bootstrap ran
pcall(function()
    if fs and fs.open then
        local f = fs.open("/kernel_debug.txt", "a")
        if f then f.writeLine("src.init: bootstrap loaded") f.close() end
    end
end)

return true

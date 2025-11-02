local M = {}

local ok, scheduler = pcall(require, "src.scheduler")
local ok2, process = pcall(require, "src.process")

function M.dump()
    print("-- debug: scheduler/process state --")
    if ok and scheduler and type(scheduler.is_running) == "function" then
        print("scheduler.is_running():", tostring(scheduler.is_running()))
    else
        print("scheduler: not available")
    end

    if ok2 and process and type(process.list) == "function" then
        local plist = process.list()
        print("process.list() -> count:", #plist)
        for _, p in ipairs(plist) do
            print(string.format("  pid=%s name=%s user=%s state=%s", tostring(p.pid), tostring(p.name), tostring(p.user), tostring(p.state)))
        end
    else
        print("process: not available")
    end
    print("-- end debug --")
end

return M

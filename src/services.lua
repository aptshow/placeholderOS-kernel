local services = {}

services.registry = {}

-- Function to register a service
function services.register(name, service)
    if services.registry[name] then
        error("Service '" .. name .. "' already exists.")
    end
    services.registry[name] = service
end

-- Function to get a service
function services.get(name)
    return services.registry[name] or error("Service '" .. name .. "' not found.")
end

return services
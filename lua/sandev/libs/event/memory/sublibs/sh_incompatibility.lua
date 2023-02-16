-- Events are blocked or removed if incompatible memories are set

-- ATTENTION! Incompatibilies can be different on client and server!

-- Set an event incompatible with a memory
function SEv.Event.Memory.Incompatibility:Set(eventName, ...)
    for _, memoryName in ipairs({ ... }) do
        self.list[eventName] = self.list[eventName] or {}
        self.list[eventName][memoryName] = true
    end
end

-- Get the incompatible event memories
function SEv.Event.Memory.Incompatibility:Get(eventName)
    return self.list[eventName]
end

-- Get the incompatibilities list
function SEv.Event.Memory.Incompatibility:GetList()
    return self.list
end

-- Check if the event is incompatible with the loaded memories
function SEv.Event.Memory.Incompatibility:Check(eventName)
    if self.list[eventName] then
        for memoryName, memoryValue in pairs(self.instance.Event.Memory:GetList()) do
            if self.list[eventName][memoryName] then
                return true
            end
        end
    end

    return false
end

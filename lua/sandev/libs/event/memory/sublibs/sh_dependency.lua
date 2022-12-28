-- Events can provide or require memories
-- Events automatically turn on or off as the player interacts and sets memories

-- ATTENTION! Dependencies can be different on client and server!

-- Set a provider
function SEv.Event.Memory.Dependency:SetProvider(eventName, ...)
    for _, memoryName in ipairs({ ... }) do
        self.providers[eventName] = self.providers[eventName] or {}
        self.providers[eventName][memoryName] = true
    end
end

-- Set a dependent
function SEv.Event.Memory.Dependency:SetDependent(eventName, ...)
    for _, memoryName in ipairs({ ... }) do
        self.dependents[eventName] = self.dependents[eventName] or {}
        self.dependents[eventName][memoryName] = true
    end
end

-- Get providers list
function SEv.Event.Memory.Dependency:GetProviders()
    return self.providers
end

-- Get dependents list
function SEv.Event.Memory.Dependency:GetDependents()
    return self.dependents
end

-- Check if the event has all the dependent memories loaded
function SEv.Event.Memory.Dependency:Check(eventName)
    local eventDependencies = self:GetDependents()[eventName]

    if eventDependencies then
        local memories = self.base.Event.Memory:GetList()

        for memoryName, _ in pairs(eventDependencies) do
            if memories[memoryName] == nil then
                return false
            end
        end
    end

    return true
end

-- Pick up which events are active or inactive according to memory dependencies
function SEv.Event.Memory.Dependency:GetDependentEventsState()
    local memoryList = self.base.Event.Memory:GetList()
    local dependentEvents = {
        enabled = {},
        disabled = {}
    }

    for eventName, memoryTab in pairs(self.dependents) do
        local totalNeededMemories = table.Count(memoryTab)
        local totalEnabledMemories = 0

        for memoryName, _ in pairs(memoryTab) do 
            if memoryList[memoryName] then
                totalEnabledMemories = totalEnabledMemories + 1
            end
        end

        if totalNeededMemories == totalEnabledMemories then
            table.insert(dependentEvents.enabled, eventName)
        else
            table.insert(dependentEvents.disabled, eventName)
        end
    end

    return dependentEvents
end


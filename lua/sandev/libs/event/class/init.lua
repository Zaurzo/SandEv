AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')

include('shared.lua')

local EventBase = SandEv.Base.Event.Base

local function Create(event, className, brushName)
    local ent = event:CreateEntity(className)
    if not ent then return end

    if brushName then
        ent:SetBrushName(brushName)
    end

    return ent
end

---Creates a new trigger for this event.
---@realm server
---@param name? string The name to give the trigger.
---@return sev_trigger? trigger
function EventBase:CreateTrigger(name)
    return Create(self, 'sev_trigger', name)
end

---Creates a new marker for this event.
---@realm server
---@param name? string The name to give the marker.
---@return sev_marker? marker
function EventBase:CreateMarker(name)
    return Create(self, 'sev_marker', name)
end

---Sets the value of a memory provided by this event.
---@realm server
---@param memory string The memory to set the value of.
---@param value any The value to set.
function EventBase:SetMemory(memory, value)
    if not self:IsMemoryProvided(memory) then
        return error('attempt to set value of memory not provided by event')
    end

    self.Instance.Memory:Set(memory, value)
end
---@class SandEv.Event
---@field ID string The ID of the event.
---@field Category string The category the event belongs to.
---@field Tier number The tier required for the event to run.
---@field Instance SandEv.Instance The SandEv instance the event belongs to.
---@field Current? SandEv.Event The current running instance of the event.
local EventBase = {}

EventBase.__index = EventBase
SandEv.Base.Event.Base = EventBase

function EventBase:Init()
    local function GetMemoryLookup(name)
        local list = self.Memory and self.Memory[name]
        if not list then return end

        local memories = {}

        for _, memory in ipairs(list) do
            memories[memory] = true
        end

        return memories
    end

    self._enabled = self:GetTier() <= self.Instance.Event:GetTier()
    self._memory_dependency = GetMemoryLookup('Dependencies')
    self._memory_incompatible = GetMemoryLookup('Incompatibilites')
    self._memory_provides = GetMemoryLookup('Provisions')
end

-- Callbacks

function EventBase:Awake()
end

function EventBase:OnEnabled()
end

function EventBase:OnDisabled()
end

function EventBase:OnBlocked()
end

function EventBase:OnIgnored()
end

-- Utility

function EventBase:GetTier()
    return self.Tier
end

local SendEventState

if SERVER then
    ---@param event SandEv.Event
    ---@param state boolean
    function SendEventState(event, state)
        net.cheap.Start('sev_change_event_state')
        net.WriteString(event.Instance.ID)
        net.WriteString(event.ID)
        net.Broadcast()
    end
end

function EventBase:Enable(dontSendToClients)
    if self._enabled then return end

    self:OnEnabled()

    if SERVER and not dontSendToClients then
        SendEventState(self, true)
    end

    self._enabled = true
end

function EventBase:Disable(dontSendToClients)
    if not self._enabled then return end

    self:OnDisabled()

    if self.Current ~= nil then
        self.Current:ClearEntities()
        self.Current = nil
    end

    if SERVER and not dontSendToClients then
        SendEventState(self, false)
    end

    self._entities = nil
    self._enabled = false
end

---@return boolean
function EventBase:IsEnabled()
    return self._enabled
end

---@return boolean
function EventBase:IsRunning()
    return self.Current ~= nil
end

---Creates a new entity for the event.
---@realm shared
---@generic T : Entity
---@param className `T` The class name of the entity to create.
---@return T?
function EventBase:CreateEntity(className)
    local ent

    if SERVER then
        ent = ents.Create(className)
    else
        ent = ents.CreateClientside(className)
    end

    if not IsValid(ent) then
        return nil
    end

    self._entities = self._entities or {}
    self._entities[ent] = true

    return ent
end

---Returns a list of all entities that belong to the event.
---@realm shared
---@return Entity[]
function EventBase:GetEntities()
    local entities = {}

    if not self._entities then
        return entities
    end

    for ent in pairs(self._entities) do
        if ent:IsValid() then
            table.insert(entities, ent)
        end
    end

    return entities
end

function EventBase:ClearEntities()
    for _, ent in ipairs(self:GetEntities()) do
        ent:Remove()
    end

    self._entities = nil
end

-- Memory management

---@param event SandEv.Event
---@param name string
---@return string[]
local function GetMemoryList(event, name)
    local memories = {}

    if event.Memory and event.Memory[name] then
        for k, memory in ipairs(event.Memory[name]) do
            memories[k] = memory
        end
    end

    return memories
end

---Returns a list of memories the event depends on to run.
---@realm shared
---@return string[]
function EventBase:GetMemoryDependencies()
    return GetMemoryList(self, 'Dependencies')
end

---Returns a list of memories that the event is incompatible with.
---@realm shared
---@return string[]
function EventBase:GetIncompatibleMemories()
    return GetMemoryList(self, 'Incompatibilities')
end

---Returns a list of memories the event provides.
---@realm shared
---@return string[]
function EventBase:GetProvidedMemories()
    return GetMemoryList(self, 'Provisions')
end

---Returns true if the event depends on the specified memory to run.
---@realm shared
---@param memory string
---@return string[]
function EventBase:IsDependentOnMemory(memory)
    local dependency = self._memory_dependency
    return (dependency and dependency[memory]) or false
end

---Returns true if the event is incompatible with the specified memory.
---@realm shared
---@param memory string
---@return string[]
function EventBase:IsIncompatibleWithMemory(memory)
    local incompatible = self._memory_incompatible
    return (incompatible and incompatible[memory]) or false
end

---Returns true if the specified memory is provided by the event.
---@realm shared
---@param memory string
---@return string[]
function EventBase:IsMemoryProvided(memory)
    local provides = self._memory_provides
    return (provides and provides[memory]) or false
end
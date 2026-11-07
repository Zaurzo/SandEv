---@class SandEv.EventLib : SandEv.Library
local EventLib = SandEv.Base:Library()
SandEv.Base.Event = EventLib

if SERVER then
    include('devmode/init.lua')
    include('class/init.lua')
    include('tier/init.lua')
else
    include('devmode/cl_init.lua')
    include('class/shared.lua')
    include('tier/cl_init.lua')
end

function EventLib:Init()
    local tierCvarName = self.Instance.ID .. '_tier'
    local tier = CreateConVar(
        tierCvarName, 
        '1', 
        FCVAR_ARCHIVE + FCVAR_REPLICATED, 
        'The tier for the ' .. self.Instance.ID .. ' instance.', 
        1, 
        self.Instance.Tiers
    )

    if SERVER then
        cvars.AddChangeCallback(tierCvarName, self.OnTierChanged)
    end

    if self.Instance:IsDevModeEnabled() then
        self:InstallDevCommands()
    else
        self.Instance:AddDevModeCallback(self.OnDevModeChanged, self.Instance.ID)
    end

    self._tier_cvar = tier
end

---@param event SandEv.Event
local function EventNewIndex(event, k, v)
    if k == 'Current' then
        event = event.Instance.Event:Get(event.ID)
    end

    rawset(event, k, v)
end

---Creates a new event class.
---@realm shared
---@param id string The ID of the event.
---@param category string The category this event belongs to.
---@param tier number The minimum tier required for this event to run.
---@return SandEv.Event
function EventLib:New(id, category, tier)
    local event = {
        ID = id,
        Category = category,
        Tier = tier,
        Instance = self.Instance
    }

    event.__index = event
    event.__newindex = EventNewIndex

    return setmetatable(event, EventLib.Base)
end

---Registers the provided event.
---@realm shared
---@param event SandEv.Event
function EventLib:Register(event)
    event:Init()
    
    self._events = self._events or {}
    self._events[event.ID] = event
end

---Returns the event with the associated ID.
---@realm shared
---@param id string
---@return SandEv.Event
function EventLib:Get(id)
    return self._events and self._events[id]
end

function EventLib:GetCurrent(id)
    local event = self:Get(id)
    return event and event.Current
end

---Returns a list of the IDs of all currently registered events.
---@realm shared
---@return SandEv.Event[] eventList
function EventLib:GetList()
    if not self._events then
        return {}
    end

    local eventList = {}

    for _, event in pairs(self._events) do
        table.insert(eventList, event)
    end

    return eventList
end

-- Initialize

local function IncludeEvents(instance, path)
    local files, dirs = file.Find('lua/' .. path .. '*', 'GAME')

    for _, fileName in ipairs(files) do
        local suffix = fileName:sub(-6, -5)

        if suffix == '_g' or instance.IN_MAP then
            SandEv:IncludeFile(path .. fileName)
        end
    end

    for _, dirName in ipairs(dirs) do
        local suffix = dirName:sub(-2)

        if suffix == '_g' or instance.IN_MAP then
            SandEv:IncludeModule(path .. dirName)
        end
    end
end

function EventLib:Initialize(eventTier)
    local eventsPath = self.Instance.ID .. '/events/'

    if not eventTier then
        eventTier = self:GetTier()
    end

    eventTier = math.min(eventTier, self:GetMaxTier())

    self._included_tiers = self._included_tiers or {}

    for tier = 1, eventTier do
        if self._included_tiers[tier] then
            continue
        end

        local tierPath = eventsPath .. 'tier' .. tier .. '/'
        local _, categories = file.Find('lua/' .. tierPath .. '*', 'GAME')

        for _, category in ipairs(categories) do
            IncludeEvents(self.Instance, tierPath .. category .. '/')
        end

        self._included_tiers[tier] = true
    end

    local eventList = self:GetList()

    table.sort(eventList, function(a, b)
        return a.ID > b.ID
    end)
    
    for _, event in ipairs(eventList) do
        if not event:IsEnabled() then continue end

        local eventInstance = setmetatable({}, event) ---@as SandEv.Event
        local enable = true

        for _, memory in ipairs(event:GetMemoryDependencies()) do
            if not self.Instance.Memory:Get(memory) then
                eventInstance:OnIgnored()
                enable = false

                break
            end
        end

        if enable then
            for _, memory in ipairs(event:GetIncompatibleMemories()) do
                if self.Instance.Memory:Get(memory) then
                    eventInstance:OnBlocked()
                    enable = false

                    break
                end
            end
        end

        if enable then
            event.Current = eventInstance

            eventInstance:Awake()
        else
            event.Current = nil
        end
    end

    if CLIENT then
        self:RequestMarkerRenderData()
    end
end
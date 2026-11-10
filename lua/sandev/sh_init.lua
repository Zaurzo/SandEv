AddCSLuaFile()

require('netcheap')

SandEv = SandEv or {}

SandEv.Colors = {
    Red = Color(255, 0, 0),
    Orange = Color(255, 127, 0),
    Yellow = Color(255, 255, 0),
    Green = Color(0, 255, 0),
    Blue = Color(0, 0, 255),
    Pink = Color(255, 0, 255),
    Purple = Color(179, 0, 255),
    Cyan = Color(0, 255, 255)
}

include('sh_util.lua')

if CLIENT then
    local gizmoAlpha = CreateClientConVar(
        'sandev_event_gizmo_alpha', 
        '0.25', 
        true, 
        false,
        'The alpha for developer mode box gizmos, such as triggers.',
        0,
        1
    )

    --Returns the alpha for developer mode box gizmos.
    ---@return number
    function SandEv:GetGizmoAlpha()
        return gizmoAlpha:GetFloat()
    end
end

function SandEv:IncludeFile(filePath)
    local fileName = filePath:GetFileFromFilename()
    local prefix = fileName:sub(1, 3)

    -- sh_ or no prefix = shared

    if SERVER then
        if prefix == 'sv_' then
            return include(filePath)
        elseif prefix == 'cl_' then
            AddCSLuaFile(filePath)
        else
            AddCSLuaFile(filePath)

            return include(filePath)
        end
    else
        if prefix ~= 'sv_' then
            return include(filePath)
        end
    end
end

function SandEv:IncludeModule(modulePath)
    local loadShared = false

    local sharedExists = file.Exists('lua/' .. modulePath .. '/shared.lua', 'GAME')
    local clientInitExists = file.Exists('lua/' .. modulePath .. '/cl_init.lua', 'GAME')
    
    if SERVER then
        if file.Exists('lua/' .. modulePath .. '/init.lua', 'GAME') then
            return include(modulePath .. '/init.lua')
        else
            loadShared = true
        end

        if clientInitExists then
            if loadShared and sharedExists then
                AddCSLuaFile(modulePath .. '/shared.lua')
            end

            AddCSLuaFile(modulePath .. '/cl_init.lua')
        end
    else
        if clientInitExists then
            return include(modulePath .. '/cl_init.lua')
        else
            loadShared = true
        end
    end

    if loadShared and sharedExists then
        return include(modulePath .. '/shared.lua')
    end
end

function SandEv:IncludeFiles(directory)
    local files = file.Find('lua/' .. directory .. '/*.lua', 'GAME')

    for _, fileName in ipairs(files) do
        self:IncludeFile(directory .. '/' .. fileName)
    end
end

function SandEv:IncludeModules(directory)
    local _, modules = file.Find('lua/' .. directory .. '/*', 'GAME')

    for _, moduleName in ipairs(modules) do
        self:IncludeModule(directory .. '/' .. moduleName)
    end
end

-- Instances --

local registeredInstances = {}

include('instance/sh_base.lua')

local function CreateLibraryInstanceRecursive(baseLib, instance, done)
    local lib = setmetatable({ Instance = instance }, baseLib) ---@as SandEv.Library

    if lib.Init then
        lib:Init()
    end

    done = done or {}
    done[baseLib] = lib

    for k, v in pairs(baseLib) do
        if (k ~= '__index' and k ~= 'Instance') and (istable(v) and v.IsSandEvLibrary) then
            if not done[v] then
                CreateLibraryInstanceRecursive(v, instance, done)
            end

            lib[k] = done[v]
        end
    end

    return lib
end

local instanceMeta = {
    ---@param instance SandEv.Instance
    ---@param k string
    __index = function(instance, k)
        local baseValue = SandEv.Base[k]
        if baseValue == nil then return end

        if istable(baseValue) and baseValue.IsSandEvLibrary then
            baseValue = CreateLibraryInstanceRecursive(baseValue, instance)
        end

        instance[k] = baseValue

        return baseValue
    end
}

---@return SandEv.Instance
function SandEv:Instance(id)
    local instance = setmetatable({ ID = id }, instanceMeta) ---@as SandEv.Instance
    instance:Init()

    return instance
end

---@param instance SandEv.Instance
function SandEv:RegisterInstance(instance)
    registeredInstances[instance.ID] = instance
end

---@return SandEv.Instance instance
function SandEv:GetInstance(id)
    return registeredInstances[id]
end

---Returns an iterator for all registered SandEv instances.
---@return fun(): integer, SandEv.Instance
function SandEv:Instances()
    return next, registeredInstances
end

---@return SandEv.Instance[]
function SandEv:GetInstances()
    local instances = {}

    for _, instance in pairs(registeredInstances) do
        table.insert(instances, instance)
    end

    return instances
end

-- Load instances

hook.Add('InitPostEntity', 'sev_post_init', function()
    local gm = gmod.GetGamemode()
    if not gm.IsSandboxDerived then return end -- Sandbox family only

    local files = file.Find('lua/sandev/instances/*.lua', 'GAME')

    for _, instanceFileName in ipairs(files) do
        local instance = include('sandev/instances/' .. instanceFileName) ---@as SandEv.Instance

        if instance then
            instance.IN_MAP = table.HasValue(instance:GetMaps(), game.GetMap())

            if instance.AutoIncludeLibraries then
                instance:IncludeLibraries()
            end

            SandEv:RegisterInstance(instance)
        end
    end

    for id, instance in pairs(registeredInstances) do
        if SERVER then
            instance.Event:Initialize()
        else
            instance.Memory:RequestMemories()
        end

        if instance:IsDevModeEnabled() then
            instance.Tool:Load()
        end

        instance:Initialize()
        
        hook.Run(id .. '_initialized')
    end

    hook.Run('sandev_initialized')
end)

hook.Add('PostCleanupMap', 'sandev_load_events', function()
    for _, instance in pairs(registeredInstances) do
        if SERVER or instance._memories_received then
            instance.Event:Initialize()
        end
    end
end)

if SERVER then
    net.cheap.Receive('sandev_client_initialized', function(len, ply)
        local instanceID = net.ReadString()
        local instance = SandEv:GetInstance(instanceID)

        hook.Run('sandev_client_initialized', instance, ply)
    end)
else
    hook.Add('sev_memories_received', 'sandev_load_events', function(instance)
        instance.Event:Initialize()

        net.cheap.Start('sandev_client_initialized')
        net.WriteString(instance.ID)
        net.SendToServer()
    end)
end
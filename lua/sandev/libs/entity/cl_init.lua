include('shared.lua')

local EntityLib = SandEv.Base.Entity

-- Properties Menu --

local properties_GetHovered = properties.GetHovered

function properties.GetHovered(...)
    local ent, tr = properties_GetHovered(...)
    local isPropertiesMenuBlocked = ent and EntityLib:IsPropertiesMenuBlocked(ent)

    if not isPropertiesMenuBlocked then
        return ent, tr
    end
end

-- Lights --

local _DynamicLight = DynamicLight
local Entity = Entity

-- This is hacky, but I'm creating a dummy dlight just for the edge case 
-- that someone using the function doesn't check for nil.
-- 
-- Note: DynamicLight creates a new userdata every call. This may be changed in
-- a future update, so it's best I keep a look out.
local dummyDLight = DynamicLight(0)
local meta = getmetatable(dummyDLight)
local dummyMeta = {}

for k, v in pairs(meta) do 
    dummyMeta[k] = v 
end

dummyMeta.__newindex = function() end
dummyMeta.__metatable = meta

debug.setmetatable(dummyDLight, dummyMeta)

function DynamicLight(index, ...)
    local ent = Entity(index)

    -- Typical usages of DynamicLight pass in the index of the entity the light is being emitted at
    -- Note: This won't catch everything
    local isLightBlocked = IsValid(ent) and EntityLib:IsLightBlocked(ent)

    if isLightBlocked then
        return dummyDLight
    end

    return _DynamicLight(index, ...)
end
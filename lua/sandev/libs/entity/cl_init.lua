include('shared.lua')

local EntityLib = SandEv.Base.Entity
local properties_GetHovered = properties.GetHovered

function properties.GetHovered(...)
    local ent, tr = properties_GetHovered(...)
    local isPropertiesMenuBlocked = ent and EntityLib:IsPropertiesMenuBlocked(ent)

    if not isPropertiesMenuBlocked then
        return ent, tr
    end
end

local _DynamicLight = DynamicLight
local Entity = Entity

function DynamicLight(index, ...)
    local ent = Entity(index)

    -- Typical usages of DynamicLight pass in the index of the entity the light is being emitted at
    -- Note: This won't catch everything
    local isLightBlocked = IsValid(ent) and EntityLib:IsLightBlocked(ent)

    if not isLightBlocked then
        return _DynamicLight(index, ...)
    end
end
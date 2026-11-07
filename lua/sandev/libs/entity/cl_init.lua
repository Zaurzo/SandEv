include('shared.lua')

local EntityLib = SandEv.Base.Entity
local properties_GetHovered = properties.GetHovered

function properties.GetHovered(...)
    local ent, tr = properties_GetHovered(...)

    if not (ent and EntityLib:IsPropertiesMenuBlocked(ent)) then
        return ent, tr
    end
end
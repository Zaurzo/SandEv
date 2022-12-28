-- Context menu

local _propertiesGetHovered = properties.GetHovered
function properties.GetHovered(eyepos, eyevec)
    local ent, tr = _propertiesGetHovered(eyepos, eyevec)

    if ent and (SEv.Ent:IsContextMenuBlocked(ent) or SEv.Ent:IsContextMenuBlocked(ent, LocalPlayer())) then
        ent = nil
    end

    return ent, tr
end
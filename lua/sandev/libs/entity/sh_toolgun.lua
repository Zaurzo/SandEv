AddCSLuaFile()

local EntityLib = SandEv.Base.Entity
local NetFlag = EntityLib.NetFlag

---Blocks the toolgun from an entity.
---@realm shared
---@param ent Entity
---@param value boolean If the toolgun should be blocked or not.
function EntityLib:BlockToolgun(ent, value)
    self:SetNetFlag(ent, NetFlag.ToolgunBlocked, value)
end

---Returns true if the toolgun is blocked from being used on the entity.
---@realm shared
---@param ent Entity
function EntityLib:IsToolgunBlocked(ent)
    return self:GetNetFlag(ent, NetFlag.ToolgunBlocked)
end

hook.Add('CanTool', 'sev_toolgun_control', function(ply, tr)
    local ent = tr.Entity

    if IsValid(ent) and EntityLib:IsToolgunBlocked(ent) then
        return false
    end
end)
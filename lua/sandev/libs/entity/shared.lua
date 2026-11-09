---@class SandEv.EntityLib : SandEv.Library
local EntityLib = SandEv.Base:Library()
SandEv.Base.Entity = EntityLib

---I need to network a few variables, and instead of using SetNWBool, I turn the variables into flags
---and send them over using SetNWInt to save slots
---@realm shared
---@enum SandEv.Entity.NetFlag
EntityLib.NetFlag = {
    SpawnedByPlayer = bit.lshift(1, 0),
    PhysgunBlocked = bit.lshift(1, 1),
    ToolgunBlocked = bit.lshift(1, 2),
    PropertiesBlocked = bit.lshift(1, 3),
    LightBlocked = bit.lshift(1, 4),
    Muted = bit.lshift(1, 5)
}

include('sh_meta.lua')
include('sh_toolgun.lua')

local NetFlag = EntityLib.NetFlag

---Sets an internal net flag.
---This is internal - although you're able to use it, you probably shouldn't.
---@realm shared
---@param ent Entity
---@param flag SandEv.Entity.NetFlag
---@param value boolean
function EntityLib:SetNetFlag(ent, flag, value)
    local flags = ent:GetNWInt('sev_net_flags', 0)

    if value then
        flags = bit.bor(flags, flag)
    else
        flags = bit.band(flags, bit.bnot(flag))
    end

    ent:SetNWInt('sev_net_flags', flags)
end

---Returns true if the entity has the specified net flag set.
---This is internal - although you're able to use it, you probably shouldn't.
---@realm shared
---@param ent Entity
---@param flag SandEv.Entity.NetFlag
---@return boolean isSet
function EntityLib:GetNetFlag(ent, flag)
    local flags = ent:GetNWInt('sev_net_flags', 0)

    return bit.band(flags, flag) == flag
end

---Returns true if the entity was spawned by a player.
---@return boolean
function EntityLib:IsSpawnedByPlayer(ent)
    return self:GetNetFlag(ent, NetFlag.SpawnedByPlayer)
end

---Blocks the physgun from an entity.
---@realm shared
---@param ent Entity
---@param value boolean If the physgun should be blocked or not.
function EntityLib:BlockPhysgun(ent, value)
    self:SetNetFlag(ent, NetFlag.PhysgunBlocked, value)
end

---Returns true if the physgun is blocked from being used on the entity.
---@realm shared
---@param ent Entity
---@return boolean
function EntityLib:IsPhysgunBlocked(ent)
    return self:GetNetFlag(ent, NetFlag.PhysgunBlocked)
end

---Blocks the properties menu from being used on an entity.
---@realm shared
---@param ent Entity
---@param value boolean If the properties menu should be blocked or not.
function EntityLib:BlockPropertiesMenu(ent, value)
    self:SetNetFlag(ent, NetFlag.PropertiesBlocked, value)
end

---Returns true if the properties menu is blocked from being used on an entity.
---@realm shared
---@param ent Entity
---@return boolean
function EntityLib:IsPropertiesMenuBlocked(ent)
    return self:GetNetFlag(ent, NetFlag.PropertiesBlocked)
end

---Blocks DynamicLight from being used on an entity.
---@realm shared
---@param ent Entity
---@param value boolean
function EntityLib:BlockLight(ent, value)
    self:SetNetFlag(ent, NetFlag.LightBlocked, value)
end

---Returns true if DynamicLight is blocked from being used on an entity.
---@realm shared
---@param ent Entity
---@return boolean
function EntityLib:IsLightBlocked(ent)
    return self:GetNetFlag(ent, NetFlag.LightBlocked)
end

---Sets whether or not all sounds coming from the provided entity should be muted.
---@realm shared
---@param ent Entity The entity to mute or unmute.
---@param value boolean The mute status.
---@param networked? boolean If the mute status should be networked to the client.
function EntityLib:SetMuted(ent, value, networked)
    if networked then
        self:SetNetFlag(ent, NetFlag.Muted, value)
    else
        ent._sev_muted = value and true or false
    end
end

---Returns true if the provided entity is muted.
---@realm shared
---@param ent Entity The entity to check.
---@return boolean isMuted
function EntityLib:IsMuted(ent)
    return ent._sev_muted or self:GetNetFlag(ent, NetFlag.Muted)
end

---Gets the closest entity to the specified position.
---@param pos Vector
---@param predicate? fun(ent : Entity, dist : number) : boolean
---@return Entity? closestEnt
function EntityLib:GetClosest(pos, predicate)
    local currentDist = math.huge
    local closestEnt

    for _, ent in ents.Iterator() do
        local dist = ent:GetPos():DistToSqr(pos)

        if dist < currentDist and (not predicate or predicate(ent, dist)) then
            currentDist = dist
            closestEnt = ent
        end
    end

    return closestEnt
end

-- Hooks

hook.Add('EntityEmitSound', 'SandEv.Entityity_sound_control', function(data)
    local ent = data.Entity

    if IsValid(ent) and EntityLib:IsMuted(ent) then
        return false
    end
end)

hook.Add('PhysgunPickup', 'sev_physgun_control', function(ply, ent)
    if EntityLib:IsPhysgunBlocked(ent) then
        return false
    end
end)
AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')

include('shared.lua')

local EntityLib = SandEv.Base.Entity
local NetFlag = EntityLib.NetFlag

local function IsNotProp(ent)
    return ent:IsNPC() or ent:IsNextBot() or ent:IsPlayer()
end

---Kills the specified entity.
---@param ent Entity
---@param attacker? Entity
function EntityLib:Kill(ent, attacker)
    ent:SetHealth(0)
    ent:TakeDamage(1, attacker, attacker)
    
    if ent:Alive() or not IsNotProp(ent) then
        ent:Fire('kill') -- if all else fails...
    end
end

local function OnPlayerSpawnedEntity(ply, ent)
    EntityLib:SetNetFlag(ent, NetFlag.SpawnedByPlayer, true)
end

hook.Add('PlayerSpawnedSENT', 'sev_on_player_spawn', OnPlayerSpawnedEntity)
hook.Add('PlayerSpawnedNPC', 'sev_on_player_spawn', OnPlayerSpawnedEntity)
hook.Add('PlayerSpawnedSWEP', 'sev_on_player_spawn', OnPlayerSpawnedEntity)
hook.Add('PlayerSpawnedVehicle', 'sev_on_player_spawn', OnPlayerSpawnedEntity)

local function OnPlayerSpawnedProp(ply, _, ent)
    EntityLib:SetNetFlag(ent, NetFlag.SpawnedByPlayer, true)
end

hook.Add('PlayerSpawnedProp', 'sev_on_player_spawn', OnPlayerSpawnedProp)
hook.Add('PlayerSpawnedEffect', 'sev_on_player_spawn', OnPlayerSpawnedProp)
hook.Add('PlayerSpawnedRagdoll', 'sev_on_player_spawn', OnPlayerSpawnedProp)
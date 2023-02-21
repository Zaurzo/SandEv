-- Handle detours
local ENT = FindMetaTable("Entity")
SEv_ENT_Fire = SEv_ENT_Fire or ENT.Fire

-- Is ent spawned by a player

function SEv.Ent:SetSpawnedByPlayer(ent, value)
    if IsValid(ent) and ent.SetNWBool then
        ent:SetNWBool("sev_spawned", true)
    end
end

hook.Add("PlayerSpawnedProp", "sev_spawned_by_player", function(ply, model, ent) SEv.Ent:SetSpawnedByPlayer(ent, true) end)
hook.Add("PlayerSpawnedEffect", "sev_spawned_by_player", function(ply, model, ent) SEv.Ent:SetSpawnedByPlayer(ent, true) end)
hook.Add("PlayerSpawnedRagdoll", "sev_spawned_by_player", function(ply, model, ent) SEv.Ent:SetSpawnedByPlayer(ent, true) end)
hook.Add("PlayerSpawnedNPC", "sev_spawned_by_player", function(ply, ent) SEv.Ent:SetSpawnedByPlayer(ent, true) end)
hook.Add("PlayerSpawnedSENT", "sev_spawned_by_player", function(ply, ent) SEv.Ent:SetSpawnedByPlayer(ent, true) end)
hook.Add("PlayerSpawnedSWEP", "sev_spawned_by_player", function(ply, ent) SEv.Ent:SetSpawnedByPlayer(ent, true) end)
hook.Add("PlayerSpawnedVehicle", "sev_spawned_by_player", function(ply, ent) SEv.Ent:SetSpawnedByPlayer(ent, true) end)

-- Damage

local function SetDamageMode(ent, mode, value, callback, args)
    if value then -- Stalker
        ent:AddEFlags(EFL_NO_DISSOLVE)
    else
        ent:RemoveEFlags(EFL_NO_DISSOLVE)
    end

    ent[mode] = value

    if callback then
        SEv.Ent:SetDamageCallback(ent, callback, args)
    end
end

function SEv.Ent:SetInvulnerable(ent, value, callback, ...)
    SetDamageMode(ent, "sev_invulnerable", value, callback, { ... })
    SEv.Ent:BlockEntRemoveCvars(ent, value)
end

function SEv.Ent:SetReflectDamage(ent, value, callback, ...)
    SetDamageMode(ent, "sev_damage_ricochet", value, callback, { ... })
    SEv.Ent:BlockEntRemoveCvars(ent, value)
end

function SEv.Ent:IsInvulnerable(ent)
    return ent.sev_invulnerable
end

function SEv.Ent:IsReflectingDamage(ent)
    return ent.sev_damage_ricochet
end

function SEv.Ent:SetDamageCallback(ent, callback, args)
    ent.sev_damage_callback = { func = callback, args = args or {} }
end

function SEv.Ent:GetDamageCallback(ent)
    return ent.sev_damage_callback
end

hook.Add("CanPlayerSuicide", "sev_block_suicide", function( ply)
    return not SEv.Ent:IsInvulnerable(ply)
end)

hook.Add("EntityTakeDamage", "sev_damage_control", function(target, dmgInfo)
    local isReflecting = SEv.Ent:IsReflectingDamage(target)
    local isInvulnerable = SEv.Ent:IsInvulnerable(target)
    local isNormal = not isReflecting and not isInvulnerable

    local callback = SEv.Ent:GetDamageCallback(target)

    if isNormal then
        if callback and isfunction(callback.func) then
            callback.func(target, dmgInfo, unpack(callback.args))
        end

        return
    end

    if isInvulnerable then
        if callback and isfunction(callback.func) then
            callback.func(target, dmgInfo, unpack(callback.args))
        end

        return true
    end

    if isReflecting then
        if callback and isfunction(callback.func) then
            callback.func(target, dmgInfo, unpack(callback.args))
        end

        local attacker = dmgInfo:GetAttacker()

        if attacker == target then -- Break the loop
            SEv.Ent:SetReflectDamage(target, false)
        end

        if attacker:IsValid() then
            attacker:TakeDamageInfo(dmgInfo)
        end

        return true
    end
end)

-- Dissolve

function SEv.Ent:Dissolve(ent, dissolveType)
    if not ent or not IsValid(ent) or not ent:IsValid() then return false end
    if not (ent:IsRagdoll() or ent:IsNPC() or ent:IsVehicle() or ent:IsWeapon() or ent:GetClass() and (
       string.find(ent:GetClass(), "prop_") or string.find(ent:GetClass(), "sev_sent"))) then return false end

    dissolveType = dissolveType or 3

    if SEv.Ent:IsReflectingDamage(ent) then
        SEv.Ent:SetReflectDamage(ent, false)
    end

    if SEv.Ent:IsInvulnerable(ent) then
        SEv.Ent:SetInvulnerable(ent, false)
    end

    local envEntityDissolver = ents.Create("env_entity_dissolver")
    local name = tostring(ent)

    ent:SetKeyValue("targetname", name)
    envEntityDissolver:SetKeyValue("magnitude", "10")
    envEntityDissolver:SetKeyValue("target", name)
    envEntityDissolver:SetKeyValue("dissolvetype", dissolveType)
    envEntityDissolver:Fire("Dissolve")
    envEntityDissolver:Fire("kill", "", 0)

    return true
end

-- Resize
-- Thanks https://steamcommunity.com/workshop/filedetails/?id=217376234
-- In addition to porting the code compactly, I've also added a height
-- compensation so that entities don't enter the ground.
-- Note: duplicator and individual axis support were ignored.

function SEv.Ent:Resize(ent, scale)
    ent:PhysicsInit(SOLID_VPHYSICS)

    local physObj = ent:GetPhysicsObject()

    if not SEv.Util:Type(physObj) == "PhysObj" or not physObj:IsValid() then return end

    local physMesh = physObj:GetMeshConvexes()

    if not istable(physMesh) or #physMesh < 1 then return end

    local mass = physObj:GetMass()
    local minS, maxS = ent:GetCollisionBounds()
    local boundVec = maxS - minS
    local relativeGroundPos1 = math.abs(boundVec.z / 2)

    local PhysicsData = {
        physObj:IsGravityEnabled(),
        physObj:GetMaterial(),
        physObj:IsCollisionEnabled(),
        physObj:IsDragEnabled(),
        physObj:GetVelocity(),
        physObj:GetAngleVelocity(),
        physObj:IsMotionEnabled()
    }

    for convexKey, convex in pairs(physMesh) do
        for posKey, posTab in pairs(convex) do
            convex[posKey] = posTab.pos * scale
        end
    end

    ent:PhysicsInitMultiConvex(physMesh)
    ent:EnableCustomCollisions(true)

    for i = 0, ent:GetBoneCount() do
        ent:ManipulateBoneScale(i, Vector(1, 1, 1) * scale)
    end

    ent:SetCollisionBounds(minS * scale, maxS * scale)

    physObj = ent:GetPhysicsObject()

    if physObj:IsValid() then
        physObj:EnableGravity(PhysicsData[1])
        physObj:SetMaterial(PhysicsData[2])
        physObj:EnableCollisions(PhysicsData[3])
        physObj:EnableDrag(PhysicsData[4])
        physObj:SetVelocity(PhysicsData[5])
        physObj:AddAngleVelocity(PhysicsData[6] - physObj:GetAngleVelocity())
        physObj:EnableMotion(PhysicsData[7])

        physObj:SetMass(math.Clamp(mass * scale * scale * scale, 0.1, 50000))
        physObj:SetDamping(0, 0)
    end

    minS, maxS = ent:GetCollisionBounds()
    boundVec = maxS - minS
    local relativeGroundPos2 = math.abs(boundVec.z / 2)

    ent:SetPos(ent:GetPos() + Vector(0, 0, relativeGroundPos2 - relativeGroundPos1))
end

-- Block Fire (For inputs = Map brushs only!)

function SEv.Ent:IsFireHidden(ent)
    return ent.sev_hidden_fire
end

function SEv.Ent:HideFire(ent, value)
    if SEv.Ent:IsSpawnedByPlayer(ent) then return end

    ent.sev_hidden_fire = value

    if value then
        ent.Fire2 = function (_self, ...)
            _self.sev_using_fire_2 = true
            SEv_ENT_Fire(_self, ...)
        end
    else
        ent.Fire2 = nil
    end
end

ENT.Fire = function(self, input, param, delay, activator, caller)
    if SEv.Ent:IsFireHidden(self) then return end

    -- Note: other addons make a lot of mistakes and the script errors end up coming from
    -- inside my map through no fault of mine, so I decided to validate the arguments.
    if not IsValid(self) then
        print("ERROR!! Ent.Fire was called by a NULL entity!")
    elseif not isstring(input) then
        print("ERROR!! Ent.Fire input must be a string!")
    elseif param ~= nil and not isstring(param) and not isnumber(param) and not isbool(param) then
        print("ERROR!! Ent.Fire param must be a string or number or boolean!")
    elseif delay ~= nil and not isnumber(delay) then
        print("ERROR!! Ent.Fire delay must be a number!")
    elseif activator ~= nil and not IsValid(activator) then
        print("ERROR!! Ent.Fire activator must be nil or a valid entity!")
    elseif caller ~= nil and not IsValid(caller) then
        print("ERROR!! Ent.Fire caller must be nil or a valid entity!")
    else
        SEv_ENT_Fire(self, input, param, delay, activator, caller)
        return
    end

    print(debug.traceback())
end

hook.Add("AcceptInput", "sev_block_external_activations", function(ent, name, activator, caller, data)
    if SEv.Ent:IsFireHidden(ent) then
        if not ent.sev_using_fire_2 then
            return true
        else
            ent.sev_using_fire_2 = false
        end
    end
end)
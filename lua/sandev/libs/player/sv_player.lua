-- Player spawn

function SEv.Ply:CallOnSpawn(ply, isOnce, callback, ...)
    if callback then
        ply.sev_on_ply_spawn_callback = { func = callback, once = isOnce, args = { ... } }
    end
end

function SEv.Ply:GetOnSpawnCallback(ply)
    return ply.sev_on_ply_spawn_callback
end

function SEv.Ply:RemoveOnSpawnCallback(ply)
    ply.sev_on_ply_spawn_callback = nil
end

hook.Add("PlayerSpawn", "sev_ply_spawn_control", function(ply, transition)
    local callbackInfo = SEv.Ply:GetOnSpawnCallback(ply)

    if callbackInfo and isfunction(callbackInfo.func) then
        callbackInfo.func(ply, transition, unpack(callbackInfo.args))

        if callbackInfo.once then
            SEv.Ply:RemoveOnSpawnCallback(ply)
        end
    end
end)

-- Switch noclip mode

function SEv.Ply:BlockNoclip(ply, value)
    ply.sev_noclip = value

    if value and ply:GetMoveType() == MOVETYPE_NOCLIP then
        ply:SetMoveType(MOVETYPE_WALK)
    end
end

function SEv.Ply:IsNoclipBlocked(ply)
    return ply.sev_noclip
end

hook.Add("Move", "sev_player_noclip_control", function(ply, mv)
    -- With this hook I prevent noclip via SetMoveType
    if ply:GetMoveType() == MOVETYPE_NOCLIP and SEv.Ply:IsNoclipBlocked(ply) then
        ply:SetMoveType(MOVETYPE_WALK)
    end
end)

-- Restore players after a map cleanup

hook.Add("PostCleanupMap", "sev_cleanup_players", function()
    for _, ply in ipairs(player.GetHumans()) do
        for k, v in pairs(ply:GetTable()) do
            if isstring(k) and string.find(k, "sev_") then
                ply[k] = nil
            end
        end
    end
end)

-- Check if the player is stuck inside entities or brushs

function SEv.Ply:IsPlayerStuck(ply) -- From "Auto Unstuck" addon, adapted. https://steamcommunity.com/sharedfiles/filedetails/?id=1867484687
    -- Check if the player is blocked using a trace based off player's Bounding Box (Supports all player sizes and models)

    if ply:GetMoveType() == MOVETYPE_NOCLIP then return false end -- Player is not flying through stuff

    local Maxs = Vector(ply:OBBMaxs().X / ply:GetModelScale(), ply:OBBMaxs().Y / ply:GetModelScale(), ply:OBBMaxs().Z / ply:GetModelScale()) 
    local Mins = Vector(ply:OBBMins().X / ply:GetModelScale(), ply:OBBMins().Y / ply:GetModelScale(), ply:OBBMins().Z / ply:GetModelScale())
    local pos = ply:GetPos()

    local tr = util.TraceHull({    
        start = pos,
        endpos = pos,
        maxs = Maxs, -- Exactly the size the player uses to collide with stuff
        mins = Mins, -- ^
        collisiongroup = COLLISION_GROUP_PLAYER, -- Collides with stuff that players collide with
        mask = MASK_PLAYERSOLID, -- Detects things like map clips
        filter = function(ent) -- Slow but necessary
            if ent:IsNPC() or ent.Type == "nextbot" then return true end
            if ent:IsScripted() and ply:BoundingRadius() - ent:BoundingRadius() > 0 then return false end
            
            -- The ent can collide with the player that is stuck
            -- The ent is not the player that is stuck
            if ent:GetCollisionGroup() ~= 20 and ent ~= ply then
                return true
            end
        end
    })

    return tr.Hit and true or false
end

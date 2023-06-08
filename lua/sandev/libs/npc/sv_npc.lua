-- Store that the entity is an npc (helps with duplication later)

local npcStalkers = {}

hook.Add("PlayerSpawnedNPC", "sev_set_is_npc", function(ply, npc)
    if IsValid(npc) then
        npc.sev_is_npc = true
    end
end)

--[[ 
    Stalkers are a bit unique.
    
    When you kill a Stalker, every Stalker that is visible to you and in the same squad of the killed Stalker will go aggresive 
    and attack every other player it sees. Even if we set their enemy to something different, it will just set it back to the
    closest player. We can prevent the attacking of all players by setting their relationship to players to a disposition
    other than hate, and set it back to D_HT by recreating the same behavior said above.

    -- Zaurzo
]]

hook.Add('OnEntityCreated', 'sev_stalker_control', function(ent)
    if ent:GetClass() == 'npc_stalker' and ent:IsNPC() then
        SEv.NPC:RestoreMissingFunc(ent, 'AddRelationship') -- Workshop compatibility

        if ent.AddRelationship then
            table.insert(npcStalkers, ent)

            ent:AddRelationship('player D_NU 99')
        end
    end
end)

hook.Add('OnNPCKilled', 'sev_stalker_control', function(ent, attacker)
    if ent:GetClass() == 'npc_stalker' and attacker:IsValid() and attacker:IsPlayer() then
        local squad = ent:GetSquad()

        for k, stalker in ipairs(npcStalkers) do
            if stalker:IsValid() then 
                if stalker:GetSquad() == squad and stalker:Visible(attacker) then
                    SEv.NPC:RestoreMissingFunc(stalker, 'AddRelationship') -- Workshop compatibility

                    if stalker.AddRelationship then
                        stalker:AddRelationship('player D_HT 99')
                    end
                end
            else
                table.remove(npcStalkers, k)
            end
        end
    end
end)

-- Attack player

function SEv.NPC:AttackPlayer(npc, ply, duration)
    if not IsValid(npc) or not IsValid(ply) or not npc:IsNPC() or not ply:IsPlayer() then return end

    self:RestoreMissingFunc(npc, 'AddEntityRelationship') -- Workshop compatibility
    self:RestoreMissingFunc(npc, 'UpdateEnemyMemory') -- Workshop compatibility

    if npc.AddEntityRelationship and npc.UpdateEnemyMemory and npc.SetEnemy then
        local isNPCStalker = npc:GetClass() == 'npc_stalker'

        if isNPCStalker then
            -- Stalkers will only attack players when this value is set to 1.
            -- https://github.com/lua9520/source-engine-2018-hl2_src/blob/3bf9df6b2785fa6d951086978a3e66f49427166a/game/server/hl2/npc_stalker.cpp#L221

            npc:SetSaveValue('m_iPlayerAggression', 1)
        end
        
        npc:AddEntityRelationship(ply, D_HT, 99)
        npc:SetEnemy(ply)
        npc:UpdateEnemyMemory(ply, ply:GetPos())

        if duration then
            local timerName = 'sev_' .. tostring(npc) .. '_attack_player_' .. tostring(ply)

            -- We use timer.Create to stop timer.Simple stacking
            if timer.Exists(timerName) then
                timer.Adjust(timerName, duration)
            else
                self:RestoreMissingFunc(npc, 'ClearEnemyMemory') -- Workshop compatibility

                timer.Create(timerName, duration, 1, function()
                    if not npc:IsValid() then return end

                    if isNPCStalker then
                        npc:SetSaveValue('m_iPlayerAggression', 0)
                    end

                    if ply:IsValid() then
                        if npc.ClearEnemyMemory then
                            npc:ClearEnemyMemory(ply)
                        end

                        if npc.AddEntityRelationship then
                            npc:AddEntityRelationship(ply, D_HT, 0)
                        end
                    end
                end)
            end
        end
    end
end

function SEv.NPC:AttackClosestPlayer(npc, duration)
    if IsValid(npc) and npc:IsNPC() then
        local ply = SEv.Ply:GetClosestPlayer(npc:GetPos())

        self:AttackPlayer(npc, ply, duration)
    end
end

-- On killed

function SEv.NPC:CallOnKilled(npc, id, callback, ...)
    if callback then
        npc.sev_on_killed_callback = npc.sev_on_killed_callback or {}
        npc.sev_on_killed_callback[id] = { func = callback, args = { ... } }
    end
end

function SEv.NPC:RemoveOnNPCKilledCallback(npc, id)
    if npc.sev_on_killed_callback then
        npc.sev_on_killed_callback[id] = nil
    end
end

function SEv.NPC:GetOnKilledCallbacks(npc)
    return npc.sev_on_killed_callback
end

hook.Add("OnNPCKilled", "sev_npc_killed_callback", function(npc, attacker, inflictor)
    local callbacks = SEv.NPC:GetOnKilledCallbacks(npc)

    if callbacks then
        for id, callback in pairs(callbacks) do
            if isfunction(callback.func) then
                callback.func(unpack(callback.args))
            end
        end
    end
end)

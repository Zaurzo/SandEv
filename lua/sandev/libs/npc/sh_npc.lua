-- Animations

function SEv.NPC:PlaySequences(npc, ...)
    if not npc:IsValid() then return end

    local sequences = { ... }

    local function startSequence(sequence)
        if not npc:IsValid() then return end

        local ang = npc:GetAngles()
        local npcName = npc:GetName()

        if npcName == "" or not npcName then
            npcName = tostring(npc)
            npc:SetName(npcName)
        end

        local scriptS = ents.Create("scripted_sequence")
        scriptS:SetKeyValue("m_iszEntity", npcName)
        scriptS:SetKeyValue("m_iszPlay", sequence)
        scriptS:SetKeyValue("angles", ang.x .. " " .. ang.y .. " " .. ang.z)
        scriptS:SetKeyValue("m_fMoveTo", "0")
        scriptS:SetKeyValue("spawnflags", "32") -- No interruptions
        scriptS:SetKeyValue("m_bDisableNPCCollisions", "0")
        scriptS:SetKeyValue("m_bIgnoreGravity", "0")
        scriptS:SetKeyValue("m_bLoopActionSequence", loop and "1" or "0")
        scriptS:SetKeyValue("m_bSynchPostIdles", "0")
        scriptS:SetKeyValue("m_flRadius", "0")
        scriptS:SetKeyValue("m_flRepeat", "0")
        scriptS:SetKeyValue("maxdxlevel", "0")
        scriptS:SetKeyValue("mindxlevel", "0")
        scriptS:SetKeyValue("mindxlevel", "0")
        scriptS:Fire("BeginSequence")

        local seqID = npc:LookupSequence(sequence)
        local duration = npc:SequenceDuration(seqID)

        timer.Simple(duration, function()
            if scriptS:IsValid() then
                scriptS:Remove()
            end
        end)
    end

    local delay = 0
    for k, sequence in ipairs(sequences) do
        timer.Simple(delay, function()
            startSequence(sequence)
        end)

        local seqID = npc:LookupSequence(sequence)
        local duration = npc:SequenceDuration(seqID)
        delay = delay + duration
    end

    return delay
end

-- Restore removed functions
--   Some addons seem to remove default NPC functions which I need.

local NPC = FindMetaTable("NPC")

function SEv.NPC:RestoreMissingFunc(ent, funcName)
    if ent[funcName] then return end

    local func = NPC[funcName]

    if func then
        ent[funcName] = func
    end    
end

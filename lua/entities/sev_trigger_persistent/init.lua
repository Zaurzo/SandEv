-- Duplicates the entities and contraptions making them persistent in relation to the trigger area

-- I avoided the default sandbox persistence system because it has no support across
-- maps (obviously) and is extremely annoying to manipulate.
--   - Xala

ENT.Base = "base_entity"
ENT.Type = "brush"

local isCleaningMap = false
hook.Add("PreCleanupMap", "sev_protect_persistent_props", function()
    isCleaningMap = true

    timer.Create("sev_protect_persistent_props", 0.2, 1, function()
        isCleaningMap = false
    end)
end)

function ENT:Setup(instance, eventName, entName, vecA, vecB, protectConstruction, isReadOnly, dumpInfoToTxtFile)
    self.instance = instance
    self:Spawn()

    isReadOnly = isReadOnly or false
    dumpInfoToTxtFile = dumpInfoToTxtFile or false

    local vecCenter = (vecA - vecB)/2 + vecB

    self.playersIn = {}

    self:SetVar("eventName", eventName)
    self:SetVar("entName", entName)
    self:SetVar("vecA", vecA)
    self:SetVar("vecB", vecB)
    self:SetVar("vecCenter", vecCenter)
    self:SetVar("color", Color(252, 119, 3, 255)) -- Orange

    self:SetVar("protectConstruction", protectConstruction)
    self:SetVar("isReadOnly", isReadOnly)
    self:SetVar("dumpInfoToTxtFile", dumpInfoToTxtFile)

    self:SetName(entName)
    self:SetPos(vecCenter)

    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBoundsWS(vecA, vecB)
    self:SetTrigger(true)

    SEv.Ent:SetCursed(self, true)

    local persistentFolder = instance.dataFolder .. "/persistent"
    file.CreateDir(persistentFolder)

    self.persistentFile = persistentFolder .. "/" .. entName .. ".dat"
    self.persistentFileDump = persistentFolder .. "/" .. entName .. ".txt"
    self.duplications = self:ReadFile() or {}

    self:SpawnSavedEnts()

    if not self:GetVar("isReadOnly") then
        local canToolHookName = "sev_check_persistence_tool_" .. tostring(self)
        hook.Add("CanTool", canToolHookName, function(ply, tr, toolname)
            if not self:IsValid() then
                hook.Remove("CanTool", canToolHookName)
                return
            end

            if not self.playersIn[ply] then return end

            local ent = tr.Entity
            if ent:IsValid() and (ent.sev_duplicated or ent.sev_constraint) then
                if toolname == "remover" then
                    self:UnsaveEnt(ent)
                else
                    timer.Simple(0.15, function()
                        if not self:IsValid() then return end

                        self:RefreshSavedEnts()
                    end)
                end
            end
        end)

        local physgunFreezeHookName = "sev_check_persistence_tool_" .. tostring(self)
        hook.Add("OnPhysgunFreeze", physgunFreezeHookName, function(weapon, phys, ent, ply)
            if not self:IsValid() then
                hook.Remove("OnPhysgunFreeze", physgunFreezeHookName)
                return
            end

            if not self.playersIn[ply] then return end

            if ent:IsValid() and ent.sev_duplicated then
                self:SaveEnt(ent)
            end
        end)
    end

    instance.Event:SetRenderInfoEntity(self)
end

function ENT:ModifyEntAndConstrainedEnts(ent)
    if not ent.sev_constraint then
        ent.sev_duplicated = true
    end

    local constrainedEntities = constraint.GetAllConstrainedEntities(ent) or {}
    for _, constrainedEnt in pairs(constrainedEntities) do
        if not constrainedEnt.sev_duplicated then
            constrainedEnt.sev_constraint = true
        end
    end
end

function ENT:ReadFile(ent)
    local compressedDupJson = file.Read(self.persistentFile, "Data")

    if compressedDupJson then
        local dupJson = util.Decompress(compressedDupJson)
        local dupTab = util.JSONToTable(dupJson or "{}")
        return dupTab
    else
        return {}
    end
end

function ENT:SaveFile()
    timer.Create("sev_set_persistence_" .. tostring(self), 1, 1, function() -- This timer cause the list to be saved only when entities are stationary
        if not self:IsValid() then return end

        local dupJson = util.TableToJSON(self.duplications)
        local conpressedDupJson = util.Compress(dupJson)
        file.Write(self.persistentFile, conpressedDupJson)

        if self:GetVar("dumpInfoToTxtFile") then
            file.Write(self.persistentFileDump, dupJson)
        end
    end)
end

function ENT:SaveEnt(ent)
    if not IsValid(ent) or not ent:IsValid() or not ent.sev_duplicated then return end
    if self:GetVar("isReadOnly") then return end

    self.duplications[tostring(ent)] = duplicator.Copy(ent)
    self:SaveFile()
end

function ENT:UnsaveEnt(ent) -- lol
    if not ent.sev_duplicated and not ent.sev_constraint then return end
    if self:GetVar("isReadOnly") then return end

    local oldLeadingCEnt = ent.sev_duplicated and ent

    local constrainedEntities = constraint.GetAllConstrainedEntities(ent) or {}
    if next(constrainedEntities) then
        for _, constrainedEnt in pairs(constrainedEntities) do
            if not oldLeadingCEnt and constrainedEnt.sev_duplicated then
                oldLeadingCEnt = constrainedEnt
            end

            constrainedEnt.sev_duplicated = nil
            constrainedEnt.sev_constraint = nil
        end
        
        timer.Simple(0.15, function() -- Wait so the game can delete entities
            if not self:IsValid() then return end

            for _, constrainedEnt in pairs(constrainedEntities) do
                if constrainedEnt ~= oldLeadingCEnt then
                    self:StartTouch(constrainedEnt)
                end
            end
        end)
    end

    if oldLeadingCEnt then
        oldLeadingCEnt.sev_duplicated = nil
        oldLeadingCEnt.sev_constraint = nil

        if oldLeadingCEnt.sev_on_angle_change_id then
            oldLeadingCEnt:RemoveCallback("OnAngleChange", oldLeadingCEnt.sev_on_angle_change_id)
        end

        oldLeadingCEnt:RemoveCallOnRemove("sev_remove_persistence")

        self.duplications[tostring(oldLeadingCEnt)] = nil
    end

    self:SaveFile()
end

function ENT:SpawnSavedEnts()
    local ply = player.GetHumans()[1]

    local duplications = table.Copy(self.duplications)
    self.duplications = {}

    local unfrozenEntsPhys = {}
    local NPCs = {}

    local delay = 0
    local delayIncrement = 0.075
    for entStr, entDuplication in pairs(duplications) do
        local isNPC = false

        for _, entInfo in pairs(entDuplication.Entities) do
            if entInfo.sev_is_npc then
                table.insert(NPCs, entInfo)
                isNPC = true
            end
            break    
        end

        if isNPC then continue end

        timer.Simple(delay, function()
            if not self:IsValid() then return end

            local createdEnts = duplicator.Paste(ply, entDuplication.Entities, entDuplication.Constraints)

            for _, createdEnt in pairs(createdEnts) do
                SEv.Ent:SetSpawnedByPlayer(createdEnt, true)
                local physObj = createdEnt:GetPhysicsObject()

                if physObj:IsValid() and physObj:IsMotionEnabled() then
                    physObj:EnableMotion(false)
                    table.insert(unfrozenEntsPhys, physObj)
                end

                if self:GetVar("protectConstruction") then
                    local model = createdEnt:GetModel()

                    if string.find(model, "models/props_phx") or 
                       string.find(model, "models/phxtended") or
                       string.find(model, "models/squad") or
                       string.find(model, "models/mechanics") or
                       string.find(model, "models/hunter") or
                       string.find(model, "models/squad") 
                        then

                        SEv.Ent:BlockPhysgun(createdEnt, true)
                        SEv.Ent:BlockToolgun(createdEnt, true)
                        SEv.Ent:BlockContextMenu(createdEnt, true)
                    end
                end
            end
        end)

        delay = delay + delayIncrement
    end

    timer.Simple(delay, function()
        if not self:IsValid() then return end

        delay = 0

        for k, entInfo in ipairs(NPCs) do
            timer.Simple(delay, function()
                local createdNPCs = duplicator.Paste(ply, { entInfo }, {})

                for _, createdNPC in ipairs(createdNPCs) do
                    SEv.Ent:SetSpawnedByPlayer(createdNPC, true)
                end
            end)

            delay = delay + delayIncrement
        end
    end)

    local afterFinishedSpawning = table.Count(duplications) * delayIncrement
    timer.Simple(afterFinishedSpawning, function()
        if not self:IsValid() then return end

        for _, physObj in ipairs(unfrozenEntsPhys) do
            if physObj:IsValid() then
                physObj:EnableMotion(true)
            end
        end

        hook.Run("sev_trigger_persistent_" .. self:GetName() .. "_finished", self)
    end)
end

function ENT:RefreshSavedEnts()
    self.duplications = {}

    local foundEnts = ents.FindInBox(self:GetVar("vecA"), self:GetVar("vecB"))

    for k, ent in ipairs(foundEnts) do
        if IsEntity(ent) then
            ent.sev_duplicated = nil
            ent.sev_constraint = nil
        end
    end

    for k, ent in ipairs(foundEnts) do
        if IsEntity(ent) then
            self:StartTouch(ent)
        end
    end

    self:SaveFile()
end

function ENT:StartTouch(ent)
    if not self.playersIn then return end -- Avoid interactions before the full init

    if ent:IsPlayer() then
        self.playersIn[ent] = true
    end

    self.instance.Event:SetGameEntity(self:GetVar("eventName"), ent)

    if not SEv.Ent:IsSpawnedByPlayer(ent) or ent:IsNextBot() then return end
    if ent.sev_duplicated or ent.sev_constraint then return end

    self:ModifyEntAndConstrainedEnts(ent)

    if not self:GetVar("isReadOnly") then
        self:SaveEnt(ent)
    end

    if self:GetVar("isReadOnly") or ent.sev_constraint then return end

    ent:CallOnRemove("sev_remove_persistence", function()
        if self:IsValid() and not isCleaningMap then
            self:UnsaveEnt(ent)
        end
    end)

    if ent.sev_on_angle_change_id then
        ent:RemoveCallback("OnAngleChange", ent.sev_on_angle_change_id)
    end

    ent.sev_on_angle_change_id = ent:AddCallback("OnAngleChange", function()
        if self:IsValid() and not isCleaningMap then
            self:SaveEnt(ent)
        end
    end)
end

function ENT:EndTouch(ent)
    if not self.playersIn then return end -- Avoid interactions before the full init

    if ent:IsPlayer() then
        self.playersIn[ent] = false
    end

    if self:GetVar("isReadOnly") then return end

    self:UnsaveEnt(ent)
    self.instance.Event:RemoveGameEntity(self:GetVar("eventName"), ent)
end

-- If for some reason entities spawn repeated (perfectly overlaping), use this to remove the extra ones
--[[
local posss = {}

for k,v in ipairs(ents.GetAll()) do
    local pos = v:GetPos()

    local checkPos = tostring(math.Round(pos.x, 2)) .. tostring(math.Round(pos.y, 2)) .. tostring (math.Round(pos.z, 2))

    if v.sev_duplicated or v.sev_constraint then
        if posss[checkPos] then
            print("rem", v)
            v:Remove()
        else
            posss[checkPos] = true
        end
    end
end
--]]
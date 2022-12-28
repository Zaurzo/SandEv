-- Make props visible only when the player is inside the area

ENT.Base = "base_entity"
ENT.Type = "brush"

function ENT:Setup(base, eventName, entName, vecA, vecB, keyName)
    self:Spawn()

    local vecCenter = (vecA - vecB)/2 + vecB

    self:SetVar("eventName", eventName)
    self:SetVar("entName", entName)
    self:SetVar("vecA", vecA)
    self:SetVar("vecB", vecB)
    self:SetVar("vecCenter", vecCenter)
    self:SetVar("color", Color(252, 119, 3, 255)) -- Orange
    self:SetVar("keyName", keyName)

    self:SetName(entName)
    self:SetPos(vecCenter)

    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBoundsWS(vecA, vecB)
    self:SetTrigger(true)

    SEv.Ent:SetCursed(self, true)

    self.isEnabled = false
    self.ents = {}

    local playerInitialSpawnHookName = "sev_init_nodraw_" .. tostring(self)
    hook.Add("PlayerInitialSpawn", playerInitialSpawnHookName, function(ply, transition)
        timer.Simple(1, function()
            if not self:IsValid() then
                hook.Remove("PlayerInitialSpawn", playerInitialSpawnHookName)
                return
            end

            if not ply:IsValid() or ply.sev_nodraw_keyname == self:GetVar("keyName") then return end

            self:DisableVisibility(ply)
        end)
    end)

    base.Event:SetRenderInfoEntity(self)
end

function ENT:AddEnt(ent)
    self.ents[ent] = true

    if not self.isEnabled then
        for k, ply in ipairs(player.GetHumans()) do
            ent:SetPreventTransmit(ply, true)

            SEv.Ent:BlockPhysgun(ent, true, ply)
            SEv.Ent:BlockToolgun(ent, true, ply)
            SEv.Ent:BlockContextMenu(ent, true, ply)
        end
    end
end

function ENT:RemoveEnt(ent)
    self.ents[ent] = nil

    for k, ply in ipairs(player.GetHumans()) do
        ent:SetPreventTransmit(ply, false)

        SEv.Ent:BlockPhysgun(ent, false, ply)
        SEv.Ent:BlockToolgun(ent, false, ply)
        SEv.Ent:BlockContextMenu(ent, false, ply)    
    end
end

function ENT:EnableVisibility(ply)
    for k, triggerNodraw in ipairs(ents.FindByClass("sev_trigger_nodraw")) do
        if triggerNodraw:GetVar("keyName") == self:GetVar("keyName") then
            triggerNodraw.isEnabled = true

            for ent, _ in pairs(triggerNodraw.ents) do
                if ent:IsValid() then
                    ent:SetPreventTransmit(ply, false)

                    SEv.Ent:BlockPhysgun(ent, false, ply)
                    SEv.Ent:BlockToolgun(ent, false, ply)
                    SEv.Ent:BlockContextMenu(ent, false, ply)
                end
            end
        end
    end
end

function ENT:DisableVisibility(ply)
    for k, triggerNodraw in ipairs(ents.FindByClass("sev_trigger_nodraw")) do
        if triggerNodraw:GetVar("keyName") == self:GetVar("keyName") then
            triggerNodraw.isEnabled = false

            for ent, _ in pairs(triggerNodraw.ents) do
                if ent:IsValid() then
                    ent:SetPreventTransmit(ply, true)

                    SEv.Ent:BlockPhysgun(ent, true, ply)
                    SEv.Ent:BlockToolgun(ent, true, ply)
                    SEv.Ent:BlockContextMenu(ent, true, ply)
                end
            end
        end
    end
end

function ENT:StartTouch(ent)
    timer.Simple(0.1, function()
        if not self:IsValid() then return end

        if SEv.Ent:IsSpawnedByPlayer(ent) then
            self:AddEnt(ent)
        elseif ent:IsPlayer() then
            self:EnableVisibility(ent)
        end
    end)
end

function ENT:EndTouch(ent)
    if SEv.Ent:IsSpawnedByPlayer(ent) then
        ent.sev_nodraw_keyname = nil

        timer.Simple(0.1, function()
            if ent:IsValid() and self:IsValid() and not ent.sev_nodraw_keyname then
                self:RemoveEnt(ent)
            end
        end)
    elseif ent:IsPlayer() then
        ent.sev_nodraw_keyname = nil

        timer.Simple(0.1, function()
            if ent:IsValid() and self:IsValid() and not ent.sev_nodraw_keyname then
                self:DisableVisibility(ent)
            end
        end)
    end
end

function ENT:Touch(ent)
    if SEv.Ent:IsSpawnedByPlayer(ent) or ent:IsPlayer() then
        if not ent.sev_nodraw_keyname then
            ent.sev_nodraw_keyname = self:GetVar("keyName")
        end
    end
end
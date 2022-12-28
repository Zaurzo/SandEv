-- A confined space from which the player cannot enter or exit by their own means

ENT.Base = "base_entity"
ENT.Type = "brush"

local plyPos = {} -- { [number SteamID] = Vector last valid pos inside the space }

--[[
    The confinement is accepted when the key is present and true in the player's objetc, while the exit
    must be made by setting the same key to false.

    e.g
    
    ply["my_key"] = true

        The player will be stuck in the area when entering it.

    ply["my_key"] = false

        The player will be able to leave the area and will be completely disconnected from it.

]]
function ENT:Setup(base, eventName, entName, vecA, vecB, keyName)
    self:Spawn()

    self:SetVar("eventName", eventName)
    self:SetVar("entName", entName)
    self:SetVar("vecA", vecA)
    self:SetVar("vecB", vecB)
    self:SetVar("vecCenter", (vecA - vecB)/2 + vecB)
    self:SetVar("color", Color(252, 119, 3, 255)) -- Orange
    self:SetVar("keyName", keyName)

    self:SetName(entName)

    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBoundsWS(vecA, vecB)
    self:SetTrigger(true)

    SEv.Ent:SetCursed(self, true)

    base.Event:SetRenderInfoEntity(self)
end

local function SetAntiFugitives(confinement, ply)
    local timerName = "sev_confinement_fugitives_" .. tostring(ply)
    timer.Create(timerName, 1, 0, function()
        if not confinement:IsValid() or not ply:IsValid() or ply[confinement:GetVar("keyName")] == nil then
            timer.Remove(timerName)
            return
        end

        if ply[confinement:GetVar("keyName")] == 0 then
            local SteamID = ply:SteamID()
            ply:SetPos(plyPos[SteamID])
        end
    end)
end

function ENT:StartTouch(ent)
    if not ent:IsPlayer() then return end
    if ent[self:GetVar("keyName")] == nil then return end

    if not isnumber(ent[self:GetVar("keyName")]) then
        ent[self:GetVar("keyName")] = 0
        SetAntiFugitives(self, ent)
    end

    ent[self:GetVar("keyName")] = ent[self:GetVar("keyName")] + 1

    if ent[self:GetVar("keyName")] == 1 then
        SEv.Ply:CallOnSpawn(ent, true, function(ply)
            if not self:IsValid() then return end
            if not ply[self:GetVar("keyName")] then return end

            local SteamID = ply:SteamID()

            if plyPos[SteamID] then
                ply:SetPos(plyPos[SteamID])
            end
        end)
    end
end

function ENT:EndTouch(ent)
    if not ent:IsPlayer() then return end
    if ent[self:GetVar("keyName")] == nil then return end

    local SteamID = ent:SteamID()

    if plyPos[SteamID] and ent[self:GetVar("keyName")] == 1 then
        if ent[self:GetVar("keyName")] ~= nil then
            local centerDist = self:GetVar("vecCenter") - ent:GetPos()
            local vecGoBack = centerDist:GetNormalized() * 40
            ent:SetVelocity(ent:GetVelocity():GetNegated())
            ent:SetPos(plyPos[SteamID] + vecGoBack)
        end
    end

    if isnumber(ent[self:GetVar("keyName")]) then
        ent[self:GetVar("keyName")] = ent[self:GetVar("keyName")] - 1
    elseif ent[self:GetVar("keyName")] == false then
        plyPos[SteamID] = nil
        ent[self:GetVar("keyName")] = nil
    end
end

function ENT:Touch(ent)
    if not ent:IsPlayer() then return end

    local SteamID = ent:SteamID() 

    if ent[self:GetVar("keyName")] ~= nil then
        plyPos[SteamID] = ent:GetPos()
    else
        local zBase = math.abs(self:GetVar("vecCenter").z - self:GetVar("vecB").z)
        local centerDist = self:GetVar("vecCenter") - Vector(0, 0, zBase) - ent:GetPos()
        ent:SetPos(ent:GetPos() - centerDist:GetNormalized() * 30)
    end
end

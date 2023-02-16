-- Func to create sprites

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Setup(instance, eventName, entName, vecCenter, width, height, angles, materialName, clientKey, flashlightOnlyMode)
    self:Spawn()

    local relVecA = Vector(height / 2, 0, width / 2)
    relVecA:Rotate(angles)

    local vecA = vecCenter + relVecA
    local vecB = vecCenter - relVecA

    self:SetVar("eventName", eventName)
    self:SetVar("entName", entName)
    self:SetVar("vecA", vecA)
    self:SetVar("vecB", vecB)

    self:SetVar("vecCenter", vecCenter)
    self:SetVar("color", Color(252, 244, 5, 255)) -- Yellow

    self:SetName(entName)
    self:SetPos(vecCenter)
    self:SetAngles(angles)
    self:SetModel("models/squad/sf_plates/sf_plate1x1.mdl")
    self:SetModelScale(0.001)
    self:DrawShadow(false)

    SEv.Ent:BlockPhysgun(self, true)
    SEv.Ent:BlockContextMenu(self, true)

    self:SetNWVector("vecA", vecA)
    self:SetNWVector("vecB", vecB)
    self:SetNWInt("width", width)
    self:SetNWInt("height", height)
    self:SetNWString("materialName", materialName)
    self:SetNWString("entName", entName)

    -- Variable that the LocalPlayer() object needs for the sprite to be rendered on the client
    self:SetNWString("clientKey", clientKey or "")

    -- The sprite will only be visible by flashlight light
    self:SetNWBool("flashlightOnlyMode", flashlightOnlyMode and true or false) 

    SEv.Map:SetProtectedEntity(self)

    instance.Event:SetRenderInfoEntity(self)
end
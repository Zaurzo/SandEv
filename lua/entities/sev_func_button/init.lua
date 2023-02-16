-- Func to create buttons

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Setup(instance, eventName, entName, vecA, vecB, hasPhysics, useType, modelName, callback, ...)
    self.instance = instance
    self:Spawn()

    local vecDiff = (vecA - vecB)/2
    local vecCenter = vecDiff + vecB

    self:SetVar("eventName", eventName)
    self:SetVar("entName", entName)
    self:SetVar("vecA", vecA)
    self:SetVar("vecB", vecB)
    self:SetVar("vecCenter", vecCenter)
    self:SetVar("color", Color(153, 50, 168, 255)) -- Purple

    self:SetName(entName)
    self:SetPos(vecCenter)
    self:SetModel(modelName)
    self:SetUseType(useType)

    if hasPhysics then
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)

        local phys = self:GetPhysicsObject()

        if phys:IsValid() then
            phys:Wake()
        end
    else
        SEv.Ent:BlockPhysgun(self, true)
    end

    self:SetVar("vecDiff", vecDiff)
    self:SetVar("callback", callback)
    self:SetVar("args", { ... })

    SEv.Ent:SetCursed(self, true)

    instance.Event:SetRenderInfoEntity(self)
end

function ENT:PhysicsCollide(data, phys)
    self:SetVar("vecCenter", self:GetPos())
    self:SetVar("vecA", self:GetPos() + self:GetVar("vecDiff"))
    self:SetVar("vecB", self:GetPos() - self:GetVar("vecDiff"))

    self.instance.Event:SetRenderInfoEntity(self)
end

function ENT:Use(activator)
    local callback = self:GetVar("callback")

    if callback then
        callback(self, activator, unpack(self:GetVar("args") or {}))
    end
end
-- Marker for existing entities that have been modified in some way

ENT.Base = "base_entity"
ENT.Type = "brush"

function ENT:Setup(base, eventName, entName, vecA, vecB)
    self:Spawn()

    self:SetVar("eventName", eventName)
    self:SetVar("entName", entName)
    self:SetVar("vecA", vecA)
    self:SetVar("vecB", vecB)
    self:SetVar("vecCenter", (vecA - vecB)/2 + vecB)
    self:SetVar("color", Color(18, 245, 10, 255)) -- Green

    self:SetSolidFlags(FSOLID_NOT_SOLID)
    self:SetName(entName)

    base.Event:SetRenderInfoEntity(self)
end
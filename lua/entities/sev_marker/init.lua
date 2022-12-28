-- Generic marker to indicate any position or area

ENT.Base = "base_entity"
ENT.Type = "brush"

function ENT:Setup(base, eventName, entName, vecA, vecB)
    self:Spawn()

    local vecA = vecB and vecA or (vecA + Vector(5, 5, 5))
    local vecB = vecB or (vecA - Vector(10, 10, 10))
    local vecCenter = (vecA - vecB)/2 + vecB

    self:SetVar("eventName", eventName)
    self:SetVar("entName", entName)
    self:SetVar("vecA", vecA)
    self:SetVar("vecB", vecB)
    self:SetVar("vecCenter", vecCenter)
    self:SetVar("color", Color(235, 64, 52, 255)) -- Red

    self:SetSolidFlags(FSOLID_NOT_SOLID)
    self:SetName(entName)
    self:SetPos(vecCenter)

    base.Event:SetRenderInfoEntity(self)
end
-- General purpose trigger

ENT.Base = "base_entity"
ENT.Type = "brush"

function ENT:Setup(instance, eventName, entName, vecA, vecB)
    self:Spawn()

    local vecCenter = (vecA - vecB)/2 + vecB

    self:SetVar("eventName", eventName)
    self:SetVar("entName", entName)
    self:SetVar("vecA", vecA)
    self:SetVar("vecB", vecB)
    self:SetVar("vecCenter", vecCenter)
    self:SetVar("color", Color(252, 119, 3, 255)) -- Orange

    self:SetName(entName)
    self:SetPos(vecCenter)

    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBoundsWS(vecA, vecB)
    self:SetTrigger(true)

    SEv.Ent:SetCursed(self, true)

    instance.Event:SetRenderInfoEntity(self)
end

-- Marker to place props

ENT.Base = "base_entity"
ENT.Type = "brush"

function ENT:Setup(instance, eventName, entName, vec)
    self:Spawn()

    self:SetVar("eventName", eventName)
    self:SetVar("entName", entName)
    self:SetVar("vecA", vec - Vector(15, 15, 0))
    self:SetVar("vecB", vec + Vector(15, 15, 40))
    self:SetVar("vecCenter", vec)
    self:SetVar("color", Color(45, 219, 250, 255)) -- Blue

    self:SetSolidFlags(FSOLID_NOT_SOLID)
    self:SetName(entName)
    self:SetPos(vec)

    instance.Event:SetRenderInfoEntity(self)
end
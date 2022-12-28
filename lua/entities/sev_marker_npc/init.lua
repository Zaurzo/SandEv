-- Marker to place NPCs

ENT.Base = "base_entity"
ENT.Type = "brush"

function ENT:Setup(base, eventName, entName, vec)
    self:Spawn()

    self:SetVar("eventName", eventName)
    self:SetVar("entName", entName)
    self:SetVar("vecA", vec - Vector(15, 15, 0))
    self:SetVar("vecB", vec + Vector(15, 15, 40))
    self:SetVar("vecCenter", vec)
    self:SetVar("color", Color(255, 0, 0, 255)) -- Red

    self:SetSolidFlags(FSOLID_NOT_SOLID)
    self:SetName(entName)
    self:SetPos(vec)

    base.Event:SetRenderInfoEntity(self)
end

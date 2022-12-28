-- A path point with triggering enabled

ENT.Base = "base_entity"
ENT.Type = "brush"

function ENT:Setup(base, eventName, entName, vec, vecConnection)
    self:Spawn()

    local vecA = vec + Vector(10, 10, 20)
    local vecB = vec - Vector(10, 10, 0)

    self:SetVar("eventName", eventName)
    self:SetVar("entName", entName)
    self:SetVar("vecA", vecA)
    self:SetVar("vecB", vecB)
    self:SetVar("vecCenter", vec + Vector(0, 0, 5))
    self:SetVar("color", Color(255, 255, 255, 255)) -- White
    self:SetVar("vecConnection", vecConnection)

    self:SetName(entName)
    self:SetPos(vec)

    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBoundsWS(vecA, vecB)
    self:SetTrigger(true)

    base.Event:SetRenderInfoEntity(self)
end
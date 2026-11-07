AddCSLuaFile()

ENT.Base = 'sev_brush'
ENT.ToolName = 'invisible'
ENT.Color = SandEv.Colors.Pink

function ENT:Initialize()
    self.BaseClass.Initialize(self)

    self:SetNotSolid(false)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(self:GetMins(), self:GetMaxs())
end

function ENT:CanTool()
    return false
end
-- General purpose trigger

AddCSLuaFile()

ENT.Base = 'sev_brush'
ENT.ToolName = 'trigger'
ENT.Color = SandEv.Colors.Orange

DEFINE_BASECLASS('sev_brush')

if SERVER then
    function ENT:Setup(event, min, max)
        BaseClass.Setup(self, event, min, max)

        self:SetTrigger(true)
        self:SetSolid(SOLID_BBOX)
        self:SetCollisionBounds(self:GetMins(), self:GetMaxs())
    end
end
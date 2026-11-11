-- General purpose trigger

DEFINE_BASECLASS('sev_brush')

ENT.Base = 'sev_brush'
ENT.ToolName = 'trigger'
ENT.Color = SandEv.Colors.Orange

function ENT:SetupDataTables()
    BaseClass.SetupDataTables(self)
    
    self:NetworkVar('Bool', 'Spherical')
    self:NetworkVar('Float', 'Radius')
end
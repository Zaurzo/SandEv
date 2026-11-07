ENT.Base = 'sev_marker'
ENT.ToolName = 'path'

if CLIENT then
    DEFINE_BASECLASS('sev_marker')

    function ENT:Initialize()
        BaseClass.Initialize(self)

        local vecInf = Vector(1, 1, 1) * math.huge

        self:SetRenderBounds(-vecInf, vecInf) -- always render
    end
end
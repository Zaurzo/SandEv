include('shared.lua')

DEFINE_BASECLASS('sev_brush')

local MAX_DISTANCE = 1000

function ENT:DrawSphere(pos, radius, color)
    local a = color.a
    local lo, la = 15, 15

    color.a = SandEv:GetGizmoAlpha() * 255

    render.SetColorMaterial()
    render.DrawSphere(pos, radius, lo, la, color)

    color.a = a

    render.DrawWireframeSphere(pos, radius, lo, la, color, true)
end

function ENT:DrawGizmos()
    if not self:GetSpherical() then
        return BaseClass.DrawGizmos(self)
    end

    local pos = self:GetPos()
    local color = self:GetColor()

    self:DrawSphere(pos, self:GetRadius(), color)

    local distance = EyePos():Distance(pos)
    if distance > MAX_DISTANCE then return end

    cam.Start2D()
        self:DrawLabels(pos, distance, color, self:GetBrushName())
    cam.End2D()
end
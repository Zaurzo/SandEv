include('cl_tiled_box.lua')
include('shared.lua')

local MAX_DISTANCE = 1000
local wireframe = Material('models/wireframe')

surface.CreateFont('SEvBrushName', {
    font = 'TargetID',
    size = 24,
    weight = 1000,
    blursize = 0,
    scanlines = 0,
    antialias = true,
    shadow = true,
})

surface.CreateFont('SEvEventName', {
    font = 'TargetID',
    size = 20,
    weight = 1000,
    blursize = 0,
    scanlines = 0,
    antialias = true,
    shadow = true,
})

function ENT:DrawLabels(pos, distance, color, brushName)
    local up = Vector(0, 0, 1 * distance / 1000)
    local eventNamePos = (pos + up):ToScreen()

    draw.DrawText(
        self:GetEventName(), 
        'SEvEventName',
        eventNamePos.x,
        eventNamePos.y,
        color,
        TEXT_ALIGN_CENTER
    )

    if not brushName or brushName == '' then return end

    local brushNamePos = pos:ToScreen()

    draw.DrawText(
        brushName, 
        'SEvBrushName',
        brushNamePos.x,
        brushNamePos.y - 25,
        color,
        TEXT_ALIGN_CENTER
    )
end

function ENT:DrawWireframeBox(pos, min, max, color)
    render.SetMaterial(wireframe)
    render.DrawWireframeBox(
        pos, 
        self:GetAngles(), 
        min, 
        max, 
        color, 
        true
    )
end

function ENT:DrawGizmos()
    local pos = self:GetPos()
    local color = self:GetColor()
    local mins, maxs = self:GetMins(), self:GetMaxs()

    self:DrawBoxMesh(pos, mins, maxs, color)
    self:DrawWireframeBox(pos, mins, maxs, color)

    local distance = EyePos():Distance(pos)
    if distance > MAX_DISTANCE then return end

    cam.Start2D()
        self:DrawLabels(pos, distance, color, self:GetBrushName())
    cam.End2D()
end

function ENT:DrawTranslucent()
    if self.Instance.Event:GetDrawGizmos() then
        self:DrawGizmos()
    end
end

hook.Add('HUDPaint', 's', function()
end)
-- General purpose brush base

---@class sev_brush
---@field Instance SandEv.Instance The instance this brush belongs to.
---@field Event SandEv.Event The event instance this brush belongs to.

ENT.Base = 'base_anim'
ENT.Type = 'anim' -- anim type instead of brush so that ENT:Draw is called
ENT.ToolName = 'brush' -- developer mode name
ENT.PhysgunDisabled = true
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
ENT.Color = Color(255, 255, 255)

function ENT:Initialize()
    self:DrawShadow(false)
    self:SetNotSolid(true)
    self:SetMoveType(MOVETYPE_NONE)

    if CLIENT then
        self:SetRenderBounds(self:GetMins(), self:GetMaxs())
    end

    local instance = SandEv:GetInstance(self:GetInstanceID())

    self.Instance = instance
    self.Event = instance.Event:GetCurrent(self:GetEventName())
end

function ENT:SetupDataTables()
    self:NetworkVar('Vector', 'Mins')
    self:NetworkVar('Vector', 'Maxs')
    self:NetworkVar('String', 'InstanceID')
    self:NetworkVar('String', 'EventName')
    self:NetworkVar('String', 'BrushName')
end
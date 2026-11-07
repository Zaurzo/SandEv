AddCSLuaFile('cl_init.lua')
AddCSLuaFile('cl_tiled_box.lua')
AddCSLuaFile('shared.lua')

include('shared.lua')

---@param event SandEv.Event
---@param min Vector
---@param max Vector
function ENT:Setup(event, min, max)
    self:SetInstanceID(event.Instance.ID)
    self:SetEvent(event)

    local center = (min - max) / 2 + max
    local lMin = WorldToLocal(min, Angle(), center, Angle())
    local lMax = WorldToLocal(max, Angle(), center, Angle())

    self:SetMins(lMin)
    self:SetMaxs(lMax)
    self:SetPos(center)
    self:SetColor(self.Color)
    self:Spawn()
end

---@param event SandEv.Event
function ENT:SetEvent(event)
    self:SetEventName(event.Category .. '_' .. event.ID)
end
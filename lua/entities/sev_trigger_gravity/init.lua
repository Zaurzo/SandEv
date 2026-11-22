AddCSLuaFile('shared.lua')

include('shared.lua')

function ENT:Initialize()
    self.BaseClass.Initialize(self)

    self._in_brush = {}
end

---@param value number
function ENT:SetBrushGravity(value)
    self._gravity = value

    local inBrush = self._in_brush
    if not inBrush then return end

    for ent in pairs(inBrush) do
        if ent:IsValid() then
            ent:SetGravity(value)
        end
    end
end

---@return number gravity
function ENT:GetBrushGravity()
    return self._gravity or 0
end

function ENT:OnEnter(ent)
    self._in_brush[ent] = ent:GetGravity()

    ent:SetGravity(self:GetBrushGravity())
end

local function RestoreGravity(trigger, ent, storedGravity)
    if not math.IsNearlyEqual(storedGravity, trigger:GetBrushGravity()) then
        ent:SetGravity(storedGravity)
    end
end

function ENT:OnExit(ent)
    local storedGravity = self._in_brush[ent]
    if not storedGravity then return end

    RestoreGravity(self, ent, storedGravity)

    self._in_brush[ent] = nil
end

function ENT:OnRemove()
    for ent, storedGravity in pairs(self._in_brush) do
        if ent:IsValid() then
            RestoreGravity(self, ent, storedGravity)
        end
    end
end
AddCSLuaFile('shared.lua')

include('shared.lua')

function ENT:Initialize()
    self.BaseClass.Initialize(self)

    self:SetBrushGravity(0)

    self._in_brush = {}
end

---@param value number
function ENT:SetBrushGravity(value)
    for ent in pairs(self._in_brush) do
        if ent:IsValid() then
            ent:SetGravity(value)
        end
    end

    self._gravity = value
end

---@return number gravity
function ENT:GetBrushGravity()
    return self._gravity
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
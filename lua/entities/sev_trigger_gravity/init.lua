AddCSLuaFile('shared.lua')

include('shared.lua')

AccessorFunc(ENT, '_gravity', 'BrushGravity', FORCE_NUMBER)

function ENT:Initialize()
    self.BaseClass.Initialize(self)

    self:SetBrushGravity(0)

    self._in_brush = {}
end

function ENT:StartTouch(ent)
    self._in_brush[ent] = ent:GetGravity()

    ent:SetGravity(self:GetBrushGravity())
end

local function RestoreGravity(trigger, ent, storedGravity)
    if not math.IsNearlyEqual(storedGravity, trigger:GetBrushGravity()) then
        ent:SetGravity(storedGravity)
    end
end

function ENT:EndTouch(ent)
    local storedGravity = self._in_brush[ent]

    if storedGravity then
        RestoreGravity(self, ent, storedGravity)
    end
end

function ENT:OnRemove()
    for ent, storedGravity in pairs(self._in_brush) do
        if ent:IsValid() then
            RestoreGravity(self, ent, storedGravity)
        end
    end
end
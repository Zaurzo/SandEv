AddCSLuaFile('shared.lua')

include('shared.lua')

AccessorFunc(ENT, '_damage', 'Damage', FORCE_NUMBER) 
AccessorFunc(ENT, '_dmg_type', 'DamageType', FORCE_NUMBER) 
AccessorFunc(ENT, '_one_shot', 'OneShot', FORCE_BOOL) 

function ENT:Initialize()
    self.BaseClass.Initialize(self)

    self:SetDamage(0)
    self:SetDamageType(0)
    self:SetOneShot(true)
end

local function Hurt(trigger, ent)
    local dmgInfo = DamageInfo()

    dmgInfo:SetDamage(trigger:GetDamage())
    dmgInfo:SetDamageType(trigger:GetDamageType())
    dmgInfo:SetAttacker(trigger)
    dmgInfo:SetInflictor(trigger)

    ent:TakeDamageInfo(dmgInfo)
end

function ENT:StartTouch(ent)
    if self:GetOneShot() then
        Hurt(self, ent)
    end
end

function ENT:Touch(ent)
    if not self:GetOneShot() then
        Hurt(self, ent)
    end
end
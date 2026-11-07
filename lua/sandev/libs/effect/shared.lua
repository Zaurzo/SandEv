---@class SandEv.EffectLib : SandEv.Library
local EffectLib = SandEv.Base:Library()
SandEv.Base.Effect = EffectLib

---Creates electrical sparks at specified position.
---@param pos Vector The position to create the sparks at.
---@param amount? integer The amount of sparks to create.
---@param scale? number The scale of the sparks' sizes.
function EffectLib:CreateSparks(pos, amount, scale)
    local ef = EffectData()
    
    amount = amount or math.random(2, 20)

    ef:SetOrigin(pos)
    ef:SetMagnitude(amount)
    ef:SetScale(scale or 1)

    util.Effect('sev_sparks', ef)
end

---Creates a combine ball explosion.
---@param pos Vector The position to create the ring explosion at.
function EffectLib:CreateRingExplosion(pos)
    local ef = EffectData()
    ef:SetOrigin(pos)

    util.Effect('sev_ring_explosion', ef)
end
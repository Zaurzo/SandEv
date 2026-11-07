EFFECT.Sound = 'NPC_CombineBall.Explosion'

-- Very closely emulates a Combine Ball explosion
-- https://wiki.facepunch.com/gmod/effects.BeamRingPoint

local function BeamRing(origin, lifeTime, alpha)
    local extraData = {
        speed= 0,
        spread= 0,
        delay= 0,
        framerate= 2,
        material= 'sprites/lgtning'
    }

    effects.BeamRingPoint(
        origin, 
        lifeTime, 
        12, 
        1024, 
        64, 
        0, 
        Color(255, 255, 225, alpha),
        extraData
    )
end

function EFFECT:Init(data)
    local origin = data:GetOrigin()

    BeamRing(origin, 0.2, 32)
    BeamRing(origin, 0.5, 64)

    EmitSound(self.Sound, origin, 1, CHAN_AUTO, 1, 75, 0, 100)

    util.Effect('cball_explode', data)
    util.ScreenShake(origin, 20, 150, 1, 1250)
end

function EFFECT:Think()
    return false -- immediately remove self
end
EFFECT.SparkGravity = Vector(0, 0, -250)

function EFFECT:Init(data)
    local origin = data:GetOrigin()
    local size = 5 * data:GetScale()
    local emitter = ParticleEmitter(origin)

    for _ = 1, data:GetMagnitude() do
        local spark = emitter:Add('effects/spark', origin)

        if spark then
            spark:SetDieTime(1)
    
            spark:SetStartAlpha(255)
            spark:SetEndAlpha(0)
    
            spark:SetStartSize(size)
            spark:SetEndSize(0)
    
            spark:SetGravity(self.SparkGravity) 
            spark:SetVelocity(VectorRand() * 50)
        end
    end
end

function EFFECT:Think()
    return false -- immediately remove self
end
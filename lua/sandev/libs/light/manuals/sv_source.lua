---@class EnvProjectedTextureManual : SandEv.Light.Manual
local EnvProjectedTextureManual = SandEv.Base.Light:Manual()

function EnvProjectedTextureManual:SetOn(light, value)
    if value then
        light:Fire('TurnOn')
    else
        light:Fire('TurnOff')
    end
end

function EnvProjectedTextureManual:IsOn(light)
    return light:GetInternalVariable('m_bState')
end

-- Note: env_projectedtexture does not have the BrightnessScale keyvalue in Garry's Mod
-- so I have to use m_LinearFloatLightColor + Color:Set/GetBrightness

---@return Color
local function GetColor(light)
    return light:GetInternalVariable('m_LinearFloatLightColor'):ToColor()
end

-- Warning: Original color will be lost if you set brightness to near or equal 0
function EnvProjectedTextureManual:SetBrightness(light, brightness)
    local color = GetColor(light)
    color:SetBrightness(brightness)

    light:SetKeyValue('lightcolor', tostring(color))
end

function EnvProjectedTextureManual:GetBrightness(light)
    return GetColor(light):GetBrightness()
end

function EnvProjectedTextureManual:Burn(light)
    self:SetOn(light, false)
end

SandEv.Base.Light:RegisterManual('env_projectedtexture', EnvProjectedTextureManual)
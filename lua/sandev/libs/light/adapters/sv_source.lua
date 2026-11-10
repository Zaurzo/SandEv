---@class EnvProjectedTextureAdapter : SandEv.Light.Adapter
local EnvProjectedTextureAdapter = SandEv.Base.Light:Adapter()

function EnvProjectedTextureAdapter:SetOn(light, value)
    if value then
        light:Fire('TurnOn')
    else
        light:Fire('TurnOff')
    end
end

function EnvProjectedTextureAdapter:IsOn(light)
    return light:GetInternalVariable('m_bState')
end

-- Note: env_projectedtexture does not have the BrightnessScale keyvalue in Garry's Mod
-- so I have to use m_LinearFloatLightColor + Color:Set/GetBrightness

---@return Color
local function GetColor(light)
    return light:GetInternalVariable('m_LinearFloatLightColor'):ToColor()
end

-- Warning: Original color will be lost if you set brightness to near or equal 0
function EnvProjectedTextureAdapter:SetBrightness(light, brightness)
    local color = GetColor(light)

    color:SetBrightness(brightness)
    light:SetKeyValue('lightcolor', tostring(color))
end

function EnvProjectedTextureAdapter:GetBrightness(light)
    return GetColor(light):GetBrightness()
end

function EnvProjectedTextureAdapter:Burn(light)
    self:SetOn(light, false)
end

SandEv.Base.Light:RegisterAdapter('env_projectedtexture', EnvProjectedTextureAdapter)
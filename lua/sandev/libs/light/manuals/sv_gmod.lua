---@class GModLightManual : SandEv.Light.Manual
local GModLightManual = SandEv.Base.Light:Manual()
local EntityLib = SandEv.Base.Entity

local pass = function() end

function GModLightManual:SetOn(light, value)
    light:SetOn(value)
end

function GModLightManual:IsOn(light)
    return light:GetOn()
end

function GModLightManual:SetBrightness(light, brightness)
    light:SetBrightness(brightness)
end

function GModLightManual:GetBrightness(light)
    return light:GetBrightness()
end

function GModLightManual:Burn(light)
    light:SetOn(false)
    light.SetOn = pass

    EntityLib:BlockLight(light, true)
end

SandEv.Base.Light:RegisterManual('gmod_light', GModLightManual)
SandEv.Base.Light:RegisterManual('gmod_lamp', GModLightManual)
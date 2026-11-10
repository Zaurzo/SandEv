---@class GModLightAdapter : SandEv.Light.Adapter
local GModLightAdapter = SandEv.Base.Light:Adapter()
local EntityLib = SandEv.Base.Entity

local pass = function() end

function GModLightAdapter:SetOn(light, value)
    light:SetOn(value)
end

function GModLightAdapter:IsOn(light)
    return light:GetOn()
end

function GModLightAdapter:SetBrightness(light, brightness)
    light:SetBrightness(brightness)
end

function GModLightAdapter:GetBrightness(light)
    return light:GetBrightness()
end

function GModLightAdapter:Burn(light)
    light:SetOn(false)
    light.SetOn = pass

    EntityLib:BlockLight(light, true)
end

SandEv.Base.Light:RegisterAdapter('gmod_light', GModLightAdapter)
SandEv.Base.Light:RegisterAdapter('gmod_lamp', GModLightAdapter)
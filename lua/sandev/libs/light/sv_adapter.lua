---@class SandEv.Light.Adapter : SandEv.Interface
local LightAdapter = SandEv.Util:Interface()
SandEv.Base.Light.AdapterInterface = LightAdapter

function LightAdapter:SetOn(light, value)
end

function LightAdapter:IsOn(light)
end

function LightAdapter:SetBrightness(light, brightness)
end

function LightAdapter:GetBrightness(light)
end

function LightAdapter:Burn(light)
end

return LightAdapter
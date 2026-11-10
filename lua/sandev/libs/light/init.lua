---@class SandEv.LightLib : SandEv.Library
local LightLib = SandEv.Base:Library()
SandEv.Base.Light = LightLib

local baseManuals = {}
baseManuals.__index = baseManuals

LightLib._manuals = baseManuals

function LightLib:Init()
    self._manuals = setmetatable({}, baseManuals)
end

local LightManual = include('sv_manual.lua') ---@class SandEv.Light.Manual

---@return SandEv.Light.Manual
function LightLib:Manual()
    return setmetatable({}, LightManual)
end

---@param class string
---@param manual SandEv.Light.Manual
function LightLib:RegisterManual(class, manual)
    self._manuals[class] = manual
end

function LightLib:RunManual(light, methodName, ...)
    local manual = self._manuals and self._manuals[light:GetClass()]

    if not manual then
        return self.Instance:Error('no registered manual for light class')
    end

    local method = manual[methodName]

    return method(manual, light, ...)
end

function LightLib:SetOn(light, value)
    return self:RunManual(light, 'SetOn', value)
end

function LightLib:IsOn(light)
    return self:RunManual(light, 'IsOn')
end

function LightLib:SetBurnResistant(light, value)
    light._sev_burn_resistant = value and true or nil
end

function LightLib:IsBurnResistant(light)
    return light._sev_burn_resistant or false
end

function LightLib:Burn(light)
    if not self:IsBurned(light) and not self:IsBurnResistant(light) then
        light._sev_light_burned = true

        return self:RunManual(light, 'Burn')
    end
end

function LightLib:IsBurned(light)
    return light._sev_light_burned or false
end

---@param instance SandEv.LightLib
local function Fade(instance, light)
    if instance:IsBurned(light) then return end
    
    local hookName = 'sev_fade_light_' .. tostring(light)
    local start = CurTime()

    hook.Add('Tick', hookName, function()
        if not light:IsValid() then
            return hook.Remove('Tick', hookName)
        end

        local brightness = instance:RunManual(light, 'GetBrightness')
        local value = Lerp(CurTime() - start, brightness, 0)

        instance:RunManual(light, 'SetBrightness', value)

        if value <= 0 then
            return hook.Remove('Tick', hookName)
        end
    end)
end

function LightLib:FadeOut(light)
    Fade(self, light)
end

-- Register base manuals

include('manuals/sv_gmod.lua')
include('manuals/sv_source.lua')

-- Hooks

hook.Add('AcceptInput', 'sev_burned_light_control', function(ent, input)
    if LightLib:IsBurned(ent) and input:lower() == 'turnon' then
        return true
    end
end)
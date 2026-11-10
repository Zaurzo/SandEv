---@class SandEv.LightLib : SandEv.Library
local LightLib = SandEv.Base:Library()
SandEv.Base.Light = LightLib

include('sv_adapter.lua')

LightLib._adapters = {}
LightLib._adapters.__index = LightLib._adapters

function LightLib:Init()
    self._adapters = setmetatable({}, LightLib._adapters)
end

---@return SandEv.Light.Adapter
function LightLib:Adapter()
    return self.AdapterInterface:extend()
end

---@param class string
---@param adapter SandEv.Light.Adapter
function LightLib:RegisterAdapter(class, adapter)
    adapter:check()

    self._adapters[class] = adapter
end

---@param self SandEv.LightLib
local function RunAdapter(self, light, methodName, ...)
    local adapter = self._adapters[light:GetClass()]
    if not adapter then return end

    local method = adapter[methodName]
    return method(adapter, light, ...)
end

function LightLib:SetOn(light, value)
    return RunAdapter(self, light, 'SetOn', value)
end

function LightLib:IsOn(light)
    return RunAdapter(self, light, 'IsOn')
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

        return RunAdapter(self, light, 'Burn')
    end
end

function LightLib:IsBurned(light)
    return light._sev_light_burned or false
end

---@param self SandEv.LightLib
local function Fade(self, light)
    if self:IsBurned(light) then return end
    
    local hookName = 'sev_fade_light_' .. tostring(light)
    local start = CurTime()

    hook.Add('Tick', hookName, function()
        if not light:IsValid() then
            return hook.Remove('Tick', hookName)
        end

        local brightness = RunAdapter(self, light, 'GetBrightness')
        local value = Lerp(CurTime() - start, brightness, 0)

        RunAdapter(self, light, 'SetBrightness', value)

        if value <= 0 then
            return hook.Remove('Tick', hookName)
        end
    end)
end

function LightLib:FadeOut(light)
    Fade(self, light)
end

-- Register base adapters

include('adapters/sv_gmod.lua')
include('adapters/sv_source.lua')

-- Hooks

hook.Add('AcceptInput', 'sev_burned_light_control', function(ent, input)
    if LightLib:IsBurned(ent) and input:lower() == 'turnon' then
        return true
    end
end)
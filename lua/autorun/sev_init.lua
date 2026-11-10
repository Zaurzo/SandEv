-- SandEv - Sandbox Events Base
-- 2021-2026

require('netcheap')

SandEv = SandEv or {}

SandEv.Colors = {
    Red = Color(255, 0, 0),
    Orange = Color(255, 127, 0),
    Yellow = Color(255, 255, 0),
    Green = Color(0, 255, 0),
    Blue = Color(0, 0, 255),
    Pink = Color(255, 0, 255),
    Purple = Color(179, 0, 255),
    Cyan = Color(0, 255, 255)
}

local function InitSandEV()
    local gm = gmod.GetGamemode()

    if gm.IsSandboxDerived then -- Sandbox family only
        include('sandev/sh_init.lua')
    end

    hook.Remove('InitPostEntity', 'sev_initialize')
end

hook.Add('InitPostEntity', 'sev_initialize', InitSandEV)
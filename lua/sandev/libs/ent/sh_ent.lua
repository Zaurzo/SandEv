-- Only functions that apply to entities in general!!

-- Detour management

local ENT = FindMetaTable("Entity")
SEv_ENT_GetClass = SEv_ENT_GetClass or ENT.GetClass
SEv_IsValid = SEv_IsValid or IsValid

-- Is ent spawned by a player

function SEv.Ent:IsSpawnedByPlayer(ent)
    return IsValid(ent) and ent:GetNWBool("sev_spawned") or false
end

-- Cleanup

function SEv.Ent:BlockCleanup(ent, value) -- Alias
    SEv.Map:BlockEntCleanup(ent, value)
end

-- Physgun

function SEv.Ent:BlockPhysgun(ent, value, ply)
    if ply and ply:IsPlayer() then
        ply.sev_physgyun = ply.sev_physgyun or {}
        ply.sev_physgyun[ent] = value
    else
        ent.sev_physgyun = value
    end
end

function SEv.Ent:IsPhysgunBlocked(ent, ply)
    if ply and ply:IsPlayer() then
        return ply.sev_physgyun and ply.sev_physgyun[ent]
    else
        return ent.sev_physgyun
    end
end

hook.Add("PhysgunPickup", "sev_physgun_pickup_control", function(ply, ent)
    local isBlocked = SEv.Ent:IsPhysgunBlocked(ent, ply) or SEv.Ent:IsPhysgunBlocked(ent)

    if isBlocked ~= nil then
        return not isBlocked
    end
end)

hook.Add("OnPhysgunFreeze", "sev_physgun_freeze_control", function(weapon, physobj, ent, ply)
    return SEv.Ent:IsPhysgunBlocked(ent) or SEv.Ent:IsPhysgunBlocked(ent, ply) or nil
end)

hook.Add("CanPlayerUnfreeze", "sev_physgun_unfreeze_control", function(ply, ent, phys)
    if SEv.Ent:IsPhysgunBlocked(ent) or SEv.Ent:IsPhysgunBlocked(ent, ply) then
        return false
    end
end)

-- Toolgun

function SEv.Ent:BlockTools(ent, ...)
    local newTab = ent.sev_blocked_tools or {}

    for k, toolname in ipairs({ ... }) do
        newTab[toolname] = true
    end

    ent.sev_blocked_tools = newTab
end

function SEv.Ent:UnblockTools(ent, ...)
    if ent.sev_blocked_tools then
        for k, toolname in ipairs({ ... }) do
            ent.sev_blocked_tools[toolname] = nil
        end
    end
end

function SEv.Ent:GetBlockedTools(ent)
    return ent.sev_blocked_tools
end

function SEv.Ent:BlockToolgun(ent, value, ply)
    if ply and ply:IsPlayer() then
        ply.sev_toolgun = ply.sev_toolgun or {}
        ply.sev_toolgun[ent] = value
    else
        ent.sev_toolgun = value
    end
end

function SEv.Ent:IsToolgunBlocked(ent, ply)
    if ply and ply:IsPlayer() then
        return ply.sev_toolgun and ply.sev_toolgun[ent]
    else
        return ent.sev_toolgun
    end
end

hook.Add("CanTool", "sev_toolgun_permission_control", function(ply, tr, toolname, tool, button)
    local ent = tr.Entity
    local IsToolgunBlocked = SEv.Ent:IsToolgunBlocked(ent) or SEv.Ent:IsToolgunBlocked(ent, ply)

    if IsValid(ent) then
        if IsToolgunBlocked ~= nil then
            return not ent.sev_toolgun
        end

        local blockedTools = SEv.Ent:GetBlockedTools(ent)

        if blockedTools then
            return not blockedTools[toolname]
        end
    end
end)

-- Context menu

function SEv.Ent:BlockContextMenu(ent, value, ply)
    if ply and ply:IsPlayer() then
        ent:SetNWBool("sev_context_menu_" .. ply:SteamID(), value)
    else
        ent:SetNWBool("sev_context_menu", value)
    end
end

function SEv.Ent:IsContextMenuBlocked(ent, ply)
    if ply and ply:IsPlayer() then
        return ent:GetNWBool("sev_context_menu_" .. ply:SteamID())
    else
        return ent:GetNWBool("sev_context_menu")
    end
end

-- Set fake invalid (breaks numerous iterations, mainly used to simulate a brush) (wild)

function SEv.Ent:IsFakeInvalid(ent)
    return ent:GetNWBool("sev_fake_invalid") and true
end

function SEv.Ent:SetFakeInvalid(ent, value)
    ent:SetNWBool("sev_fake_invalid", value)
end

function IsValid(var)
    if not SEv_IsValid(var) then return false end
    if IsEntity(var) and var.GetNWBool and SEv.Ent:IsFakeInvalid(var) then return false end
    return true
end

-- Curse (events use this information in a variety of ways)

function SEv.Ent:SetCursed(ent, value)
    ent.sev_cursed = value
end

function SEv.Ent:IsCursed(ent)
    return ent.sev_cursed
end

function SEv.Ent:HideCurse(ent, value)
    ent.sev_hide_curse = value
end

function SEv.Ent:IsCurseHidden(ent)
    return ent.sev_hide_curse
end

-- Sounds

function SEv.Ent:SetMute(ent, value)
    ent.sev_muted = value
end

function SEv.Ent:IsMuted(ent)
    return ent.sev_muted
end

hook.Add("EntityEmitSound", "sev_sound_control", function(soundTab)
    if soundTab.Entity and SEv.Ent:IsMuted(soundTab.Entity) then
        return false
    end
end)

-- Fade

local function Fade(ent, fadingTime, callback, args, isIn)
    if not ent or not ent:IsValid() then return end

    local hookName = "sev_fade_" .. (isIn and "in" or "out") .. "_" .. tostring(ent)
    local maxTime = CurTime() + fadingTime
    local renderMode = ent:GetRenderMode()
    local color = ent:GetColor()

    -- Make fade out prevail over fade in
    if not isIn and hook.GetTable()["Tick"] and hook.GetTable()["Tick"]["sev_fade_in_" .. tostring(ent)] then
        hook.Remove("Tick", "sev_fade_in_" .. tostring(ent))
    end

    ent:SetRenderMode(RENDERMODE_TRANSCOLOR) -- Note: it doesn't work with everything

    hook.Add("Tick", hookName, function()
        if CurTime() >= maxTime or not ent:IsValid() then
            if ent:IsValid() then
                ent:SetRenderMode(renderMode)

                if callback and isfunction(callback) then
                    callback(unpack(args))
                end
            end

            hook.Remove("Tick", hookName)
        else
            local percentage = (isIn and 1 or 0) - (maxTime - CurTime()) / fadingTime * (isIn and 1 or -1)

            ent:SetColor(Color(color.r, color.g, color.b, color.a * percentage))
        end
    end)
end

function SEv.Ent:FadeIn(ent, fadingTime, callback, ...)
    Fade(ent, fadingTime, callback, { ... }, true)
end

function SEv.Ent:FadeOut(ent, fadingTime, callback, ...)
    Fade(ent, fadingTime, callback, { ... })
end

-- Set fake classname (By Zaurzo - A.R.C.)

function SEv.Ent:IsClassFake(ent)
    return ent:GetNWBool("sev_fake_class_name") and true
end

function SEv.Ent:SetFakeClass(ent, class)
    ent:SetNWString("sev_fake_class_name", class)
end

function SEv.Ent:GetRealClass(ent)
    return SEv_ENT_GetClass(ent)
end

ENT.GetClass = function(self)
    if SEv.Ent:IsClassFake(self) then return self:GetNWString("sev_fake_class_name") end
    return SEv_ENT_GetClass(self)
end

-- Hide information from HUDs and ent finders
-- See /base/addon/entinfo

function SEv.Ent:IsInfoHidden(ent)
    return ent:GetNWBool("sev_cover_ent_name") and true
end

function SEv.Ent:HideInfo(ent, value)
    ent:SetNWBool("sev_cover_ent_name", value)
end

-- Conditional callback

function SEv.Ent:CallOnCondition(ent, condition, callback, ...)
    local name = tostring(ent)
    local args = { ... }

    timer.Create(name, 0.2, 0, function()
        if not ent:IsValid() then
            timer.Remove(name)
            return
        end

        if not condition() then return end

        timer.Remove(name)

        callback(unpack(args))
    end)
end
local state = {} -- { [string ent id] = bool state }

-- Control states

function SEv.Light:IsOn(ent)
    if ent.GetOn then
        return ent:GetOn()
    end

    local index = tostring(ent)

    if state[index] == nil then
        state[index] = bit.band(ent:GetFlags(), 1)
    end

    return state[index]
end

function SEv.Light:SetOn(ent)
    if ent.SetOn then
        ent:SetOn(true)
    else
        ent:Fire("TurnOn")
        state[tostring(ent)] = true
    end

    return true
end

function SEv.Light:SetOff(ent)
    if ent.SetOn then
        ent:SetOn(false)
    else
        ent:Fire("TurnOff")
        state[tostring(ent)] = false
    end

    return false
end

function SEv.Light:Toggle(ent)
    if self:IsOn(ent) then
        return self:SetOff(ent)
    else
        return self:SetOn(ent)
    end
end

-- Burn light

function SEv.Light:IsBurnResistant(ent)
    return ent.sev_burn_resistant
end

function SEv.Light:SetBurnResistant(ent, value)
    ent.sev_burn_resistant = value
end

function SEv.Light:IsBurned(ent)
    return ent.sev_burned_light
end

function SEv.Light:Burn(ent)
    if not ent or not ent:IsValid() then return false end
    if self:IsBurned(ent) or self:IsBurnResistant(ent) then return false end

    if ent.Burn then
        ent:Burn() -- Implement this function to burn out complex lamps like the ones in Wiremod

        SEv.Ent:BlockContextMenu(ent, true)
        ent.sev_burned_light = true

        return true
    end

    if ent.SetOn and ent.GetOn then
        if ent:GetOn() then
            ent:SetOn()
        end

        ent.SetOn = function() return end

        SEv.Ent:BlockContextMenu(ent, true)
        ent.sev_burned_light = true

        return true
    end

    return false
end

-- Fade light
-- Requires ent.GetBrightness and ent.SetBrightness
local function Fade(ent, isIn, callback)
    if not ent or not ent:IsValid() then return false end
    if SEv.Light:IsBurned(ent) then return false end
    if not (ent.GetBrightness and ent.SetBrightness) then return false end

    ent:SetBrightness(2) -- Corrects Lerp causing extreme glares

    local start = SysTime()
    local brightness = ent:GetBrightness()
    local name = tostring(ent)
    local max = 200

    hook.Add("Tick", name, function()
        if not ent or not ent:IsValid() then
            hook.Remove("Tick", name)
            return
        end

        local value = Lerp(SysTime() - start, isIn and max or 0, isIn and 0 or max)

        ent:SetBrightness(brightness - value/40 * math.abs(brightness))

        if value == (isIn and 0 or max) then -- Note: sometimes Lerp goes from almost max back to 0, but this creates a nice effect on the lamps.
            if callback and isfunction(callback) then
                callback()
            end

            hook.Remove("Tick", name)
        end
    end)

    return true
end

function SEv.Light:FadeOut(ent, callback)
    return Fade(ent, false, callback)
end

function SEv.Light:FadeIn(ent, callback)
    return Fade(ent, true, callback)
end

-- Make lights blink
-- Requires ent.SetOn and ent.GetOff or ent.Fire("TurnOn") and ent.Fire("TurnOff")
function SEv.Light:Blink(ent, maxTime, finalState, callbackOn, callbackOff, callbackEnd)
    if not ent or not ent:IsValid() then return false end
    if self:IsBurned(ent) then return false end

    local supported = {
        ["env_projectedtexture"] = true,
        ["gmod_light"] = true,
        ["gmod_lamp"] = true,
        ["light_spot"] = true,
        ["light"] = true,
        ["classiclight"] = true
    }

    if not ent:GetClass() or not supported[ent:GetClass()] then return false end

    local timeRanges = {
        { 20, 40 },
        { 10, 30 },
        { 1, 10 },
        { 10, 30 },
        { 10, 20 },
        { 1, 15 },
        { 1, 11 },
        { 1, 5 }
    }

    local function finalBlink(ent)
        if ent:IsValid() and isbool(finalState) then
            if finalState then
                timer.Simple(0.15, function()
                    if ent:IsValid() then
                        self:SetOn(ent)
                    end
                end)

                if callbackOn and isfunction(callbackOn) then
                    callbackOn()
                end
            else
                timer.Simple(0.15, function()
                    if ent:IsValid() then
                        self:SetOff(ent)
                    end
                end)

                if callbackOff and isfunction(callbackOff) then
                    callbackOff()
                end
            end
        end

        if callbackEnd and isfunction(callbackEnd) then
            callbackEnd()
        end
    end

    local totalTime = 0
    local function blink()
        if totalTime == maxTime then
            finalBlink(ent)

            return
        end

        local timeRange = timeRanges[math.random(1, 8)]
        local newTime = math.random(timeRange[1], timeRange[2]) / 100

        if totalTime + newTime > maxTime then
            newTime = maxTime - totalTime
        end

        totalTime = totalTime + newTime

        timer.Simple(newTime, function()
            if not ent:IsValid() then return end

            if SEv.Light:Toggle(ent) then
                if callbackOn and isfunction(callbackOn) then
                    callbackOn()
                end
            else
                if callbackOff and isfunction(callbackOff) then
                    callbackOff()
                end
            end

            blink()
        end)
    end

    blink()

    return true
end

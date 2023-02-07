-- This custom MsgC will fix color code printing for linux SRCDS
-- SRCDS on linux doesn't support 256 color mode
-- So we have to detour MSGC and replace it for the available ones.
--   Note: despite my modifications this color fix was given to me by a friend a long time ago - Xala

local colorMap = {
    [1] = Color(0, 0, 0),
    [2] = Color(0, 0, 127),
    [3] = Color(0, 127, 0),
    [4] = Color(0, 127, 127),
    [5] = Color(127, 0, 0),
    [6] = Color(127, 0, 127),
    [7] = Color(127, 127, 0),
    [8] = Color(200, 200, 200),
    [9] = Color(127, 127, 127),
    [10] = Color(0, 0, 255),
    [11] = Color(0, 255, 0),
    [12] = Color(0, 255, 255),
    [13] = Color(255, 0, 0),
    [14] = Color(255, 0, 255),
    [15] = Color(255, 255, 0),
    [16] = Color(255, 255, 255),
    [17] = Color(128, 128, 128)
}

if system.IsLinux() and SERVER and game.IsDedicated() then
    local availableColors = {
        "\27[38;5;0m", "\27[38;5;18m", "\27[38;5;22m", "\27[38;5;12m",
        "\27[38;5;52m", "\27[38;5;53m", "\27[38;5;3m", "\27[38;5;240m",
        "\27[38;5;8m", "\27[38;5;4m", "\27[38;5;10m", "\27[38;5;14m",
        "\27[38;5;9m", "\27[38;5;13m", "\27[38;5;11m", "\27[38;5;15m",
        "\27[38;5;8m"
    }

    local colorClearSequence = "\27[0m"

    local function GetFixedColorSequence(col)
        if table.HasValue(colorMap, col) then return col end

        local curColorDist, closestColorDist, closestColorIndex

        for i = 1, #colorMap do
            curColorDist = (col.r - colorMap[i].r)^2 + (col.g - colorMap[i].g)^2 + (col.b - colorMap[i].b)^2

            if i == 1 or curColorDist < closestColorDist then
                closestColorDist = curColorDist
                closestColorIndex = i
            end
        end

        return availableColors[closestColorIndex]
    end

    local function PrintColored(color, text)
        local colorSequence = colorClearSequence

        if istable(color) then
            colorSequence = GetFixedColorSequence(color)
        elseif isstring(color) then
            colorSequence = color
        end

        if not isstring(colorSequence) then
            colorSequence = colorClearSequence
        end

        Msg(colorSequence .. text .. colorClearSequence)
    end

    function SEv.Log:MsgC(...)
        local thisSequence = colorClearSequence

        for k, arg in ipairs({...}) do
            if istable(arg) then
                thisSequence = GetFixedColorSequence(arg)
            else
                PrintColored(thisSequence, tostring(arg))
            end
        end

        Msg("\n")
    end
else
    function SEv.Log:MsgC(...)
        MsgC(...)
        Msg("\n")
    end
end

function SEv.Log:Debug(debug, msg)
    if not self.enabled then return end

    if debug or self.debugAll then
        self:MsgC(colorMap[16], "[SEv] " .. msg)
    end
end

function SEv.Log:Info(msg)
    if not self.enabled then return end
    self:MsgC(colorMap[12], "[SEv] " .. msg)
end

function SEv.Log:Warning(msg)
    if not self.enabled then return end
    self:MsgC(colorMap[15], "[SEv] " .. msg)
end

function SEv.Log:Error(msg)
    if not self.enabled then return end
    self:MsgC(Color(250, 49, 49), "[SEv] " .. msg)
end

function SEv.Log:Critical(msg)
    if not self.enabled then return end
    self:MsgC(Color(250, 49, 49), "[SEv][CRITICAL] " .. msg)
end

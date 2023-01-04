-- Deal with workshop addons

function SEv.Workshop:InitializeList()
    local addons = engine.GetAddons()

    for i = 1, #addons do
        local addon = addons[i]
        self.list[tonumber(addon.wsid)] = addon
    end
end

function SEv.Workshop:IsInstalled(wsid)
    return self.list[wsid] and true or false
end

function SEv.Workshop:IsMounted(wsid)
    return SEv.Workshop:IsInstalled(wsid) and self.list[wsid].mounted or false
end

function SEv.Workshop:Download(wsid)
    local path = "cache/workshop/" .. wsid .. ".gma"

    if not file.Exists(path, "GAME") then
        steamworks.DownloadUGC(wsid, function() return end)
    end
end

function SEv.Workshop:GetMountedByTag(tag)
    local list = {}

    for k, addonTab in ipairs(engine.GetAddons()) do
        if addonTab.mounted then
            table.insert(list, addonTab)
        end
    end

    return list
end

-- Get all the gma information
-- https://github.com/Facepunch/gmad/blob/master/src/create_gmad.cpp#L60
--[[
    Returns: nil if not a valid gma file or
    {
        header = {
            identification = string,
            version = number or string, idk
        },
        timeStamp = number unix timestamp in seconds,
        title = string title,
        description = string description,
        files = {
            {
                name = string name,
                size = number size,
                crc = number crc,
                offset = number offset
            },
            ...
        }
    }
]]
local function GetGMAInfo(gma)
    -- To-do: create a "File lib" to add these useful conversions I needed to do here -Xala
    local function Int64(_file) -- little-endian
        local low  = _file:ReadLong() -- 32-bit integer
        local high = _file:ReadLong()
        return high * 0x100000000 + low -- high * 2^32 + low = 64-bit integer
    end
    local function UInt64(_file) -- little-endian
        local low  = _file:ReadULong() -- Unsigned 32-bit integer
        local high = _file:ReadULong()
        return high * 0x100000000 + low -- high * 2^32 + low = Unsigned 64-bit integer
    end

    if gma:Read(4) ~= "GMAD" then return end
    
    local gmaInfo = {}

    -- Header
    gmaInfo.header = {
        -- Ident
        identification = "GMAD",
        -- Version
        version = gma:Read(1)
    }

    -- SteamID, unnused
    gma:Skip(8) 

    -- Timestamp
    gmaInfo.timeStamp = UInt64(gma)

    -- Required content, probably unnused
    while not gma:EndOfFile() and gma:Read(1) ~= '\0' do end

    -- Title
    gmaInfo.title = {}
    while not gma:EndOfFile() do
        local char = gma:Read(1)
        if char == '\0' then break end
        gmaInfo.title[#gmaInfo.title + 1] = char
    end
    gmaInfo.title = table.concat(gmaInfo.title)

    -- Description
    gmaInfo.description = {}
    while not gma:EndOfFile() do
        local char = gma:Read(1)
        if char == '\0' then break end
        gmaInfo.description[#gmaInfo.description + 1] = char
    end
    gmaInfo.description = table.concat(gmaInfo.description)

    -- Author name, unnused
    gma:Skip(12)

    -- Version, unnused
    gma:Skip(4)

    -- File list
    gmaInfo.files = {}
    while not gma:EndOfFile() do
        -- File number
        local number = gma:ReadULong()
        if number == 0 then break end

        -- File name
        local name = {}
        while not gma:EndOfFile() do
            local char = gma:Read(1)
            if char == '\0' then break end
            name[#name + 1] = char
        end
        name = table.concat(name)

        -- File size
        local size = Int64(gma)

        -- File CRC
        local crc = gma:ReadULong()

        table.insert(gmaInfo.files, {
            name = name,
            size = size,
            crc = crc
        })
    end

    -- File offset
    local offset = gma:Tell()
    for k, fileInfo in ipairs(gmaInfo.files) do
        fileInfo.offset = offset
        offset = offset + fileInfo.size
    end
    
    return gmaInfo
end
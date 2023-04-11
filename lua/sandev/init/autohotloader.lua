--[[
    This hotloader allows SandEv (or SEv) to be executed without the need for the player to subscribe to it.

    To use it in your project, just include the following lines in your shared initialization file (e.g. lua/autorun/mystuff.lua):


    hook.Add("OnGamemodeLoaded", "SEv_init", function()
        if SEv then return end
        file.CreateDir("sandev")
        timer.Simple(0, function()
            http.Fetch("https://raw.githubusercontent.com/Xalalau/SandEv/main/lua/sandev/init/autohotloader.lua", function(SEvHotloader)
                file.Write("sandev/sevloader.txt", SEvHotloader)
                RunString(SEvHotloader)
                StartSEvHotload(false)
            end, function()
                local SEvHotloader = file.Read("sandev/sevloader.txt", "DATA")
                if SEvHotloader then
                    RunString(SEvHotloader, "DATA")
                    StartSEvHotload(false)
                end
            end)
        end)
    end)


    Only one instance of SandEv will be executed no matter how many times StartSEvHotload() is called and
    the gma loading process will be done as follows:

    1) SEv is running on the server
        1.1) The client has no gma or the client has a different gma
            -- Download SEv gma from the server
            -- Mount on the client
        1.2) The client has the same gma
            -- Mount on the client
    2) SEv is not running on the server
        2.1) The client has no gma or the client gma is outdated
            -- Download gma from the workshop
            -- Send gma to the server if the server has no gma or if its gma is outdated
            -- Mount SEv on the server
            -- Mount SEv on the client
        2.2) The client has the same gma
            -- Mount SEv on the server
            -- Mount SEv on the client

    After the gma mounting the server will init SEv and clients will do the same thing right after.

    Singleplayer and listen or dedicated servers are supported. The code handles changelevels, new players joining the game and
    players returning to the game right after disconnecting.

    If you have concerns about how this module works, please ask a programmer to inspect it. Comments have been
    added at most steps for ease of understanding. Notify me immediately if any exploits are discovered.

    Thank you,
    - Xalalau Xubilozo
]]

-- ------------------------------------------------------------------------
-- Auxiliar functions copied or adapted from SandEv
-- ------------------------------------------------------------------------

-- Send huge binary
local sendTab = {}
local function SendData(chunksID, data, callbackName, toPly)
    local chunksSubID = SysTime()

    local totalSize = string.len(data)
    local chunkSize = 64000 -- ~64KB max
    local totalChunks = math.ceil(totalSize / chunkSize)

    -- 3 minutes to remove possible memory leaks
    sendTab[chunksID] = chunksSubID
    timer.Create(chunksID, 180, 1, function()
        sendTab[chunksID] = nil
    end)

    for i = 1, totalChunks, 1 do
        local startByte = chunkSize * (i - 1) + 1
        local remaining = totalSize - (startByte - 1)
        local endByte = remaining < chunkSize and (startByte - 1) + remaining or chunkSize * i
        local chunk = string.sub(data, startByte, endByte)

        timer.Simple(i * 0.1, function()
            if sendTab[chunksID] ~= chunksSubID then return end

            local isLastChunk = i == totalChunks

            net.Start("sev_hotloader_continue")
            net.WriteString("sev_hotloader_net_send_string")
            net.WriteString(chunksID)
            net.WriteUInt(sendTab[chunksID], 32)
            net.WriteUInt(#chunk, 16)
            net.WriteData(chunk, #chunk)
            net.WriteBool(isLastChunk)
            if isLastChunk then
                net.WriteString(callbackName)
            else
                net.WriteString("")
            end
            if SERVER then
                if toPly then
                    net.Send(toPly)
                else
                    net.Broadcast()
                end
            else
                net.SendToServer()
            end

            if isLastChunk then
                sendTab[chunksID] = nil
            end
        end)
    end
end

local receivedTab = {}
local function NET_ReceiveData(chunksID, chunksSubID, len, chunk, isLastChunk, callbackName)
    -- Initialize streams or reset overwriten ones
    if not receivedTab[chunksID] or receivedTab[chunksID].chunksSubID ~= chunksSubID then
        receivedTab[chunksID] = {
            chunksSubID = chunksSubID,
            data = ""
        }

        -- 3 minutes to remove possible memory leaks
        timer.Create(chunksID, 180, 1, function()
            receivedTab[chunksID] = nil
        end)
    end

    -- Rebuild the compressed string
    receivedTab[chunksID].data = receivedTab[chunksID].data .. chunk

    -- Finish stream
    if isLastChunk then
        local data = receivedTab[chunksID].data

        _G[callbackName](data)
    end
end

-- Get gma title, which is used as the mounted addon folder name on the root gmod dir
--   Src: https://github.com/Facepunch/gmad/blob/master/src/create_gmad.cpp#L60
--   Thanks to https://github.com/Facepunch/garrysmod-issues/issues/5143 and Zaurzo for the help
--   I also implemented the function SEv.Workshop:GetGMAInfo() to read the entire gma
local function GetGMATitle(gma)
    if gma:Read(4) ~= "GMAD" then return end

    -- Version (1)
    -- SteamID, unnused (8)
    -- Timestamp (8)
    gma:Skip(17)

    -- Required content, probably unnused
    while not gma:EndOfFile() and gma:Read(1) ~= '\0' do end

    -- Title
    local title = {}
    while not gma:EndOfFile() do
        local char = gma:Read(1)
        if char == '\0' then break end
        title[#title + 1] = char
    end
    title = table.concat(title)

    return title
end

-- ------------------------------------------------------------------------
-- The hotloader
-- ------------------------------------------------------------------------

if SERVER then
    util.AddNetworkString("sev_hotloader_continue") -- I'm just using a single net string because the hotloader only runs once. Change requested by Zaurzo.
end

local isDedicated = game.IsDedicated() -- game.IsDedicated() is always false on the client, so I "fix" it later

local SHL = {} -- SandEv Hotloader

local sandevInfo = {
    updated = 0,
    file = '',
    size = '',
    tags = '',
    title = '',
    timeadded = ''
}

local hotloaderLogging
local isSEvMounted = false
local hotloaderAddonInfo = {}
local hotloadedExtraAddCSLua = {} -- Used on dedicated servers only
local totalMountedFiles = 0
local delayPerFile = not game.SinglePlayer() and 0.012 or 0

-- SEv info
local SEVInitFile = "autorun/sev_init.lua"
local SEVInfoFile = "sandev/sandevinfo.txt"
local SEVGMA = "sandev/sandev.dat" -- Data folder
local SEvWSID = "2908040257"

function SHL:ShowLog(log)
    if hotloaderLogging then
        print("[SEvLoader] " .. log)
    end
end

-- Show the hotloaded addon as mounted addon
SEv_engineGetAddons = SEv_engineGetAddons or engine.GetAddons

function engine.GetAddons()
    local mountedAddons = SEv_engineGetAddons()

    if isSEvMounted then
        table.Merge(mountedAddons, hotloaderAddonInfo)
    end

    return mountedAddons
end

function SHL:AddAddonInfo(addonInfo)
    table.insert(hotloaderAddonInfo, addonInfo)
end

-- Load an entity
function SHL:HotloadEntity(luaFolder, objName, entBase, entClass, filename)
    _G[objName] = {}
    _G[objName].Folder = luaFolder .. "/" .. entClass

    if luaFolder == "weapons" then
        _G[objName].Primary = {}
        _G[objName].Secondary = {}
    end

    local filesIncluded = false

    if isstring(filename) then
        AddCSLuaFile(luaFolder .. "/" .. filename)
        include(luaFolder .. "/" .. filename)
        filesIncluded = true
    else
        if SERVER then
            local files, dirs = file.Find(_G[objName].Folder .. "/*", "LUA")
            for k, filename in ipairs(files) do
                AddCSLuaFile(_G[objName].Folder .. "/" .. filename)
            end

            if file.Exists(_G[objName].Folder .. "/init.lua", "LUA") then
                include(_G[objName].Folder .. "/init.lua")
                filesIncluded = true
            end
        else
            if file.Exists(_G[objName].Folder .. "/cl_init.lua", "LUA") then
                include(_G[objName].Folder .. "/cl_init.lua")
                filesIncluded = true
            end
        end
    end

    if filesIncluded then
        SHL:ShowLog("[Register entity] " .. entClass)

        entBase.Register(ENT, entClass)
        baseclass.Set(entClass, ENT)
    end

    _G[objName] = nil
end

-- Load new sents and sweps
function SHL:HotloadEntities(gmaTitle, luaFolder, objName, entBase)
    local files, dirs = file.Find("lua/" .. luaFolder .. "/*", gmaTitle)

    -- Check for unregistered entities

    -- Files
    for k, filename in ipairs(files) do
        local char1, char2, entClass = string.find(filename, "([%w_]*).lua")

        -- Register new entities
        if not entBase.GetStored(entClass) then
            SHL:HotloadEntity(luaFolder, objName, entBase, entClass, filename)
        end
    end

    -- Folders
    for k, entClass in ipairs(dirs) do
        -- Register new entities
        if entClass ~= "gmod_tool" and not entBase.GetStored(entClass) then
            if file.Exists(luaFolder .. "/" .. entClass .. "/init.lua", "LUA") or 
                file.Exists(luaFolder .. "/" .. entClass .. "/cl_init.lua", "LUA")
                then
                SHL:HotloadEntity(luaFolder, objName, entBase, entClass, filename)
            end
        end
    end
end

--[[
    Load custom toolgun
    https://github.com/Facepunch/garrysmod/blob/e147111b1e5add3853b61efe021c01be0ee10cbd/garrysmod/gamemodes/sandbox/entities/weapons/gmod_tool/stool.lua#L132

    Issue: https://wiki.facepunch.com/gmod/Auto_Refresh
       Autorefresh does not always work. Not knowing these restrictions can lead to confusion. These are the currently known limitations:
       ...
       "It doesn't work with dynamically included / AddCSLuaFile'd content - either for all, or specific cases. ( However, editing the primary cl_init,
       shared, init.lua files will trigger it, or any files included from those files; but anything dynamically added will not trigger the event - 
       current test-case is with include rules inside of a function, called in sh_init.lua and cl_init / init includes sh_init and AddCSLuaFile )""
       ...
   
    Workaround: On multiplayer the CLIENT Lua files don't fully integrate (due to the datapack not refreshing) and seem to break includes internally, but
                they get correctly mounted on both realms. Given this situation, I replace all include(path) calls with RunString(file.Read(path, 'Lua'))
                and end up with fully working addons. These replacements are only necessary in multiplayer, but I also do them in singleplayer to avoid
                warning messages about datapack inconsistencies. -- Xala
]]
function SHL:HotloadTools(gmaTitle)
    SWEP = baseclass.Get('gmod_tool')
    toolObj = getmetatable(SWEP.Tool["axis"])

    local toolModes = file.Find("lua/weapons/gmod_tool/stools/*.lua", gmaTitle)
    local foundToolsToMount = false

    -- Check for unregistered tools
    for k, filename in ipairs(toolModes) do
        local char1, char2, toolMode = string.find(filename, "([%w_]*).lua")

        -- Register new tools
        if not SWEP.Tool[toolMode] then
            SHL:ShowLog("[Register tool] " .. toolMode)

            foundToolsToMount = true

            -- Create the tool object
            TOOL = toolObj:Create()
            TOOL.Mode = toolMode

            AddCSLuaFile("weapons/gmod_tool/stools/" .. filename)
            include("weapons/gmod_tool/stools/" .. filename)

            TOOL:CreateConVars()

            -- Register the object in the toolgun class for new toolguns
            SWEP.Tool[toolMode] = TOOL
    
            -- Register the object in spawned toolguns
            for k, ply in ipairs(player.GetHumans()) do
                local toolGun = ply:GetWeapon('gmod_tool')
        
                if IsValid(toolGun) then
                    toolGun.Tool[toolMode] = TOOL
                end
            end

            TOOL = nil
        end
    end

    local TOOLS_LIST = SWEP.Tool

    toolObj = nil
    SWEP = nil

    if foundToolsToMount then
        -- Initialize new tools in spawned toolguns
        for k, ply in ipairs(player.GetHumans()) do
            local toolGun = ply:GetWeapon('gmod_tool')
    
            if IsValid(toolGun) then
                toolGun:InitializeTools()
            end
        end

        -- Rebuild the spawnmenu
        if CLIENT then
            hook.Add("PopulateToolMenu", "AddSToolsToMenu", function()
                for toolMode, TOOL in pairs(TOOLS_LIST) do
                    if TOOL.AddToMenu ~= false then
                        spawnmenu.AddToolMenuOption(
                            TOOL.Tab or "Main",
                            TOOL.Category or "New Category",
                            toolMode,
                            TOOL.Name or "#" .. toolMode,
                            TOOL.Command or "gmod_tool " .. toolMode,
                            TOOL.ConfigName or toolMode,
                            TOOL.BuildCPanel
                        )
                    end
                end
            end)

            RunConsoleCommand('spawnmenu_reload')
        end
    end
end

-- Initialize SEV. The gma must be already mounted and all the Lua files included.
function SHL:InitSEv()
    -- If SEv is mounted and it's SERVER, broadcast init to make new players start their init
    if isSEvMounted then
        if SERVER then
            net.Start("sev_hotloader_continue")
            net.WriteString("sev_init")
            net.Broadcast()
        end

        return
    end

    -- Init SEv portals
    if CLIENT then
        local sev_portal_init = hook.GetTable()["InitPostEntity"]["sev_portal_init"]
        sev_portal_init()
    end

    -- Init SEv
    local sev_init = hook.GetTable()["InitPostEntity"]["sev_init"]

    if isDedicated then
        -- AddCSLuaFile doesn't work with hotloaded files on dedicated servers, so I send
        -- the file contents to clients so them can include the code when the it's needed
        if SERVER then
            sev_init()

            local compressedString = util.Compress(util.TableToJSON(hotloadedExtraAddCSLua))
            SendData("sandev_addcslua_extra_dedicated", compressedString, "ReceivedExtraAddCSLua")
        else
            net.Start("sev_hotloader_continue")
            net.WriteString("sev_request_addcslua_extra_dedicated")
            net.SendToServer()
        end
    else
        sev_init()

        if SERVER then
            net.Start("sev_hotloader_continue")
            net.WriteString("sev_init")
            net.Broadcast()
        end
    end

    -- At this point SandEv is fully mounted
    isSEvMounted = true

    -- Remove temporary detours
    timer.Simple(60, function()
        AddCSLuaFile = AddCSLuaFileInUse
        include = includeInUse
    end)
end

local function NET_Init()
    if CLIENT then
        timer.Simple(totalMountedFiles * delayPerFile, function()
            SHL:InitSEv()
        end)
    else
        SHL:InitSEv()
    end
end

-- Client requests addcslua info from the server to finish hotloading the SandEv
local function NET_RequestAddcsluaExtraDedicated()
    if CLIENT then return end

    local compressedString = util.Compress(util.TableToJSON(hotloadedExtraAddCSLua))
    SendData("sandev_addcslua_extra_dedicated", compressedString, "ReceivedExtraAddCSLua", ply)
end

-- AddCSLua for files added by the SandEv instances system
-- This function is only used on dedicated servers
-- DO NOT call directly!! It's a callback for the SendData function
function ReceivedExtraAddCSLua(data)
    if SERVER or not isDedicated or isSEvMounted then return end

    hotloadedExtraAddCSLua = util.JSONToTable(util.Decompress(data))

    -- Mount SEv
    local sev_init = hook.GetTable()["InitPostEntity"]["sev_init"]

    sev_init()

    -- At this point SandEv is fully mounted
    isSEvMounted = true
end

function SHL:HotloadSEv(gmaTitle)
    -- Note: WSHL_* vars are workarounds to solve Midgame Workshop Hotloader conflicts
    -- Zaurzo added them while he's rewriting his tool so we can coexist right now

    local detourCLIncludeOnSingleplayer = true

    -- Add temporary detours

    -- AddCSLuaFile: helps to debug
    local AddCSLuaFileOriginal = AddCSLuaFileOriginal or WSHL_AddCSLuaFile or AddCSLuaFile
    AddCSLuaFileInUse = AddCSLuaFileInUse or AddCSLuaFile
    function AddCSLuaFile(path)
        if CLIENT then return end

        if path == nil then
            path = debug.getinfo(2).short_src
        end

        if file.Exists(path, "LUA") then
            SHL:ShowLog("[AddCSLuaFile] " .. path)
            AddCSLuaFileOriginal(path)

            if isDedicated and not string.find(path, "sandev") and not string.find(path, "sev_") then
                local fileContent = file.Read(path, 'LUA')
                hotloadedExtraAddCSLua[path] = fileContent
            end
        end
    end

    -- Include: helps to debug and workarounds the CLIENT include datapack issue
    local includeOriginal = includeOriginal or WSHL_include or include
    includeInUse = includeInUse or include
    function include(path)
        if not file.Exists(path, "LUA") or not string.find(path, "([\\/]+)") then
            local fixedPath = string.GetPathFromFilename(debug.getinfo(2).source) .. path
            fixedPath = string.gsub(fixedPath, "@", "")
            fixedPath = string.gsub(fixedPath, "lua/", "")

            if file.Exists(fixedPath, "LUA") then
                path = fixedPath
            end
        end

        if CLIENT and (detourCLIncludeOnSingleplayer or not game.SinglePlayer()) then
            local fileContent = file.Read(path, 'LUA')

            if fileContent then
                SHL:ShowLog("[include cl hack] " .. path)
                RunString(fileContent, path)
            elseif hotloadedExtraAddCSLua[path] then
                SHL:ShowLog("[include cl hack on dedicated server] " .. path)
                fileContent = hotloadedExtraAddCSLua[path]
                RunString(fileContent, path)
            else
                SHL:ShowLog("[include cl hack] FAILED TO INCLUDE " .. path)
            end
        else
            SHL:ShowLog("[include] " .. path)
            includeOriginal(path)
        end
    end

    -- Loading order
    -- https://wiki.facepunch.com/gmod/Lua_Loading_Order

    -- Load all lua files
    include(SEVInitFile)

    -- Load new scripted weapons
    SHL:HotloadEntities(gmaTitle, "weapons", "SWEP", weapons)

    -- Load new tools
    SHL:HotloadTools(gmaTitle)

    -- Load new scripted entities
    SHL:HotloadEntities(gmaTitle, "entities", "ENT", scripted_ents)
end

-- Mount a gma file
function SHL:MountSEv(path)
    if path == nil then
        path = "data/" .. sandevInfo.file
    end

    -- If SEv is already mounted on the server ignore the request and try
    -- to mount it on new players (The "sev_mount" net also ignores players with
    -- a mounted SandEv)
    if SERVER and SEv then
        net.Start("sev_hotloader_continue")
        net.WriteString("sev_mount")
        net.Broadcast()
        return
    end

    -- Mount files
    local isMounted, files = game.MountGMA(path)
    local gmaTitle = GetGMATitle(file.Open(path, "rb", "GAME"))

    totalMountedFiles = #files

    if not isMounted then
        print("Error trying to hotload sandev")
        return
    end

    SHL:HotloadSEv(gmaTitle)

    -- After ther server is finished we have to mount SEv on clients
    if SERVER then
        -- On servers we need to wait a bit to AddCSLuaFile be finished before going ahead
        timer.Simple(totalMountedFiles * delayPerFile, function()
            net.Start("sev_hotloader_continue")
            net.WriteString("sev_mount")
            net.Broadcast()
        end)
    -- Clients need to go through the server before initing SEv because the server must init before them
    else
        net.Start("sev_hotloader_continue")
        net.WriteString("sev_init")
        net.SendToServer()
    end
end

local function NET_Mount()
    if SERVER then return end

    if not SEv then
        SHL:MountSEv()
    end
end

-- The server received an updated SEv gma from a client
function ReceivedSEvGMA(gmaContent)
    if CLIENT then return end

    SHL:SaveSEvGMA(gmaContent)

    SHL:MountSEv()
end

-- Save SEv gma file to the data folder
function SHL:SaveSEvGMA(gmaContent)
    local gmaCopy = file.Open(SEVGMA, "wb", "DATA")

    if not gmaCopy then
        print("Failed to write SandEv gma to the disk.")
        return
    end

    gmaCopy:Write(gmaContent)
    gmaCopy:Close()
end

-- Update persistent SandEv data
function SHL:SaveSEvAddonInfo(addonInfo)
    sandevInfo.updated = tonumber(addonInfo.updated)
    sandevInfo.file = addonInfo.file
    sandevInfo.size = addonInfo.size
    sandevInfo.tags = addonInfo.tags
    sandevInfo.title = addonInfo.title
    sandevInfo.timeadded = addonInfo.timeadded

    file.Write(SEVInfoFile, util.TableToJSON(sandevInfo, true))
end

-- Get the addonInfo from the persistent SandEv data
function SHL:GetStoredAddonInfo()
    return {
        downloaded = true,
        file = sandevInfo.file,
        models = 0,
        mounted = true,
        size = sandevInfo.size,
        tags = sandevInfo.tags,
        timeadded = sandevInfo.timeadded,
        title = sandevInfo.title,
        updated = sandevInfo.updated,
        wsid = SEvWSID
    }
end

-- Send a updated SEv gma to the server if requested
local function NET_RequestGMA(callbackName)
    local gmaCopy = file.Open(SEVGMA, "rb", "DATA")

    if gmaCopy then
        local gmaContent = gmaCopy:Read(gmaCopy:Size())
        gmaCopy:Close()

        SendData("sandev_gma", gmaContent, callbackName, nil)
    end
end

-- Check if the server cached SEv exists and is updated
-- Request a updated gma otherwise
local function NET_SendAddonInfoToSV(ply, addonInfo)
    if CLIENT then return end

    local updated = sandevInfo.updated

    if not SEv then
        SHL:SaveSEvAddonInfo(addonInfo)
        SHL:AddAddonInfo(addonInfo)
    end

    if not SEv and addonInfo.updated > tonumber(updated) then
        net.Start("sev_hotloader_continue")
        net.WriteString("sev_request_gma")
        net.WriteString("ReceivedSEvGMA")
        net.Send(ply)
    else
        SHL:MountSEv()
    end
end

local function NET_GetAddonInfoFromSV(ply)
    if CLIENT then return end

    local addonInfo = SHL:GetStoredAddonInfo()

    net.Start("sev_hotloader_continue")
    net.WriteString("sev_send_addon_info_to_cl")
    net.WriteTable(addonInfo)
    net.WriteBool(isSEvMounted)
    net.WriteBool(isDedicated)
    net.Send(ply)
end

-- Download the SEv version beign used by the server
function SHL:DownloadSEvFromServer(SVAddonInfo)
    if SERVER then return end

    SHL:ShowLog("Downloading gma from server...")

    -- Register addon info
    SHL:AddAddonInfo(SVAddonInfo)

    -- Save addon info
    SHL:SaveSEvAddonInfo(SVAddonInfo)

    -- Request SEv
    net.Start("sev_hotloader_continue")
    net.WriteString("sev_request_gma")
    net.WriteString("DownloadedSEvFromServer")
    net.SendToServer()
end

-- Load the SEv downloaded from the server
function DownloadedSEvFromServer(gmaContent)
    if SERVER then return end

    -- Save gma content
    SHL:SaveSEvGMA(gmaContent)

    -- Mount SEv
    SHL:MountSEv()
end

-- Download the latest SEv from the workshop
function SHL:DownloadSEvFromWorkshop(result)
    if SERVER then return end

    SHL:ShowLog("Downloading gma from workshop...")

    steamworks.DownloadUGC(SEvWSID, function(path, _file)
        -- Save gma content
        local gmaContent = _file:Read(_file:Size())
        SHL:SaveSEvGMA(gmaContent)

        -- Register addon info
        local timeadded = os.time()
        local addonInfo = {
            downloaded = true,
            file = SEVGMA,
            models = 0,
            mounted = true,
            size = result.size,
            tags = result.tags,
            timeadded = timeadded,
            title = result.title,
            updated = result.updated,
            wsid = SEvWSID
        }

        SHL:AddAddonInfo(addonInfo)

        -- Save addon info
        SHL:SaveSEvAddonInfo(addonInfo)

        -- Mount SEv
        net.Start("sev_hotloader_continue")
        net.WriteString("sev_send_addon_info_to_sv")
        net.WriteTable(addonInfo)
        net.SendToServer()
    end)
end

-- Use the local client cached SEv
function SHL:LoadCachedSEv(isMountedOnServer)
    if SERVER then return end

    SHL:ShowLog("Using cached gma")

    -- Register addon info
    local addonInfo = SHL:GetStoredAddonInfo()

    SHL:AddAddonInfo(addonInfo)

    -- Mount SEv
    if isMountedOnServer then
        SHL:MountSEv()
    else
        net.Start("sev_hotloader_continue")
        net.WriteString("sev_send_addon_info_to_sv")
        net.WriteTable(addonInfo)
        net.SendToServer()    
    end
end

-- It's only possible to download workshop addons on clients, so we need to
-- send the gma information and contents to the server when there's a dedicated
-- server executing and the cached gma is outdated.
function SHL:DownloadSEv(SVAddonInfo, isMountedOnSv)
    if SERVER then return end

    SHL:ShowLog("SandEv Auto Hotloader is starting...")

    -- Get the last stored values
    local updated = sandevInfo.updated

    -- Start SEv GMA download if needed or mount a cached version.
    -- The cached version works offline.
    steamworks.FileInfo(SEvWSID, function(result)
        -- The server has a SEv gma initialized
        if isMountedOnSv and SVAddonInfo and next(SVAddonInfo) then
            -- Get the server gma if the local one differs
            if updated ~= SVAddonInfo.updated then
                SHL:DownloadSEvFromServer(SVAddonInfo)
            -- Load the local gma if the it's the same
            else
                SHL:LoadCachedSEv(isMountedOnSv)
            end
        -- The server doesn't have SEv initialized and the client needs to download a new version
        elseif result ~= nil and (updated == '0' or result.updated > tonumber(updated)) then
            SHL:DownloadSEvFromWorkshop(result)
        -- The server doesn't have SEv initialized and the client has an usable cached version
        elseif updated ~= '0' then
            SHL:LoadCachedSEv(isMountedOnSv)
        else
            SHL:ShowLog("Failed to hotload SandEv due to errors accessing the Workshop.")
        end
    end)
end

local function NET_SendAddonInfoToCL(SVAddonInfo, isMountedOnSv, isDedicatedSV)
    if SERVER then return end

    isDedicated = isDedicatedSV

    SHL:DownloadSEv(SVAddonInfo, isMountedOnSv)
end

function StartSEvHotload(enableLogging)
    hotloaderLogging = enableLogging

    -- Check if SEv is already loaded
    if SEv then
        SHL:ShowLog("SandEv is already executing, ignoring hotload")
        return
    end

    -- Make sure sandev folder exists
    file.CreateDir("sandev")

    -- Drop legacy data storage -- REMOVE THIS LATER
    if sql.TableExists("SEv") then
        sql.Query("DROP TABLE SEv;")
        file.Delete("sandev.dat")
        file.Delete("sevloader.txt")
    end

    -- Get the persistent data
    if file.Exists(SEVInfoFile, "DATA") then
        sandevInfo = util.JSONToTable(file.Read(SEVInfoFile, "Data"))
    end

    -- Get the server state and start the hotload
    if CLIENT then
        timer.Simple(0.2, function() -- Forces the net to work
            net.Start("sev_hotloader_continue")
            net.WriteString("sev_get_addon_info_from_sv")
            net.SendToServer()
        end)
    end
end

net.Receive("sev_hotloader_continue", function(len, ply)
    local call = net.ReadString()

    if call == "sev_hotloader_net_send_string" then
        local chunksID = net.ReadString()
        local chunksSubID = net.ReadUInt(32)
        local len = net.ReadUInt(16)
        local chunk = net.ReadData(len)
        local isLastChunk = net.ReadBool()
        local callbackName = net.ReadString() -- Empty until isLastChunk is true.
        NET_ReceiveData(chunksID, chunksSubID, len, chunk, isLastChunk, callbackName)
    elseif call == "sev_mount" then
        NET_Mount()
    elseif call == "sev_send_addon_info_to_sv" then
        local addonInfo = net.ReadTable()
        NET_SendAddonInfoToSV(ply, addonInfo)
    elseif call == "sev_get_addon_info_from_sv" then
        NET_GetAddonInfoFromSV(ply)
    elseif call == "sev_send_addon_info_to_cl" then
        local SVAddonInfo = net.ReadTable()
        local isMountedOnSv = net.ReadBool()
        local isDedicated = net.ReadBool()
        NET_SendAddonInfoToCL(SVAddonInfo, isMountedOnSv, isDedicated)
    elseif call == "sev_request_gma" then
        local callbackName = net.ReadString()
        NET_RequestGMA(callbackName)
    elseif call == "sev_request_addcslua_extra_dedicated" then
        NET_RequestAddcsluaExtraDedicated()
    elseif call == "sev_init" then
        NET_Init()
    end
end)

-- Restore addon info and state after a map changelevel
if SEv then
    local addonInfo = SHL:GetStoredAddonInfo()
    SHL:AddAddonInfo(addonInfo)
    isSEvMounted = true
end
--[[
    This hotloader allows SandEv to be included without the need for the player to subscribe to it. Only one instance
    of SandEv will be executed and a new gma will be downloaded if there are workshop updates.

    Singleplayer, listen servers and dedicated servers are supported.

    If you have concerns about how this module works, please ask a programmer to inspect the code. Comments have been
    added at most steps for ease of understanding.

    To use this hotloader in your project, just include the following lines in your shared initialization file (e.g. lua/autorun/mystuff.lua):

    hook.Add("Initialize", "SEv_init", function()
        if SEv then return end
        http.Fetch("https://raw.githubusercontent.com/Xalalau/SandEv/main/lua/sandev/init/autohotloader.lua", function(SEvHotloader)
            RunString(SEvHotloader)
            StartSEvHotload(false)
        end)
    end)

    Thank you,
    - Xalalau Xubilozo
]]

-- ------------------------------------------------------------------------
-- Auxiliar functions copied or adapted from SandEv
-- ------------------------------------------------------------------------

-- Add the network name to be used by the SendData function
if SERVER then
    util.AddNetworkString("hotloader_net_send_string")
end

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

            net.Start("hotloader_net_send_string")
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
net.Receive("hotloader_net_send_string", function()
    local chunksID = net.ReadString()
    local chunksSubID = net.ReadUInt(32)
    local len = net.ReadUInt(16)
    local chunk = net.ReadData(len)
    local isLastChunk = net.ReadBool()
    local callbackName = net.ReadString() -- Empty until isLastChunk is true.

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
end)

-- ------------------------------------------------------------------------
-- The hotloader
-- ------------------------------------------------------------------------

if SERVER then
    util.AddNetworkString("sev_mount")
    util.AddNetworkString("sev_send_addon_info_to_sv")
    util.AddNetworkString("sev_get_addon_info_from_sv")
    util.AddNetworkString("sev_send_addon_info_to_cl")
    util.AddNetworkString("sev_request_gma")
    util.AddNetworkString("sev_request_mount_on_cl")
end

local SHL = {} -- SandEv Hotloader

local hotloaderLogging
local isSEvMounted = false
local hotloaderAddonInfo = {}
local hotloadedExtraAddCSLua = {} -- Used on dedicated servers only

-- SEv info
local SEVInitFile = "autorun/sev_init.lua"
local SEVGMA = "sandev.dat" -- Data folder
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
function SHL:HotloadEntity(_type, objName, entBase, entClass, filename)
    _G[objName] = {}
    _G[objName].Folder = _type .. "/" .. entClass

    if _type == "weapons" then
        _G[objName].Primary = {}
        _G[objName].Secondary = {}
    end

    local filesIncluded = false

    if isstring(filename) then
        AddCSLuaFile(_type .. "/" .. filename)
        include(_type .. "/" .. filename)
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
function SHL:HotloadEntities(_type, objName, entBase)
    local files, dirs = file.Find(_type .. "/*", "LUA")

    -- Check for unregistered entities

    -- Files
    for k, filename in ipairs(files) do
        local char1, char2, entClass = string.find(filename, "([%w_]*).lua")

        -- Register new entities
        if not entBase.GetStored(entClass) then
            SHL:HotloadEntity(_type, objName, entBase, entClass, filename)
        end
    end

    -- Folders
    for k, entClass in ipairs(dirs) do
        -- Register new entities
        if entClass ~= "gmod_tool" and not entBase.GetStored(entClass) then
            if file.Exists(_type .. "/" .. entClass .. "/init.lua", "LUA") or 
                file.Exists(_type .. "/" .. entClass .. "/cl_init.lua", "LUA")
                then
                SHL:HotloadEntity(_type, objName, entBase, entClass, filename)
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
function SHL:HotloadTools()
    SWEP = baseclass.Get('gmod_tool')
    toolObj = getmetatable(SWEP.Tool["axis"])

    local toolModes = file.Find("weapons/gmod_tool/stools/*.lua", "LUA")
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

function SHL:HotloadSEv()
    local detourCLIncludeOnSingleplayer = true

    -- Add temporary detours

    -- AddCSLuaFile: helps to debug
    AddCSLuaFileOriginal = AddCSLuaFileOriginal or _G.AddCSLuaFile
    function AddCSLuaFile(path)
        if CLIENT then return end

        if path == nil then
            path = debug.getinfo(2).short_src
        end

        if file.Exists(path, "LUA") then
            SHL:ShowLog("[AddCSLuaFile] " .. path)
            AddCSLuaFileOriginal(path)

            if game.IsDedicated and not string.find(path, "sandev") and not string.find(path, "sev_") then
                local fileContent = file.Read(path, 'LUA')
                hotloadedExtraAddCSLua[path] = fileContent
            end
        end
    end

    -- Include: helps to debug and workarounds the CLIENT include datapack issue
    includeOriginal = includeOriginal or _G.include
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
    SHL:HotloadEntities("weapons", "SWEP", weapons)

    -- Load new tools
    SHL:HotloadTools()

    -- Load new scripted entities
    SHL:HotloadEntities("entities", "ENT", scripted_ents)

    -- At this point SandEv is fully mounted
    isSEvMounted = true

    -- Start SandEv
    timer.Simple(0.6, function()
        if CLIENT then
            local sev_portal_init = hook.GetTable()["InitPostEntity"]["sev_portal_init"]
            sev_portal_init()
        end

        local sev_init = hook.GetTable()["InitPostEntity"]["sev_init"]
        sev_init()
    end)

    -- Remove temporary detours
    timer.Simple(1.5, function()
        AddCSLuaFile = AddCSLuaFileOriginal
        include = includeOriginal
    end)
end

-- The client has to ask the server if SEv can be mounted
function SHL:RequestMountSEvOnCl(ply)
    if CLIENT then return end

    if game.IsDedicated then
        timer.Simple(0.9, function()
            local compressedString = util.Compress(util.TableToJSON(hotloadedExtraAddCSLua))
            SendData("sandev_addcslua_extra_dedicated", compressedString, "ReceivedExtraAddCSLua", nil)
        end)
    elseif ply then
        net.Start("sev_mount")
        net.Send(ply)
    else
        net.Start("sev_mount")
        net.Broadcast()
    end
end

if SERVER then
    net.Receive("sev_request_mount_on_cl", function(len, ply)
        SHL:RequestMountSEvOnCl(ply)
    end)
end

-- Mount a gma file
function SHL:MountSEv(path)
    if path == nil then
        path = "data/" .. sql.Query("SELECT value FROM SEv WHERE key = 'file';")[1].value
    end

    -- If SEv is already mounted on the server ignore the request and try
    -- to mount it on new players (The "sev_mount" net ignores players with
    -- a mounted SandEv)
    if SERVER and SEv then
        SHL:RequestMountSEvOnCl()
        return
    end

    -- Mount files
    local isMounted, files = game.MountGMA(path)

    if not isMounted then
        print("Error trying to hotload sandev")
        return
    end

    -- Check wether the mounted files are accessible or not
    local mountedFiles = 0
    local retries = 10
    timer.Create(path, 0.3, 0, function()
        for k, _file in ipairs(files) do
            if file.Exists(_file, "GAME") then
                SHL:ShowLog("[file.Exists]: " .. _file)
                mountedFiles = mountedFiles + 1
            end
        end

        -- If so, start the hotloading process
        if mountedFiles == #files or retries == 0 then
            SHL:HotloadSEv()

            if SERVER then
                SHL:RequestMountSEvOnCl()
            end

            timer.Remove(path)
        end

        retries = retries - 1
    end)
end

if CLIENT then
    net.Receive("sev_mount", function()
        if not SEv then
            SHL:MountSEv()
        end
    end)
end

-- AddCSLua for files added by the SandEv bases system
-- This function is only used on dedicated servers
-- DO NOT call this function directly!! It must be used only as a callback for the SendData function
function ReceivedExtraAddCSLua(data)
    if SERVER then return end

    hotloadedExtraAddCSLua = util.JSONToTable(util.Decompress(data))
    SHL:MountSEv()
end

-- The server received an updated SEv gma from a client
function ReceivedSEvGMA(gmaContent)
    if CLIENT then return end

    SHL:SaveSEvGMA(gmaContent)

    net.Start("sev_request_mount_on_cl")
    net.SendToServer()
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

-- Initialize persistent SandEv data
function SHL:InitSEvSQL()
    if not sql.TableExists("SEv") then
        sql.Query("CREATE TABLE SEv(key TEXT, value TEXT);")
        sql.Query("INSERT INTO SEv (key, value) VALUES ('file', '');")
        sql.Query("INSERT INTO SEv (key, value) VALUES ('updated', '0');")
        sql.Query("INSERT INTO SEv (key, value) VALUES ('size', '');")
        sql.Query("INSERT INTO SEv (key, value) VALUES ('tags', '');")
        sql.Query("INSERT INTO SEv (key, value) VALUES ('title', '');")
        sql.Query("INSERT INTO SEv (key, value) VALUES ('timeadded', '');")
    end
end

-- Update persistent SandEv data
function SHL:UpdatedSEvSQL(addonInfo)
    sql.Query("UPDATE SEv SET value = '" .. addonInfo.updated .. "' WHERE key = 'updated';")
    sql.Query("UPDATE SEv SET value = '" .. addonInfo.file .. "' WHERE key = 'file';")
    sql.Query("UPDATE SEv SET value = '" .. addonInfo.size .. "' WHERE key = 'size';")
    sql.Query("UPDATE SEv SET value = '" .. addonInfo.tags .. "' WHERE key = 'tags';")
    sql.Query("UPDATE SEv SET value = '" .. addonInfo.title .. "' WHERE key = 'title';")
    sql.Query("UPDATE SEv SET value = '" .. addonInfo.timeadded .. "' WHERE key = 'timeadded';")
end

-- Get the addonInfo from the persistent SandEv data
function SHL:GetAddonInfoFromSQL()
    return {
        downloaded = true,
        file = sql.Query("SELECT value FROM SEv WHERE key = 'file';")[1].value,
        models = 0,
        mounted = true,
        size = sql.Query("SELECT value FROM SEv WHERE key = 'size';")[1].value,
        tags = sql.Query("SELECT value FROM SEv WHERE key = 'tags';")[1].value,
        timeadded = sql.Query("SELECT value FROM SEv WHERE key = 'timeadded';")[1].value,
        title = sql.Query("SELECT value FROM SEv WHERE key = 'title';")[1].value,
        updated = tonumber(sql.Query("SELECT value FROM SEv WHERE key = 'updated';")[1].value),
        wsid = SEvWSID
    }
end

-- Send a updated SEv gma to the server if requested
net.Receive("sev_request_gma", function()
    local gmaCopy = file.Open(SEVGMA, "rb", "DATA")
    local callbackName = net.ReadString()

    if gmaCopy then
        local gmaContent = gmaCopy:Read(gmaCopy:Size())
        gmaCopy:Close()

        timer.Simple(0.2, function()
            SendData("sandev_gma", gmaContent, callbackName, nil)
        end)
    end
end)

-- Check if the server cached SEv exists and is updated
-- Request a updated gma otherwise
if SERVER then
    net.Receive("sev_send_addon_info_to_sv", function(len, ply)
        local addonInfo = net.ReadTable()
        local updated = sql.Query("SELECT value FROM SEv WHERE key = 'updated';")[1].value

        if not SEv then
            SHL:UpdatedSEvSQL(addonInfo)
            SHL:AddAddonInfo(addonInfo)
        end

        if not SEv and addonInfo.updated > tonumber(updated) then
            net.Start("sev_request_gma")
            net.WriteString("ReceivedSEvGMA")
            net.Send(ply)
        else
            SHL:MountSEv()
        end
    end)

    net.Receive("sev_get_addon_info_from_sv", function(len, ply)
        local addonInfo = SHL:GetAddonInfoFromSQL()

        net.Start("sev_send_addon_info_to_cl")
        net.WriteTable(addonInfo)
        net.WriteBool(isSEvMounted)
        net.Send(ply)
    end)
end

-- Download the SEv version beign used by the server
function SHL:DownloadSEvFromServer(SVAddonInfo)
    if SERVER then return end

    SHL:ShowLog("Downloading gma from server...")

    -- Register addon info
    SHL:AddAddonInfo(SVAddonInfo)

    -- Save addon info
    SHL:UpdatedSEvSQL(SVAddonInfo)

    -- Request SEv
    net.Start("sev_request_gma")
    net.WriteString("DownloadedSEvFromServer")
    net.SendToServer()
end

-- Load the SEv downloaded from the server
function DownloadedSEvFromServer(gmaContent)
    if SERVER then return end

    -- Save gma content
    SHL:SaveSEvGMA(gmaContent)

    -- Mount SEv
    net.Start("sev_request_mount_on_cl")
    net.SendToServer()
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
        SHL:UpdatedSEvSQL(addonInfo)

        -- Mount SEv
        net.Start("sev_send_addon_info_to_sv")
        net.WriteTable(addonInfo)
        net.SendToServer()
    end)
end

-- Use the local client cached SEv
function SHL:LoadCachedSEv(isMountedOnServer)
    if SERVER then return end

    SHL:ShowLog("Using cached gma")

    -- Register addon info
    local addonInfo = SHL:GetAddonInfoFromSQL()

    SHL:AddAddonInfo(addonInfo)

    -- Mount SEv
    if isMountedOnServer then
        net.Start("sev_request_mount_on_cl")
        net.SendToServer()
    else
        net.Start("sev_send_addon_info_to_sv")
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
    local updated = sql.Query("SELECT value FROM SEv WHERE key = 'updated';")[1].value

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

function StartSEvHotload(enableLogging)
    hotloaderLogging = enableLogging

    -- Check if SEv is already loaded
    if SEv then
        SHL:ShowLog("SandEv is already executing, ignoring hotload")
        return
    end

    -- Initialize persistent data
    SHL:InitSEvSQL()

    -- Set net names

    -- Get the server state and start the hotload
    if CLIENT then
        timer.Simple(0, function()
            net.Start("sev_get_addon_info_from_sv")
            net.SendToServer()
        end)

        net.Receive("sev_send_addon_info_to_cl", function(len, ply)
            local SVAddonInfo = net.ReadTable()
            local isMountedOnSv = net.ReadBool()

            SHL:DownloadSEv(SVAddonInfo, isMountedOnSv)
        end)
    end
end

-- Restore addon info and state after a map changelevel
if SEv then
    local addonInfo = SHL:GetAddonInfoFromSQL()
    SHL:AddAddonInfo(addonInfo)
    isSEvMounted = true
end
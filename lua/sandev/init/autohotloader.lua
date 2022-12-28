--[[
    This hotloader allows SandEv to be included without the need for the player to subscribe to it.

    Only one instance of SandEv will be allowed and the download will only happen if an update is released
    in the workshop.

    To use the hotloader, just include these lines in your shared initialization file (e.g. lua/autorun/mystuff.lua):

    hook.Add("Initialize", "SEv_init", function()
        if SEv then return end
        http.Fetch("https://raw.githubusercontent.com/Xalalau/SandEv/main/lua/sandev/init/autohotloader.lua", function(SEvHotloader)
            RunString(SEvHotloader)
        end)
    end)
]]

local hotloaderLogging = true

local function showLog(log)
    if hotloaderLogging then
        print("[SEvLoader] " .. log)
    end
end

-- Load an entity
local function IncludeEntity(_type, entClass, entBase, filename)
    ENT = {}
    ENT.Folder = _type .. "/" .. entClass

    if _type == "weapons" then
        ENT.Primary = {}
        ENT.Secondary = {}
    end

    local filesIncluded = false

    if isstring(filename) then
        AddCSLuaFile(_type .. "/" .. filename)
        include(_type .. "/" .. filename)
        filesIncluded = true
    else
        if SERVER then
            local files, dirs = file.Find(ENT.Folder .. "/*", "LUA")
            for k, filename in ipairs(files) do
                AddCSLuaFile(ENT.Folder .. "/" .. filename)
            end

            if file.Exists(ENT.Folder .. "/init.lua", "LUA") then
                include(ENT.Folder .. "/init.lua")
                filesIncluded = true
            end
        else
            if file.Exists(ENT.Folder .. "/cl_init.lua", "LUA") then
                include(ENT.Folder .. "/cl_init.lua")
                filesIncluded = true
            end
        end
    end

    if filesIncluded then
        showLog("[Register entity] " .. entClass)

        entBase.Register(ENT, entClass)
        baseclass.Set(entClass, ENT)
    end

    ENT = nil
end

-- Load new sents and sweps
local function HotloadEntities(_type, entBase)
    local files, dirs = file.Find(_type .. "/*", "LUA")

    -- Check for unregistered entities

    -- Files
    for k, filename in ipairs(files) do
        local char1, char2, entClass = string.find(filename, "([%w_]*).lua")

        -- Register new entities
        if not entBase.GetStored(entClass) then
            IncludeEntity(_type, entClass, entBase, filename)
        end
    end

    -- Folders
    for k, entClass in ipairs(dirs) do
        -- Register new entities
        if entClass ~= "gmod_tool" and not entBase.GetStored(entClass) then
            if file.Exists(_type .. "/" .. entClass .. "/init.lua", "LUA") or 
                file.Exists(_type .. "/" .. entClass .. "/cl_init.lua", "LUA")
                then
                IncludeEntity(_type, entClass, entBase, filename)
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
                warning messages about datapack inconsistencies. -- Xalalau
]]
local function HotloadTools()
    SWEP = baseclass.Get('gmod_tool')
    toolObj = getmetatable(SWEP.Tool["axis"])

    local toolModes = file.Find("weapons/gmod_tool/stools/*.lua", "LUA")
    local foundToolsToMount = false

    -- Check for unregistered tools
    for k, filename in ipairs(toolModes) do
        local char1, char2, toolMode = string.find(filename, "([%w_]*).lua")

        -- Register new tools
        if not SWEP.Tool[toolMode] then
            showLog("[Register tool] " .. toolMode)

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

local function HotloadSEv()
    -- Detours
    local initFile = "autorun/sev_init.lua"
    local detourCLIncludeOnSingleplayer = true

    -- AddCSLuaFile detour: helps to debug
    AddCSLuaFileOriginal = AddCSLuaFileOriginal or _G.AddCSLuaFile
    function AddCSLuaFile(path)
        if path == nil then
            path = debug.getinfo(2).short_src
        end

        if file.Exists(path, "LUA") then
            showLog("[AddCSLuaFile] " .. path)
            AddCSLuaFileOriginal(path)
        end
    end

    -- Include detour: helps to debug and workarounds the CLIENT include datapack issue
    includeOriginal = includeOriginal or _G.include
    function include(path)
        if not file.Exists(path, "LUA") or not string.find(path, "([\\/]+)") then
            local fixedPath = string.gsub(string.GetPathFromFilename(debug.getinfo(2).short_src) .. path, "lua/", "")

            if file.Exists(fixedPath, "LUA") then
                path = fixedPath
            end
        end

        if CLIENT and (detourCLIncludeOnSingleplayer or not game.SinglePlayer()) then
            local fileContent = file.Read(path, 'LUA')

            if fileContent then
                showLog("[include cl hack] " .. path)
                RunString(fileContent, path)
            else
                showLog("[include cl hack] FAILED TO INCLUDE " .. path)
            end
        else
            showLog("[include] " .. path)
            includeOriginal(path)
        end
    end

    -- Loading order
    -- https://wiki.facepunch.com/gmod/Lua_Loading_Order

    -- Load all lua files
    include(initFile)

    -- Load new scripted weapons
    HotloadEntities("weapons", weapons)

    -- Load new tools
    HotloadTools()

    -- Load new scripted entities
    HotloadEntities("entities", scripted_ents)

    -- Start SandEv
    timer.Simple(1, function()
        if CLIENT then
            local sev_portal_init = hook.GetTable()["InitPostEntity"]["sev_portal_init"]
            sev_portal_init()
        end

        local sev_init = hook.GetTable()["InitPostEntity"]["sev_init"]
        sev_init()
    end)

    -- Remove detours
    timer.Simple(1.5, function()
        AddCSLuaFile = AddCSLuaFileOriginal
        include = includeOriginal
    end)
end

if SERVER then
    net.Receive("sev_hotload", function(len, ply)
        HotloadSEv()
    end)
end

local function MountSEv(path)
    if SERVER then return end

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
                showLog("[file.Exists]: " .. _file)
                mountedFiles = mountedFiles + 1
            end
        end

        if mountedFiles == #files or retries == 0 then
            net.Start("sev_hotload")
            net.SendToServer()

            timer.Simple(1, function() -- In practice the server runs first, so I'm kinda emulating it here. Idk if it's necessary. -- Xala
                HotloadSEv()
            end)

            timer.Remove(path)
        end

        retries = retries - 1
    end)
end

local function DownloadSEv()
    if SERVER then return end

    showLog("SandEv Auto Hotloader is starting...")

    -- SEv wsid
    local SEvWSID = 2908040257

    -- Initialize persistent data
    if not sql.TableExists("SEv") then
        sql.Query("CREATE TABLE SEv(key TEXT, value TEXT);")
        sql.Query("INSERT INTO SEv (key, value) VALUES ('gma_path', '');")
        sql.Query("INSERT INTO SEv (key, value) VALUES ('version', '');")
    end

    -- Get the last stored values
    local version = sql.Query("SELECT value FROM SEv WHERE key = 'version';")[1].value

    -- Check for GMA updates and download a new version from workshop if needed
    steamworks.FileInfo(SEvWSID, function(result)
        if tostring(result.updated) == version then
            local path = sql.Query("SELECT value FROM SEv WHERE key = 'gma_path';")[1].value

            showLog("Using cached version")
            MountSEv(path)
        else
            showLog("Downloading new version...")
            steamworks.DownloadUGC(SEvWSID, function(path, _file)
                sql.Query("UPDATE SEv SET value = '" .. result.updated .. "' WHERE key = 'version';")
                sql.Query("UPDATE SEv SET value = '" .. path .. "' WHERE key = 'gma_path';")

                MountSEv(path)
            end)
        end
    end)
end

function StartSEvHotload()
    --Check if SEv is already loaded
    if SEv then
        showLog("SandEv is already executing, ignoring hotload")
        return
    end

    if SERVER then
        util.AddNetworkString("sev_hotload")
    else
        DownloadSEv()
    end
end

StartSEvHotload()
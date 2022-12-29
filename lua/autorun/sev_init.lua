--[[
    SandEv or SEv - Sandbox Events System
    'Cause Hammer alone is not enough

    By Xalalau Xubilozo, 2021 - 2023

    Anomaly Research Center (A.R.C.) Exploration, 2022 - 2023
    Revealing and exposing curses.
    Collaborators:
        Zaurzo - https://steamcommunity.com/profiles/76561198809606958

    MIT License
]]




--[[
    -----------------------
    Base Lua file structure
    -----------------------

    -- Initialization file (check the next sections)
    /lua/autorun/customfilename.lua

    -- The base loads the Lua files sequentially, in alphabetical order and from higher to lower folder levels

    -- General Lua file prefixes
         =   No prefix means the file will simply be mounted and available on the server
    sh_  =   Add the file to the server and to the clients
    sv_  =   Add the file to only to the server
    cl_  =   Add the file to only to clients

    e.g.  sv_myluafile.lua

    -- Scripts to run right after the previous base and before the base libs and events
    /lua/autorun/baseluafolder/init/*

    -- Custom libraries
    /lua/autorun/baseluafolder/libs/*

    -- Custom events sorted by tier level
    /lua/autorun/baseluafolder/events/tier*/*

    -- Events files can have these suffixes
         =   No suffix. The event will be loaded on the base aimed maps and on all tiers
    _g   =   global. The event will be loaded on any map
    _t   =   tier. The event will be loaded on the base aimed maps and only when the correct tier is loaded
    _gt  =   global and tier

    e.g.  sv_myevent_g.lua

    ---------------------------------
    Minimal base initialization table
    ---------------------------------

    BASE = {
        id = string base small id,                           -- An small name to be part of commands and internal ids
        luaFolder = string my lua folder,                    -- For events and libs
        dataFolder = string my data folder,                  -- For memories and custom data
        maps = { string some_map_name, ... },                -- List of maps where all events must run. Add "*" to whitelist all maps
        toolCategories = { string my tools category, ... },  -- Create devmove tool categories (they'll appear only when devmode is enabled)
        errorData = {                                        -- Enable the ErrorAPI to collect script errors via http
            databaseName = string database name,
            wsid = string addon workshop id,
            url = string server url,
            patterns = { string pattern },                   -- Usually a folder name from /lua
        },
        enableLobby = boolean enable                         -- Append a copy of the lobby system as BASE.Lobby
        enableEvents = boolean enable                        -- Append a copy of the events system as BASE.Event, BASE.Event.Memory,
                                                             -- BASE.Event.Memory.Incompatibility and BASE.Event.Memory.Dependency
    }

    -----------------------
    Hook the base to SandEv
    -----------------------

    -- Just copy and adapt the following code:

    local function PostInitCallback(isInitialized)
        -- Run code right after the base is completely loaded
        -- if isInitialized the base failed to integrate
    end

    -- Include the base
    hook.Add("SEvInit", BASE.luaFolder .. "_init", function(SEv)
        SEv:IncludeBase(BASE, PostInitCallback)
    end)

    --------------------
    Create custom events
    --------------------

    Refer to
    /lua/sandev/tier1/event_creation_ref.lua
    for more information
]]




SEv = SEv or {
    devMode = false, -- The devMode enables access to SandEv's in-game commands and messages. They are used to control, visualize and create events
    id = "sandev", -- Stores base id
    luaFolder = "sandev", -- Stores events and libs
    dataFolder = "sandev", -- Stores memories and custom data
    bases = {}, -- External bases, using the same structure as SEv table (they'll be loaded into the map)
    toolCategories = { "SandEv Tools" }, -- Devmove tool categories
    errorData = { -- Send addon errors to a server
        databaseName = "sandev",
        wsid = "2908040257",
        url = "https://gerror.xalalau.com",
        patterns = { "sandev" }, -- Folder inside /lua
    },
    Event = { -- Lib to deal with events
        list = {}, -- { [string event name] = function create event, ... }
        loadingOrder = {}, -- { string event name, ... } -- The load order is the file inclusion order
        customEntityList = {}, -- { [string event name] = { [entity ent] = table entity rendering info, ... }, ... }
        gameEntityList = {}, -- { [string event name] = { [entity ent] = bool, ... }, ... }
        Memory = { -- Lib to remember player map progress
            filename = "memories.txt", -- Location to save Memories.List
            path = "", -- Relative memories file path (base.dataFolder + SEv.Event.filename)
            list = {}, -- { [string memory name] = bool is active, ... } -- Controlled on serverside and copied to clientside
            swaped = {}, -- { [string memory name] = nil or last memory value, ... } -- Hold toggled memories values
            Incompatibility = { -- Sublib to block events based on memories
                list = {} -- { [string memory name] = { ["string memory name"] = true, ... }, ... }
            },
            Dependency = { -- Sublib to deal with memory dependencies
                providers = {}, -- { [string event name] = { ["string memory name"] = true, ... } } -- Events that provide memories
                dependents = {} -- { [string event name] = { ["string memory name"] = true, ... } } -- Events that require memories
                -- The above two tables above when crossed produce a dependency logic and evidence errors.
            }
        },
    },
    Addon = {}, -- General addons support
    Custom = {},
    Effect = {},
    Ent = {},
    Workshop = {
        list = {} -- { [string addn wsid] = table engine.GetAddons() addon info, ... }
    },
    Light = {},
    Lobby = {},
    Map = {
        nodesFolder = "nodes",
        nodesCacheFilename = game.GetMap() .. "_nodes.txt", -- File to save the map node positions
        path = "", -- Relative map nodes file path (base.dataFolder + SEv.Map.nodesFolder + "map name _ SEv.Map.filename")
        nodesList, -- { [int index] = Vector position, ... } -- Map node positions
        blockCleanup = false,
        CleanupEntFilter = {} -- { [entity ent] = bool, ... }
    },
    Material = {},
    Net = {
        sendTab = {}, -- { [string chunksID] = int chunksSubID }
        receivedTab = {} -- { [string chunksID] = { chunksSubID = int, compressedString = byte string } }
    },
    NPC = {},
    Ply = {},
    Portals = {
        portalIndex = 0,
        enableFunneling = false
    },
    Prop = {},
    Tool = {
        categoriesPanel,
        bases = {},
        categoryControllers = {}
    },
    Util = {},
    Vehicle = {}
}

-- Define nodes file path
SEv.Map.path = SEv.dataFolder .. "/" .. SEv.Map.nodesFolder .. "/" .. SEv.Map.nodesCacheFilename

if SERVER then
    SEv.Event.lastSentChunksID = nil -- str -- Internal. Prevent older chunks from being uploaded if the map is reloaded

    -- Lobby system (lua/sev/base/sv_lobby.lua):
    SEv.Lobby.servers = { -- We can have multiple server links
    }
    SEv.Lobby.selectedServerDB = ""
    SEv.Lobby.version = "3"
    SEv.Lobby.isEnabled = false
    SEv.Lobby.selectedServerLink = ""
    SEv.Lobby.lobbyChecksLimit = 20
    SEv.Lobby.lobbyChecks = 0
    SEv.Lobby.isNewEntry = true
    SEv.Lobby.gameID = math.random(1, 999) -- Used to identify multiple GMod instances on the same machine. May "fail" rarely but whatever
    SEv.Lobby.printResponses = false -- Flood the console with information returned from the server
    SEv.Lobby.invaderClass = "" -- A class name to process lobby interactions
end

if CLIENT then
    SEv.Event.renderEvent = {} -- { [string event name] = { enabled = bool should render event, [string entID] = { entRenderInfo }, ... } }

    SEv.Lobby.lastPercent = 0

    -- Break lights
    SEv.Addon.spysNightVision = true
    SEv.Addon.NV_ToggleNightVision = nil
end

-- Include code

-- Prefixes:
local prefixes = {
    "sh_",
    "sv_",
    "cl_"
}

-- Load source files
local function HandleFile(filePath, prefix)
    if SERVER then
        if prefix ~= "cl_" then
            include(filePath)
        end

        if prefix ~= "sv_" then
            AddCSLuaFile(filePath)
        end
    end

    if CLIENT then
        if prefix ~= "sv_" then
            include(filePath)
        end
    end
end

local function ReadDir(dir, prefix, isCurrentTier, ignoreSuffixes, isBaseMap)
    local files, dirs = file.Find(dir .. "*", "LUA")
    local selectedFiles = {}

    -- Separate files by type
    for _, file in ipairs(files) do
        if string.sub(file, -4) == ".lua" then
            local filePath = dir .. file

            if string.sub(file, 0, 3) == prefix then
                table.insert(selectedFiles, filePath)
            end
        end
    end

    -- Load separated files
    for _, filePath in ipairs(selectedFiles) do
        -- Check suffixes
        if not ignoreSuffixes then
            if isBaseMap then
                if (string.find(filePath, "_t.", 1, true) or string.find(filePath, "_gt.", 1, true)) and not isCurrentTier then continue end 
            else
                if string.find(filePath, "_gt.", 1, true) then
                    if not isCurrentTier then continue end 
                else
                    if not string.find(filePath, "_g.", 1, true) then continue end
                end
            end
        end

        HandleFile(filePath, prefix)
    end

    -- Open the next directory
    for _, subDir in ipairs(dirs) do
        ReadDir(dir .. subDir .. "/", prefix, isCurrentTier, ignoreSuffixes, isBaseMap)
    end
end

function SEv:IncludeFiles(folder, isCurrentTier, ignoreSuffixes, isBaseMap)
    for _, prefix in ipairs(prefixes) do
        ReadDir(folder, prefix, isCurrentTier, ignoreSuffixes, isBaseMap)
    end
end

-- Add bases
function SEv:IncludeBase(base, PostInitCallback)
    table.insert(SEv.bases, base)
    base.PostInitCallback = PostInitCallback

    if base.id then
        print("[SandEv] Registered " .. base.id .. " base")
    end
end

-- SandEv extra init
local function PostInitCallback(initialized)
    if not initialized then
        SEv = nil
        return
    end
end

-- Bases init
hook.Add("InitPostEntity", "sev_init", function()
    -- Register bases
    hook.Run("SEvInit", SEv)

    -- Check gamemode (sandbox family only)
    local gamemode = gmod.GetGamemode()

    if not gamemode.IsSandboxDerived then
        PostInitCallback(false)

        for k, base in ipairs(SEv.bases) do
            if base.PostInitCallback then
                base.PostInitCallback(false)
            end
        end

        return
    end

    -- Random number generation
    math.randomseed(os.time())

    -- Create nodes folder
    file.CreateDir(SEv.dataFolder .. "/" .. SEv.Map.nodesFolder)

	-- Particles
	game.AddParticles("particles/train_steam.pcf")
	PrecacheParticleSystem("steam_train")

    -- Init SEv
    do
        -- Create data folders
        file.CreateDir(SEv.dataFolder)

        -- Load init functions
        SEv:IncludeFiles(SEv.luaFolder .. "/init/", nil, true)

        -- Register ErrorAPI entries
        local addonData = ErrorAPI:RegisterAddon(SEv.errorData.dataSEvName, SEv.errorData.url, SEv.errorData.patterns, SEv.errorData.wsid)

        if addonData then
            hook.Add(SEv.id .. "_devmode", SEv.luaFolder .. "_control_error_api", function(state)
                addonData.enabled = not state
            end)
        end

        -- Set tool categories
        if CLIENT then
            SEv:RegisterToolCategories(SEv)
        end

        -- Include libs
        SEv:IncludeFiles(SEv.luaFolder .. "/libs/", nil, true)

        -- Initialize libs
        SEv.Workshop:InitializeList()

        if SERVER then
            SEv.Map:LoadGroundNodes()
        else
            timer.Simple(0.4, function() -- Just to be sure
                SEv.Addon:StealSpysNightVisionControl()
            end)
        end

        -- Set devmode
        if SEv.devMode then
            base:EnableDevMode()
        end

        -- Run last initializations
        PostInitCallback(true)

        -- Print message
        print("[SandEv] Loaded itself")
    end

    -- Init bases
    for k, base in ipairs(SEv.bases) do
        -- Initialize net variables
        if SERVER then
            SEv:AddBaseNets(base)
        end
    
        -- Create data folders
        file.CreateDir(base.dataFolder)

        -- Load init functions
        SEv:IncludeFiles(base.luaFolder .. "/init/", nil, true)

        -- Add devMode
        SEv:AddDevModeToBase(base)

        -- Register ErrorAPI entries
        if base.errorData then
            local addonData = ErrorAPI:RegisterAddon(base.errorData.databaseName, base.errorData.url, base.errorData.patterns, base.errorData.wsid)

            if addonData then
                hook.Add(base.id .. "_devmode", base.luaFolder .. "_control_error_api", function(state)
                    addonData.enabled = not state
                end)
            end
        end

        -- Set tool categories
        if CLIENT then
            SEv:RegisterToolCategories(base)
        end

        -- Include libs
        SEv:IncludeFiles(base.luaFolder .. "/libs/", nil, true)

        -- Initialize custom lobby systems
        if base.enableLobby then
            base.Lobby = table.Copy(SEv.Lobby)

            base.Lobby.base = base
        end

        -- Initialize custom event systems
        if base.enableEvents then
            base.Event = table.Copy(SEv.Event)

            base.Event.base = base
            base.Event.Memory.base = base
            base.Event.Memory.Incompatibility.base = base
            base.Event.Memory.Dependency.base = base

            -- Define memories file path
            base.Event.Memory.path = base.dataFolder .. "/" .. SEv.Event.Memory.filename

            base.Event:InitSh(base)
            if SERVER then
                base.Event:InitSv(base)
            else
                base.Event:InitCl(base)
            end

            base.Event.Memory:InitSh(base)
            if SERVER then
                base.Event.Memory:InitSv(base)
            else
                base.Event.Memory:InitCl(base)
            end

            if SERVER then
                base.Event.Memory:Load()
                base.Event:InitializeTier()
            end

            -- Send the server memories at the appropriate time
            if CLIENT then
                net.Start(base.id .. "_ask_for_memories")
                net.SendToServer()

                hook.Add(base.id .. "_memories_received", base.id .. "_initialize_cl_events", function()
                    base.Event:InitializeTier()
                end)
            end
        end

        -- Set devmode
        if base.devMode then
            base:EnableDevMode()
        end

        -- Run last initializations
        if base.PostInitCallback then
            base.PostInitCallback(true)
        end

        -- Print message
        if base.id then
            print("[SandEv] Loaded " .. base.id .. " base")
        end
    end

    -- Lock down some libs (only after they were copied!!)
    SEv.Util:BlockDirectLibCalls(SEv.Lobby)
    SEv.Util:BlockDirectLibCalls(SEv.Event)
    SEv.Util:BlockDirectLibCalls(SEv.Event.Memory)
    SEv.Util:BlockDirectLibCalls(SEv.Event.Memory.Incompatibility)
    SEv.Util:BlockDirectLibCalls(SEv.Event.Memory.Dependency)
end)

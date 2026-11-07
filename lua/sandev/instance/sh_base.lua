AddCSLuaFile()

---@class SandEv.Library
---@field Name string The name of this library.
---@field Instance SandEv.Instance The instance this library is being used on.

---@class SandEv.Instance
---@field ID string The ID of this instance.
---@field Tiers number The amount of event tiers.
---@field Maps? string[] The list of maps to load events in.
---@field AutoIncludeLibraries boolean If this instance's libraries are included automatically.
---@field IN_MAP boolean Whether or not the current map is an event map.
local Instance = {}
SandEv.Base = Instance

Instance.ID = 'sandev'
Instance.Tiers = 1
Instance.AutoIncludeLibraries = true

---This is used internally - although you're able to use it, you probably shouldn't.
---You may be looking for SandEv.Instance:Initialize() instead.
function Instance:Init()
    file.CreateDir(self.ID)

    self._devmode_convar = CreateConVar(
        'devmode_' .. self.ID .. '_enabled',
        '0',
        FCVAR_ARCHIVE + FCVAR_REPLICATED,
        '',
        0,
        1
    )
end

---Creates a new library for a SandEv instance.
---@param baseName? string The name of the library to inherit.
---@return table SandEv.Library
function Instance:Library(baseName)
    local baseLib = Instance[baseName] ---@as SandEv.Library
    local library = {}

    library.Instance = self
    library.IsSandEvLibrary = true
    library.__index = library

    if baseLib then
        setmetatable(library, baseLib)
    end

    return library
end

function Instance:IncludeLibraries()
    local path = self.ID .. '/libs/'
    local files, dirs = file.Find('lua/' .. path .. '*', 'GAME')

    for _, fileName in ipairs(files) do
        SandEv:IncludeFile(path .. fileName)
    end

    for _, dirName in ipairs(dirs) do
        SandEv:IncludeModule(path .. dirName)
    end
end

function Instance:GetMaps()
    local maps = {}

    if self.Maps then
        for k, map in ipairs(self.Maps) do
            maps[k] = map
        end
    end

    return maps
end

function Instance:Print(message)
    print('[' .. self.ID .. '] ' .. message)
end

function Instance:Error(message, noHalt)
    message = '[' .. self.ID .. '] ' .. message
    
    if noHalt then
        return ErrorNoHaltWithStack(message)
    else
        return error(message, 2)
    end
end

function Instance:IsDevModeEnabled()
    return self._devmode_convar:GetBool()
end

---@param callback function
---@param id? string
function Instance:AddDevModeCallback(callback, id)
    cvars.AddChangeCallback(self._devmode_convar:GetName(), callback, id)
end

function Instance:Initialize()
end

-- Load base SandEv libraries

Instance:IncludeLibraries()

return Instance
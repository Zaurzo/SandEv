---@class SandEv.ToolLib : SandEv.Library
local ToolLib = SandEv.Base:Library()
SandEv.Base.Tool = ToolLib

local toolRegistry
local toolObj

local function OnDevModeEnabled(cvarName, old, new)
    if new ~= '1' then return end

    local instanceID = cvarName:match('devmode_(%w+)_')
    local instance = SandEv:GetInstance(instanceID)

    instance.Tool:Load()
end

function ToolLib:Init()
    toolRegistry = toolRegistry or weapons.GetStored('gmod_tool').Tool
    toolObj = toolObj or getmetatable(toolRegistry.axis)

    self.Instance:AddDevModeCallback(OnDevModeEnabled, 'sandev_dev_tools')
end

---@return TOOL
function ToolLib:New()
    local tool = {}

    return setmetatable(tool, toolObj)
end

function ToolLib:Register(id, tool)
    self._tools = self._tools or {}
    self._tools[id] = tool

    toolRegistry[self.Instance.ID .. '_' .. id] = tool
end

function ToolLib:GetAll()
    local tools = {}

    if self._tools then
        for name, tool in pairs(self._tools) do
            tools[name] = tool
        end
    end

    return tools
end

function ToolLib:Load()
    if self._loaded then return end

    if self ~= ToolLib then
        ToolLib:Load()
    end

    local path = self.Instance.ID .. '/tools'
    
    SandEv:IncludeFiles(path)
    SandEv:IncludeModules(path)

    self._loaded = true
end

do return end
if SERVER then return end

---@param toolLib SandEv.ToolLib
local function PopulateTools(toolLib)
    for id, tool in pairs(toolLib:GetAll()) do
        if tool.AddToMenu == false then continue end

        spawnmenu.AddToolMenuOption(
            tool.Tab or 'Main',
            tool.Category or 'New Category',
            id,
            tool.Name or ('#' .. id),
            tool.Command or ('gmod_tool ' .. id),
            tool.ConfigName or id,
            tool.BuildCPanel
        )
    end
end

hook.Add('PopulateToolMenu', 'AddSToolsToMenu', function()
    local populateBaseTools = false

    for _, instance in SandEv:Instances() do
        if instance:IsDevModeEnabled() then
            PopulateTools(instance.Tool)

            populateBaseTools = true
        end
    end

    if populateBaseTools then
        PopulateTools(ToolLib)
    end
end)
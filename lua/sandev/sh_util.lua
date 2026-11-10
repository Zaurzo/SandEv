AddCSLuaFile()

local Util = {}
SandEv.Util = Util

---@class SandEv.Interface
local Interface = {}
Interface.__index = Interface

function Interface:extend()
    return setmetatable({}, self)
end

function Interface:check()
    local missing = {}

    for k in pairs(self._fields) do
        if not self[k] then
            table.insert(missing, k)
        end
    end

    if #missing > 0 then
        table.sort(missing)

        return error('required fields missing: ' .. table.concat(missing, ', '))
    end

    return true
end

function Interface:__newindex(k, v)
    self._fields[k] = v
end

local function InterfaceNewIndex(self, k, v)
    if not self._fields[k] then
        local msg = 'attempt to add field %q not in interface blueprint'
        
        return error(msg:format(k))
    end

    rawset(self, k, v)
end

---@return SandEv.Interface
function Util:Interface()
    local interface = { ---@as SandEv.Interface
        _fields = {},
        __newindex = InterfaceNewIndex
    }

    interface.__index = interface

    return setmetatable(interface, Interface) 
end
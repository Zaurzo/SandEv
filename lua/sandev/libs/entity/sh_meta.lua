---@class SandEv.EntityLib.MetaLib : SandEv.Library
local MetaLib = SandEv.Base:Library()
SandEv.Base.Entity.Meta = MetaLib

local metaTables = {}
local entityMeta = FindMetaTable('Entity')
local getTable = entityMeta.GetTable

local function GetEntityTableMeta(meta)
    local mt = metaTables[meta]

    if mt then
        return mt
    end

    mt = { __index = meta }

    local base = meta.MetaBaseClass

    if base then
        setmetatable(mt, GetEntityTableMeta(base))

        mt = { __index = mt }
    end

    metaTables[meta] = mt

    return mt
end

function MetaLib:Convert(ent, value)
    local meta = getmetatable(ent)
    local tbl = getTable(ent)

    if not value then
        tbl._sev_meta_converted = nil

        -- getmetatable respects the __metatable field
        -- so if the entity is converted it will return the original metatable
        return debug.setmetatable(ent, meta)
    end

    if tbl._sev_meta_converted then
        return self.Instance:Error('entity meta is already converted')
    end

    tbl._sev_meta_converted = true
    
    setmetatable(tbl, GetEntityTableMeta(meta))

    local newMeta = {}

    for k, v in pairs(meta) do
        if k:sub(1, 2) == '__' then
            newMeta[k] = v
        end
    end

    newMeta.__index = tbl
    newMeta.__metatable = meta

    return debug.setmetatable(ent, newMeta)
end

---@return boolean
function MetaLib:IsConverted(ent)
    local tbl = getTable(ent)

    return tbl._sev_meta_converted or false
end

local function RetFalse()
    return false
end

---Sets if IsValid should always return false on the entity.
---Requires the entity to be converted with Entity.Meta:Convert
---@param ent Entity
---@param value boolean
function MetaLib:SetInvalid(ent, value)
    if not self:IsConverted(ent) then
        return self.Instance:Error('entity has not been converted with Entity.Meta:Convert')
    end

    local tbl = getTable(ent)

    tbl.IsValid = value and RetFalse or nil
end
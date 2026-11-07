AddCSLuaFile()

local cheap = {}
local net, util, hook, ents = net, util, hook, ents

if SERVER then
    util.AddNetworkString('netcheap')
end

module('net.cheap')

---@param messageName string
function Start(messageName)
    net.Start('netcheap')
    net.WriteString(messageName)
end

---@param str string
function WriteCompressed(str)
    local data = util.Compress(str)
    local size = #data

    net.WriteUInt(size, 16)
    net.WriteData(data, size)
end

---@param maxSize? number
function ReadCompressed(maxSize)
    local size = net.ReadUInt(16)
    local data = net.ReadData(size)

    return util.Decompress(data, maxSize)
end

---@param ent Entity
function WriteEntity(ent)
    net.WriteUInt(ent:GetCreationID(), 24)
end

local readEntityQueue

if CLIENT then
    readEntityQueue = {}

    hook.Add('NetworkEntityCreated', 'net.cheap.ReadEntity', function(ent)
        local id = ent:GetCreationID()
        local callback = readEntityQueue[id]

        if not callback then return end

        callback(ent)

        readEntityQueue[id] = nil
    end)
end

---@param callback? function
function ReadEntity(callback)
    local creationID = net.ReadUInt(24)
    local readEnt

    for _, ent in ents.Iterator() do
        if ent:GetCreationID() == creationID then
            readEnt = ent
            break
        end
    end

    if not readEnt then
        if CLIENT then
            readEntityQueue[creationID] = callback
        end
    else
        if callback then
            callback(readEnt)
        end
    end

    return readEnt
end

---@param messageName string
---@param callback function
function Receive(messageName, callback)
    cheap[messageName] = callback
end

---@param len number
---@param ply Player
local function ReceiveCheap(len, ply)
    local messageName = net.ReadString()
    local callback = cheap[messageName]

    if callback then
        return callback(len, ply)
    end
end

net.Receive('netcheap', ReceiveCheap)
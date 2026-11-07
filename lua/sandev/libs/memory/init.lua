AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')

include('shared.lua')

local MemoryLib = SandEv.Base.Memory

---Loads the current memory data.
---@realm server
---@return table memories
function MemoryLib:Load()
    local memories = self._memories

    if memories then
        return memories
    end
    
    local json = file.Read(self:GetPath(), 'DATA')

    if json then
        memories = util.JSONToTable(json)
    else
        memories = {}
    end

    self._memories = memories

    return memories
end

---Writes the current memories to disk.
---@realm server
---@return boolean successful
function MemoryLib:Save()
    local memories = self._memories

    if not memories then
        return true
    end

    local json = util.TableToJSON(memories, true)

    return file.Write(self:GetPath(), json)
end

---Sets the value of the specified memory.
---@realm server
---@param memory string
---@param value any
---@return boolean successful
function MemoryLib:Set(memory, value)
    local memories = self:Load()

    memories[memory] = value

    net.cheap.Start('sandev_set_memory')

    net.WriteString(self.Instance.ID)
    net.WriteString(memory)
    net.WriteType(value)
    net.Broadcast()

    return self:Save()
end

net.cheap.Receive('sandev_request_memories', function(len, ply)
    local instanceID = net.ReadString()
    local instance = SandEv:GetInstance(instanceID)

    if not instance then return end

    local internalVarName = '_' .. instanceID .. '_memories_requested'
    if ply[internalVarName] then return end

    local json = file.Read(instance.Memory:GetPath(), 'DATA')

    if not json then
        json = '{}'
    end

    net.cheap.Start('sandev_request_memories')
    net.WriteString(instanceID)
    net.cheap.WriteCompressed(json)
    net.Send(ply)

    ply[internalVarName] = true
end)
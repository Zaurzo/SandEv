include('shared.lua')

local MemoryLib = SandEv.Base.Memory

---Loads the current memory data.
---@realm client
---@return table memories
function MemoryLib:Load()
    local memories = self._memories

    if not memories then
        memories = {}
        self._memories = memories

        self:RequestMemories()
    end

    return memories
end

---Requests the current memory data from the server.
---@realm client
function MemoryLib:RequestMemories()
    net.cheap.Start('sandev_request_memories')
    net.WriteString(self.Instance.ID)
    net.SendToServer()
end

net.cheap.Receive('sandev_set_memory', function()
    local instanceID = net.ReadString()
    local instance = SandEv:GetInstance(instanceID)

    if not instance then return end

    local memory = net.ReadString()
    local memoryValue = net.ReadType()
    local memories = instance.Memory:Load()

    memories[memory] = memoryValue
end)

net.cheap.Receive('sandev_request_memories', function()
    local instanceID = net.ReadString()
    local instance = SandEv:GetInstance(instanceID)

    if not instance then return end

    local json = net.cheap.ReadCompressed()
    if not json then return end

    local receivedMemories = util.JSONToTable(json)
    
    if receivedMemories then
        table.Merge(instance.Memory:Load(), receivedMemories)
    end

    instance._memories_received = true

    hook.Run('sandev_memories_received', instance)
end)
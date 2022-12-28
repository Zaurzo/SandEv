-- Persistent event memories
-- Events can have unlimited memories

-- Send active server memories to clients
function SEv.Event.Memory:ReceiveAllMemories(serverMemories)
    for memoryName, value in pairs(serverMemories) do
        self.list[memoryName] = value
    end
end 

-- Base init
function SEv.Event.Memory:InitCl(base)
    net.Receive(base.id .. "_broadcast_memory", function()
        local memoryName = net.ReadString()
        local doNotRefreshEvents = net.ReadBool()
        local value = util.JSONToTable(net.ReadString())
    
        value = value and unpack(value)
    
        base.Event.Memory:Set(memoryName, value, doNotRefreshEvents, true)
    end)
    
    net.Receive(base.id .. "_broadcast_memories", function()
        base.Event.Memory:ReceiveAllMemories(net.ReadTable())
        hook.Run(base.id .. "_memories_received")
    end)
    

    base.Event.Memory.InitCl = nil
end
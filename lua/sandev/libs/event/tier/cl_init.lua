include('shared.lua')

net.cheap.Receive('sev_instance_tier_changed', function()
    local instanceID = net.ReadString()
    local instance = SandEv:GetInstance(instanceID)

    if not instance then return end

    local oldTier = net.ReadUInt(6)
    local newTier = net.ReadUInt(6)

    instance.Event:RefreshByTier(newTier)

    hook.Run(instanceID .. '_event_tier_changed', oldTier, newTier)
end)
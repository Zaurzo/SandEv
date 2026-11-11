AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')

include('shared.lua')

net.cheap.Receive('sandev_prepare_marker_data', function(len, ply)
    local instanceID = net.ReadString()
    local instance = SandEv:GetInstance(instanceID)

    if not instance then return end

    net.cheap.Start('sandev_marker_data')

    local markers = instance.Entity:FindBasedOn('sev_marker', true)

    for _, marker in ipairs(markers) do
        net.WriteEntity(marker)

        marker:WriteData()
    end

    net.Broadcast()
end)
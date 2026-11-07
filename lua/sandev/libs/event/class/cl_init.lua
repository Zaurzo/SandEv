include('shared.lua')

local EntityLib = SandEv.Base.Event

function EntityLib.Base:DrawGizmos()
end

net.cheap.Receive('sev_change_event_state', function()
    local instanceID = net.ReadString()
    local instance = SandEv:GetInstance(instanceID)

    if not instance then return end

    local eventID = net.ReadString()
    local event = instance.Event:Get(eventID)

    if not event then return end

    local state = net.ReadBool()

    if state then
        event:Enable()
    else
        event:Disable()
    end
end)
include('shared.lua')

local EventLib = SandEv.Base.Event

function EventLib:GetDrawGizmos()
    if self._gizmos_convar ~= nil then
        return self._gizmos_convar:GetBool()
    end

    return false
end

function EventLib:RequestMarkerRenderData()
    if not self:GetDrawGizmos() then return end

    -- so stupid
    timer.Simple(0.01, function()
        net.cheap.Start('sandev_prepare_marker_data')
        net.WriteString(self.Instance.ID)
        net.SendToServer()
    end)
end

function EventLib:DrawGizmos()
    local events = self._events
    if not events or not self:GetDrawGizmos() then return end

    for _, event in pairs(events) do
        if event.Current then
            event.Current:DrawGizmos()
        end
    end
end

---@realm client
function EventLib.OnDrawGizmosChanged(convarName, old, new)
    if new ~= '1' then return end

    local instanceID = convarName:match('(%w+)_')
    local instance = SandEv:GetInstance(instanceID)

    if instance then
        instance.Event:RequestMarkerRenderData()
    end
end

hook.Add('PostDrawTranslucentRenderables', 'identifier', function()
    for _, instance in SandEv:Instances() do
        instance.Event:DrawGizmos()
    end
end)

net.cheap.Receive('sandev_devmode_enabled', function()
    local instanceID = net.ReadString()
    local instance = SandEv:GetInstance(instanceID)

    if instance then
        instance.Event:InstallDevCommands()
    end
end)

net.cheap.Receive('sandev_marker_data', function()
    local marker = net.ReadEntity() ---@as sev_marker

    if marker:IsValid() then
        marker:ReadData()
    end
end)
AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')

include('shared.lua')

function ENT:Setup(event)
    self:SetInstanceID(event.Instance.ID)
    self:SetEvent(event)
    self:Spawn()

    self._markers = {}
    self._connections = {}
end

function ENT:AddMarker(mins, maxs)
    local count = #self._markers
    if count >= 127 then return end

    local markerData = {
        mins = mins,
        maxs = maxs
    }

    return table.insert(self._markers, markerData)
end

function ENT:AddMarkerConnection(markerA, markerB)
    local connectionData = {
        markerA = markerA,
        markerB = markerB
    }

    return table.insert(self._connections, connectionData)
end

function ENT:WriteData()
    local markers = self._markers

    net.WriteUInt(#markers, 7)

    for _, marker in ipairs(markers) do
        net.WriteVector(marker.mins)
        net.WriteVector(marker.maxs)
    end

    local connections = self._connections

    net.WriteUInt(#connections, 7)

    for _, connection in ipairs(connections) do
        net.WriteUInt(connection.markerA, 7)
        net.WriteUInt(connection.markerB, 7)
    end
end
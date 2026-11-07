include('shared.lua')

local MAX_DISTANCE = 1000

function ENT:ReadData()
    local markerData = {}
    local markerCount = net.ReadUInt(7)

    for i = 1, markerCount do
        local mins = net.ReadVector()
        local maxs = net.ReadVector()
        local center = (mins - maxs) / 2 + maxs

        markerData[i] = {
            center = center,
            mins = mins,
            maxs = maxs,
            mesh = self:CreateBoxMesh(mins - center, maxs - center)
        }
    end

    local connectionCount = net.ReadUInt(7)

    for _ = 1, connectionCount do
        local markerA = net.ReadUInt(7)
        local markerB = net.ReadUInt(7)
        local marker = markerData[markerA]

        if marker then
            marker.connections = table.ForceInsert(marker.connections, markerB)
        end
    end

    self._markers = markerData
end

function ENT:DrawConnections(markerA, color)
    local connections = markerA.connections
    if not connections then return end

    for _, markerID in ipairs(connections) do
        local markerB = self._markers[markerID]
        if not markerB then continue end

        render.SetColorMaterial()
        render.DrawBeam(
            markerA.center, 
            markerB.center, 
            1, 1, 1, 
            color
        )
    end
end

function ENT:DrawGizmos()
    local markers = self._markers
    if not markers then return end

    local color = self:GetColor()
    local brushName = self:GetBrushName()
    local pos = self:GetPos()

    for k, marker in ipairs(markers) do
        self:DrawWireframeBox(pos, marker.mins, marker.maxs, color)
        self:DrawBoxMesh(marker.center, marker.mins, marker.maxs, color, marker.mesh)
        self:DrawConnections(marker, color)

        local pos = marker.center
        local distance = EyePos():Distance(pos)
        
        if distance > MAX_DISTANCE then continue end

        if brushName then
            brushName = brushName .. k
        end

        cam.Start2D()
            self:DrawLabels(pos, distance, color, brushName)
        cam.End2D()
    end
end
AddCSLuaFile('shared.lua')
include('shared.lua')

DEFINE_BASECLASS('sev_marker')

AccessorFunc(ENT, '_think_delay', 'ThinkDelay', FORCE_NUMBER)

function ENT:Initialize()
    BaseClass.Initialize(self)
    
    self:SetThinkDelay(0.1)
end

---@param point Vector
---@return int
function ENT:AddPoint(point)
    self._points = self._points or {}

    local size = Vector(10, 10, 10)
    local mins = -size + point
    local maxs = size + point

    self:AddMarker(mins, maxs)

    local pointIndex = #self._points + 1

    if pointIndex > 1 then
        self:AddMarkerConnection(pointIndex - 1, pointIndex)
    end

    self._points[pointIndex] = {
        pos = point,
        mins = mins,
        maxs = maxs
    }
    
    return pointIndex
end

---@return Vector[]
function ENT:GetPoints()
    local points = {}

    for k, point in ipairs(self._points) do
        points[k] = point
    end

    return points
end

---@param ent Entity
function ENT:Follow(ent)
    self._ents = self._ents or {}
    self._ents[ent] = 1

    self:OnPathAdvance(ent, self._points[1])
end

function ENT:Think()
    self:NextThink(CurTime() + self:GetThinkDelay())

    local ents = self._ents
    
    if not ents or table.IsEmpty(ents) then
        return true
    end

    for ent, pointIndex in pairs(ents) do
        if not ent:IsValid() then
            ents[ent] = nil
            break
        end
        
        local point = self._points[pointIndex]

        if ent:GetPos():WithinAABox(point.mins, point.maxs) then
            pointIndex = pointIndex + 1
            point = self._points[pointIndex]

            if not point then
                ents[ent] = nil
                break 
            end

            self:OnPathAdvance(ent, point)
            
            ents[ent] = pointIndex
        end

        self:OnPathThink(ent, point)
    end

    return true
end

---@param ent Entity
---@param point table
function ENT:OnPathAdvance(ent, point)
end

---@param ent Entity
---@param point table
function ENT:OnPathThink(ent, point)
end
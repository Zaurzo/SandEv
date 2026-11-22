AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')

include('shared.lua')

DEFINE_BASECLASS('sev_brush')

local sphericalTriggerList = {}

function ENT:Setup(event, min, max)
    BaseClass.Setup(self, event, min, max)

    self:SetTrigger(true)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(self:GetMins(), self:GetMaxs())
end

---@param event SandEv.Event
---@param radius number
function ENT:SetupSphere(event, pos, radius)
    local size = Vector(radius, radius, radius)
    local mins, maxs = pos + -size, pos + size

    self:Setup(event, mins, maxs)
    self:SetSpherical(true)
    self:SetRadius(radius)

    self._in_sphere = {}

    table.insert(sphericalTriggerList, self)
end

function ENT:OnEnter(ent)
end

function ENT:OnStay(ent)
end

function ENT:OnExit(ent)
end

---@param self sev_trigger
local function IsInSphere(self, ent)
    local pos = self:GetPos()
    local hit = ent:NearestPoint(pos)

    return pos:DistToSqr(hit) <= (self:GetRadius() ^ 2)
end

---@param self sev_trigger
local function SphereThink(self)
    local inSphere = self._in_sphere

    for ent in pairs(inSphere) do
        local valid = ent:IsValid()

        if not valid or not IsInSphere(self, ent) then
            inSphere[ent] = nil

            if valid then
                self:OnExit(ent)
            end
        end
    end

    if table.IsEmpty(inSphere) then
        self.Think = nil
    end

    self:NextThink(CurTime())

    return true
end

function ENT:StartTouch(ent)
    if not self:GetSpherical() then
        return self:OnEnter(ent)
    end
end

function ENT:Touch(ent)
    if not self:GetSpherical() then
        return self:OnStay(ent)
    end

    if not IsInSphere(self, ent) then return end

    local inSphere = self._in_sphere

    if not inSphere[ent] then
        inSphere[ent] = true

        self:OnEnter(ent)
        self:NextThink(CurTime())

        self.Think = SphereThink
    end

    self:OnStay(ent)
end

function ENT:EndTouch(ent)
    if not self:GetSpherical() then
        return self:OnExit(ent)
    end
end

hook.Add('EntityRemoved', 'sev_spherical_triggers', function(ent)
    local class = ent:GetClass()

    if class == 'sev_trigger' or scripted_ents.IsBasedOn(class, 'sev_trigger') then
        local trigger = ent ---@as sev_trigger

        if trigger:GetSpherical() then
            table.RemoveByValue(sphericalTriggerList, trigger)
        end

        return
    end

    for _, trigger in ipairs(sphericalTriggerList) do
        local inSphere = trigger._in_sphere
        if not inSphere[ent] then continue end

        trigger:OnExit(ent)

        inSphere[ent] = nil
    end
end)
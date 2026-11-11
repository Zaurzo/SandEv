AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')

include('shared.lua')

DEFINE_BASECLASS('sev_brush')

---@overload fun(event : SandEv.Event, pos : Vector, radius : number)
function ENT:Setup(event, min, max)
    if isnumber(max) then
        local pos = min
        local radius = max ---@as number
        local size = Vector(radius, radius, radius)

        min, max = pos + -size, pos + size

        self:SetSpherical(true)
        self:SetRadius(radius)

        self._in_sphere = {}
    end

    BaseClass.Setup(self, event, min, max)

    self:SetTrigger(true)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(self:GetMins(), self:GetMaxs())
    self:NextThink(math.huge)
end

---@param self sev_trigger
local function IsInSphere(self, ent)
    local pos = self:GetPos()
    local hit = ent:NearestPoint(pos)

    return pos:DistToSqr(hit) <= (self:GetRadius() ^ 2)
end

function ENT:Think()
    if not self:GetSpherical() then
        return true
    end

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
        self:NextThink(math.huge)
    else
        self:NextThink(CurTime())
    end

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
    end

    self:OnStay(ent)
end

function ENT:EndTouch(ent)
    if not self:GetSpherical() then
        return self:OnExit(ent)
    end
end

function ENT:OnEnter(ent)
end

function ENT:OnStay(ent)
end

function ENT:OnExit(ent)
end
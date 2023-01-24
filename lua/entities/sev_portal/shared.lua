-- Seamless portals addon by Mee
-- You may use this code as a reference for your own projects, but please do not publish this addon as your own.
--        New: Adapted to gm_construct 13 beta as a library, as MIT license and GMod Workshop rules allow.
--          This is by no means an addon reupload, the code has been modified and the rights respected.
--          I also asked permission from the addon creator before doing this.
--              - Xalalau

SEvPortals = {
    portalIndex = 0,
    enableFunneling = false
}

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

-- ENT.Category     = "Seamless Portals"
-- ENT.PrintName    = "Seamless Portal"
-- ENT.Author       = "Mee"
-- ENT.Purpose      = ""
-- ENT.Instructions = ""
ENT.Spawnable    = false

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "ExitPortal")
    self:NetworkVar("Vector", 0, "PortalSize")
    self:NetworkVar("Bool", 0, "DisableBackface")
end

function ENT:LinkPortal(ent)
    if not ent or not ent:IsValid() then return end
    self:SetExitPortal(ent)
    ent:SetExitPortal(self)
end

-- custom size for portal
function ENT:SetExitSize(n)
    self:SetPortalSize(n)
    self:UpdatePhysmesh(n)
end

-- (for older api compatibility)
function ENT:ExitPortal()
    return self:GetExitPortal()
end

function ENT:GetExitSize()
    return self:GetPortalSize()
end

function ENT:IncrementPortal()
    SEvPortals.portalIndex = SEvPortals.portalIndex + 1
end

function ENT:OnRemove()
    SEvPortals.portalIndex = SEvPortals.portalIndex - 1
    if SERVER and self.PORTAL_REMOVE_EXIT then
        SafeRemoveEntity(self:GetExitPortal())
    end
end

-- scale the physmesh
function ENT:UpdatePhysmesh()
    self:PhysicsInit(6)
    if self:GetPhysicsObject():IsValid() then
        local finalMesh = {}
        for k, tri in pairs(self:GetPhysicsObject():GetMeshConvexes()[1]) do
            local pos = tri.pos * self:GetExitSize()
            pos[3] = pos[3] > 0 and 0.5 or -0.5
            table.insert(finalMesh, pos)
        end
        self:PhysicsInitConvex(finalMesh)
        self:EnableCustomCollisions(true)
        self:GetPhysicsObject():EnableMotion(false)
        self:GetPhysicsObject():SetMaterial("glass")
        self:GetPhysicsObject():SetMass(250)

        if CLIENT then 
            local mins, maxs = self:GetModelBounds()
            self:SetRenderBounds(mins * self:GetExitSize(), maxs * self:GetExitSize())
        end
    else
        self:PhysicsDestroy()
        self:EnableCustomCollisions(false)
        print("SEv Portal: Failure to create a portal physics mesh " .. self:EntIndex())
    end
end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end

SEvPortals.PortalIndex = 0 --#ents.FindByClass("sev_portal")
SEvPortals.MaxRTs = 6
SEvPortals.TransformPortal = function(a, b, pos, ang)
    if not a or not b or not b:IsValid() or not a:IsValid() then return Vector(), Angle() end
    local editedPos = Vector()
    local editedAng = Angle()

    if pos then
        editedPos = a:WorldToLocal(pos) * (b:GetExitSize()[1] / a:GetExitSize()[1])
        editedPos = b:LocalToWorld(Vector(editedPos[1], -editedPos[2], -editedPos[3]))
        editedPos = editedPos + b:GetUp()
    end

    if ang then
        local localAng = a:WorldToLocalAngles(ang)
        editedAng = b:LocalToWorldAngles(Angle(-localAng[1], -localAng[2], localAng[3] + 180))
    end

    -- mirror portal
    if a == b then
        if pos then
            editedPos = a:LocalToWorld(a:WorldToLocal(pos) * Vector(1, 1, -1)) 
        end

        if ang then
            local localAng = a:WorldToLocalAngles(ang)
            editedAng = a:LocalToWorldAngles(Angle(-localAng[1], localAng[2], -localAng[3] + 180))
        end
    end

    return editedPos, editedAng
end

function ENT:OnPlyUsage(callback)
    if not isfunction(callback) then return end

    self.plyUsageCallbacks = self.plyUsageCallbacks or {}
    table.insert(self.plyUsageCallbacks, callback)
end

function ENT:RunPlyUsageCallbacks(ply)
    for k, func in ipairs(self.plyUsageCallbacks or {}) do
        func(ply)
    end
end

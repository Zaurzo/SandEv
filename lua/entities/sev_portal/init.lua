AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/hunter/plates/plate2x2.mdl")
    self:SetAngles(self:GetAngles() + Angle(90, 0, 0))
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:PhysWake()
    self:SetMaterial("debug/debugempty")    -- missing texture
    self:SetRenderMode(RENDERMODE_TRANSCOLOR)
    self:SetCollisionGroup(COLLISION_GROUP_WORLD)
    self:DrawShadow(false)
    if self:GetExitSize() == Vector() then
        self:SetExitSize(Vector(1, 1, 1))
    else
        self:SetExitSize(self:GetExitSize())
    end
    SEv.Portals.portalIndex = SEv.Portals.portalIndex + 1
end

function ENT:SpawnFunction(ply, tr)
    local portal1 = ents.Create("sev_portal")
    portal1:SetPos(tr.HitPos + tr.HitNormal * 150)
    portal1:Spawn()

    local portal2 = ents.Create("sev_portal")
    portal2:SetPos(tr.HitPos + tr.HitNormal * 50)
    portal2:Spawn()

    if CPPI then portal2:CPPISetOwner(ply) end

    portal1:LinkPortal(portal2)
    portal2:LinkPortal(portal1)
    portal1.PORTAL_REMOVE_EXIT = true
    portal2.PORTAL_REMOVE_EXIT = true

    return portal1
end

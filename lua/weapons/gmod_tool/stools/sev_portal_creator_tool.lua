TOOL.Category = "SandEv Tools"
TOOL.Name = "#Tool.sev_portal_creator_tool.name"

TOOL.Information = {
    { name = "left" },
    { name = "right1", stage = 1 },
    { name = "right2", stage = 2 }
}

TOOL.LinkTarget = NULL

-- yoink! smiley :)
local function VectorAngle(vec1, vec2)
    local costheta = vec1:Dot(vec2) / (vec1:Length() * vec2:Length())
    local theta = math.acos(costheta)
    return math.deg(theta)
end

function TOOL:GetPlacementPosition(tr)
    if not tr then tr = self:GetOwner():GetEyeTrace() end
    if not tr.Hit then return false end
    -- yoink! smiley :)
    local rotatedAng = tr.HitNormal:Angle() + Angle(90, 0, 0)

    local elevationangle = VectorAngle(vector_up, tr.HitNormal)
    if elevationangle < 1 or (elevationangle > 179 and elevationangle < 181) then 
        rotatedAng.y = self:GetOwner():EyeAngles().y + 180
    end
    --
    return (tr.HitPos + tr.HitNormal * self:GetOwner():GetInfoNum("portal_size_z", 1.1) * 10), rotatedAng
end

function TOOL:GetLinkTarget()
    if ( SERVER ) then
        return self.LinkTarget
    else
        return self:GetOwner():GetNWEntity("pct_linkTarget")
    end
end

if ( CLIENT ) then

    local green = Color(0, 255, 0, 50)

    language.Add("Tool.sev_portal_creator_tool.name", "Portal Creator")
    language.Add("Tool.sev_portal_creator_tool.desc", "Creates and links portals")
    language.Add("Tool.sev_portal_creator_tool.left", "Left Click: Create portal")
    language.Add("Tool.sev_portal_creator_tool.right1", "Right Click: Start linking a portal")
    language.Add("Tool.sev_portal_creator_tool.right2", "Right Click: Create link to another portal")

    -- yoink! smiley :)
    local xVar = CreateClientConVar("portal_size_x", "1", false, true, "Sets the size of the portal along the X axis", 0.01, 15)
    local yVar = CreateClientConVar("portal_size_y", "1", false, true, "Sets the size of the portal along the Y axis", 0.01, 15)
    local zVar = CreateClientConVar("portal_size_z", "1.1", false, true, "Sets the size of the portal along the Z axis", 0.01, 15)
    local backVar = CreateClientConVar("portal_backface", "1", false, true, "Sets whether to spawn with a backface or not", 0, 1)

    function TOOL.BuildCPanel(panel)
        panel:AddControl("label", {
            text = "Creates and links portals. The portals code is derived from 'Seamless Portals', created by 'Mee'.",
        })
        panel:NumSlider("Portal Size X", "portal_size_x", 0.05, 15, 2)
        panel:NumSlider("Portal Size Y", "portal_size_y", 0.05, 15, 2)
        panel:NumSlider("Portal Size Z", "portal_size_z", 0.05, 15, 2)
        panel:CheckBox("Has Backface (Invisible until linked!)", "portal_backface")
    end

    local beamMat = Material("cable/blue_elec")
    function TOOL:DrawHUD()
        local pos, angles = self:GetPlacementPosition()
        if not pos then return end
        --
        cam.Start3D()
            if self:GetStage() == 2 then
                local target = self:GetLinkTarget()
                if IsValid(target) then
                    local from = target:GetPos()
                    local to = pos
                    local tr = self.Owner:GetEyeTrace()
                    -- the tower of if statements
                    if tr.Hit then
                        local ent = tr.Entity
                        if IsValid(ent) then
                            if ent:GetClass() == "sev_portal" then
                                if ent:EntIndex() ~= target:EntIndex() then
                                    to = ent:GetPos()
                                end
                            end
                        end
                    end
                    render.SetMaterial(beamMat)
                    render.DrawBeam(from, to, 3, 0, 1)
                    cam.End3D()
                    return
                end
            end
            local xScale = xVar:GetFloat()
            local yScale = yVar:GetFloat()
            local zScale = zVar:GetFloat()
            render.SetColorMaterial()
            render.DrawBox(pos, angles, Vector(-47.45 * xScale, -47.45 * yScale, -zScale * 10), Vector(47.45 * xScale, 47.45 * yScale, 0), green)
        cam.End3D()
    end

    function TOOL:LeftClick()
        return true
    end

    function TOOL:RightClick()
        return true
    end

elseif ( SERVER ) then

    function TOOL:Deploy()
        self:SetStage(1)
    end

    function TOOL:LeftClick(trace)
        local pos, angles = self:GetPlacementPosition(trace)
        if not pos then return false end
        local ent = ents.Create("sev_portal")
        ent:SetPos(pos)
        ent:SetAngles(angles + Angle(270, 0, 0))
        ent:Spawn()
        if CPPI then ent:CPPISetOwner(self:GetOwner()) end
        -- yoink! smiley
        local sizex = self:GetOwner():GetInfoNum("portal_size_x", 1)
        local sizey = self:GetOwner():GetInfoNum("portal_size_y", 1)
        local sizez = self:GetOwner():GetInfoNum("portal_size_z", 1.1)
        ent:SetExitSize(Vector(sizex, sizey, sizez))
        ent:SetDisableBackface(self:GetOwner():GetInfoNum("portal_backface", 1) == 0)
        cleanup.Add(self:GetOwner(), "props", ent)
        undo.Create("Seamless Portal")
            undo.AddEntity(ent)
            undo.SetPlayer(self:GetOwner())
        undo.Finish()
        return true
    end

    function TOOL:SetLinkTarget(ent)
        self.LinkTarget = ent
        self:GetOwner():SetNWEntity("pct_linkTarget", ent)
    end

    function TOOL:GetTarget(trace)
        if not trace.Hit then return NULL end
        local ent = trace.Entity
        if not ent then return NULL end
        if ent:GetClass() ~= "sev_portal" then return NULL end
        if CPPI then
            if not ent:CPPICanTool(self:GetOwner(), "sev_portal_creator_tool") then return NULL end
        end
        return ent
    end

    function TOOL:RightClick(trace)
        local ent = self:GetTarget(trace)
        if not IsValid(ent) then
            self:SetStage(1)
            return false
        end
        local stage = self:GetStage()
        if (stage <= 1) then
            self:SetLinkTarget(ent)
            self:SetStage(2)
        else
            local linkTarget = self:GetLinkTarget()
            if (ent:EntIndex() == linkTarget:EntIndex()) then
                --[[
                self:SetStage(1)
                return false
                ]]
            end
            -- LinkPortal already contains an IsValid check
            ent:LinkPortal(linkTarget)
            self:SetStage(1)
        end
        return true
    end

end
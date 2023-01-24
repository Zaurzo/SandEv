TOOL.Category = "SandEv Tools"
TOOL.Name = "#Tool.sev_portal_resizer_tool.name"

if CLIENT then
    language.Add("Tool.sev_portal_resizer_tool.name", "Portal Resizer")
    language.Add("Tool.sev_portal_resizer_tool.desc", "Sets the size of portals")
    
    TOOL.ConvarX = CreateClientConVar("portal_size_x", "1", false, true, "Sets the size of the portal along the X axis", 0.01, 15)
    TOOL.ConvarY = CreateClientConVar("portal_size_y", "1", false, true, "Sets the size of the portal along the Y axis", 0.01, 15)
    TOOL.ConvarZ = CreateClientConVar("portal_size_z", "1.1", false, true, "Sets the size of the portal along the Z axis", 0.01, 15)

    TOOL.DisplayX = TOOL.ConvarX:GetInt()
    TOOL.DisplayY = TOOL.ConvarY:GetInt()
    TOOL.DisplayZ = TOOL.ConvarY:GetInt()

    TOOL.Information = {
        {name = "left"},
    }

    language.Add( "Tool.sev_portal_resizer_tool.left", "Sets the size of portals" )

    function TOOL.BuildCPanel(panel)
        panel:AddControl("label", {
            text = "Sets the size of portals. The portals code is derived from 'Seamless Portals', created by 'Mee'.",
        })
        panel:NumSlider("Portal Size X", "portal_size_x", 0.05, 15, 2)
        panel:NumSlider("Portal Size Y", "portal_size_y", 0.05, 15, 2)
        panel:NumSlider("Portal Size Z", "portal_size_z", 0.05, 15, 2)
    end

    local COLOR_GREEN = Color(0, 255, 0, 50)
    function TOOL:DrawHUD()
        local traceTable = util.GetPlayerTrace(self:GetOwner())
        local trace = SEvPortals.TraceLine(traceTable)
        
        if not trace.Entity or not trace.Entity:IsValid() or not trace.Entity.GetClass or trace.Entity:GetClass() ~= "sev_portal" then return end    -- dont draw the world or else u crash lol

        local mins, maxs = trace.Entity:OBBMins(), trace.Entity:OBBMaxs()
        mins[3] = mins[3] * 3
        maxs[3] = 0

        cam.Start3D()
            render.SetColorMaterial()
            render.DrawBox(trace.Entity:GetPos(), trace.Entity:GetAngles(), mins, maxs, COLOR_GREEN)
        cam.End3D()
    end
end

function TOOL:LeftClick(trace)
    local traceTable = util.GetPlayerTrace(self:GetOwner())
    local trace = SEvPortals.TraceLine(traceTable)

    if not trace.Entity or trace.Entity:GetClass() ~= "sev_portal" then return false end
    if CPPI and SERVER then if not trace.Entity:CPPICanTool(self:GetOwner(), "remover") then return false end end
    local sizex = self:GetOwner():GetInfoNum("portal_size_x", 1)
    local sizey = self:GetOwner():GetInfoNum("portal_size_y", 1)
    local sizez = self:GetOwner():GetInfoNum("portal_size_z", 1.1)
    trace.Entity:SetExitSize(Vector(sizex, sizey, sizez))
    return true
end

function TOOL:RightClick(trace)
    local traceTable = util.GetPlayerTrace(self:GetOwner())
    local trace = SEvPortals.TraceLine(traceTable)

    if not trace.Entity or trace.Entity:GetClass() ~= "sev_portal" then return false end
    if CPPI and SERVER then if not trace.Entity:CPPICanTool(self:GetOwner(), "remover") then return false end end
    trace.Entity:SetExitSize(Vector(1, 1, 1))
    return true
end


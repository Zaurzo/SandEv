TOOL.Category = "SandEv Tools"
TOOL.Name = "#Tool.sev_get_normal_pos.name"
TOOL.Command = nil
TOOL.ConfigName = ""
TOOL.Information = {
    { name = "left" },
    { name = "right" },
    { name = "reload" }
}

if CLIENT then
    language.Add("Tool.sev_get_normal_pos.name", "Get Position & Normal")
    language.Add("Tool.sev_get_normal_pos.desc", "Gets the position and normal vectors to 2 decimal places.")
    language.Add("Tool.sev_get_normal_pos.left", "Left Click: Get trace hit position and normal.")
    language.Add("Tool.sev_get_normal_pos.right", "Right Click: Get entity position.")
    language.Add("Tool.sev_get_normal_pos.reload", "Reload: Get your position.")
end

local function PrintPosAndNormal(ply, pos, normal)
    if SERVER then
        ply:ChatPrint("Position: Vector(" .. math.Round(pos.x, 2) .. ", " .. math.Round(pos.y, 2) .. ", ".. math.Round(pos.z, 2) .. ")")

        if normal then
            ply:ChatPrint("Normal: Vector(" .. math.Round(normal.x, 2) .. ", " .. math.Round(normal.y, 2) .. ", ".. math.Round(normal.z, 2) .. ")")
        end
    end
end

function TOOL:LeftClick(trace)
    PrintPosAndNormal(self:GetOwner(), trace.HitPos, trace.HitNormal)
    return true
end
 
function TOOL:RightClick(trace)
    if trace.Entity and not trace.Entity:IsWorld() then
        PrintPosAndNormal(self:GetOwner(), trace.Entity:GetPos())
        return true
    else
        return false
    end
end

function TOOL:Reload(trace)
    PrintPosAndNormal(self:GetOwner(), self:GetOwner():GetPos())
    return false
end

function TOOL.BuildCPanel(pnl)
    pnl:AddControl("Header",{Text = "#Tool.sev_get_normal_pos.name", Description = "#Tool.sev_get_normal_pos.desc"})
end
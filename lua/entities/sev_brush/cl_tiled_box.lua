local TILE = 64

-- Behold, the only AI generated Lua code in this project down below.
-- This mimics the hammer trigger entities when show_triggers is enabled.
-- Note: I only added this because I think it looks cool. I can easily remove it and
-- nothing big would be lost.

local function Quad(pos, s, t)
    mesh.Position(pos)
    mesh.TexCoord(0, s, t)
    mesh.Color(255, 255, 255, 255)
    mesh.AdvanceVertex()
end

local function Face(a, b, c, d, w, h)
    Quad(a, w, h)
    Quad(b, w, 0)
    Quad(c, 0, 0)
    Quad(d, 0, h)
end

local function ChooseTileCounts(dx, dy, dz)
    dx, dy, dz = math.abs(dx), math.abs(dy), math.abs(dz)

    local bestError, bestX, bestY, bestZ = math.huge, 1, 1, 1
    
    for tileSize = TILE * 0.7, TILE * 1.4, TILE * 0.01 do
        local tx = math.max(1, math.Round(dx / tileSize))
        local ty = math.max(1, math.Round(dy / tileSize))
        local tz = math.max(1, math.Round(dz / tileSize))

        local err = math.abs(math.log((dx / tx) / tileSize))
                  + math.abs(math.log((dy / ty) / tileSize))
                  + math.abs(math.log((dz / tz) / tileSize))

        if err < bestError then
            bestError, bestX, bestY, bestZ = err, tx, ty, tz
        end
    end

    return bestX, bestY, bestZ
end

---@param boxMesh IMesh
---@param mins Vector
---@param maxs Vector
local function DrawTiledBox(boxMesh, mins, maxs)
    mins, maxs = Vector(mins), Vector(maxs)

    OrderVectors(mins, maxs)

    local x1, y1, z1 = mins:Unpack()
    local x2, y2, z2 = maxs:Unpack()
    local tx, ty, tz = ChooseTileCounts(x2 - x1, y2 - y1, z2 - z1)

    local c1 = Vector(x1, y1, z1)
    local c2 = Vector(x1, y1, z2)
    local c3 = Vector(x1, y2, z1)
    local c4 = Vector(x1, y2, z2)
    local c5 = Vector(x2, y1, z1)
    local c6 = Vector(x2, y1, z2)
    local c7 = Vector(x2, y2, z1)
    local c8 = Vector(x2, y2, z2)

    mesh.Begin(boxMesh, MATERIAL_QUADS, 6)
        Face(c1, c2, c4, c3, ty, tz)
        Face(c7, c8, c6, c5, ty, tz)
        Face(c5, c6, c2, c1, tx, tz)
        Face(c3, c4, c8, c7, tx, tz)
        Face(c1, c3, c7, c5, tx, ty)
        Face(c2, c6, c8, c4, ty, tx)
    mesh.End()
end

function ENT:CreateBoxMesh(mins, maxs)
    local mesh = Mesh()

    DrawTiledBox(mesh, mins, maxs)

    return mesh
end

local flippedUV = Vector(-1, 1, 1)

function ENT:DrawBoxMesh(pos, mins, maxs, color, boxMesh)
    local alpha = SandEv:GetGizmoAlpha()
    if math.IsNearlyEqual(alpha, 0) then return end

    if not boxMesh then
        boxMesh = self._box_mesh

        if not boxMesh then
            boxMesh = self:CreateBoxMesh(mins, maxs)
            
            self._box_mesh = boxMesh
        end
    end
    
    local matrix = Matrix()

    matrix:SetTranslation(pos)
    matrix:SetAngles(self:GetAngles())

    local texMatrix = Matrix()
    local isInside = EyePos():WithinAABox(pos + self:GetMins(), pos + self:GetMaxs())

    if isInside then
        texMatrix:SetScale(flippedUV)
    end

    local toolMat = SandEv.Base.Material:CreateToolMaterial(self.ToolName)

    toolMat:SetVector('$color2', color:ToVector())
    toolMat:SetFloat('$alpha', alpha)
    toolMat:SetMatrix('$basetexturetransform', texMatrix)

    cam.PushModelMatrix(matrix)
        render.SetMaterial(toolMat)

        toolMat:SetVector('$color2', color:ToVector())
        toolMat:SetFloat('$alpha', alpha)

        if isInside then
            render.CullMode(MATERIAL_CULLMODE_CCW)
        else
            render.CullMode(MATERIAL_CULLMODE_CW)
        end

        boxMesh:Draw()

        render.CullMode(MATERIAL_CULLMODE_CCW)
    cam.PopModelMatrix()
end
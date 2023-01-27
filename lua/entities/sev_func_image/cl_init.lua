include("shared.lua")

function ENT:Initialize()
    self.ready = false 

    local timerName = "sev_init_sprite_" .. tostring(self)
    timer.Create(timerName, 0.1, 60, function()
        if not self:IsValid() then return end
        if self:GetNWVector("vecA") == Vector(0, 0, 0) or self:GetNWVector("vecB") == Vector(0, 0, 0) then return end

        self:SetRenderBoundsWS(self:GetNWVector("vecA"), self:GetNWVector("vecB"))

        self.ready = true

        timer.Remove(timerName)
    end)
end

function ENT:Draw()
    if not SEv or not SEv.Material.FixVertexLitMaterial then return end -- Wait for the autohotloader

    local clientKey = self:GetNWString("clientKey")

    if clientKey ~= "" and not LocalPlayer()[clientKey] then return end

    self:DrawModel()

    if not self.ready then return true end

    if self.material == nil then
        self.material = SEv.Material:FixVertexLitMaterial(self:GetNWString("materialName"))
    end

    if not self.material then return true end

    local pos = self:GetPos()
    local matrix = Matrix()
    matrix:Translate(pos)
    matrix:Rotate(self:GetAngles() + Angle(0, 0, 180))
    matrix:Scale(Vector(self:GetNWInt("height"), 0.01, self:GetNWInt("width")))
  
    local up = Vector(0, 0, 1)
    local right = Vector(1, 0, 0)
    local forward = Vector(0, 1, 0)
  
    local down = up * -1
    local left = right * -1
    local backward = forward * -1

    render.SetMaterial(self.material)
    cam.PushModelMatrix(matrix)
        if not self:GetNWBool("flashlightOnlyMode") then
            mesh.Begin(MATERIAL_QUADS, 6)
                --mesh.QuadEasy(up / 2, up, 1, 1)
                --mesh.QuadEasy(down / 2, down, 1, 1)
        
                --mesh.QuadEasy(left / 2, left, 1, 1)
                --mesh.QuadEasy(right / 2, right, 1, 1)
        
                mesh.QuadEasy(forward / 2, forward, 1, 1)
                --mesh.QuadEasy(backward / 2, backward, 1, 1)
            mesh.End()
        end

        if LocalPlayer():FlashlightIsOn() then
            render.PushFlashlightMode(true)
            mesh.Begin(MATERIAL_QUADS, 6)
                --mesh.QuadEasy(up / 2, up, 1, 1)
                --mesh.QuadEasy(down / 2, down, 1, 1)
        
                --mesh.QuadEasy(left / 2, left, 1, 1)
                --mesh.QuadEasy(right / 2, right, 1, 1)
        
                mesh.QuadEasy(forward * 2, forward, 1, 1)
                --mesh.QuadEasy(backward / 2, backward, 1, 1)
            mesh.End()
            render.PopFlashlightMode()
        end
    cam.PopModelMatrix()
end
include("shared.lua")

function ENT:Think()
    local state = self:GetNWBool("state")

    if not state == true then return end

    local pos = self:GetPos()
    local r = math.Truncate(self:GetNWInt("r"))
    local g = math.Truncate(self:GetNWInt("g"))
    local b = math.Truncate(self:GetNWInt("b"))
    local brightness = self:GetNWInt("brightness")
    local decay = self:GetNWInt("decay")
    local size = self:GetNWInt("size")

    if not pos or not r or not g or not b or not brightness or not decay or not size then return end

    local dlight = DynamicLight(self:EntIndex())

    if dlight then
        dlight.pos = pos
        dlight.r = r
        dlight.g = g
        dlight.b = b
        dlight.brightness = brightness
        dlight.Decay = decay
        dlight.Size = size
        dlight.DieTime = CurTime() + 1
    end
end

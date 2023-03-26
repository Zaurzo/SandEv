AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Setup(instance, eventName, entName, vec, color, decay, size)
    self:Spawn()

    local vecA = vec + Vector(10, 10, 10)
    local vecB = vec - Vector(10, 10, 10)

    self:SetVar("eventName", eventName)
    self:SetVar("entName", entName)
    self:SetVar("vecA", vecA)
    self:SetVar("vecB", vecB)
    self:SetVar("vecCenter", vec)
    self:SetVar("color", Color(255, 255, 255, 255)) -- White

    self:SetPos(vec)

    self:SetNWInt("r", color.r)
    self:SetNWInt("g", color.g)
    self:SetNWInt("b", color.b)
    self:SetNWInt("brightness", color.brightness)
    self:SetNWInt("decay", decay)
    self:SetNWInt("size", size)

    self:SetNWBool("state", true)

    instance.Event:SetRenderInfoEntity(self)
end

function ENT:SetOn(state)
    self:SetNWBool("state", state and true or false)
end

function ENT:GetOn()
    return self:GetNWBool("state")
end

function ENT:GetBrightness()
    return self:GetNWInt("brightness")
end

function ENT:SetBrightness(brightness)
    self:SetNWInt("brightness", brightness)
end

function ENT:GetSize()
    return self:GetNWInt("size")
end

function ENT:SetSize(size)
    self:SetNWInt("size", size)
end

function ENT:GetDecay()
    return self:GetNWInt("decay")
end

function ENT:SetDecay(decay)
    self:SetNWInt("decay", decay)
end

function ENT:GetColor()
    return Color(self:GetNWInt("r"), self:GetNWInt("g"), self:GetNWInt("b"), self:GetNWInt("brightness"))
end

function ENT:SetColor(color)
    self:SetNWInt("r", color.r)
    self:SetNWInt("g", color.g)
    self:SetNWInt("b", color.b)
    self:SetNWInt("brightness", color.brightness)
end

function ENT:Toggle()
    self:SetNWBool("state", not self:GetNWBool("state"))
end

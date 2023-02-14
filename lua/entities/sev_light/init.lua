AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Setup(base, eventName, entName, vec, color, decay, size)
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

    base.Event:SetRenderInfoEntity(self)
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

function ENT:Toggle()
    self:SetNWBool("state", not self:GetNWBool("state"))
end

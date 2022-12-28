-- Trigger hurt

ENT.Base = "base_entity"
ENT.Type = "brush"

function ENT:Setup(base, eventName, entName, vecA, vecB, filterIn, dmg, dmgType, delay)
    dmgType = dmgType or DMG_GENERIC
    delay = delay or 1

    self:Spawn()

    self:SetVar("eventName", eventName)
    self:SetVar("entName", entName)
    self:SetVar("vecA", vecA)
    self:SetVar("vecB", vecB)
    self:SetVar("vecCenter", (vecA - vecB)/2 + vecB)
    self:SetVar("color", Color(252, 119, 3, 255)) -- Orange

    self:SetName(entName)

    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBoundsWS(vecA, vecB)
    self:SetTrigger(true)

    -- everything, npc, bot, player, invehicle, prop
    local filter = {}
    for _, filterType in ipairs(filterIn or {}) do
        filter[filterType] = true
    end

    self:SetVar("filter", filter)
    self:SetVar("dmgType", dmgType)
    self:SetVar("dmg", dmg)
    self:SetVar("delay", delay)

    SEv.Ent:SetCursed(self, true)

    base.Event:SetRenderInfoEntity(self)
end

local waitNextDamage

function ENT:Touch(ent)
    if not ent:IsValid() then return end
    if waitNextDamage then return end

    local filter = self:GetVar("filter")

    if filter.everything or
       filter.player and ent:IsPlayer() or
       filter.npc and ent:IsNPC() or
       filter.bot and ent:IsBot() or
       filter.prop and ent:GetClass() and string.find(ent:GetClass(), "prop_")
       then

        if ent.Health then
            if ent.InVehicle and ent:InVehicle() and not filter.vehicle then
                return
            end

            local d = DamageInfo()
            d:SetDamage(self:GetVar("dmg"))
            d:SetAttacker(self)
            d:SetDamageType(self:GetVar("dmgType")) 
        
            ent:TakeDamageInfo(d)

            waitNextDamage = true

            timer.Simple(self:GetVar("delay"), function()
                waitNextDamage = false
            end)
        end
    end
end

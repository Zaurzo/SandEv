AddCSLuaFile('shared.lua')

include('shared.lua')

local EntityLib = SandEv.Base.Event

---Sets the event tier.
---@realm server
---@param tier number
function EntityLib:SetTier(tier)
    self._forced_tier_change = true
    self._tier_cvar:SetInt(tier)
end

---Sets a tier to be unreachable.
---@realm server
---@param tier number
---@param unreachable boolean
function EntityLib:SetTierUnreachable(tier, unreachable)
    self._unreachable_tiers = self._unreachable_tiers or {}
    self._unreachable_tiers[tier] = unreachable and true or nil
end

---Sets the memory the specified tier depends on to be reached.
---@realm server
---@param tier number
---@param memory string
function EntityLib:SetTierMemoryDependency(tier, memory)
    self._tier_dependencies = self._tier_dependencies or {}
    self._tier_dependencies[tier] = memory
end

---Returns true if the player can reach the specified tier.
---@realm server
---@param tier number
---@return boolean reachable
function EntityLib:IsTierReachable(tier)
    if self._unreachable_tiers and self._unreachable_tiers[tier] then
        return false
    end

    local memory = self._tier_dependencies and self._tier_dependencies[tier]

    if memory then
        return self.Instance.Memory:Get(memory) and true or false
    end

    return true
end

---Returns the max possible event tier the player can reach.
---@realm server
---@return number maxTier
function EntityLib:GetMaxPossibleTier()
    local maxTier = 1

    for tier = 2, self:GetMaxTier() do
        if not self:IsTierReachable(tier) then
            break
        end

        maxTier = tier
    end

    return maxTier
end

---Called when the instance's tier convar is changed.
---This is callback used for cvars.AddChangeCallback
---@param convarName string
---@param oldValue string
---@param newValue string
function EntityLib.OnTierChanged(convarName, oldValue, newValue)
    local instanceID = convarName:match('^(%w+)_')
    local instance = SandEv:GetInstance(instanceID)

    if not instance then return end

    local oldTier = tonumber(oldValue)
    local newTier = tonumber(newValue)

    if instance.Event._forced_tier_change then
        instance.Event._forced_tier_change = nil

        return
    end

    if not instance.Event:IsTierReachable(newTier) and not instance:IsDevModeEnabled() then
        instance:Print('You do not have enough power to switch to this tier.')

        instance.Event:SetTier(oldTier)

        return
    end

    if SERVER then
        net.cheap.Start('sev_instance_tier_changed')
        net.WriteString(instanceID)
        net.WriteUInt(oldTier, 6)
        net.WriteUInt(newTier, 6)
        net.Broadcast()
    end

    instance.Event:RefreshByTier(newTier)
    instance:Print('Switched to tier ' .. newTier .. '.')

    game.CleanUpMap()

    hook.Run(instanceID .. '_event_tier_changed', oldTier, newTier)
end
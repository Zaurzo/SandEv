local EntityLib = SandEv.Base.Event

---Returns the current event tier.
---@realm shared
---@return number
function EntityLib:GetTier()
    return self._tier_cvar:GetInt()
end

---Returns the max event tier.
---@realm shared
---@return number
function EntityLib:GetMaxTier()
    return self.Instance.Tiers
end

---@param tier number
function EntityLib:RefreshByTier(tier)
    for _, event in ipairs(self:GetList()) do
        if event:GetTier() <= tier then
            event:Enable()
        else
            event:Disable()
        end
    end
end
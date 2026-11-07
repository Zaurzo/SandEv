local EventLib = SandEv.Base.Event

---Returns the current event tier.
---@realm shared
---@return number
function EventLib:GetTier()
    return self._tier_cvar:GetInt()
end

---Returns the max event tier.
---@realm shared
---@return number
function EventLib:GetMaxTier()
    return self.Instance.Tiers
end

---@param tier number
function EventLib:RefreshByTier(tier)
    for _, event in ipairs(self:GetList()) do
        if event:GetTier() <= tier then
            event:Enable()
        else
            event:Disable()
        end
    end
end
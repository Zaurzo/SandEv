-- Manage detours

SEv_gameCleanUpMap = SEv_gameCleanUpMap or game.CleanUpMap

-- Cleanup

function SEv.Map:IsCleanupBlocked()
    return self.blockCleanup
end

function SEv.Map:BlockCleanup(value)
    self.blockCleanup = value
end

function SEv.Map:BlockEntCleanup(ent, value)
    self.CleanupEntFilter[ent] = value
end

function game.CleanUpMap(dontSendToClients, extraFilters)
    if SEv.Map:IsCleanupBlocked() then return end

    local processedClasses = {}
    for ent, isBlocked in pairs(SEv.Map.CleanupEntFilter) do
        if ent:IsValid() then
            local class = ent:GetClass()

            if not processedClasses[class] then
                processedClasses[class] = true

                for k, ent in ipairs(ents.FindByClass(class)) do
                    if not SEv.Map.CleanupEntFilter[ent] then
                        ent:Remove()
                    end
                end
            end
        else
            SEv.Map.CleanupEntFilter[ent] = nil
        end
    end

    if not istable(extraFilters) then
        extraFilters = {}
    end

    for class in pairs(processedClasses) do
        table.insert(extraFilters, class)
    end

    SEv_gameCleanUpMap(dontSendToClients, extraFilters)
end

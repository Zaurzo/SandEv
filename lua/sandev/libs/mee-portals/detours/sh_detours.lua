-- detours so stuff go through portals

-- bullet detour
hook.Add("EntityFireBullets", "sev_portal_detour_bullet", function(entity, data)
    if not SEv.Portals or SEv.Portals.portalIndex < 1 then return end

    local tr = SEv.Portals.TraceLine({start = data.Src, endpos = data.Src + data.Dir * data.Distance, filter = entity})
    local hitPortal = tr.Entity

    if not hitPortal:IsValid() then return end

    if SEv.Ent:GetRealClass(hitPortal) == "sev_portal" and hitPortal:GetExitPortal() and hitPortal:GetExitPortal():IsValid() then
        if (tr.HitPos - hitPortal:GetPos()):Dot(hitPortal:GetUp()) > 0 then
            local newPos, newAng = SEv.Portals.TransformPortal(hitPortal, hitPortal:GetExitPortal(), tr.HitPos, data.Dir:Angle())

            --ignoreentity doesnt seem to work for some reason
            data.IgnoreEntity = hitPortal:GetExitPortal()
            data.Src = newPos
            data.Dir = newAng:Forward()
            data.Tracer = 0

            return true
        end
    end
end)

-- effect detour (Thanks to WasabiThumb)
SEv_UtilEffect = SEv_UtilEffect or util.Effect
local function effect(effectName, effectData, allowOverride, ignorePredictionOrRecipientFilter)
     if SEv.Portals.portalIndex > 0 and (effectName == "phys_freeze" or effectName == "phys_unfreeze") then return end

    -- Note: other addons make a lot of mistakes and the script errors end up coming from
    -- inside my map through no fault of mine, so I decided to validate the arguments.
    if not isstring(effectName) then
        print("ERROR!! util.Effect effectName must be a string!")
    elseif SEv.Util:Type(effectData) ~= "CEffectData" then
        print("ERROR!! util.Effect effectData must be a CEffectData object!")
    elseif allowOverride ~= nil and not isbool(allowOverride) then
        print("ERROR!! util.Effect allowOverride must be a boolean!")
    else
        SEv_UtilEffect(effectName, effectData, allowOverride, ignorePredictionOrRecipientFilter)
        return
    end

    print(debug.traceback())
end
util.Effect = effect

-- super simple traceline detour
SEv.Portals.TraceLine = SEv.Portals.TraceLine or util.TraceLine
local function editedTraceLine(data)
    local tr = SEv.Portals.TraceLine(data)

    if tr.Entity:IsValid() and
       SEv.Ent:GetRealClass(tr.Entity) == "sev_portal" and
       tr.Entity:GetExitPortal() and
       tr.Entity:GetExitPortal():IsValid() and
       tr.Entity ~= tr.Entity:GetExitPortal()
           then

        local hitPortal = tr.Entity

        if tr.HitNormal:Dot(hitPortal:GetUp()) > 0 then
            local editeddata = table.Copy(data)

            editeddata.start = SEv.Portals.TransformPortal(hitPortal, hitPortal:GetExitPortal(), tr.HitPos)
            editeddata.endpos = SEv.Portals.TransformPortal(hitPortal, hitPortal:GetExitPortal(), data.endpos)
            -- filter the exit portal from being hit by the ray

            if IsValid(data.filter) and IsEntity(data.filter) and data.filter:GetClass() ~= "player" then
                editeddata.filter = {data.filter, hitPortal:GetExitPortal()}
            else
                if istable(editeddata.filter) then
                    table.insert(editeddata.filter, hitPortal:GetExitPortal())
                else
                    editeddata.filter = hitPortal:GetExitPortal()
                end
            end

            return SEv.Portals.TraceLine(editeddata)
        end
    end

    return tr
end

-- use original traceline if there are no portals
timer.Create("sev_portals_traceline", 1, 0, function()
    if SEv.Portals.portalIndex > 0 then
        util.TraceLine = editedTraceLine
    else
        util.TraceLine = SEv.Portals.TraceLine    -- THE ORIGINAL TRACELINE
    end
end)
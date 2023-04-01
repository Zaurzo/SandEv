-- Auxiliar functions to create complex scenes

-- Create a path using sev_trigger_path_point and a table of vectors
local pathIndex = 0
function SEv.Custom:CreatePath(instance, pathVecs, eventName, postionTouchCallback, lastPositionTouchCallback)
    if CLIENT then return end

    local pathEnts = {}
    local curIndex = pathIndex

    for k,_ in ipairs(pathVecs) do
        local connectionVec

        if pathVecs[k + 1] then
            local vecA = pathVecs[k + 1] + Vector(5, 5, 10)
            local vecB = pathVecs[k + 1] - Vector(5, 5, 0)

            connectionVec = (vecA - vecB)/2 + vecB
        end

        local pathEnt = ents.Create("sev_trigger_path_point")
        pathEnt:Setup(instance, eventName, eventName .. "_path_" .. curIndex .. "_" .. k, pathVecs[k], connectionVec)

        table.insert(pathEnts, pathEnt)

        function pathEnt:StartTouch(ent)
            if ent:IsValid() then
                local curVec = pathVecs[k]
                local nextVec = pathVecs[k + 1]

                if nextVec then
                    if postionTouchCallback then
                        postionTouchCallback(ent, curVec, nextVec)
                    end
                else
                    if lastPositionTouchCallback then
                        lastPositionTouchCallback(ent, curVec)
                    end
                end
            end
        end
    end

    pathIndex = pathIndex + 1

    return pathEnts
end

-- Proximity trigger
function SEv.Custom:CreateProximityTrigger(instance, eventName, baseEnt, relTriggerPos, height, size, callbackStartTouch, callbackTouch, callbackEndTouch)
    if not isfunction(callbackStartTouch) and not isfunction(callbackTouch) and not isfunction(callbackEndTouch) then return end
    relTriggerPos = relTriggerPos or Vector(0, 0, 0)

    local absTriggerPos = baseEnt:GetPos() + relTriggerPos
    if not baseEnt.proximityTrigger then
        baseEnt.proximityTrigger = {}
    end

    local proximityTrigger = ents.Create("sev_trigger")
    local proximityTriggerId = "sev_proximity_trigger_" .. tostring(proximityTrigger)

    local function SetVeryNearTriggerPos(proximityTrigger)
        proximityTrigger:Setup(instance, eventName, "proximityTrigger" .. tostring(proximityTrigger), absTriggerPos + Vector(size, size, height), absTriggerPos + Vector(-size, -size, 0))
    end

    SetVeryNearTriggerPos(proximityTrigger)
    proximityTrigger:SetParent(baseEnt)

    if isfunction(callbackStartTouch) then
        proximityTrigger["StartTouch"] = function (self, touchingEnt)
            if baseEnt:IsValid() then
                callbackStartTouch(self, touchingEnt)
            end
        end
    end

    if isfunction(callbackTouch) then
        proximityTrigger["Touch"] = function (self, touchingEnt)
            if baseEnt:IsValid() then
                callbackTouch(self, touchingEnt)
            end
        end
    end

    if isfunction(callbackEndTouch) then
        proximityTrigger["EndTouch"] = function (self, touchingEnt)
            if baseEnt:IsValid() then
                callbackEndTouch(self, touchingEnt)
            end
        end
    end

    local lastPos = baseEnt:GetPos()
    timer.Create(proximityTriggerId, 0.2, 0, function()
        if not baseEnt:IsValid() or not proximityTrigger:IsValid() then
            timer.Remove(proximityTriggerId)
            return
        end

        local pos = baseEnt:GetPos()
        if lastPos ~= pos then
            lastPos = pos
            absTriggerPos = baseEnt:GetPos() + relTriggerPos
            SetVeryNearTriggerPos(proximityTrigger)
        end
    end)

    proximityTrigger:CallOnRemove(proximityTriggerId, function()
        instance.Event:RemoveRenderInfoEntity(proximityTrigger)
    end)

    table.insert(baseEnt.proximityTrigger, proximityTrigger)
end

--[[
    Creates portal areas to redirect the players

    ---------------------------------------------------------------------
    eventName
    ---------------------------------------------------------------------
    
    Hooks the function entities to an event. It's a string.

    ---------------------------------------------------------------------
    maxAreaTriggersInfo
    ---------------------------------------------------------------------

    The areas where the player must be in to keep the portals open. They should encompass
    the portals themselves, the portals maximum range areas and the portals activation triggers.
 
    Declaration of an area:
        local maxAreaTriggersInfo = { 
            {
                -- Trigger info
            }
        }

    Declaration of multiple areas:
        local maxAreaTriggersInfo = { {}, {} }, { {}, {} }, ...

    The maximum delay the player can stay outside these areas is 0.2s, otherwise the portals close.

    Trigger information:
        vecA = Vector -- Point A of the rectangular area
        vecB = Vector -- Point B of the rectangular area

    Example:
        local maxAreaTriggersInfo = { -- A large area that encompasses the two portals, the walkable area and the opening triggers.
            {
                vecA = Vector(-5280.03, 1256.76, -302.77),
                vecB = Vector(2543.71, 1471.97, -16.68)
            }
        }

    ---------------------------------------------------------------------
    startTriggersInfo
    ---------------------------------------------------------------------

    Areas where the player passes and which can open portals.
    They must be encompassed by at least 1 maxAreaTriggersInfo trigger.
 
    Declaration of an area:
        local startTriggersInfo = { 
            {
                -- Trigger info
            }
        }

    Declaration of multiple areas
        local startTriggersInfo = { {}, {} }, { {}, {} }, ...

    The maximum delay the players can stay outside these areas is 0.3s, otherwise the portals close.

    Trigger information:
        vecA = Vector,         -- Point A of the rectangular area
        vecB = Vector,         -- Point B of the rectangular area
        probability = integer  -- Probability between 1 and 100 that the port will be opened

    Example:
        local startTriggersInfo = {
            {
                vecA = Vector(-5278.67, 1291.79, -303.97),
                vecB = Vector(-5266.05, 1471.97, -176.87),
                probability = 15
            },
            {
                vecA = Vector(1616.12, 1279.69, -303.97),
                vecB = Vector(1775.74, 1264.36, -176.03),
                probability = 15
            }
        }

    ---------------------------------------------------------------------
    portalInfo
    ---------------------------------------------------------------------
    
    Configures multiple portals.
    They must be encompassed by at least 1 maxAreaTriggersInfo trigger.

    To connect two portals just declare them in pairs:
        local portalInfo = { 
            {
                -- Portal info 1
            },
            {
                -- Portal info 2
            } 
        }

    It's also possible to create a mirror by declaring a single portal:
        local portalInfo = {
            {
                -- Portal info, will be considered a mirror
            }
        }

    We can declare many portals and mirrors at once:
    Portals:
        local portalInfo = { {}, {} }, { {}, {} }, ...
    Mirrors:
        local portalInfo = { {} }, { {} }, ...

    This is the portal information:
        pos = Vector                -- Center position
        ang = Angle                 -- Angle
        sizeX = float               -- Scale X
        sizeY = float               -- Scale Y
        sizeZ = float               -- Scale Z
        maxUsage = integer          -- The maximum number of times a portal or mirror can be passed through before it closes on its own
        disableRender = bool        -- Default false. Don't render the portal. Useful in perfectly similar environments or to use over map mirrors
        disablePropTeleport = bool  -- Default false. If props will be teleported
        enableFunneling = bool      -- Default false. If players will be pulled to the portal

    Portal example:
        local portalInfo = {
            {
                {
                    pos = Vector(-4127.908203, 5387.442871, 649.233459),
                    ang = Angle(90, 90, 180),
                    sizeX = 1.2,
                    sizeY = 2.35,
                    sizeZ = 1.1, -- Mee recommended me 1.1 for portals that act as static map props
                    maxUsage = 2 -- The player must only enter this side a maximum of two times.
                },
                {
                    pos = Vector(-4127.845703, 5386.560059, 1161.220459),
                    ang = Angle(90, -90, 180),
                    sizeX = 1.2,
                    sizeY = 2.35,
                    sizeZ = 1.1
                }
            }
        }

    Mirror example:
        local portalInfo = {
        {
            {
                pos = Vector(-2063.768555, -2062, -286.152008),
                ang = Angle(90, -90, 180),
                sizeX = 2.14,
                sizeY = 12.87,
                sizeZ = 1.1,
                disableRender = true -- Positioned on top of the map mirror
            }
        }

    ---------------------------------------------------------------------
    callbacks
    ---------------------------------------------------------------------

    Callback functions to help assemble the events.
        local callbacks = {
            -- Functions
        }

    Functions:
        startCondition = function(ply) -- Call before testing the portal chance. If not true the portal will be ignored
        startPortals = function(ply) -- Call once if portals open (Remember that portals only open with 1 player in the maximum area)
        endPortals = function(ply)   -- Call once when portals close
        plyEnterMaxAreas = function(ply) -- Call once when a player enters the max portal areas
        plyExitMaxAreas = function(ply)  -- Call once when a player exits the max portal areas

    Example:
        local callbacks = {
            startPortals = function(ply)
                ply:Flashlight(false)
                ply:AllowFlashlight(false)
            end,
            plyEnterMaxAreas = function(ply)
                ply:Flashlight(false)
                ply:AllowFlashlight(false)
            end,
            plyExitMaxAreas = function(ply)
                ply:AllowFlashlight(true)
            end,
            endPortals = function(ply)
                ply:GodDisable()
                ply:Kill()
            end
        }

    --------------------

    Returns: table createdEnts

    Enjoy,
    - Xalalau
]]
function SEv.Custom:CreatePortalAreas(instance, eventName, maxAreaTriggersInfo, startTriggersInfo, portalInfo, callbacks)
    local portals = {}
    local plysInMaxArea = {} -- States: nil: outside, true: inside, false: exiting
    local arePortalsEnabled = false
    local canClosePortals = false
    local createdEnts = {}
    local extraId = #ents.FindByClass("sev_portal")

    local function deleteAllPortalEntities(ent)
        for k, ent in ipairs(createdEnts) do
            if ent:IsValid() then
                instance.Event:RemoveRenderInfoEntity(ent)
                ent:Remove()
            end
        end
    end

    local function closePortals(ent)
        if not canClosePortals then return end

        canClosePortals = false

        for k, portal in ipairs(portals) do
            if portal:IsValid() then
                portal:Remove()
            end
        end

        if callbacks and isfunction(callbacks.endPortals) then
            callbacks.endPortals(ent)
        end

        portals = {}
    end

    for k, portalPair in ipairs(portalInfo) do
        local portal1Marker = ents.Create("sev_marker")
        portal1Marker:Setup(instance, eventName, eventName .. "Portal1MarkerPair" .. k  .. "_" .. extraId, portalPair[1].pos)
        table.insert(createdEnts, portal1Marker)

        if portalPair[2] then
            local portal2Marker = ents.Create("sev_marker")
            portal2Marker:Setup(instance, eventName, eventName .. "Portal2MarkerPair" .. k  .. "_" .. extraId, portalPair[2].pos)
            table.insert(createdEnts, portal2Marker)
        end
    end

    for k, startTriggerInfo in ipairs(startTriggersInfo) do
        local portalTrigger = ents.Create("sev_trigger")
        portalTrigger:Setup(instance, eventName, eventName .. "PortalTrigger" .. k  .. "_" .. extraId, startTriggerInfo.vecA, startTriggerInfo.vecB)
        table.insert(createdEnts, portalTrigger)

        function portalTrigger:StartTouch(ent)
            if table.Count(plysInMaxArea) > 1 then return end
            if #portals > 0 then return end
            if not ent:IsPlayer() then return end

            if callbacks and isfunction(callbacks.startCondition) then
                if not callbacks.startCondition(ent) then
                    return
                end
            end

            if math.random(1, 100) <= startTriggerInfo.probability then
                arePortalsEnabled = true

                for k, portalPair in ipairs(portalInfo) do
                    local portal1Usage = 0

                    local portal1 = ents.Create("sev_portal")
                    table.insert(createdEnts, portal1)
                    portal1:SetPos(portalPair[1].pos)
                    portal1:Spawn()
                    portal1:SetAngles(portalPair[1].ang)
                    portal1:SetExitSize(Vector(portalPair[1].sizeX, portalPair[1].sizeY, portalPair[1].sizeZ))
                    portal1:OnPlyUsage(function(ply)
                        if portalPair[1].maxUsage then
                            portal1Usage = portal1Usage + 1

                            if portal1Usage == portalPair[1].maxUsage then
                                timer.Simple(2, function()
                                    closePortals(ply)
                                    deleteAllPortalEntities(ent)
                                end)
                            end
                        end
                    end)
                    SEv.Ent:BlockPhysgun(portal1, true)
                    instance.Event:RegisterEntity(eventName, portal1)
                    table.insert(portals, portal1)

                    if isbool(portalPair[1].disablePropTeleport) then
                        portal1:SetNWBool("disablePropTeleport", portalPair[1].disablePropTeleport)
                    end
                    if isbool(portalPair[1].enableFunneling) then
                        portal1:SetNWBool("enableFunneling", portalPair[1].enableFunneling)
                    end
                    if isbool(portalPair[1].disableRender) then
                        portal1:SetNWBool("disableRender", portalPair[1].disableRender)
                    end

                    local portal2
                    if portalPair[2] then
                        SEv.Ent:HideInfo(portal1, true)

                        local portal2Usage = 0

                        portal2 = ents.Create("sev_portal")
                        table.insert(createdEnts, portal2)
                        portal2:SetPos(portalPair[2].pos)
                        portal2:Spawn()
                        portal2:SetAngles(portalPair[2].ang)
                        portal2:SetExitSize(Vector(portalPair[2].sizeX, portalPair[2].sizeY, portalPair[2].sizeZ))
                        portal2:OnPlyUsage(function(ply)
                            if portalPair[2].maxUsage then
                                portal2Usage = portal2Usage + 1
    
                                if portal2Usage == portalPair[2].maxUsage then
                                    timer.Simple(2, function()
                                        closePortals(ply)
                                        deleteAllPortalEntities(ent)
                                    end)
                                end
                            end
                        end)
                        SEv.Ent:BlockPhysgun(portal2, true)
                        SEv.Ent:HideInfo(portal2, true)
                        instance.Event:RegisterEntity(eventName, portal2)
                        table.insert(portals, portal2)

                        if isbool(portalPair[2].disablePropTeleport) then
                            portal2:SetNWBool("disablePropTeleport", portalPair[2].disablePropTeleport)
                        end
                        if isbool(portalPair[2].enableFunneling) then
                            portal2:SetNWBool("enableFunneling", portalPair[2].enableFunneling)
                        end
                        if isbool(portalPair[2].disableRender) then
                            portal2:SetNWBool("disableRender", portalPair[2].disableRender)
                        end
                    else
                        SEv.Ent:SetFakeClass(portal1, "func_reflective_glass")
                        SEv.Ent:BlockToolgun(portal1, true)
                    end

                    portal1:LinkPortal(portal2 or portal1)
                    portal1.PORTAL_REMOVE_EXIT = true
                    if portal2 then
                        portal2.PORTAL_REMOVE_EXIT = true
                    end
                end

                if callbacks and isfunction(callbacks.startPortals) then
                    callbacks.startPortals(ent)
                    canClosePortals = true
                end
            end
        end
    end

    for k, maxAreaTriggerInfo in ipairs(maxAreaTriggersInfo) do
        local maxAreaTrigger = ents.Create("sev_trigger")
        maxAreaTrigger:Setup(instance, eventName, eventName .. "MaxAreaTrigger" .. k  .. "_" .. extraId, maxAreaTriggerInfo.vecA, maxAreaTriggerInfo.vecB)
        table.insert(createdEnts, maxAreaTrigger)

        function maxAreaTrigger:StartTouch(ent)
            if not ent:IsPlayer() then return end

            if arePortalsEnabled and plysInMaxArea[ent] == nil and callbacks and isfunction(callbacks.plyEnterMaxAreas) then
                callbacks.plyEnterMaxAreas(ent)
            end

            plysInMaxArea[ent] = true
        end

        function maxAreaTrigger:Touch(ent)
            if not ent:IsPlayer() then return end

            if not plysInMaxArea[ent] then
                plysInMaxArea[ent] = true
            end
        end

        function maxAreaTrigger:EndTouch(ent)
            if not ent:IsPlayer() then return end

            plysInMaxArea[ent] = false

            timer.Simple(0.3, function() -- The time a player has to move from a maxAreaTrigger to another
                if not maxAreaTrigger:IsValid() then return end

                if arePortalsEnabled and not plysInMaxArea[ent] and callbacks and isfunction(callbacks.plyExitMaxAreas) then
                    callbacks.plyExitMaxAreas(ent)
                end

                if not plysInMaxArea[ent] then
                    plysInMaxArea[ent] = nil
                end

                if arePortalsEnabled and table.Count(plysInMaxArea) == 0 and #portals > 0 then
                    closePortals(ent)
                end
            end)
        end
    end

    return createdEnts
end
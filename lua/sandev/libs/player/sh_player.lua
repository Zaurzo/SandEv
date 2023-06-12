-- Get the closest player

function SEv.Ply:GetClosestPlayer(pos, dist)
    local plys = player.GetHumans()

    if #plys == 0 then return end

    local curPly, curPlyPos
    local curDist = dist or math.huge

    for i = 1, #plys do
        local ply = plys[i]
        local plyPos = ply:GetPos()
        local dist = pos:DistToSqr(plyPos)

        if dist < curDist then
            curPly = ply
            curPlyPos = plyPos
            curDist = dist
        end
    end

    if curPly and IsValid(curPly) then
        curDist = pos:Distance(curPlyPos)
    end
    
    return curPly, curDist
end

-- Get all players in sphere
function SEv.Ply:GetPlayersInSphere(origin, radius)
    local players = player.GetHumans()
    local radiusSqr = radius * radius or 1000
    local results = {}
    for _, player in ipairs(players) do
        local distanceSqr = (player:GetPos() - origin):LengthSqr()
        if distanceSqr <= radiusSqr then
            table.insert(results, player)
        end
    end
    return results
end
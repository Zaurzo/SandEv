-- Get the closest player

function SEv.Ply:GetClosestPlayer(pos)
    local plys = player.GetHumans()

    if #plys == 0 then return end

    local curPly, curPlyPos
    local curDist = math.huge

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

-- Send huge 
function SEv.Net:SendString(string, callbackName, ply)
    local chunksID = util.MD5(string)
    local chunksSubID = SysTime()
    local compressedString = util.Compress(string)
    local totalSize = string.len(compressedString)
    local chunkSize = 64000 -- 64KB (Max value: 64KB. Min value: 11KB (so we get a min 0.1s delay on 1MBps cap speed))
    local totalChunks = math.ceil(totalSize / chunkSize)
    local maxSpeed = chunkSize / 1000 / 1024 -- 1 MBps

    -- 3 minutes to remove possible memory leaks
    sendTab[chunksID] = chunksSubID
    timer.Create(chunksID, 180, 1, function()
        sendTab[chunksID] = nil
    end)

    for i = 1, totalChunks, 1 do
        local startByte = chunkSize * (i - 1) + 1
        local remaining = totalSize - (startByte - 1)
        local endByte = remaining < chunkSize and (startByte - 1) + remaining or chunkSize * i
        local chunk = string.sub(compressedString, startByte, endByte)

        timer.Simple(i * maxSpeed, function()
            if sendTab[chunksID] ~= chunksSubID then return end

            local isLastChunk = i == totalChunks

            net.Start("sev_net_send_string")
            net.WriteString(chunksID)
            net.WriteUInt(sendTab[chunksID], 32)
            net.WriteUInt(#chunk, 16)
            net.WriteData(chunk, #chunk)
            net.WriteBool(isLastChunk)
            if isLastChunk then
                net.WriteString(callbackName)
            else
                net.WriteString("")
            end
            if ply then
                net.Send(ply)
            else
                net.Broadcast()
            end

            if isLastChunk then
                sendTab[chunksID] = nil
            end
        end)
    end
end

net.Receive("sev_net_send_string", function()
    local chunksID = net.ReadString()
    local chunksSubID = net.ReadUInt(32)
    local len = net.ReadUInt(16)
    local chunk = net.ReadData(len)
    local isLastPart = net.ReadBool()
    local callbackName = net.ReadString() -- Empty until isLastPart is true.

    -- Initialize streams or reset overwriten ones
    if not SEv.Net.receivedTab[chunksID] or SEv.Net.receivedTab[chunksID].chunksSubID ~= chunksSubID then
        SEv.Net.receivedTab[chunksID] = {
            chunksSubID = chunksSubID,
            compressedString = ""
        }

        -- 3 minutes to remove possible memory leaks
        timer.Create(chunksID, 180, 1, function()
            SEv.Net.receivedTab[chunksID] = nil
        end)
    end

    -- Rebuild the compressed string
    SEv.Net.receivedTab[chunksID].compressedString = SEv.Net.receivedTab[chunksID].compressedString .. chunk

    -- Finish stream
    if isLastPart then
        local decompressedString = util.Decompress(SEv.Net.receivedTab[chunksID].compressedString)
        _G[callbackName](decompressedString)
    end
end)

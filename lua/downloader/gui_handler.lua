local MODULE = {}
MODULE.Order = 9

if GetConVar("downloader_gui_enabled"):GetBool() then
    util.AddNetworkString("uwd_exchange_scan_result")
    util.AddNetworkString("uwd_set_manual_selection")

    local subContext = {}

    -- Send huge binary
    local sendTab = {}
    local function SendData(chunksID, data, toPly)
        local chunksSubID = SysTime()

        local totalSize = string.len(data)
        local chunkSize = 64000 -- ~64KB max
        local totalChunks = math.ceil(totalSize / chunkSize)

        -- 3 minutes to remove possible memory leaks
        sendTab[chunksID] = chunksSubID
        timer.Create(chunksID, 180, 1, function()
            sendTab[chunksID] = nil
        end)

        for i = 1, totalChunks, 1 do
            local startByte = chunkSize * (i - 1) + 1
            local remaining = totalSize - (startByte - 1)
            local endByte = remaining < chunkSize and (startByte - 1) + remaining or chunkSize * i
            local chunk = string.sub(data, startByte, endByte)

            timer.Simple(i * 0.1, function()
                if sendTab[chunksID] ~= chunksSubID then return end

                local isLastChunk = i == totalChunks

                net.Start("uwd_exchange_scan_result")
                net.WriteString(chunksID)
                net.WriteUInt(sendTab[chunksID], 32)
                net.WriteUInt(#chunk, 16)
                net.WriteData(chunk, #chunk)
                net.WriteBool(isLastChunk)
                if SERVER then
                    if toPly then
                        net.Send(toPly)
                    else
                        net.Broadcast()
                    end
                else
                    net.SendToServer()
                end

                if isLastChunk then
                    sendTab[chunksID] = nil
                end
            end)
        end
    end

    net.Receive("uwd_exchange_scan_result", function(len, ply)
        local scanResult = table.Copy(subContext.scanResult)

        for wsid, value in pairs(subContext.manualAddons) do
            if scanResult[wsid] then
                scanResult[wsid].cachedManual = value
            end
        end

        scanResult =  util.Compress(util.TableToJSON(scanResult))

        SendData(tostring(ply), scanResult, ply)
    end)

    net.Receive("uwd_set_manual_selection", function(len, ply)
        if not ply:IsAdmin() then return end

        local wsid = tonumber(net.ReadString())
        local value = net.ReadBool()

        local cacheFile = subContext.dataFolder .. "/workshop_cache.txt"
        local cache = util.JSONToTable(file.Read(cacheFile, "DATA") or "{}") or {}

        cache[wsid] = cache[wsid] or {}
        cache[wsid].manual = value

        subContext.manualAddons[wsid] = value

        file.Write(cacheFile, util.TableToJSON(cache))
    end)

    function MODULE:Run(context)
        subContext.scanResult = table.Copy(context.scanResult)
        subContext.manualAddons = table.Copy(context.manualAddons)
        subContext.dataFolder = context.dataFolder
    end
end

return MODULE
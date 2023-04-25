local MODULE = {}
MODULE.Order = 9

local subContext = {}

net.Receive("uwd_exchange_scan_result", function(len, ply)
    local scanResult = table.Copy(subContext.scanResult)

    for wsid, value in pairs(subContext.manualAddons) do
        if scanResult[wsid] then
            scanResult[wsid].cachedManual = value
        end
    end

    scanResult = util.TableToJSON(scanResult)

    net.Start("uwd_exchange_scan_result")
    net.WriteString(scanResult) -- Lazy
    net.Send(ply)
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

return MODULE
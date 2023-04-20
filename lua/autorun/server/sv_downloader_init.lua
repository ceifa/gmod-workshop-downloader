if game.SinglePlayer() then
    return
end

util.AddNetworkString("uwd_exchange_scan_result")
util.AddNetworkString("uwd_set_manual_selection")

local files = file.Find("downloader/*.lua", "LUA")
local modules = {}

for _, moduleFile in ipairs(files) do
    table.insert(modules, include("downloader/" .. moduleFile))
end

table.sort(modules, function(a, b)
    if a.Order == nil or b.Order == nil then
        return a.Order ~= nil
    end

    return a.Order < b.Order
end)

local context = {
    dataFolder = "uwd",
    addons = engine.GetAddons(),
    ignoreResources = {},
    usingAddons = {},
    started = SysTime(),
    gamemodeAddons = {},
    addonsToCache = {},
    manualAddons = {},
    scanResult = {}
}

if not file.Exists(context.dataFolder, "DATA") then
    file.CreateDir(context.dataFolder)
end

net.Receive("uwd_exchange_scan_result", function(len, ply)
    local scanResult = table.Copy(context.scanResult)

    for wsid, value in pairs(context.manualAddons) do
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

    local cacheFile = context.dataFolder .. "/workshop_cache.txt"
    local cache = util.JSONToTable(file.Read(cacheFile, "DATA") or "{}") or {}

    cache[wsid] = cache[wsid] or {}
    cache[wsid].manual = value

    file.Write(cacheFile, util.TableToJSON(cache))
end)

for _, downloaderModule in ipairs(modules) do
    if downloaderModule.Run then
        downloaderModule:Run(context)
    end
end

-- Garbage collection will clean everything by itself after execution
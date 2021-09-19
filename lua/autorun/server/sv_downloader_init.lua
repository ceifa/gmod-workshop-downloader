if game.SinglePlayer() then
    return
end

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
    track = {},
    started = SysTime(),
    gamemodeAddons = {},
    addonsToCache = {}
}

if not file.Exists(context.dataFolder, "DATA") then
    file.CreateDir(context.dataFolder)
end

for _, downloaderModule in ipairs(modules) do
    if downloaderModule.Run then
        downloaderModule:Run(context)
    end
end

-- Garbage collection will clean everything by itself after execution
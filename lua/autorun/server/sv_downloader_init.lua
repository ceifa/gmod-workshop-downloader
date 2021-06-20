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
    addons = engine.GetAddons(),
    ignoreResources = {},
    usingAddons = {},
    track = {},
    started = SysTime()
}

print("[DOWNLOADER] SCANNING " .. #context.addons .. " ADDONS TO ADD RESOURCES...")

for _, downloaderModule in ipairs(modules) do
    if downloaderModule.Run then
        downloaderModule:Run(context)
    end
end

for _, usingAddon in ipairs(context.usingAddons) do
    resource.AddWorkshop(usingAddon.wsid)
    print(string.format("[DOWNLOADER] [+] %-10s %s", usingAddon.wsid, usingAddon.title))
end

print("[DOWNLOADER] FINISHED TO ADD RESOURCES: " .. #context.usingAddons .. " ADDONS SELECTED")

-- Garbage collection will clean everything by itself after execution
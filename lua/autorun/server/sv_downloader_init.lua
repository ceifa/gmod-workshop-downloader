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
    started = SysTime(),
    gamemodeAddons = {},
    addonsToCache = {}
}

if not file.Exists(context.dataFolder, "DATA") then
    file.CreateDir(context.dataFolder)
end

local function ExecuteModule(index)
    local downloaderModule = modules[index]

    if downloaderModule.Condition then
        if not downloaderModule:Condition(context) then
            timer.Simple(0.2, function()
                ExecuteModule(index)
            end)

            return
        end
    end

    if downloaderModule.Run then
        downloaderModule:Run(context)
    end

    if modules[index + 1] then
        ExecuteModule(index + 1)
    end
end

ExecuteModule(1)

-- Garbage collection will clean everything by itself after execution
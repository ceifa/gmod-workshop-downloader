local MODULE = {}
MODULE.Order = 2

local currentMap = game.GetMap()

local function GetMapFiles(addonTitle)
    return file.Find("maps/*.bsp", addonTitle) or {}
end

local function IsUsingSomeMap(mapFiles)
    for _, mapFile in ipairs(mapFiles) do
        if string.StripExtension(mapFile) == currentMap then return true end
    end

    return false
end

function MODULE:Run(context)
    for _, addon in ipairs(context.addons) do
        local mapFiles = GetMapFiles(addon.title)

        if #mapFiles > 0 then
            if IsUsingSomeMap(mapFiles) then
                table.insert(context.usingAddons, addon)
            end

            -- Is probably a map addon, resources should be ignored
            table.insert(context.ignoreResources, addon.wsid)
        end
    end
end

return MODULE
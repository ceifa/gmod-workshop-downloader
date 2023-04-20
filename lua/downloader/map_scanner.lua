local MODULE = {}
MODULE.Order = 4

local currentMap = game.GetMap()

function MODULE:Run(context)
    for _, addon in ipairs(context.addons) do
        local isMap = addon.tags and addon.tags:lower():find("map")

        if isMap then
            if file.Exists("maps/" .. currentMap  .. ".bsp", addon.title) then
                table.insert(context.usingAddons, addon)
                context.scanResult[addon.wsid] = { selected = true, type = "Current map" }
            else
                context.scanResult[addon.wsid] = { selected = false, type = "Map or map content" }
            end

            -- Is probably a map addon, resources should be ignored
            context.ignoreResources[addon.wsid] = true
        end
    end
end

return MODULE
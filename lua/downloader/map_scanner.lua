local MODULE = {}
MODULE.Order = 4

local currentMap = game.GetMap()

function MODULE:Run(context)
    for _, addon in ipairs(context.addons) do
        local isMap = addon.tags and addon.tags:lower():find("map")

        if isMap then
            -- file.Exists does not work here
            local mapFile = file.Find("maps/" .. currentMap  .. ".bsp", addon.title)
            if #mapFile == 1 then
                table.insert(context.usingAddons, addon)
            end

            -- Is probably a map addon, resources should be ignored
            context.ignoreResources[addon.wsid] = true
        end
    end
end

return MODULE
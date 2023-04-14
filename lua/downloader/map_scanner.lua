local MODULE = {}
MODULE.Order = 4

local currentMap = game.GetMap()

function MODULE:Run(context)
    local foundMap = false

    for _, addon in ipairs(context.addons) do
        local isMap = addon.tags and addon.tags:lower():find("map")

        if isMap then
            if file.Exists("maps/" .. currentMap  .. ".bsp", addon.title) then
                foundMap = true

                table.insert(context.usingAddons, addon)

                http.Fetch('https://steamcommunity.com/sharedfiles/filedetails/?id=' .. addon.wsid,
                function(body)
                    for wsid in string.gmatch(body, '<a href="https://steamcommunity%.com/workshop/filedetails/%?id=(%d+)" target="_blank">') do
                        context.ignoreResources[wsid] = false
                    end
                    context.mapInfoFinished = true
                end,
                function()
                    context.mapInfoFinished = true
                end)
            end

            -- Is probably a map addon, resources should be ignored
            context.ignoreResources[addon.wsid] = true
        end
    end

    if not foundMap then
        context.mapInfoFinished = true
    end
end

return MODULE
local MODULE = {}
MODULE.Order = 2

local currentGamemode = engine.ActiveGamemode()

local function IsCurrentGamemode(gamemodeFolders, addonTitle)
    local totalGamemodeFiles = 0

    for _, gamemodeFolder in ipairs(gamemodeFolders) do
        if gamemodeFolder == currentGamemode then
            return true
        end

        -- file.Exists does not work here
        local gamemodeFiles = file.Find("gamemodes/" .. gamemodeFolder .. "/*.txt", addonTitle)

        totalGamemodeFiles = totalGamemodeFiles + #gamemodeFiles

        for _, gamemodeFile in ipairs(gamemodeFiles) do
            if gamemodeFile == currentGamemode then
                return true
            end
        end
    end

    return totalGamemodeFiles == 0 and nil or false
end

function MODULE:Run(context)
    for _, addon in ipairs(context.addons) do
        -- Does not support wildcard on folders :(
        local _, gamemodeFolders = file.Find("gamemodes/*", addon.title)

        if #gamemodeFolders > 0 then
            -- true if it's current gamemode
            -- false if it's a gamemode but not the current
            -- nil if it's a false positive, probably not a gamemode
            local isCurrentGamemode = IsCurrentGamemode(gamemodeFolders, addon.title)
            if isCurrentGamemode ~= nil then
                if isCurrentGamemode then
                    table.insert(context.usingAddons, addon)
                end

                -- Is probably a gamemode addon, resources should be ignored
                context.ignoreResources[addon.wsid] = true
            end
        end
    end
end

return MODULE
local MODULE = {}
MODULE.Order = 1

local currentGamemode = engine.ActiveGamemode()

local function IsUsingGamemode(gamemodeFolders, addonTitle)
    for _, gamemodeFolder in ipairs(gamemodeFolders) do
        -- file.Exists does not work here
        local gamemodeFiles = file.Find("gamemodes/" .. gamemodeFolder .. "/" .. currentGamemode .. ".txt", addonTitle)

        if #gamemodeFiles == 1 then
            return true
        end
    end

    return false
end

function MODULE:Run(context)
    local gamemodeFound = false

    for _, addon in ipairs(context.addons) do
        -- Does not support wildcard on folders :(
        local _, gamemodeFolders = file.Find("gamemodes/*", addon.title)

        if #gamemodeFolders > 0 then
            if not gamemodeFound and IsUsingGamemode(gamemodeFolders, addon.title) then
                table.insert(context.usingAddons, addon)
                gamemodeFound = true
            end

            -- Is probably a gamemode addon, resources should be ignored
            context.ignoreResources[addon.wsid] = true
        end
    end
end

return MODULE
local MODULE = {}
MODULE.Order = 1

local currentGamemode = engine.ActiveGamemode()

local function IsUsingGamemode(gamemodeFolders, addonTitle)
    for _, gamemodeFolder in ipairs(gamemodeFolders) do
        local gamemodeFiles = file.Find("gamemodes/" .. gamemodeFolder .. "/" .. currentGamemode .. ".txt", addonTitle)

        if #gamemodeFiles > 0 then
            return true
        end
    end

    return false
end

function MODULE:Run(context)
    for _, addon in ipairs(context.addons) do
        -- Does not support wildcard on folders :(
        local _, gamemodeFolders = file.Find("gamemodes/*", addon.title)

        if #gamemodeFolders > 0 then
            if IsUsingGamemode(gamemodeFolders, addon.title) then
                table.insert(context.usingAddons, addon)
            end

            -- Is probably a gamemode addon, resources should be ignored
            table.insert(context.ignoreResources, addon.wsid)
        end
    end
end

return MODULE
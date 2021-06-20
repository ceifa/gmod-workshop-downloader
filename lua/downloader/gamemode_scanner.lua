local MODULE = {}
MODULE.Order = 1

local installedGamemodes = engine.GetGamemodes()
local currentGamemode = engine.ActiveGamemode()

local function GetGamemodesName(addonTitle)
    local _, gamemodeFolders = file.Find([[gamemodes/*]], addonTitle)
    local gamemodes = {}

    if gamemodeFolders and #gamemodeFolders > 0 then
        for _, gamemodeFolder in ipairs(gamemodeFolders) do
            local gamemodeFiles = file.Find("gamemodes/" .. gamemodeFolder .. "/*.txt", addonTitle)

            for _, gamemodeFile in ipairs(gamemodeFiles) do
                local gamemodeName = string.StripExtension(gamemodeFile)

                for _, installedGamemode in ipairs(installedGamemodes) do
                    if installedGamemode.name == gamemodeName then
                        table.insert(gamemodes, gamemodeName)
                    end
                end
            end
        end
    end

    return gamemodes
end

local function IsUsingSomeGamemode(gamemodeNames)
    for _, gamemodeName in ipairs(gamemodeNames) do
        if gamemodeName == currentGamemode then return true end
    end

    return false
end

function MODULE:Run(context)
    for _, addon in ipairs(context.addons) do
        local gamemodesName = GetGamemodesName(addon.title)

        if #gamemodesName > 0 then
            if IsUsingSomeGamemode(gamemodesName) then
                table.insert(context.usingAddons, addon)
            end

            -- Is probably a gamemode addon, resources should be ignored
            table.insert(context.ignoreResources, addon.wsid)
        end
    end
end

return MODULE
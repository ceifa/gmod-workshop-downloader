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

function MODULE:Run()
    local gamemodeFound = false

    for _, addon in ipairs(self.context.addons) do
        local isGamemode = addon.tags and addon.tags:lower():find("gamemode")

        if isGamemode then
            if not gamemodeFound then
                -- Does not support wildcard on folders :(
                local _, gamemodeFolders = file.Find("gamemodes/*", addon.title)

                if IsUsingGamemode(gamemodeFolders, addon.title) then
                    table.insert(self.context.usingAddons, addon)
                    gamemodeFound = true
                end
            end

            -- Is probably a gamemode addon, resources should be ignored
            self.context.ignoreResources[addon.wsid] = true
        end
    end
end

return MODULE
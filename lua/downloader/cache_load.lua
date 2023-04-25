local MODULE = {}
MODULE.Order = 2

function MODULE:Run(context)
    local cacheFile = context.dataFolder .. "/workshop_cache.txt"
    local cache = util.JSONToTable(file.Read(cacheFile, "DATA") or "{}") or {}

    for _, addon in ipairs(context.addons) do
        -- tonumber because of https://github.com/Facepunch/garrysmod-issues/issues/3561#issuecomment-428479149
        local scanned = cache[tonumber(addon.wsid)]

        -- cache exists and is up to date?
        if scanned and scanned.updated == addon.updated then
            if scanned.hasResource then
                table.insert(context.usingAddons, addon)
                context.addonsToCache[addon.wsid] = true
                context.scanResult[addon.wsid] = { selected = true, type = "Resources" }
            else
                context.scanResult[addon.wsid] = { selected = false, type = "Lua" }
            end

            context.ignoreResources[addon.wsid] = true
            context.gamemodeAddons[addon.wsid] = scanned.isGamemode
            context.manualAddons[addon.wsid] = scanned.manual
        end
    end

    context.cacheQuantity = table.Count(cache)
end

return MODULE
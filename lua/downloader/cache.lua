local MODULE = {}
MODULE.Priority = 3

function MODULE:Run(context)
    -- cache = { [number wsid] = number updated, ... }
    local cacheFile = context.dataFolder .. "/workshop_cache.txt"
    local cache = file.Exists(cacheFile, "DATA") and util.JSONToTable(file.Read(cacheFile, "DATA")) or {}

    for _, addon in ipairs(context.addons) do
        local scanned = cache[tonumber(addon.wsid)]
        local lastUpdate = addon.updated
        
        if scanned == lastUpdate then
            table.insert(context.cache, addon)
        else
            cache[addon.wsid] = lastUpdate
        end
    end

    file.Write(cacheFile, util.TableToJSON(cache))
end

return MODULE
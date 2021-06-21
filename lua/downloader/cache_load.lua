local MODULE = {}
MODULE.Order = 3

function MODULE:Run(context)
    -- cache = { [number wsid] = { bool isResource, string updated }, ... }
    local cacheFile = context.dataFolder .. "/workshop_cache.txt"
    local cache = util.JSONToTable(file.Read(cacheFile, "DATA") or "{}")

    for _, addon in ipairs(context.addons) do
        local scanned = cache[tonumber(addon.wsid)] -- BUG: JSONToTable loads wsid as a number instead of a string

        if scanned then
            if scanned.isResource then
                if scanned.updated == addon.updated then
                    table.insert(context.usingAddons, addon)
                    table.insert(context.ignoreResources, addon.wsid)
                end
            else
                table.insert(context.ignoreResources, addon.wsid)
            end
        end
    end

    file.Write(cacheFile, util.TableToJSON(cache))
end

return MODULE
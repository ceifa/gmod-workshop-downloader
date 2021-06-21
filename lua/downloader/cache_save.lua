local MODULE = {}
MODULE.Order = 5

function MODULE:Run(context)
    -- cache = { [number wsid] = { bool isResource, string updated }, ... }
    local cacheFile = context.dataFolder .. "/workshop_cache.txt"
    local cache = {}

    for _, addon in ipairs(context.addons) do
        cache[addon.wsid] = {
            isResource = table.HasValue(context.usingAddons, addon),
            updated = addon.updated
        }
    end

    file.Write(cacheFile, util.TableToJSON(cache))
end

return MODULE
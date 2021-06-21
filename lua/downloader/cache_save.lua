local MODULE = {}
MODULE.Order = 5

function MODULE:Run()
    -- cache = { [number wsid] = { bool hasResource, string updated }, ... }
    local cacheFile = self.context.dataFolder .. "/workshop_cache.txt"
    local cache = {}

    for _, addon in ipairs(self.context.addons) do
        cache[addon.wsid] = {
            hasResource = table.HasValue(self.context.usingAddons, addon),
            updated = addon.updated
        }
    end

    file.Write(cacheFile, util.TableToJSON(cache))
end

return MODULE
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

concommand.Add("downloader_legacy_cache", function(ply, cmd, args)
    if #MODULE.context.legacyFiles > 0 then
        local cacheFile = MODULE.context.dataFolder .. "/legacy_cache.txt"
        local cache = "if SERVER then\n"

        for _, legacyFile in ipairs(MODULE.context.legacyFiles) do
            cache = cache .. "    resource.AddSingleFile(\"" .. legacyFile .. "\")\n"
        end

        cache = cache .. "end\n"

        file.Write(cacheFile, cache)
    end
end)

return MODULE
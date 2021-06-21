local MODULE = {}
MODULE.Order = 3

function MODULE:Run()
    -- cache = { [number wsid] = { bool hasResource, string updated }, ... }
    local cacheFile = self.context.dataFolder .. "/workshop_cache.txt"
    local cache = util.JSONToTable(file.Read(cacheFile, "DATA") or "{}")

    for _, addon in ipairs(self.context.addons) do
        if not self.context.ignoreResources[addon.wsid] then
            -- I'm using tonumber because https://github.com/Facepunch/garrysmod-issues/issues/3561#issuecomment-428479149
            local scanned = cache[tonumber(addon.wsid)]

            -- cache exists and is up to date?
            if scanned and scanned.updated == addon.updated then
                if scanned.hasResource then
                    table.insert(self.context.usingAddons, addon)
                end

                self.context.ignoreResources[addon.wsid] = true
            end
        end
    end

    self.context.cacheQuantity = table.Count(cache)
end

return MODULE
local MODULE = {}
MODULE.Order = 7

local dumpWorkshopCache = CreateConVar("downloader_dump_workshop_cache", 0, FCVAR_ARCHIVE, "Should dump the next Workshop resources scan into a txt file")

function MODULE:Run(context)
    -- cache = { [number wsid] = { bool hasResource, string updated }, ... }
    local cacheFile = context.dataFolder .. "/workshop_cache.txt"
    local cache = {}

    for _, addon in ipairs(context.addons) do
        cache[addon.wsid] = {
            hasResource = table.HasValue(context.usingAddons, addon),
            updated = addon.updated
        }
    end

    file.Write(cacheFile, util.TableToJSON(cache))

    if dumpWorkshopCache:GetBool() and #context.usingAddons > 0 then
        local cacheFile = context.dataFolder .. "/dump_workshop_cache.txt"
        local cache = "if SERVER then\n"

        for _, addon in ipairs(context.usingAddons) do
            cache = cache .. "    resource.AddWorkshop(\"" .. addon.wsid .. "\") -- " .. addon.title .. "\n"
        end

        cache = cache .. "end\n"

        RunConsoleCommand("downloader_dump_workshop_cache", 0)

        file.Write(cacheFile, cache)

        print("[DOWNLOADER] RESOURCES DUMPED INTO '" .. cacheFile .. "'")
    end
end

return MODULE
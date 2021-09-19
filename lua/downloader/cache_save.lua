local MODULE = {}
MODULE.Order = 7

local shouldDumpWorkshopCache = CreateConVar("downloader_dump_workshop_cache", 0, FCVAR_ARCHIVE, "Should dump the next Workshop resources scan into a txt file")

local function DumpWorkshopCache(context)
    local cacheFile = context.dataFolder .. "/dump_workshop_cache.txt"
    local cache = "if SERVER then\n"

    for _, addon in ipairs(context.usingAddons) do
        cache = cache .. "    resource.AddWorkshop(\"" .. addon.wsid .. "\") -- " .. addon.title .. "\n"
    end

    cache = cache .. "end\n"

    shouldDumpWorkshopCache:SetBool(false)

    file.Write(cacheFile, cache)

    print("[DOWNLOADER] RESOURCES DUMPED INTO '" .. cacheFile .. "'")
end

function MODULE:Run(context)
    -- cache = { [number wsid] = { bool hasResource, string updated }, ... }
    local cacheFile = context.dataFolder .. "/workshop_cache.txt"
    local cache = {}

    for _, addon in ipairs(context.addons) do
        cache[addon.wsid] = {
            hasResource = context.addonsToCache[addon.wsid] == true,
            updated = addon.updated,
            isGamemode = context.gamemodeAddons[addon.wsid] == true
        }
    end

    file.Write(cacheFile, util.TableToJSON(cache))

    if shouldDumpWorkshopCache:GetBool() and #context.usingAddons > 0 then
        DumpWorkshopCache(context)
    end
end

return MODULE
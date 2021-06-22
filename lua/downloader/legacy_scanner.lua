local MODULE = {}
MODULE.Order = 0

local resourceExtensions = include("downloader/resources.lua")
local shouldScan = CreateConVar("downloader_legacy_scan_danger", 0, FCVAR_ARCHIVE, "Should scan for legacy addons (DANGER!!!)")
local dumpLegacyCache = CreateConVar("downloader_dump_legacy_cache", 0, FCVAR_ARCHIVE, "Should dump the next Legacy Addon resources scan into a txt file")

local function AddFiles(originPath, currentPath, legacyFiles)
    local files, dirs = file.Find(originPath .. currentPath .. "*", "MOD")

    if files then
        for _, subFile in ipairs(files) do
            local ext = string.GetExtensionFromFilename(subFile)
            if resourceExtensions[ext] then
                table.insert(legacyFiles, { addon = string.Explode("/", originPath)[2], path = currentPath .. subFile })
            end
        end
    end

    if dirs then
        for _, subDir in ipairs(dirs) do
            AddFiles(originPath, currentPath .. subDir .. "/", legacyFiles)
        end
    end
end

local function ScanAddons(context)
    local _, folders = file.Find("addons/*", "MOD")
    local currentMap = game.GetMap()

    local legacyFiles = {}
    local isFastDL = GetConVar("sv_downloadurl"):GetString() ~= ""
    local isServerDL = not isFastDL
    local downloadSize = 0
    local _, totalLegacy = file.Find("addons/*", "MOD")
    totalLegacy = #totalLegacy

    print("[DOWNLOADER] SCANNING " .. totalLegacy .. " LEGACY ADDONS TO ADD RESOURCES...")

    for _, folder in ipairs(folders or {}) do
        AddFiles("addons/" .. folder .. "/", "", legacyFiles)

        local mapFiles = file.Find("addons/" .. folder .. "/maps/*.bsp", "MOD") or {}
        for _, mapFile in ipairs(mapFiles) do
            if string.StripExtension(mapFile) == currentMap then
                table.insert(legacyFiles, { addon = folder, path = "maps/" .. mapFile .. ".bsp" })
            end
        end
    end

    for _, legacyFile in ipairs(legacyFiles) do
        print(string.format("[DOWNLOADER] [+] LEGACY '%s'", legacyFile.path))
        resource.AddSingleFile(legacyFile.path)
        downloadSize = downloadSize + file.Size(legacyFile.path .. (isFastDL and file.Exists(legacyFile.path .. ".bz2", "GAME") and ".bz2" or ""), "GAME")
    end

    downloadSize = math.Round(downloadSize / 1000000, 2) -- Byte to Megabyte

    print(string.format("[DOWNLOADER] FINISHED TO ADD LEGACY ADDONS: %s FILES SELECTED (%s MB)", #legacyFiles, downloadSize))
    if isFastDL then
        print("[DOWNLOADER] USING FASTDL. DOWNLOAD TIME CHANGES ACCORDING TO INTERNET SPEED")
    else
        -- Note: ServerDL speed is limited to 30KBps, but commonly reaches 20KBps or less, so I'm using 25KBps to approximate time
        local time = ((downloadSize * 1000) / 25) / 60
        print(string.format("[DOWNLOADER] USING SERVERDL. APPROXIMATE FULL DOWNLOAD TIME: %.2f MINUTES", time))
    end

    if isServerDL and not GetConVar("sv_allowdownload"):GetBool() then
        ErrorNoHalt("[DOWNLOADER] WARNING! YOU ARE TRYING TO USE SERVERDL WITH 'sv_allowdownload' SET TO 0!\n")
    end

    if context then
        context.legacyDownloadSize = downloadSize
    end

    if dumpLegacyCache:GetBool() and #legacyFiles > 0 then
        local cacheFile = "uwd/dump_legacy_cache.txt"
        local cache = "if SERVER then\n"

        local lastAddon
        for _, legacyFile in ipairs(legacyFiles) do
            if legacyFile.addon ~= lastAddon then
                cache = cache .. "    -- " .. legacyFile.addon .. "\n"
                lastAddon = legacyFile.addon
            end
            cache = cache .. "    resource.AddSingleFile(\"" .. legacyFile.path .. "\")\n"
        end

        cache = cache .. "end\n"

        RunConsoleCommand("downloader_dump_legacy_cache", 0)

        file.Write(cacheFile, cache)

        print("[DOWNLOADER] LEGACY ADDON RESOURCES DUMPED INTO '" .. cacheFile .. "'")
    end
end

function MODULE:Run(context)
    context.legacyScan = shouldScan:GetBool()
    if context.legacyScan then
        ScanAddons(context)
    end
end

cvars.AddChangeCallback("downloader_legacy_scan_danger", function(convar_name, value_old, value_new)
    if value_new == "1" then
        ScanAddons()
    end
end)

return MODULE
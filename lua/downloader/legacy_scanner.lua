local MODULE = {}
MODULE.Order = 6

local resourceExtensions = include("downloader/resources.lua")
local shouldScan = CreateConVar("downloader_legacy_scan_danger", 0, FCVAR_ARCHIVE, "Should scan for legacy addons (DANGER!!!)")

local function AddFiles(originPath, currentPath, legacyFiles)
    local files, dirs = file.Find(originPath .. currentPath .. "*", "MOD")

    if files then
        for _, subFile in ipairs(files) do
            local ext = string.GetExtensionFromFilename(subFile)
            if resourceExtensions[ext] then
                table.insert(legacyFiles, currentPath .. subFile)
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

    for _, folder in ipairs(folders or {}) do
        AddFiles("addons/" .. folder .. "/", "", legacyFiles)

        local mapFiles = file.Find("addons/" .. folder .. "/maps/*.bsp", "MOD") or {}
        for _, mapFile in ipairs(mapFiles) do
            if string.StripExtension(mapFile) == currentMap then
                table.insert(legacyFiles, "maps/" .. mapFile .. ".bsp")
            end
        end
    end

    for _, legacyFile in ipairs(legacyFiles) do
        print(string.format("[DOWNLOADER] [+] LEGACY '%s'", legacyFile))
        resource.AddSingleFile(legacyFile)
        downloadSize = downloadSize + file.Size(legacyFile .. (isFastDL and file.Exists(legacyFile .. ".bz2", "GAME") and ".bz2" or ""), "GAME")
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

    context.legacyDownloadSize = downloadSize
    context.legacyFiles = #legacyFiles
end

function MODULE:Run()
    if shouldScan:GetBool() then
        ScanAddons(self.context)
    end
end

cvars.AddChangeCallback("downloader_legacy_scan_danger", function(convar_name, value_old, value_new)
    if value_new == "1" then
        ScanAddons(MODULE.context)
    end
end)

return MODULE
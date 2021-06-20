local MODULE = {}
MODULE.Priority = 10

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

local function ScanAddons()
    local _, folders = file.Find("addons/*", "MOD")
    local currentMap = game.GetMap()

    local legacyFiles = {}
    local isFastDL = GetConVar("sv_downloadurl"):GetString() ~= "" and true
    local isServerDL = not isFastDL
    local compressedSize = 0
    local uncompressedSize = 0

    if isServerDL and not GetConVar("sv_allowdownload"):GetBool() then
        print("[DOWNLOADER] ERROR! YOU ARE TRYING TO USE SERVERDL WITH 'sv_allowdownload' SET TO 0! SKIPPING SCAN")
        return
    end

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
        uncompressedSize = uncompressedSize + file.Size(legacyFile, "GAME")
        if isFastDL and file.Exists(legacyFile .. ".bz2", "GAME") then
            compressedSize = compressedSize + file.Size(legacyFile .. ".bz2", "GAME")
        end
    end

    uncompressedSize = math.Round(uncompressedSize/1000000, 2) -- Byte to Megabyte

    print("[DOWNLOADER] FINISHED TO ADD LEGACY ADDONS: " .. #legacyFiles .. " FILES SELECTED")
    print("[DOWNLOADER] TOTAL UNCOMPRESSED SIZE: " .. uncompressedSize .. "MB")
    if isFastDL then
        if compressedSize ~= 0 then
            compressedSize = math.Round(compressedSize/1000000, 2)
            print("[DOWNLOADER] TOTAL COMPRESSED SIZE: " .. compressedSize .. "MB")
        end
        print("[DOWNLOADER] YOUR ARE USING FASTDL. DOWNLOAD TIME CHANGES ACCORDING TO INTERNET SPEED")
    else
        -- ServerDL speed is limited to 20KBps
        print("[DOWNLOADER] YOUR ARE USING SERVERDL. MINIMUM FULL DOWNLOAD TIME: " .. ((uncompressedSize * 1000) / 20) / 60 .. " MINUTES")
    end
end

function MODULE:Run(context)
    if shouldScan:GetBool() then
        ScanAddons()
    end
end

cvars.AddChangeCallback("downloader_legacy_scan_danger", function(convar_name, value_old, value_new)
    if value_new == "1" then
        ScanAddons()
    end
end)

return MODULE
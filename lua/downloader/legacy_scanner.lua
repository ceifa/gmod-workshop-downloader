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
    end

    print("[DOWNLOADER] FINISHED TO ADD LEGACY ADDONS: " .. #legacyFiles .. " FILES SELECTED")
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
-- Download any gmas with these extensions
DOWNLOADER.ResourceExtensions = {
    --Models
    mdl = true,
    vtx = true,
    vcd = true,
    --Sounds
    wav = true,
    mp3 = true,
    ogg = true,
    --Materials, Textures
    vmt = true,
    vtf = true,
    png = true,
    -- Particles
    pcf = true,
    -- Resources
    ttf = true
}

-- Select wich gmas are maps
function DOWNLOADER:ScanMapsGMA(addon)
    local mapFiles = file.Find("maps/*.bsp", addon)

    if mapFiles and #mapFiles > 0 then
        local currentMap = game.GetMap()

        for _, mapFile in ipairs(mapFiles) do
            if string.StripExtension(mapFile) == currentMap then
                return true
            end
        end

        return false
    end
end

-- Analyze each mounted workshop addon
function DOWNLOADER:ScanGMA(currentPah, mountedGMAPath)
    local files, dirs = file.Find(currentPah .. "*", mountedGMAPath)

    if files then
        for _, subFile in ipairs(files) do
            local ext = string.GetExtensionFromFilename(subFile)

            if self.ResourceExtensions[ext] then
                return true
            end
        end
    end

    if dirs then
        for _, subDir in ipairs(dirs) do
            local result = self:ScanGMA(currentPah .. subDir .. "/", mountedGMAPath)

            if result then
                return result
            end
        end
    end
end

function DOWNLOADER:GetWorkshopAddons()
    local installedAddons = engine.GetAddons()

    local workshopAddons = {}

    for _, addon in ipairs(installedAddons) do
        if addon.downloaded and addon.mounted then
            local id = tonumber(addon.wsid)
            workshopAddons[id] = {
                Mode = self.Mode.Disabled
            }

            local mapScan = self:ScanMapsGMA(addon.title)

            if mapScan or (mapScan == nil and self:ScanGMA("", addon.title)) then
                workshopAddons[id].Mode = self.Mode.LoadingScreen
            elseif mapScan ~= nil then
                workshopAddons[id].Mode = self.Mode.WhenBeingUsed
            end
        end
    end

    return workshopAddons
end

-- Run once
function DOWNLOADER:GetAllAddons()
    if game.SinglePlayer() then
        return
    end

    local currentAddons = self:GetValue("addons") or {}
    local workshopAddons = self:GetWorkshopAddons()

    for k, v in pairs(workshopAddons) do
        if not currentAddons[k] then
            currentAddons[k] = workshopAddons[k]
        end
    end

    return currentAddons
end
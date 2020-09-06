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

-- Last valid scanned workshop collection
DOWNLOADER.CacheFile = "uwdcache.txt"

-- Generate a unique name based on the collection items
function DOWNLOADER:GenerateCollectionChecksum(workshopAddons)
    local uniqueID = ""

    for  _, addon in ipairs(workshopAddons) do
        uniqueID = uniqueID .. addon.wsid
    end

    return util.CRC(uniqueID)
end

-- Load the cache file
function DOWNLOADER:LoadCache(checksum)
	if file.Exists(self.CacheFile, "DATA") then
        local cache = util.JSONToTable(file.Read(self.CacheFile, "DATA"))

        return cache.checksum == checksum and cache
    end
end

-- Save a new cache file
function DOWNLOADER:SaveCache(selectedAddons)
    file.Write(self.CacheFile, util.TableToJSON(selectedAddons))
end

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

function DOWNLOADER:AddWorkshopResources()
    local workshopAddons = engine.GetAddons()
    local selectedAddons = {}
    local checksum = self:GenerateCollectionChecksum(workshopAddons)
    local cache = self:LoadCache(checksum)
    local totalAdded = 0

    if not cache then
        print("[DOWNLOADER] SCANNING " .. #workshopAddons .. " ADDONS TO ADD RESOURCES...")
    else
        print("[DOWNLOADER] ADDING RESOURCES FOR " .. #cache .. " ADDONS FROM OUR CACHE FILE...")
    end

    for _, addon in ipairs(cache or workshopAddons) do
        if cache or addon.downloaded and addon.mounted then
            local mapScan = not cache and self:ScanMapsGMA(addon.title)

            if cache or mapScan or (mapScan == nil and self:ScanGMA("", addon.title)) then
                if not cache then
                    table.insert(selectedAddons, addon)
                    totalAdded = totalAdded + 1
                end
                resource.AddWorkshop(addon.wsid)
                print(string.format("[DOWNLOADER] [+] %-10s %s", addon.wsid, addon.title))
            end
        end
    end

    print("[DOWNLOADER] FINISHED TO ADD RESOURCES" .. (cache and "" or ": " .. totalAdded .. " ADDONS SELECTED"))

    if not cache then
        selectedAddons.checksum = checksum
        self:SaveCache(selectedAddons)
    end
end

-- Check if there are any unused playermodels on Pointshop
function DOWNLOADER:CheckUnusedPlayermodels()
    local models = player_manager.AllValidModels()
    local totalNotFound = 0

    print("[DOWNLOADER] STARTING TO CHECK POINTSHOP PLAYERMODELS...")

    for k, model in pairs(models) do
        model = string.lower(model)

        if not string.StartWith(model, "models/player/group") then
            local found = false

            for _, psItem in pairs(PS.Items) do
                if psItem.Model and string.lower(psItem.Model) == model then
                    found = true
                    break
                end
            end

            if not found then
                totalNotFound = totalNotFound + 1
                MsgC(Color(255, 0, 0), "[DOWNLOADER] MODEL " .. k .. " NOT FOUND IN POINTSHOP: " .. model .. "\n")
            end
        end
    end

    print("[DOWNLOADER] FINISHED POINTSHOP SEARCH: " .. totalNotFound .. " PLAYERMODELS NOT FOUND")
end

-- Run once
function DOWNLOADER:Start(finishCallback)
    if game.SinglePlayer() then
        finishCallback()
        return
    end

    self:AddWorkshopResources()

    if PS then
        timer.Simple(5, function()
            self:CheckUnusedPlayermodels()
            finishCallback()
        end)
    else
        MsgC(Color(255, 0, 0), "[DOWNLOADER] POINTSHOP 1 NOT FOUND, SKIPPING PLAYERMODELS CHECK\n")
        finishCallback()
    end
end

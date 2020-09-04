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
    pcf = true
}

-- Select wich gmas are maps
function DOWNLOADER:SelectMapGMAs(workshopAddons)
    for k, addon in pairs(workshopAddons) do
        local isMap = false
        local _, dirs = file.Find("*", addon.title)

        if dirs then
            for _, subDir in pairs(dirs) do
                if subDir == "maps" then
                    isMap = true
                    break
                end
            end

            workshopAddons[k].isMap = isMap
        end
    end
end

-- Analyze each mounted workshop addon
function DOWNLOADER:ScanGMA(currentPah, mountedGMAPath, isMap)
    local files, dirs = file.Find(currentPah .. "*", mountedGMAPath)

    if files then
        for _, subFile in pairs(files) do
            local ext = string.GetExtensionFromFilename(subFile)
            local isMapExt = ext == "bsp"

            -- Download the gma if...

            -- it's the current map
            if isMapExt then
                local isCurrentMap = string.StripExtension(subFile) == game.GetMap()

                return isCurrentMap
            -- it's a addon with one of the listed extensions
            elseif not isMap and self.ResourceExtensions[ext] then
                return true
            end
        end
    end

    if dirs then
        for _, subDir in pairs(dirs) do
            local result = self:ScanGMA(currentPah .. subDir .. "/", mountedGMAPath, isMap)

            if result ~= nil then
                return result
            end
        end
    end
end

function DOWNLOADER:AddWorkshopResources(workshopAddons)
    local totalAdded = 0

    print("[DOWNLOADER] SCANNING " .. #workshopAddons .. " ADDONS TO ADD RESOURCES...")

    for _, addon in pairs(workshopAddons) do
        if addon.downloaded and addon.mounted and self:ScanGMA("", addon.title, addon.isMap) then
            resource.AddWorkshop(addon.wsid)
            totalAdded = totalAdded + 1
            print(string.format("[DOWNLOADER] [+] %-10s %s", addon.wsid, addon.title))
        end
    end

    print("[DOWNLOADER] FINISHED TO ADD RESOURCES: " .. totalAdded .. " ADDONS SELECTED")
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
    local workshopAddons = engine.GetAddons()

    self:SelectMapGMAs(workshopAddons)
    self:AddWorkshopResources(workshopAddons)

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
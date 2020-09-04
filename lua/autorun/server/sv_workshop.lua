DOWNLOADER = {}
DOWNLOADER.__index = DOWNLOADER

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
    png = true
}

-- Download a gma with the current map if it's available
function DOWNLOADER:IsCurrentMap(file, ext)
    if ext == "bsp" and string.StripExtension(file) == game.GetMap() then
        return true
    end

    return false
end

-- Analyze each mounted workshop addon
function DOWNLOADER:ParseAddon(currentPah, mountedGMAPath)
    local files, dirs = file.Find(currentPah .. "*", mountedGMAPath)

    if files then
        for _, file in pairs(files) do
            local ext = string.GetExtensionFromFilename(file)

            if self.ResourceExtensions[ext] then return true end 
            if self.IsCurrentMap(file, ext) then return true end
        end
    end

    if dirs then
        for _, newSubDir in pairs(dirs) do
            if self:ParseAddon(currentPah .. newSubDir .. "/", mountedGMAPath) then return true end
        end
    end
end

function DOWNLOADER:AddWorkshopResources()
    local addons = engine.GetAddons()
    local totalAdded = 0

    print("[DOWNLOADER] SCANNING " .. #addons .. " ADDONS TO ADD RESOURCES...")

    for _, addon in pairs(addons) do
        if addon.downloaded and addon.mounted then
            if self:ParseAddon("", addon.title) then
                resource.AddWorkshop(addon.wsid)
                totalAdded = totalAdded + 1
                print(string.format("[DOWNLOADER] [+] %-10s %s", addon.wsid, addon.title))
            end
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
function DOWNLOADER:Start()
    self:AddWorkshopResources()

    if PS then
        timer.Simple(5, function()
            self:CheckUnusedPlayermodels()
            DOWNLOADER = nil
        end)
    else
        MsgC(Color(255, 0, 0), "[DOWNLOADER] POINTSHOP 1 NOT FOUND, SKIPPING PLAYERMODELS CHECK\n")
        DOWNLOADER = nil
    end
end
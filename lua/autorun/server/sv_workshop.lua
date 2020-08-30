DOWNLOADER = {}
DOWNLOADER.__index = DOWNLOADER

DOWNLOADER.ResourceExtensions = {
    --Models
    mdl = true,
    vtx = true,
    --Sounds
    wav = true,
    mp3 = true,
    ogg = true,
    --Materials, Textures
    vmt = true,
    vtf = true,
    png = true
}

function DOWNLOADER:Traverse(subPath, basePath, foundExts)
    local files, dirs = file.Find(subPath .. "*", basePath)

    for _, f in pairs(files) do
        local ext = string.GetExtensionFromFilename(f)
        foundExts[ext] = true
        if ext == "bsp" and string.StripExtension(f) == game.GetMap() then return true end
    end

    for _, d in pairs(dirs) do
        if self:Traverse(subPath .. d .. "/", basePath, foundExts) then return true end
    end
end

function DOWNLOADER:AddWorkshopResources()
    local addons = engine.GetAddons()
    print("[DOWNLOADER] STARTING TO ADD RESOURCES FOR " .. #addons .. " ADDONS...")

    for _, addon in pairs(addons) do
        if addon.downloaded and addon.mounted then
            local found_exts = {}
            local shouldAdd = self:Traverse("", addon.title, found_exts)

            -- if addon fails initial test but does not contain a map, check for resource files
            if not shouldAdd and not found_exts.bsp then
                for res_ext, _ in pairs(self.ResourceExtensions) do
                    if found_exts[res_ext] then
                        shouldAdd = true
                        break
                    end
                end
            end

            if shouldAdd then
                resource.AddWorkshop(addon.wsid)
                print("[DOWNLOADER] ADDING RESOURCE FOR '" .. addon.title .. "' WITH WSID '" .. addon.wsid .. "'")
            end
        end
    end

    print("[DOWNLOADER] FINISHED TO ADD RESOURCES")
end

function DOWNLOADER:CheckUnusedPlayermodels()
    print("[DOWNLOADER] STARTING TO CHECK POINTSHOP PLAYERMODELS")
    local models = player_manager.AllValidModels()

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
                MsgC(Color(255, 0, 0), "[DOWNLOADER] MODEL " .. k .. " NOT FOUND IN POINTSHOP: " .. model .. "\n")
            end
        end
    end

    print("[DOWNLOADER] FINISHED POINTSHOP SEARCH")
end

function DOWNLOADER:Start()
    self:AddWorkshopResources()

    if PS then
        timer.Simple(5, function()
            self:CheckUnusedPlayermodels()
            DOWNLOADER = nil
        end)
    else
        MsgC(Color(255, 0, 0), "[DOWNLOADER] POINTSHOP 1 NOT FOUND\n")
        DOWNLOADER = nil
    end
end
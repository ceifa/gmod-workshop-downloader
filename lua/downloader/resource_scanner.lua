local MODULE = {}
MODULE.Priority = 3

-- Download any gmas with these extensions
local resourceExtensions = {
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

local function HasUsingResource(currentPah, addonTitle)
    local files, dirs = file.Find(currentPah .. "*", addonTitle)

    if files then
        for _, subFile in ipairs(files) do
            local ext = string.GetExtensionFromFilename(subFile)

            if resourceExtensions[ext] then
                return true
            end
        end
    end

    if dirs then
        for _, subDir in ipairs(dirs) do
            local result = HasUsingResource(currentPah .. subDir .. "/", addonTitle)

            if result then
                return result
            end
        end
    end
end

function MODULE:Run(context)
    for _, addon in ipairs(context.addons) do
        if not table.HasValue(context.ignoreResources, addon.wsid) and HasUsingResource("", addon.title) then
            table.insert(context.usingAddons, addon)
        end
    end
end

return MODULE
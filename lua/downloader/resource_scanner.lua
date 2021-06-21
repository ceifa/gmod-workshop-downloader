local MODULE = {}
MODULE.Order = 4

-- Download any gmas with these extensions
local resourceExtensions = include("downloader/resources.lua")

local function HasUsingResource(currentPath, addonTitle)
    local files, dirs = file.Find(currentPath .. "*", addonTitle)

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
            local result = HasUsingResource(currentPath .. subDir .. "/", addonTitle)

            if result then
                return result
            end
        end
    end
end

function MODULE:Run(context)
    for _, addon in ipairs(context.addons) do
        if not table.HasValue(context.ignoreResources, addon.wsid) then
            local hasResources = context.cache[tonumber(addon.wsid)] or addon.models > 0 or HasUsingResource("", addon.title)
            if hasResources then
                table.insert(context.usingAddons, addon)
            end
        end
    end
end

return MODULE
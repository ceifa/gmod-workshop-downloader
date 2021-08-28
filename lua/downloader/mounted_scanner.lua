local MODULE = {}
MODULE.Order = 1

function MODULE:Run(context)
    for key = #context.addons, 1, -1 do
        local addon = context.addons[key]
        if not addon.downloaded or not addon.mounted then
            table.remove(context.addons, key)
        end
    end

    print("[DOWNLOADER] SCANNING " .. #context.addons .. " ADDONS TO ADD RESOURCES...")
end

return MODULE

local MODULE = {}
MODULE.Order = 1

function MODULE:Run(context)
    for key, addon in ipairs(context.addons) do
        if not addon.downloaded or not addon.mounted then
            table.remove(context.addons, key)
        end
    end

    print("[DOWNLOADER] SCANNING " .. #context.addons .. " ADDONS TO ADD RESOURCES...")
end

return MODULE
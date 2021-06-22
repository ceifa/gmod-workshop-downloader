local MODULE = {}
MODULE.Order = 6

function MODULE:Run(context)
    for _, usingAddon in ipairs(context.usingAddons) do
        resource.AddWorkshop(usingAddon.wsid)
        print(string.format("[DOWNLOADER] [+] %-10s %s", usingAddon.wsid, usingAddon.title))
    end

    print("[DOWNLOADER] FINISHED TO ADD RESOURCES: " .. #context.usingAddons .. " ADDONS SELECTED")
end

return MODULE
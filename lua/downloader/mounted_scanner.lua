local MODULE = {}
MODULE.Order = 0

function MODULE:Run(context)
    for key, addon in ipairs(context.addons) do
        if not addon.downloaded or not addon.mounted then
            table.remove(context.addons, key)
        end
    end
end

return MODULE
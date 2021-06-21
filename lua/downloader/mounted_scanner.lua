local MODULE = {}
MODULE.Order = 0

function MODULE:Run()
    for key, addon in ipairs(self.context.addons) do
        if not addon.downloaded or not addon.mounted then
            table.remove(self.context.addons, key)
        end
    end
end

return MODULE
local MODULE = {}
MODULE.Order = 6

function MODULE:Run(context)
    local selectedManualAddons = {}

    for k, addon in ipairs(context.addons) do
        if context.manualAddons[addon.wsid] then
            selectedManualAddons[addon.wsid] = addon
        end
    end

    for key = #context.usingAddons, 1, -1 do
        local addon = context.usingAddons[key]
        if context.manualAddons[addon.wsid] == false then
            table.remove(context.usingAddons, key)
        elseif context.manualAddons[addon.wsid] == true then
            selectedManualAddons[addon.wsid] = nil
        end
    end

    for wsid, addon in pairs(selectedManualAddons) do
        table.insert(context.usingAddons, addon)
    end
end

return MODULE
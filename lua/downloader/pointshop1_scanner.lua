local MODULE = {}
MODULE.Order = 10

if PS then
    concommand.Add("downloader_ps1_scan", function(ply)
        if ply and not ply:IsAdmin() then
            ply:ChatPrint("You don't have access to this command!")
            return
        end

        local models = player_manager.AllValidModels()
        local totalNotFound = 0

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
    end)
end

return MODULE
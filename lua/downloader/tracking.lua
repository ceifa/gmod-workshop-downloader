local MODULE = {}
MODULE.Order = 100

local disableTracking = CreateConVar("downloader_disable_tracking", 0, FCVAR_ARCHIVE, "Should disable tracking report")

function MODULE:Run(context)
    if not disableTracking:GetBool() then
        local finished = SysTime()

        -- Defer tracking request
        timer.Simple(12, function()
            local body = util.TableToJSON({
                hostname = GetHostName(),
                gamemode = engine.ActiveGamemode(),
                ip = game.GetIPAddress(),
                dedicated = game.IsDedicated(),
                elapsed = finished - context.started,
                addons = #context.addons,
                usingAddons = #context.usingAddons,
                fastDl = GetConVar("sv_downloadurl"):GetString() ~= "",
                legacyScan = context.legacyScan,
                legacyDownloadSize = context.legacyDownloadSize,
                legacyFiles = context.legacyFiles
            })

            print("TRACKING2")
            HTTP({
                url = "https://api.ceifa.tv/track/gmod-workshop-downloader",
                method = "POST",
                type = "application/json",
                body = body
            })
        end)
    end
end

return MODULE
local MODULE = {}
MODULE.Order = 100

local disableTelemetry = CreateConVar("downloader_disable_telemetry", 0, FCVAR_ARCHIVE, "Should disable telemetry report")

function MODULE:Run(context)

    do return end -- Disabled

    if not disableTelemetry:GetBool() then
        local finished = SysTime()

        -- Defer telemetry request
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
                legacyAddons = context.legacyAddons,
                cacheQuantity = context.cacheQuantity
            })

            HTTP({
                url = "https://api.ceifa.tv/track/gmod-workshop-downloader",
                method = "POST",
                type = "application/json",
                body = body,
                failed = function(reason)
                    print("[DOWNLOADER] Failed to send telemetry data: " .. reason .. "\n")
                end
            })
        end)
    end
end

return MODULE
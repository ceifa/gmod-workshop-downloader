local MODULE = {}
MODULE.Order = 100

local disableTracking = CreateConVar("downloader_disable_tracking", 0, FCVAR_ARCHIVE, "Should disable tracking report")

function MODULE:Run()
    if not disableTracking:GetBool() then
        local finished = SysTime()

        -- Defer tracking request
        timer.Simple(12, function()
            local body = util.TableToJSON({
                hostname = GetHostName(),
                gamemode = engine.ActiveGamemode(),
                ip = game.GetIPAddress(),
                dedicated = game.IsDedicated(),
                elapsed = finished - self.context.started,
                addons = #self.context.addons,
                usingAddons = #self.context.usingAddons,
                fastDl = GetConVar("sv_downloadurl"):GetString() ~= "",
                legacyScan = self.context.legacyScan,
                legacyDownloadSize = self.context.legacyDownloadSize,
                legacyFiles = self.context.legacyFiles,
                cacheQuantity = self.context.cacheQuantity
            })

            HTTP({
                url = "https://api.ceifa.tv/track/gmod-workshop-downloader",
                method = "POST",
                type = "application/json",
                body = body,
                failed = function(reason)
                    ErrorNoHalt("[DOWNLOADER ]Failed to send track data: " .. reason .. "\n")
                end
            })
        end)
    end
end

return MODULE
DOWNLOADER = {}
DOWNLOADER.__index = DOWNLOADER

include("downloader/sv_workshop.lua")

DOWNLOADER:Start(function()
    hook.Run("WorkshopDownloader.Finished")
    DOWNLOADER = nil
end)
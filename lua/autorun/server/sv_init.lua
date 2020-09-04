include("autorun/server/sv_workshop.lua")

DOWNLOADER = {}
DOWNLOADER.__index = DOWNLOADER

DOWNLOADER:Start(function()
    hook.Run("WorkshopDownloader.Finished")
    DOWNLOADER = nil
end)
net.Receive("UWD_DownloadAddons", function(len)
    local addonsToReceive = len / (32 + 4)
    local addons = DOWNLOADER.Addons or {}

    for i = 1, addonsToReceive do
        local mode = net.ReadUInt(4)
        local wsid = net.ReadUInt(32)
        addons[wsid] = {
            Mode = mode
        }
    end

    local function downloadAndMount(wid)
        steamworks.DownloadUGC(wid, function(path, fileHandle)
            if path then
                game.MountGMA(path)
            end
        end)
    end

    for wid, details in pairs(addons) do
        if details.Mode == DOWNLOADER.Mode.AfterEnter then
            steamworks.FileInfo(wid, function(result)
                if not file.Exists("cache/workshop/" .. result.previewid .. ".cache", "GAME") then
                    downloadAndMount(wid)
                end
            end)
        end
    end

    DOWNLOADER.Addons = addons
end)

function DOWNLOADER:ToggleMenu()
    if not self.Menu or not self.Menu:IsValid() then
        if not LocalPlayer():IsAdmin() then return end

        self.Menu = vgui.Create("DownloaderMenu")
        self.Menu:SetAddons(self.Addons)
    else
        self.Menu:Close()
    end
end

hook.Add("OnPlayerChat", "UWD_ToggleCommand", function(ply, text, team, dead)
    if ply == LocalPlayer() and string.lower(text) == "!uwd" and DOWNLOADER then
        DOWNLOADER:ToggleMenu()
    end
end)

concommand.Add("uwd_menu", function()
    if DOWNLOADER then
        DOWNLOADER:ToggleMenu()
    end
end)

concommand.Add("uwd_autodestroy", function()
    DOWNLOADER = nil
end)
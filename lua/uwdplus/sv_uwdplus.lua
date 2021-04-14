util.AddNetworkString("UWD_DownloadAddons")
util.AddNetworkString("UWD_SetAddon")

function DOWNLOADER:Start()
    self.Addons = self:GetAllAddons()

    local count = 0
    for k, v in pairs(self.Addons) do
        if v.Mode == self.Mode.LoadingScreen then
            count = count + 1
            resource.AddWorkshop(k)
        end
    end

    print("[DOWNLOADER] FINISHED TO ADD RESOURCES ON LoadingScreen: " .. count .. " ADDONS SELECTED")

    hook.Add("ClientSignOnStateChanged", "UWD_UserDownload", function(connid, old, new)
        if new ~= SIGNONSTATE_FULL then return end

        timer.Simple(0, function()
            local ply = Player(connid)
            if not IsValid(ply) then return end

            net.Start("UWD_DownloadAddons")
                for k, v in pairs(self.Addons) do
                    net.WriteUInt(v.Mode, 4)
                    net.WriteUInt(k, 32)
                end
            net.Send(ply)
        end)
    end)

    self:SetValue("addons", self.Addons)
end

net.Receive("UWD_SetAddon", function(len, ply)
    local mode = net.ReadUInt(4)
    local wsid = net.ReadUInt(32)

    if not ply:IsAdmin() then return end

    DOWNLOADER:SetAddon(wsid, mode)
end)
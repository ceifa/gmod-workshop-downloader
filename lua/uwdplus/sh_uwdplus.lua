function DOWNLOADER:SetAddon(wsid, mode)
    if SERVER then
        self.Addons[wsid] = self.Addons[wsid] or {}
        self.Addons[wsid].Mode = mode
        self:SetValue("addons", self.Addons)

        if mode == self.Mode.LoadingScreen then
            resource.AddWorkshop(wsid)
        end

        net.Start("UWD_DownloadAddons")
            net.WriteUInt(mode, 4)
            net.WriteUInt(wsid, 32)
        net.Broadcast()
    else
        net.Start("UWD_SetAddon")
            net.WriteUInt(mode, 4)
            net.WriteUInt(wsid, 32)
        net.SendToServer()
    end
end

concommand.Add("uwd_setaddon", function(ply, cmd, args)
    -- Should only be handled on server
    if SERVER and args[1] and args[2] and ply:IsAdmin() then
        DOWNLOADER:SetAddon(args[1], args[2])
    end
end, function(cmd, sargs)
    local args = sargs:Split(" ")

    if #args <= 2 then
        local possibleAddonId = args[1]
        local suggestions = {}

        for k, v in pairs(DOWNLOADER.Addons) do
            local wsid = tostring(k)
            if wsid:find(possibleAddonId) then
                table.insert(suggestions, cmd .. " " .. wsid)
            end
        end

        return suggestions
    else
        local suggestions = {}

        for k, v in pairs(DOWNLOADER.Mode) do
            table.insert(suggestions, cmd .. sargs .. v)
        end

        return suggestions
    end
end, "Used to configure an addon on Ultimate Workshop Downloader Plus")
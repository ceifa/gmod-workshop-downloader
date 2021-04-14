local panel = {}
panel.OutLineSize = 2
panel.ContainerPadding = 20
panel.HeaderSize = panel.ContainerPadding * 2 + 28 / 2

surface.CreateFont("Roboto1", {
    font = "Roboto Regular",
    size = ScrH() * .02,
    antialias = true,
    weight = 500
})

surface.CreateFont("Roboto2", {
    font = "Roboto Regular",
    size = ScrH() * .015,
    antialias = true,
    weight = 500
})

function panel:Init()
    self:MakePopup()

    self.LoadingMaterial = Material("materials/uwdplus/loading.png")
    self:SetSize(ScrW() * .3, ScrH() * .8)

    self._startTime = SysTime()

    self:RenderAddAddon()
    self:RenderScroll()

    -- This turns off the engine drawing
    self:SetPaintBackgroundEnabled(false)
    self:SetPaintBorderEnabled(false)
end

function panel:OnSizeChanged(w, h)
    self:SetPos((ScrW() / 2) - (self:GetWide() / 2), (ScrH() / 2) - (self:GetTall() / 2))
    local close = vgui.Create("DButton", self)
    close:SetSize(100, 34)
    close:SetPos(self:GetWide() - self.ContainerPadding - close:GetWide(), self.OutLineSize or 0)
    close:SetText("Close")
    close:SetTextColor(color_white)
    close.Panel = self

    function close:Paint(ww, hh)
        surface.SetDrawColor(ColorAlpha(color_white, 12))
        surface.DrawRect(0, 0, ww, hh)
        surface.SetDrawColor(Color(46, 46, 46))
        surface.DrawRect(self.Panel.OutLineSize, self.Panel.OutLineSize, ww - self.Panel.OutLineSize * 2, hh - self.Panel.OutLineSize * 2)
    end

    function close:DoClick()
        self.Panel:Close()
    end
end

function panel:SetAddons(addons)
    for wsid, details in pairs(addons) do
        if not details.CachedInfo then
            steamworks.FileInfo(wsid, function(result)
                if result then
                    details.CachedInfo = result

                    if IsValid(self) then
                        self:RenderAddon(details)
                    end
                end
            end)
        else
            self:RenderAddon(details)
        end
    end
end

function panel:RenderAddon(addon)
    local h = ScrH() * .1
    local addonPanel = vgui.Create("EditablePanel", self)
    addonPanel:SetSize(self.Scroll:GetWide(), h)
    addonPanel:Dock(TOP)
    addonPanel:DockMargin(self.Panel.OutLineSize + 8, self.Panel.OutLineSize, self.Panel.OutLineSize, self.Panel.OutLineSize)
    addonPanel.Panel = self

    function addonPanel:Paint(ww, hh)
        surface.SetDrawColor(ColorAlpha(color_black, 100))
        surface.DrawRect(0, 0, ww, hh)
    end

    local image = vgui.Create("DImageButton", addonPanel)
    image:SetMaterial(self.LoadingMaterial)
    image:SetSize(h, h)
    image:Dock(LEFT)

    self:GetImageMaterial(addon.CachedInfo.id, addon.CachedInfo.previewurl, function(material)
        if material then
            image:SetMaterial(material)
        end
    end)

    local title = vgui.Create("DLabel", addonPanel)
    title:SetText(addon.CachedInfo.title)
    title:SetFont("Roboto1")
    title:Dock(TOP)
    title:DockMargin(8, 4, 8, 4)

    local updated = vgui.Create("DLabel", addonPanel)
    updated:SetText("Updated: " .. os.date("%m/%d/%y", addon.CachedInfo.updated))
    updated:SetFont("Roboto2")
    updated:Dock(TOP)
    updated:DockMargin(8, 0, 8, 0)
    updated:SetTextColor(ColorAlpha(color_white, 100))

    local options = vgui.Create("DComboBox", addonPanel)
    options:SetSortItems(false)
    options:SetValue(self:LookupMode(addon.Mode))
    options:SetTall(24)
    options:DockMargin(8, 0, self.ContainerPadding, 8)
    options:Dock(BOTTOM)

    options.OnSelect = function(s, i, val, data)
        addon.Mode = data
        self.Panel:SendToServer(addon.CachedInfo.id)
    end

    for k, v in pairs(DOWNLOADER.Mode) do
        options:AddChoice(self:LookupMode(v), v)
    end

    local mode = vgui.Create("DLabel", addonPanel)
    mode:SetText("Download mode:")
    mode:SetFont("Roboto2")
    mode:Dock(BOTTOM)
    mode:DockMargin(8, 0, 8, 0)

    self.Scroll:AddItem(addonPanel)
end

function panel:GetImageMaterial(id, url, callback)
    if not file.Exists("image_cache", "DATA") then
        file.CreateDir("image_cache")
    end

    if file.Exists("image_cache/" .. id .. ".png", "DATA") then
        callback(Material("data/image_cache/" .. id .. ".png", "noclamp smooth"))
    else
        http.Fetch(url, function(body)
            file.Write("image_cache/" .. id .. ".png", body)
            callback(Material("data/image_cache/" .. id .. ".png", "noclamp smooth"))
        end, function()
            callback(false)
        end)
    end
end

function panel:LookupMode(mode)
    local modes = {
        "Disabled",
        "Download on loading screen",
        "Download after user entered",
        "Download only if will be used (only working for maps yet)"
    }

    return modes[mode]
end

function panel:RenderAddAddon()
    local inputcontainer = vgui.Create("EditablePanel", self)
    inputcontainer:DockMargin(self.Panel.OutLineSize + 8, self.HeaderSize, self.Panel.OutLineSize + 8, self.OutLineSize)
    inputcontainer:Dock(TOP)

    local input = vgui.Create("DTextEntry", inputcontainer)
    input:Dock(FILL)
    input:DockMargin(0, 0, 8, 0)
    input:SetFont("Roboto2")
    input:SetPlaceholderText("Please enter the workshop URL")

    local add = vgui.Create("DButton", inputcontainer)
    add:Dock(RIGHT)
    add:SetSize(100, 34)
    add:SetPos(self:GetWide() - self.ContainerPadding - add:GetWide(), self.OutLineSize or 0)
    add:SetText("Add")
    add:SetTextColor(color_white)
    add.Panel = self

    function add:Paint(ww, hh)
        local color = self:GetDisabled() and color_black or Color(38, 65, 92)
        surface.SetDrawColor(ColorAlpha(color, 100))
        surface.DrawRect(0, 0, ww, hh)
        surface.SetDrawColor(color)
        surface.DrawRect(self.Panel.OutLineSize, self.Panel.OutLineSize, ww - self.Panel.OutLineSize * 2, hh - self.Panel.OutLineSize * 2)
    end

    function add:DoClick()
        self:SetDisabled(true)

        local value = input:GetValue()
        local wsid = tonumber(value)

        if not wsid then
            local match = value:match("id=(%d+)")
            wsid = tonumber(match)
        end

        if wsid and not DOWNLOADER.Addons[wsid] then
            input:SetValue("")

            steamworks.FileInfo(wsid, function(result)
                if result then
                    DOWNLOADER.Addons[wsid] = {
                        Mode = DOWNLOADER.Mode.Disabled,
                        CachedInfo = result
                    }

                    if IsValid(self.Panel) then
                        self.Panel:RenderAddon(DOWNLOADER.Addons[wsid])
                        self.Panel.Scroll.VBar:AnimateTo(self.Panel.Scroll:GetCanvas():GetTall(), 0.5, 0, 0.5)
                        self.Panel:SendToServer(wsid)
                    end
                end

                self:SetDisabled(false)
            end)
        else
            self:SetDisabled(false)
        end
    end
end

function panel:RenderScroll()
    self.Scroll = vgui.Create("DScrollPanel", self)

    self.Scroll.VBar.Paint = function(s, w, h)
        draw.RoundedBox(4, 3, 13, 8, h - 24, ColorAlpha(color_black, 100))
    end

    self.Scroll.VBar.btnUp.Paint = function(s, w, h) end
    self.Scroll.VBar.btnDown.Paint = function(s, w, h) end

    self.Scroll.VBar.btnGrip.Paint = function(s, w, h)
        draw.RoundedBox(4, 5, 0, 4, h + 22, Color(38, 65, 92))
    end

    self.Scroll:DockMargin(0, self.OutLineSize, 0, self.OutLineSize)
    self.Scroll:Dock(FILL)
    -- self.Scroll:SetSize(self:GetWide(), self:GetTall() - self.HeaderSize - 20)
    -- self.Scroll:SetPos(0, self.HeaderSize)
end

function panel:Close()
    self:Remove()
end

function panel:Paint(w, h)
    Derma_DrawBackgroundBlur(self, self._startTime)
    surface.SetDrawColor(Color(38, 65, 92))
    surface.DrawRect(0, 0, w, h)
    surface.SetDrawColor(Color(35, 35, 35))
    surface.DrawRect(self.OutLineSize, self.OutLineSize, w - self.OutLineSize * 2, h - self.OutLineSize * 2)
end

function panel:SendToServer(wsid)
    wsid = tonumber(wsid)
    local mode = DOWNLOADER.Addons[wsid].Mode

    DOWNLOADER:SetAddon(wsid, mode)
end

vgui.Register("DownloaderMenu", panel, "EditablePanel")
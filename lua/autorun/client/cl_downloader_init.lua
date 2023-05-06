if game.SinglePlayer() or not GetConVar("downloader_gui_enabled"):GetBool() then
    return
end

surface.CreateFont("uwd_panel_font", {
    font = "Arial",
    extended = false,
    size = 12,
    weight = 500,
    blursize = 0,
    scanlines = 0,
    antialias = true,
    underline = false,
    italic = false,
    strikeout = false,
    symbol = false,
    rotary = false,
    shadow = true,
    additive = false,
    outline = false,
})

local FILTER = {
    ALL = 0,
    SELECTED = 1,
    IGNORED = 2,
    MANUAL = 3
}

local Browser = {}

Browser.initialized = false

Browser.cacheFile = "uwd/browser_cache.txt"

Browser.topBar = 25
Browser.border = 10
Browser.backgroundColor = Color(255, 255, 255, 255)

Browser.titleBarBackgroundColor = Color(37, 37, 37, 255)

Browser.iconSize = 150
Browser.iconTextHeight = 25
Browser.controlButtonsWidth = 100

Browser.commonHeight = 25
Browser.scrollBarWidth = 15
Browser.filterWidth = 125

Browser.maxIconsWidth = math.floor((ScrW() * 0.8) / Browser.iconSize)
Browser.maxIconsHeight = math.floor((ScrH() * 0.9) / Browser.iconSize)

Browser.width = Browser.maxIconsWidth * Browser.iconSize + Browser.maxIconsWidth * Browser.border + Browser.border + Browser.scrollBarWidth
Browser.height = Browser.maxIconsHeight * Browser.iconSize + Browser.maxIconsHeight * Browser.border + Browser.border + Browser.topBar

Browser.iconBackgroundColor = {
    ignored = Color(246, 255, 228),
    selected = Color(188, 235, 96),
    restart = Color(255, 130, 130),
    rejoin = Color(255, 255, 71)
}

function Browser:LoadCache()
    local cache = file.Read(self.cacheFile, "DATA")
    self.cache = util.JSONToTable(cache or "{}")
end

function Browser:SaveCache()
    file.Write(self.cacheFile, util.TableToJSON(self.cache))
end

function Browser:Open(scanResult)
    if scanResult then
        self.scanResult = scanResult
    end

    if self.initialized then
        self.frame:SetVisible(true)
    else
        self:SetupBasePanels()
        self:LoadCache()
        self:PopulateList()
        self.initialized = true
    end
end

function Browser:SetupBasePanels()
    if self.initialized then return end

    self.frame = vgui.Create("DFrame")
    self.frame:SetTitle("Ultimate Workshop Downloader")
    self.frame:SetSize(self.width, self.height)
    self.frame:SetDeleteOnClose(false)
    self.frame:SetIcon("games/16/all.png")
    self.frame:SetVisible(true)
    self.frame:Center()
    self.frame:MakePopup()
    function Browser:Close()
        self:SetVisible(false)
    end

    -- Element properties

    local panelInfo = {
        width = self.frame:GetWide(),
        height = self.frame:GetTall() - self.topBar,
        x = 0,
        y = self.topBar
    }

    local panelTitleInfo = {
        width = self.frame:GetWide(),
        height = self.topBar,
        x = 0,
        y = 0
    }

    local filterInfo = {
        width = self.filterWidth,
        height = self.commonHeight,
        x = self.frame:GetWide() - self.filterWidth - self.controlButtonsWidth,
        y = 0
    }

    local addonsScrollInfo = {
        width = self.frame:GetWide() - self.border,
        height = self.frame:GetTall() - self.topBar - self.border * 2,
        x = self.border,
        y = self.border
    }

    -- Main area
    self.panel = vgui.Create("DPanel", self.frame)
    self.panel:SetSize(panelInfo.width, panelInfo.height)
    self.panel:SetPos(panelInfo.x, panelInfo.y)
    self.panel:SetBackgroundColor(Browser.backgroundColor)

    -- Alert text
    self.alertTextBackground = vgui.Create("DPanel", self.frame)
    self.alertTextBackground:SetPos(0, self.iconSize - self.iconTextHeight)
    self.alertTextBackground:SetBackgroundColor(iconBackgroundColor)
    self.alertTextBackground:SetVisible(false)

    self.alertText = vgui.Create("DLabel", self.alertTextBackground)
    self.alertText:SetPos(5, 5)
    self.alertText:SetColor(Color(0, 0, 0, 255))

    -- Icons list
    self.addonsScroll = vgui.Create("DScrollPanel", self.panel)
    self.addonsScroll:SetSize(addonsScrollInfo.width, addonsScrollInfo.height)
    self.addonsScroll:SetPos(addonsScrollInfo.x, addonsScrollInfo.y)

    self.addonsList = vgui.Create("DIconLayout", self.addonsScroll)
    self.addonsList:Dock(FILL)
    self.addonsList:SetSpaceY(self.border)
    self.addonsList:SetSpaceX(self.border)
    self.addonsList:IsHovered()
    self.addonsList.void = {} -- Used to hide elements when filtering

    -- Filter
    self.filter = vgui.Create("DComboBox", self.frame)
    self.filter:SetSize(filterInfo.width, filterInfo.height)
    self.filter:SetPos(filterInfo.x, filterInfo.y)
    self.filter:AddChoice("All", FILTER.ALL, false, "icon16/box.png")
    self.filter:AddChoice("Selected", FILTER.SELECTED, false, "icon16/accept.png")
    self.filter:AddChoice("Ignored", FILTER.IGNORED, false, "icon16/delete.png")
    self.filter:AddChoice("Manual", FILTER.MANUAL, false, "icon16/pencil.png")
    self.filter:SetText("All")
    self.filter.OnSelect = function(self, index, value)
        Browser:FilterAddons(self:GetOptionData(index))
    end
end

-- An alert message saying what's needed to fully apply the changes
function Browser:SetAlertText()
    -- Check if the message is needed and show or hide the panel
    local found
    for wsid, resultInfo in pairs(self.scanResult) do
        if resultInfo.manual ~= nil then
            if resultInfo.manual == true then
                if not self.scanResult[wsid].selected then
                    found = "Select"
                end
            else
                found = "Ignore"
                break
            end
        end
    end

    if not found then
        if self.alertTextBackground:IsVisible() then
            self.alertTextBackground:SetVisible(false)
        end

        return
    end

    if not self.alertTextBackground:IsVisible() then
        self.alertTextBackground:SetVisible(true)
    end

    -- Set the correct message / background color and resize the element
    if found == "Select" then
        self.alertText:SetText("You need to rejoin the server to download the new selected addons.")
        self.alertTextBackground:SetBackgroundColor(self.iconBackgroundColor.rejoin)
    elseif found == "Ignore" then
        self.alertText:SetText("The server needs to be restarted to remove new ignored or previously selected addons.")
        self.alertTextBackground:SetBackgroundColor(self.iconBackgroundColor.restart)
    end
    self.alertText:SizeToContents()

    self.alertTextBackground:SizeToChildren(true, true)
    local alertBackW = self.alertTextBackground:GetWide() + 5

    local alertTextInfo = {
        width = alertBackW,
        height = self.commonHeight,
        x = self.frame:GetWide()/2 - alertBackW/2,
        y = 0
    }

    self.alertTextBackground:SetSize(alertTextInfo.width, alertTextInfo.height)
    self.alertTextBackground:SetPos(alertTextInfo.x, alertTextInfo.y)
end

-- Fill up the menu with the addons, always sorted by name
function Browser:PopulateList()
    local addons = engine.GetAddons() -- I get the addon names locally instead of sending them through net
    local baseDelayNotFound = 0.05
    local baseDelayFound = 0.025
    local delay = 0.45

    table.sort(addons, function(a, b) return string.lower(a.title) < string.lower(b.title) end)

    for k, addonInfo in ipairs(addons) do
        local wsid = tonumber(addonInfo.wsid) -- Note: loading the cache from a json always converts the wsid to number

        if not self.scanResult[wsid] then continue end -- Ignore unmounted addons

        local iconBackgroundColor
        if self.scanResult[wsid].cachedManual == nil and self.scanResult[wsid].selected or self.scanResult[wsid].cachedManual then
            iconBackgroundColor = self.iconBackgroundColor.selected
        else
            iconBackgroundColor = self.iconBackgroundColor.ignored
        end

        local iconArea = self.addonsList:Add(vgui.Create("DPanel"))
        iconArea:SetSize(self.iconSize, self.iconSize)
        iconArea:SetBackgroundColor(iconBackgroundColor)

        self.scanResult[wsid].iconArea = iconArea

        local contentSize = self.iconSize * 0.94
        local contentBorder = self.iconSize * 0.06 / 2

        local iconBackground = vgui.Create("DPanel", iconArea)
        iconBackground:SetPos(contentBorder, contentBorder)
        iconBackground:SetSize(contentSize, contentSize)

        local iconTitleBackground = vgui.Create("DPanel", iconArea)
        iconTitleBackground:SetSize(self.iconSize, self.iconTextHeight)
        iconTitleBackground:SetBackgroundColor(iconBackgroundColor)
        iconTitleBackground:SetTooltip(addonInfo.title)

        local iconTitle = vgui.Create("DLabel", iconTitleBackground)
        iconTitle:SetWide(self.iconSize)
        iconTitle:SetPos(5, 2)
        iconTitle:SetText(addonInfo.title)
        iconTitle:SetColor(Color(0, 0, 0, 255))

        local manualAlertBackground = vgui.Create("DPanel", iconArea)
        manualAlertBackground:SetPos(0, self.iconSize - self.iconTextHeight * 2 - self.border)
        manualAlertBackground:SetBackgroundColor(iconBackgroundColor)

        local manualAlert = vgui.Create("DLabel", manualAlertBackground)
        manualAlert:SetPos(5, 5)
        manualAlert:SetText("Manual")
        manualAlert:SetColor(Color(0, 0, 0, 255))

        manualAlertBackground:Hide()
        if self.scanResult[wsid].cachedManual ~= nil and self.scanResult[wsid].cachedManual ~= self.scanResult[wsid].selected then
            manualAlertBackground:Show()
        end

        manualAlert:SizeToContents()

        manualAlertBackground:SizeToChildren(true, true)
        local manualBackW = manualAlertBackground:GetWide()
        manualAlertBackground:SetSize(manualBackW + 5, self.commonHeight)

        local iconTypeBackground = vgui.Create("DPanel", iconArea)
        iconTypeBackground:SetPos(0, self.iconSize - self.iconTextHeight)
        iconTypeBackground:SetBackgroundColor(iconBackgroundColor)

        local iconType = vgui.Create("DLabel", iconTypeBackground)
        iconType:SetPos(5, 5)
        iconType:SetText(self.scanResult[wsid].type)
        iconType:SetColor(Color(0, 0, 0, 255))
        iconType:SizeToContents()

        iconTypeBackground:SizeToChildren(true, true)
        local typeBackW = iconTypeBackground:GetWide()
        iconTypeBackground:SetSize(typeBackW + 5, self.commonHeight)

        local icon = vgui.Create("DImageButton", iconBackground)
        icon:SetSize(contentSize, contentSize)
        icon:SetPos(0, 0)
        icon:SetTooltip("Left Click - Toggle | Right Click - Open on Workshop")
        icon.OnDepressed = function()
            -- Workshop page
            if input.IsMouseDown(108) then -- MOUSE_RIGHT
                steamworks.ViewFile(wsid)
            -- Toggle selection
            elseif input.IsMouseDown(107) then -- MOUSE_LEFT
                if not LocalPlayer():IsAdmin() then return end

                -- Get the initial state
                local initialState
                if self.scanResult[wsid].cachedManual ~= nil then
                    initialState = self.scanResult[wsid].cachedManual
                else
                    initialState = self.scanResult[wsid].selected
                end

                -- Initialize the new manual state
                if self.scanResult[wsid].manual == nil then
                    self.scanResult[wsid].manual = not initialState
                else
                    self.scanResult[wsid].manual = not self.scanResult[wsid].manual
                end

                -- Change the Manual panel message and show or hide it
                if self.scanResult[wsid].cachedManual ~= nil and
                   self.scanResult[wsid].cachedManual ~= self.scanResult[wsid].selected
                then
                    if self.scanResult[wsid].manual == initialState then
                        manualAlertBackground:Show()
                    else
                        manualAlertBackground:Hide()
                    end
                else
                    if self.scanResult[wsid].manual == initialState then
                        manualAlertBackground:Hide()
                    else
                        manualAlertBackground:Show()
                    end
                end

                iconType:SizeToContents()

                iconTypeBackground:SizeToChildren(true, true)
                local backW = iconTypeBackground:GetWide()
                iconTypeBackground:SetSize(backW + 5, backW + 2)

                -- Change general background colors
                if self.scanResult[wsid].manual == true then
                    local backgroundColor

                    if initialState then
                        backgroundColor = self.iconBackgroundColor.selected
                    else
                        backgroundColor = self.iconBackgroundColor.rejoin
                    end

                    iconArea:SetBackgroundColor(backgroundColor)
                    iconTitleBackground:SetBackgroundColor(backgroundColor)
                    iconTypeBackground:SetBackgroundColor(backgroundColor)
                    manualAlertBackground:SetBackgroundColor(backgroundColor)
                else
                    iconArea:SetBackgroundColor(self.iconBackgroundColor.restart)
                    iconTitleBackground:SetBackgroundColor(self.iconBackgroundColor.restart)
                    iconTypeBackground:SetBackgroundColor(self.iconBackgroundColor.restart)
                    manualAlertBackground:SetBackgroundColor(self.iconBackgroundColor.restart)
                end

                -- Add the alert message to the top of the page saying what's needed to fully apply the changes
                self:SetAlertText()

                -- Set the new value on the server
                net.Start("uwd_set_manual_selection")
                net.WriteString(tostring(wsid))
                net.WriteBool(self.scanResult[wsid].manual)
                net.SendToServer()
            end
        end

        -- The images will be retrieved from the workshop or from the cache
        -- while the delay make sure we don't send too many requests neither
        -- read too much info from the disk at the same time. I save the cache
        -- every 20 new downloads and when the process is done (given at least
        -- 1 new image was downloaded)
        local iteratingNewAddons = 0
        if self.cache[wsid] and file.Exists(self.cache[wsid], "GAME") then
            delay = delay + baseDelayFound
            timer.Simple(delay, function()
                if IsValid(self.frame) and IsValid(icon) then
                    local iconMaterial = AddonMaterial(self.cache[wsid])
                    icon:SetMaterial(iconMaterial)
                end
            end)
        else
            delay = delay + baseDelayNotFound
            iteratingNewAddons = iteratingNewAddons + 1
            timer.Simple(delay, function()
                steamworks.FileInfo(addonInfo.wsid, function(result)
                    steamworks.Download(result.previewid, true, function(cachePath)
                        if IsValid(self.frame) and IsValid(icon) then
                            local iconMaterial = AddonMaterial(cachePath)
                            icon:SetMaterial(iconMaterial)
                            self.cache[wsid] = cachePath
                        end
                    end) 
                end)
            end)
        end

        if iteratingNewAddons == 20 or (k == #addons and iteratingNewAddons != 0) then
            iteratingNewAddons = 0
            timer.Simple(delay + 1, function()
                if IsValid(self.frame) then
                    self:SaveCache()
                end
            end)
        end
    end
end

-- Filter the addons by type, always sorted by name
function Browser:FilterAddons(selectedValue)
    -- Getting addons
    local addons = engine.GetAddons()

    table.sort(addons, function(a, b) return string.lower(a.title) < string.lower(b.title) end)

    -- Move all icons to the void and hide them
    for k, addonInfo in ipairs(addons) do
        local wsid = tonumber(addonInfo.wsid)
        local scanInfo = self.scanResult[wsid]

        if not scanInfo then continue end

        if IsValid(scanInfo.iconArea) then
            scanInfo.iconArea:SetParent(self.addonsList.void)
            scanInfo.iconArea:Hide()
        end    
    end

    -- Move the selected icons back to the panel and make sure they appear
    for k, addonInfo in ipairs(addons) do
        local wsid = tonumber(addonInfo.wsid)
        local scanInfo = self.scanResult[wsid]

        if not scanInfo then continue end

        if IsValid(scanInfo.iconArea) then
            if selectedValue == FILTER.ALL then
                scanInfo.iconArea:Show()
                scanInfo.iconArea:SetParent(self.addonsList)
            elseif selectedValue == FILTER.SELECTED then
                if scanInfo.manual == nil and scanInfo.cachedManual == nil and scanInfo.selected == true or
                   scanInfo.manual == nil and scanInfo.cachedManual == true or
                   scanInfo.manual == true
                then
                    scanInfo.iconArea:Show()
                    scanInfo.iconArea:SetParent(self.addonsList)
                end
            elseif selectedValue == FILTER.IGNORED then
                if scanInfo.manual == nil and scanInfo.cachedManual == nil and scanInfo.selected == false or
                   scanInfo.manual == nil and scanInfo.cachedManual == false or
                   scanInfo.manual == false
                then
                    scanInfo.iconArea:Show()
                    scanInfo.iconArea:SetParent(self.addonsList)
                end
            elseif selectedValue == FILTER.MANUAL then
                if scanInfo.manual == nil and scanInfo.cachedManual ~= nil and scanInfo.cachedManual ~= scanInfo.selected or
                   scanInfo.manual ~= nil and scanInfo.manual ~= scanInfo.selected
                then
                    scanInfo.iconArea:Show()
                    scanInfo.iconArea:SetParent(self.addonsList)
                end
            end
        end  
    end

    -- Refresh the scroll bar
    timer.Simple(0.2, function()
        if IsValid(self.frame) and IsValid(self.addonsScroll) then
            self.addonsScroll:InvalidateLayout()
        end
    end)
end

do
    local receivedTab = {}
    net.Receive("uwd_exchange_scan_result", function(len, ply)
        local chunksID = net.ReadString()
        local chunksSubID = net.ReadUInt(32)
        local len = net.ReadUInt(16)
        local chunk = net.ReadData(len)
        local isLastChunk = net.ReadBool()

        -- Initialize streams or reset overwriten ones
        if not receivedTab[chunksID] or receivedTab[chunksID].chunksSubID ~= chunksSubID then
            receivedTab[chunksID] = {
                chunksSubID = chunksSubID,
                data = ""
            }

            -- 3 minutes to remove possible memory leaks
            timer.Create(chunksID, 180, 1, function()
                receivedTab[chunksID] = nil
            end)
        end

        -- Rebuild the compressed string
        receivedTab[chunksID].data = receivedTab[chunksID].data .. chunk

        -- Finish stream
        if isLastChunk then
            local data = receivedTab[chunksID].data

            Browser:Open(util.JSONToTable(util.Decompress(data)))
        end
    end)
end

concommand.Add("downloader_page", function()
    steamworks.ViewFile(2214712098)
end)

concommand.Add("downloader_menu", function()
    if Browser.scanResult then
        Browser:Open()
    else
        net.Start("uwd_exchange_scan_result")
        net.SendToServer()
    end
end)




local function CPanel(self)
    self:Help("UWD - Install and forget.")
    self:Button("Open Menu", "downloader_menu")
    self:ControlHelp("- Automatic")
    self:ControlHelp("- Intelligent addon selection")
    self:ControlHelp("- Extremely fast")
    self:ControlHelp("- Secure")
    self:ControlHelp("- For listen and dedicated servers")
    self:ControlHelp("- Supports legacy addons")
    self:ControlHelp("- Has an easy yet powerful panel")
    self:ControlHelp("- Validates pointshop models")
    self:ControlHelp("- Actually works")
    self:Help("If you find any addons that were not detected, please report them to us!")
    self:Button("Report Error", "downloader_page")
end

hook.Add("PopulateToolMenu", "All hail the menus", function ()
    spawnmenu.AddToolMenuOption("Utilities", "Ultimate Workshop Downloder", "Addons", "Addons", "", "", CPanel)
end)

-- Tests

-- if UWD_Test and IsValid(UWD_Test.frame) then
--     UWD_Test.frame:Remove()
-- end

-- UWD_Test = Browser

-- if Browser.scanResult then
--     Browser:Open()
-- else
--     net.Start("uwd_exchange_scan_result")
--     net.SendToServer()
-- end

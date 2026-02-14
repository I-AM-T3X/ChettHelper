local addonName, addon = ...

addon.configCreated = false
addon.settingsCategory = nil

function addon:CreateConfig()
    if self.configCreated then return end
    self.configCreated = true
    
    local settingsPanel = CreateFrame("FRAME", "CHETTHelperSettingsPanel")
    settingsPanel.name = "CHETT Helper"
    
    -- Title
    local title = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetText("|cffffd100Settings|r")
    title:SetFontObject("GameFontNormalHuge")
    
    -- Subtitle
    local subtitle = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -4)
    subtitle:SetText("Configure which quests to track and display preferences")
    subtitle:SetTextColor(0.7, 0.7, 0.7, 1)
    
    -- Helper function to create section boxes
    local function CreateSection(parent, headerText, descText, yPos, height)
        local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        box:SetPoint("TOPLEFT", 16, yPos)
        box:SetPoint("TOPRIGHT", -16, yPos)
        box:SetHeight(height)
        box:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            tile = true, tileSize = 32, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        box:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        box:SetBackdropColor(0, 0, 0, 0.8)
        
        local header = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        header:SetPoint("TOPLEFT", 12, -10)
        header:SetText("|cffffd100" .. headerText .. "|r")
        header:SetFontObject("GameFontNormalLarge")
        
        if descText then
            local desc = box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            desc:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
            desc:SetText(descText)
            desc:SetTextColor(0.7, 0.7, 0.7, 1)
        end
        
        return box
    end
    
    -- Section 1: Quest Tracking
    local questBox = CreateSection(settingsPanel, "Quest Tracking", "Select which C.H.E.T.T. List tasks to display", -50, 140)
    
    local colWidth = 145
    local rowHeight = 20
    local startX = 12
    local startY = -42
    
    for i, quest in ipairs(addon.QUESTS) do
        local col = (i - 1) % 4
        local row = math.floor((i - 1) / 4)
        
        local cb = CreateFrame("CheckButton", "CHETTCheck"..quest.key, questBox, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", startX + (col * colWidth), startY - (row * rowHeight))
        cb.Text:SetText(quest.name)
        cb.Text:SetFontObject("GameFontNormalSmall")
        cb:SetChecked(self.Settings[quest.key])
        cb:SetScript("OnClick", function(selfBtn)
            addon.Settings[quest.key] = selfBtn:GetChecked()
            CHETTHelperDB[quest.key] = selfBtn:GetChecked()
            addon:UpdateQuestList()
        end)
    end
    
    -- Section 2: Display Options
    local displayBox = CreateSection(settingsPanel, "Display Options", "Customize the appearance of the quest list", -200, 95)
    
    -- Font Size
    local fontLabel = displayBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fontLabel:SetPoint("TOPLEFT", 12, -40)
    fontLabel:SetText("Font Size")
    fontLabel:SetTextColor(0.8, 0.8, 0.8, 1)
    
    local fontValue = displayBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fontValue:SetPoint("LEFT", fontLabel, "RIGHT", 8, 0)
    fontValue:SetText(self.Settings.fontSize or addon.DEFAULT_FONT_SIZE)
    fontValue:SetTextColor(1, 0.82, 0, 1)
    
    local slider = CreateFrame("Slider", "CHETTFontSizeSlider", displayBox, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", fontLabel, "BOTTOMLEFT", 0, -6)
    slider:SetWidth(200)
    slider:SetHeight(16)
    slider:SetMinMaxValues(10, 32)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(self.Settings.fontSize or addon.DEFAULT_FONT_SIZE)
    
    _G[slider:GetName().."Low"]:SetText("10")
    _G[slider:GetName().."High"]:SetText("32")
    _G[slider:GetName().."Text"]:SetText("")
    
    slider:SetScript("OnValueChanged", function(selfSlider, value)
        value = math.floor(value + 0.5)
        addon.Settings.fontSize = value
        CHETTHelperDB.fontSize = value
        fontValue:SetText(value)
        addon:UpdateQuestList()
    end)
    
    -- Growth Direction
    local growLabel = displayBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    growLabel:SetPoint("TOPLEFT", 280, -40)
    growLabel:SetText("Growth Direction")
    growLabel:SetTextColor(0.8, 0.8, 0.8, 1)
    
    local growDropdown = CreateFrame("Frame", "CHETTGrowDropdown", displayBox, "UIDropDownMenuTemplate")
    growDropdown:SetPoint("TOPLEFT", growLabel, "BOTTOMLEFT", -16, -2)
    
    local function GrowDropdown_OnClick(_, arg1)
        addon.Settings.growDirection = arg1
        CHETTHelperDB.growDirection = arg1
        UIDropDownMenu_SetText(growDropdown, arg1 == "UP" and "Grow Up" or "Grow Down")
        addon:UpdateQuestList()
    end
    
    UIDropDownMenu_SetWidth(growDropdown, 140)
    UIDropDownMenu_SetText(growDropdown, (self.Settings.growDirection or "DOWN") == "UP" and "Grow Up" or "Grow Down")
    
    UIDropDownMenu_Initialize(growDropdown, function(_, _, _)
        local info = UIDropDownMenu_CreateInfo()
        
        info.text = "Grow Down"
        info.arg1 = "DOWN"
        info.func = GrowDropdown_OnClick
        info.checked = (addon.Settings.growDirection or "DOWN") == "DOWN"
        UIDropDownMenu_AddButton(info)
        
        info.text = "Grow Up"
        info.arg1 = "UP"
        info.func = GrowDropdown_OnClick
        info.checked = (addon.Settings.growDirection or "DOWN") == "UP"
        UIDropDownMenu_AddButton(info)
    end)
    
    -- Section 3: Automation Options
    local autoBox = CreateSection(settingsPanel, "Automation Options", "Convenient quality-of-life features for Undermine", -305, 90)
    
    local autoCB1 = CreateFrame("CheckButton", "CHETTAutoTake", autoBox, "InterfaceOptionsCheckButtonTemplate")
    autoCB1:SetPoint("TOPLEFT", 12, -38)
    autoCB1.Text:SetText("Auto-take free weekly C.H.E.T.T. List")
    autoCB1.Text:SetFontObject("GameFontNormalSmall")
    autoCB1:SetChecked(self.Settings.autoTake)
    autoCB1:SetScript("OnClick", function(selfBtn) 
        addon.Settings.autoTake = selfBtn:GetChecked() 
        CHETTHelperDB.autoTake = selfBtn:GetChecked()
    end)
    
    local autoCB2 = CreateFrame("CheckButton", "CHETTSkipGossip", autoBox, "InterfaceOptionsCheckButtonTemplate")
    autoCB2:SetPoint("TOPLEFT", 320, -38)
    autoCB2.Text:SetText("Auto-skip rare/scrap gossip")
    autoCB2.Text:SetFontObject("GameFontNormalSmall")
    autoCB2:SetChecked(self.Settings.skipGossip)
    autoCB2:SetScript("OnClick", function(selfBtn) 
        addon.Settings.skipGossip = selfBtn:GetChecked() 
        CHETTHelperDB.skipGossip = selfBtn:GetChecked()
    end)
    
    local autoCB3 = CreateFrame("CheckButton", "CHETTSkipDrills", autoBox, "InterfaceOptionsCheckButtonTemplate")
    autoCB3:SetPoint("TOPLEFT", 12, -62)
    autoCB3.Text:SetText("Auto-skip drill gossip")
    autoCB3.Text:SetFontObject("GameFontNormalSmall")
    autoCB3:SetChecked(self.Settings.skipDrills)
    autoCB3:SetScript("OnClick", function(selfBtn) 
        addon.Settings.skipDrills = selfBtn:GetChecked() 
        CHETTHelperDB.skipDrills = selfBtn:GetChecked()
    end)
    
    -- Bottom Note
    local note = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    note:SetPoint("BOTTOM", 0, 16)
    note:SetText("Note: Settings are saved per character. Use /chb to open this panel.")
    note:SetTextColor(0.5, 0.5, 0.5, 1)
    
    local category = Settings.RegisterCanvasLayoutCategory(settingsPanel, settingsPanel.name)
    Settings.RegisterAddOnCategory(category)
    self.settingsCategory = category
end
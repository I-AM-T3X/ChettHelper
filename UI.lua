local addonName, addon = ...

-- Main frame
addon.CHETTHelper = nil
addon.questLines = {}
addon.uiCreated = false

-- Settings reference (set by Core)
addon.Settings = {}

local function GetLineSpacing()
    local fontSize = addon.Settings.fontSize or addon.DEFAULT_FONT_SIZE
    return fontSize + 4
end

function addon:GetFrameWidth()
    local fontSize = addon.Settings.fontSize or addon.DEFAULT_FONT_SIZE
    if fontSize > 24 then
        return addon.DEFAULT_WIDTH + ((fontSize - 24) * 8)
    end
    return addon.DEFAULT_WIDTH
end

function addon:CreateUI()
    if self.uiCreated then return end
    self.uiCreated = true
    
    local frame = CreateFrame("Frame", "CHETTHelperFrame", UIParent)
    frame:SetPoint("CENTER", 370, -40)
    frame:SetSize(250, 400)
    frame:SetMovable(true)
    frame:EnableMouse(false)
    frame:SetFrameStrata("LOW")
    
    self.CHETTHelper = frame
    
    -- List button (secure)
    frame.openListBtn = CreateFrame("Button", "CHETTHelperOpenList", frame, "SecureActionButtonTemplate")
    frame.openListBtn:SetSize(40, 40)
    frame.openListBtn:SetPoint("CENTER", frame, "TOP", 0, -20)
    frame.openListBtn:SetFrameStrata("MEDIUM")
    frame.openListBtn:SetFrameLevel(5)
    frame.openListBtn:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
    frame.openListBtn:RegisterForDrag("LeftButton")
    frame.openListBtn:SetAttribute("type", "macro")
    frame.openListBtn:SetAttribute("macrotext", "/use item:" .. addon.C_HETT_LIST_ITEM)
    frame.openListBtn:EnableMouse(true)
    
    local icon = frame.openListBtn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture(C_Item.GetItemIconByID(addon.C_HETT_LIST_ITEM) or 134391)
    frame.openListBtn.icon = icon
    
    local border = CreateFrame("Frame", nil, frame.openListBtn, "BackdropTemplate")
    border:SetAllPoints()
    border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
    })
    border:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
    
    frame.openListBtn.check = frame.openListBtn:CreateTexture(nil, "OVERLAY")
    frame.openListBtn.check:SetSize(32, 32)
    frame.openListBtn.check:SetPoint("CENTER")
    frame.openListBtn.check:SetAtlas("common-icon-checkmark-yellow")
    frame.openListBtn.check:Hide()
    
    frame.openListBtn.glow = frame.openListBtn:CreateTexture(nil, "OVERLAY")
    frame.openListBtn.glow:SetAtlas("UI-ActionButton-Border")
    frame.openListBtn.glow:SetBlendMode("ADD")
    frame.openListBtn.glow:SetSize(70, 70)
    frame.openListBtn.glow:SetPoint("CENTER")
    frame.openListBtn.glow:Hide()
    
    frame.openListBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("C.H.E.T.T. Helper")
        if addon:HasCHETTList() then
            GameTooltip:AddLine("Click to open C.H.E.T.T. List", 0.8, 0.8, 0.8, true)
        else
            GameTooltip:AddLine("Get a C.H.E.T.T. List from a Cartel vendor!", 1, 0.4, 0.4, true)
        end
        GameTooltip:Show()
    end)
    frame.openListBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame.openListBtn:SetScript("OnDragStart", function() frame:StartMoving() end)
    frame.openListBtn:SetScript("OnDragStop", function() 
        frame:StopMovingOrSizing() 
        addon:SaveFramePosition() -- SAVE POSITION
    end)
    
    -- Buy rep button (secure)
    frame.buyRepBtn = CreateFrame("Button", "CHETTHelperBuyRep", frame, "SecureActionButtonTemplate")
    frame.buyRepBtn:SetSize(40, 40)
    frame.buyRepBtn:SetPoint("CENTER", frame.openListBtn, "CENTER", 0, 0)
    frame.buyRepBtn:SetFrameStrata("MEDIUM")
    frame.buyRepBtn:SetFrameLevel(5)
    frame.buyRepBtn:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
    frame.buyRepBtn:RegisterForDrag("LeftButton")
    frame.buyRepBtn:SetAttribute("type", "macro")
    frame.buyRepBtn:SetAttribute("macrotext", "/run BuyMerchantItem(8,1)")
    frame.buyRepBtn:Hide()
    frame.buyRepBtn:EnableMouse(true)
    
    local repIcon = frame.buyRepBtn:CreateTexture(nil, "ARTWORK")
    repIcon:SetAllPoints()
    repIcon:SetTexture(1519430)
    frame.buyRepBtn.icon = repIcon
    
    frame.buyRepBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Buy Cartel Reputation")
        GameTooltip:AddLine("Click to purchase reputation item", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    frame.buyRepBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame.buyRepBtn:SetScript("OnDragStart", function() frame:StartMoving() end)
    frame.buyRepBtn:SetScript("OnDragStop", function() 
        frame:StopMovingOrSizing() 
        addon:SaveFramePosition() -- SAVE POSITION
    end)
    
    -- Quest frame
    frame.questFrame = CreateFrame("Frame", nil, frame)
    frame.questFrame:SetPoint("TOP", frame.openListBtn, "BOTTOM", 0, -5)
    frame.questFrame:SetSize(250, 350)
    frame.questFrame:EnableMouse(false)
    
    -- Quest lines
    local lineSpacing = GetLineSpacing()
    for i, quest in ipairs(addon.QUESTS) do
        local line = frame.questFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        line:SetFont(addon.FONT, addon.Settings.fontSize or addon.DEFAULT_FONT_SIZE, "OUTLINE")
        line:SetPoint("TOP", frame.questFrame, "TOP", 0, -(i-1) * lineSpacing)
        line:SetJustifyH("CENTER")
        line:SetWidth(250)
        line:SetTextColor(1, 1, 1, 1)
        line:SetWordWrap(false)
        addon.questLines[i] = line
        
        if quest.special == "gig" then
            line.icon = frame.questFrame:CreateTexture(nil, "OVERLAY")
            line.icon:SetSize(20, 20)
            line.icon:SetPoint("RIGHT", line, "LEFT", -5, 0)
            line.icon:SetAtlas("quest-recurring-turnin")
            line.icon:Hide()
        end
    end
end

function addon:UpdateQuestList()
    if InCombatLockdown() then
        self.needsUpdate = true
        return
    end
    self.needsUpdate = false
    
    if not self:IsInValidZone() then
        self.CHETTHelper:Hide()
        return
    end
    
    if self:IsWeeklyCompleted() and not self:HasCHETTList() then
        self.CHETTHelper:Hide()
        return
    end
    
    self.CHETTHelper:Show()
    
    local frameWidth = self:GetFrameWidth()
    self.CHETTHelper:SetWidth(frameWidth)
    self.CHETTHelper.questFrame:SetWidth(frameWidth)
    
    for _, line in ipairs(self.questLines) do
        line:SetWidth(frameWidth)
    end
    
    self.CHETTHelper.questFrame:ClearAllPoints()
    if self.Settings.growDirection == "UP" then
        self.CHETTHelper.questFrame:SetPoint("BOTTOM", self.CHETTHelper.openListBtn, "TOP", 0, 5)
    else
        self.CHETTHelper.questFrame:SetPoint("TOP", self.CHETTHelper.openListBtn, "BOTTOM", 0, -5)
    end
    
    local hasListNow = self:HasCHETTList()
    if hasListNow and not self.hadListPreviously then
        self:ClearQuestCache()
    end
    self.hadListPreviously = hasListNow
    
    for _, quest in ipairs(addon.QUESTS) do
        if quest.id ~= -1 and C_QuestLog.IsQuestFlaggedCompleted(quest.id) then
            self:CacheQuestCompletion(quest.id)
        end
    end
    
    if not hasListNow then
        self.CHETTHelper.questFrame:Hide()
        self.CHETTHelper.openListBtn:Show()
        self.CHETTHelper.buyRepBtn:Hide()
        self.CHETTHelper.openListBtn.check:Hide()
        self.CHETTHelper.openListBtn.glow:Hide()
        return
    end
    
    local completed = self:GetCompletedCount()
    local ready = self:GetReadyCount()
    self.lastCompletedCount = completed
    
    local allTurnedIn = (completed >= addon.COMPLETION_THRESHOLD and ready == 0)
    
    if allTurnedIn then
        self.CHETTHelper.questFrame:Hide()
        self.CHETTHelper.openListBtn:Hide()
        self.CHETTHelper.buyRepBtn:Show()
    else
        self.CHETTHelper.questFrame:Show()
        self.CHETTHelper.openListBtn:Show()
        self.CHETTHelper.buyRepBtn:Hide()
    end
    
    local visibleIndex = 0
    local fontSize = self.Settings.fontSize or addon.DEFAULT_FONT_SIZE
    local lineSpacing = GetLineSpacing()
    local growUp = self.Settings.growDirection == "UP"
    
    for i, quest in ipairs(addon.QUESTS) do
        local line = self.questLines[i]
        local shouldShow = false
        local isComplete = false
        local isReadyForTurnIn = false
        
        line:SetFont(addon.FONT, fontSize, "OUTLINE")
        
        if quest.key == "gig" then
            shouldShow = C_QuestLog.IsOnQuest(quest.id)
            if shouldShow then
                isComplete = self:IsSideGigCompleted()
                isReadyForTurnIn = self:IsSideGigReady()
            end
        else
            shouldShow = C_QuestLog.IsOnQuest(quest.id) or self:IsQuestCached(quest.id)
            if shouldShow then
                isComplete = C_QuestLog.ReadyForTurnIn(quest.id) or C_QuestLog.IsQuestFlaggedCompleted(quest.id) or self:IsQuestCached(quest.id)
                isReadyForTurnIn = C_QuestLog.ReadyForTurnIn(quest.id)
            end
        end
        
        if self.Settings[quest.key] and shouldShow then
            visibleIndex = visibleIndex + 1
            line:ClearAllPoints()
            
            if growUp then
                line:SetPoint("BOTTOM", self.CHETTHelper.questFrame, "BOTTOM", 0, (visibleIndex-1) * lineSpacing)
            else
                line:SetPoint("TOP", self.CHETTHelper.questFrame, "TOP", 0, -(visibleIndex-1) * lineSpacing)
            end
            
            line:Show()
            
            if isComplete then
                line:SetText("|cff00ff00" .. quest.name .. "|r")
            else
                line:SetText("|cffffffff" .. quest.name .. "|r")
            end
            
            if quest.special == "gig" and line.icon then
                if isReadyForTurnIn and not isComplete then
                    line.icon:Show()
                else
                    line.icon:Hide()
                end
            end
        else
            line:Hide()
            if line.icon then line.icon:Hide() end
        end
    end
    
    if allTurnedIn then
        self.CHETTHelper.openListBtn.check:Show()
        self.CHETTHelper.openListBtn.glow:Hide()
    elseif ready >= 3 then
        self.CHETTHelper.openListBtn.check:Hide()
        self.CHETTHelper.openListBtn.glow:Show()
    else
        self.CHETTHelper.openListBtn.check:Hide()
        self.CHETTHelper.openListBtn.glow:Hide()
    end
end
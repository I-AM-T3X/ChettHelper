local addonName, addon = ...

local SIDE_GIG_QUESTS = {
    [85962] = true, [86178] = true, [85553] = true, [86180] = true,
    [85554] = true, [85945] = true, [85960] = true, [86177] = true,
    [85913] = true, [85944] = true, [85914] = true, [86179] = true,
}

local QUESTS = {
    {id = 86923, name = "50 Fishing Pools",          key = "fish",      default = false},
    {id = 86920, name = "5 Player Kills",            key = "war",       default = false},
    {id = 86924, name = "5 Battle Pets",             key = "pets",      default = false},
    {id = 87304, name = "Excavation Delve",          key = "vacate",    default = false},
    {id = 87303, name = "Sidestreet Delve",          key = "sidestreet",default = true},
    {id = 86917, name = "10 Jobs",                   key = "jobs",      default = true},
    {id = 87302, name = "3 Rares",                   key = "rare",      default = true},
    {id = 86918, name = "100 Scrap Cans",            key = "scrap",     default = true},
    {id = 86919, name = "Side Gig",                  key = "gig",       default = true, special = "gig"},
    {id = 87305, name = "2 Races",                   key = "drive",     default = true},
    {id = 87306, name = "50 Turbo Cans",             key = "turbo",     default = true},
    {id = 87307, name = "25 Dumpsters",              key = "garbage",   default = true},
    {id = 86915, name = "Side with Cartel",          key = "cartel",    default = false},
}

local C_HETT_LIST_ITEM = 235053
local WEEKLY_QUEST_ID = 87296
local COMPLETION_THRESHOLD = 4
local FONT = "Fonts\\FRIZQT__.TTF"

local VALID_ZONES = {
    [2346] = true, [2214] = true, [862] = true, [2396] = true,
}

local GOSSIP_RARE_NPCS = {[234834] = true, [234819] = true, [234751] = true, [236035] = true, [231221] = true}
local GOSSIP_RARE_OPTION = 124544
local GOSSIP_LIST_OPTION = 131991
local GOSSIP_DRILL_OPTIONS = {[125429] = true, [125409] = true, [125433] = true, [125434] = true}

local CHETTHelper = CreateFrame("Frame", "CHETTHelperFrame", UIParent)
CHETTHelper:SetPoint("CENTER", 370, -40)
CHETTHelper:SetMovable(true)
CHETTHelper:EnableMouse(true)
CHETTHelper:RegisterForDrag("LeftButton")
CHETTHelper:SetFrameStrata("LOW")

local CHETTSettings = {}
local lastCompletedCount = 0
local sideGigCompletionCache = {}
local hadListPreviously = false
local needsUpdate = false

local function IsInValidZone()
    local mapID = C_Map.GetBestMapForUnit("player")
    return mapID and VALID_ZONES[mapID] or false
end

local function HasCHETTList()
    return C_Item.GetItemCount(C_HETT_LIST_ITEM, false) > 0
end

local function IsWeeklyCompleted()
    return C_QuestLog.IsQuestFlaggedCompleted(WEEKLY_QUEST_ID)
end

local function IsSideGigCompleted()
    for questID, _ in pairs(SIDE_GIG_QUESTS) do
        if C_QuestLog.IsQuestFlaggedCompleted(questID) or sideGigCompletionCache[questID] then
            return true
        end
    end
    return false
end

local function IsSideGigReady()
    for questID, _ in pairs(SIDE_GIG_QUESTS) do
        if C_QuestLog.IsOnQuest(questID) and C_QuestLog.ReadyForTurnIn(questID) then
            return true
        end
    end
    return false
end

local function GetCompletedCount()
    local count = 0
    for _, quest in ipairs(QUESTS) do
        if quest.key == "gig" then
            if IsSideGigCompleted() then count = count + 1 end
        elseif C_QuestLog.IsQuestFlaggedCompleted(quest.id) then
            count = count + 1
        end
    end
    return count
end

local function GetReadyCount()
    local count = 0
    for _, quest in ipairs(QUESTS) do
        if quest.key == "gig" then
            if IsSideGigReady() then count = count + 1 end
        elseif C_QuestLog.IsOnQuest(quest.id) and C_QuestLog.ReadyForTurnIn(quest.id) then
            count = count + 1
        end
    end
    return count
end

local function CreateUI()
    if CHETTHelper.uiCreated then return end
    CHETTHelper.uiCreated = true
    
    CHETTHelper:SetSize(250, 400)
    
    CHETTHelper.openListBtn = CreateFrame("Button", "CHETTHelperOpenList", CHETTHelper, "SecureActionButtonTemplate")
    CHETTHelper.openListBtn:SetSize(40, 40)
    CHETTHelper.openListBtn:SetPoint("CENTER", CHETTHelper, "TOP", 0, -20)
    CHETTHelper.openListBtn:SetFrameStrata("MEDIUM")
    CHETTHelper.openListBtn:SetFrameLevel(5)
    CHETTHelper.openListBtn:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
    CHETTHelper.openListBtn:RegisterForDrag("LeftButton")
    CHETTHelper.openListBtn:SetAttribute("type", "macro")
    CHETTHelper.openListBtn:SetAttribute("macrotext", "/use item:235053")
    
    local icon = CHETTHelper.openListBtn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture(C_Item.GetItemIconByID(C_HETT_LIST_ITEM) or 134391)
    CHETTHelper.openListBtn.icon = icon
    
    local border = CreateFrame("Frame", nil, CHETTHelper.openListBtn, "BackdropTemplate")
    border:SetAllPoints()
    border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
    })
    border:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
    
    CHETTHelper.openListBtn.check = CHETTHelper.openListBtn:CreateTexture(nil, "OVERLAY")
    CHETTHelper.openListBtn.check:SetSize(32, 32)
    CHETTHelper.openListBtn.check:SetPoint("CENTER")
    CHETTHelper.openListBtn.check:SetAtlas("common-icon-checkmark-yellow")
    CHETTHelper.openListBtn.check:Hide()
    
    CHETTHelper.openListBtn.glow = CHETTHelper.openListBtn:CreateTexture(nil, "OVERLAY")
    CHETTHelper.openListBtn.glow:SetAtlas("UI-ActionButton-Border")
    CHETTHelper.openListBtn.glow:SetBlendMode("ADD")
    CHETTHelper.openListBtn.glow:SetSize(70, 70)
    CHETTHelper.openListBtn.glow:SetPoint("CENTER")
    CHETTHelper.openListBtn.glow:Hide()
    
    CHETTHelper.openListBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("C.H.E.T.T. Helper")
        if HasCHETTList() then
            GameTooltip:AddLine("Click to open C.H.E.T.T. List", 0.8, 0.8, 0.8, true)
        else
            GameTooltip:AddLine("Get a C.H.E.T.T. List from a Cartel vendor!", 1, 0.4, 0.4, true)
        end
        GameTooltip:Show()
    end)
    CHETTHelper.openListBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    CHETTHelper.openListBtn:SetScript("OnDragStart", function() CHETTHelper:StartMoving() end)
    CHETTHelper.openListBtn:SetScript("OnDragStop", function() CHETTHelper:StopMovingOrSizing() end)
    
    CHETTHelper.buyRepBtn = CreateFrame("Button", "CHETTHelperBuyRep", CHETTHelper, "SecureActionButtonTemplate")
    CHETTHelper.buyRepBtn:SetSize(40, 40)
    CHETTHelper.buyRepBtn:SetPoint("CENTER", CHETTHelper.openListBtn, "CENTER", 0, 0)
    CHETTHelper.buyRepBtn:SetFrameStrata("MEDIUM")
    CHETTHelper.buyRepBtn:SetFrameLevel(5)
    CHETTHelper.buyRepBtn:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
    CHETTHelper.buyRepBtn:RegisterForDrag("LeftButton")
    CHETTHelper.buyRepBtn:SetAttribute("type", "macro")
    CHETTHelper.buyRepBtn:SetAttribute("macrotext", "/run BuyMerchantItem(8,1)")
    CHETTHelper.buyRepBtn:Hide()
    
    local repIcon = CHETTHelper.buyRepBtn:CreateTexture(nil, "ARTWORK")
    repIcon:SetAllPoints()
    repIcon:SetTexture(1519430)
    CHETTHelper.buyRepBtn.icon = repIcon
    
    CHETTHelper.buyRepBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Buy Cartel Reputation")
        GameTooltip:AddLine("Click to purchase reputation item", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    CHETTHelper.buyRepBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    CHETTHelper.buyRepBtn:SetScript("OnDragStart", function() CHETTHelper:StartMoving() end)
    CHETTHelper.buyRepBtn:SetScript("OnDragStop", function() CHETTHelper:StopMovingOrSizing() end)
    
    CHETTHelper.questFrame = CreateFrame("Frame", nil, CHETTHelper)
    CHETTHelper.questFrame:SetPoint("TOP", CHETTHelper.openListBtn, "BOTTOM", 0, -5)
    CHETTHelper.questFrame:SetSize(250, 350)
    
    CHETTHelper.questLines = {}
    for i, quest in ipairs(QUESTS) do
        local line = CHETTHelper.questFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        line:SetFont(FONT, 24, "OUTLINE")
        line:SetPoint("TOP", CHETTHelper.questFrame, "TOP", 0, -(i-1) * 28)
        line:SetJustifyH("CENTER")
        line:SetWidth(250)
        line:SetTextColor(1, 1, 1, 1)
        line:SetWordWrap(false)
        CHETTHelper.questLines[i] = line
        
        if quest.special == "gig" then
            line.icon = CHETTHelper.questFrame:CreateTexture(nil, "OVERLAY")
            line.icon:SetSize(20, 20)
            line.icon:SetPoint("RIGHT", line, "LEFT", -5, 0)
            line.icon:SetAtlas("quest-recurring-turnin")
            line.icon:Hide()
        end
    end
end

local function UpdateQuestList()
    -- CRITICAL FIX: Check combat FIRST before any Show/Hide
    if InCombatLockdown() then
        needsUpdate = true
        return
    end
    needsUpdate = false
    
    if not IsInValidZone() then
        CHETTHelper:Hide()
        return
    end
    
    if IsWeeklyCompleted() and not HasCHETTList() then
        CHETTHelper:Hide()
        return
    end
    
    -- Safe to show frame now
    CHETTHelper:Show()
    
    local hasListNow = HasCHETTList()
    if hasListNow and not hadListPreviously then
        sideGigCompletionCache = {}
    end
    hadListPreviously = hasListNow
    
    for questID, _ in pairs(SIDE_GIG_QUESTS) do
        if C_QuestLog.IsQuestFlaggedCompleted(questID) then
            sideGigCompletionCache[questID] = true
        end
    end
    
    if not hasListNow then
        CHETTHelper.questFrame:Hide()
        CHETTHelper.openListBtn:Show()
        CHETTHelper.buyRepBtn:Hide()
        CHETTHelper.openListBtn.check:Hide()
        CHETTHelper.openListBtn.glow:Hide()
        return
    end
    
    local completed = GetCompletedCount()
    local ready = GetReadyCount()
    lastCompletedCount = completed
    
    -- Only switch to buy rep button when all 4 are turned in (completed >= 4 AND none are waiting)
    local allTurnedIn = (completed >= COMPLETION_THRESHOLD and ready == 0)
    
    if allTurnedIn then
        CHETTHelper.questFrame:Hide()
        CHETTHelper.openListBtn:Hide()
        CHETTHelper.buyRepBtn:Show()
    else
        CHETTHelper.questFrame:Show()
        CHETTHelper.openListBtn:Show()
        CHETTHelper.buyRepBtn:Hide()
    end
    
    local visibleIndex = 0
    
    for i, quest in ipairs(QUESTS) do
        local line = CHETTHelper.questLines[i]
        local shouldShow = false
        local isComplete = false
        local isReadyForTurnIn = false
        
        if quest.key == "gig" then
            shouldShow = C_QuestLog.IsOnQuest(quest.id)
            if shouldShow then
                isComplete = IsSideGigCompleted()
                isReadyForTurnIn = IsSideGigReady()
            end
        else
            shouldShow = C_QuestLog.IsOnQuest(quest.id)
            if shouldShow then
                isComplete = C_QuestLog.ReadyForTurnIn(quest.id) or C_QuestLog.IsQuestFlaggedCompleted(quest.id)
                isReadyForTurnIn = C_QuestLog.ReadyForTurnIn(quest.id)
            end
        end
        
        if CHETTSettings[quest.key] and shouldShow then
            visibleIndex = visibleIndex + 1
            line:ClearAllPoints()
            line:SetPoint("TOP", CHETTHelper.questFrame, "TOP", 0, -(visibleIndex-1) * 28)
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
    
    -- Update icon indicators
    if allTurnedIn then
        CHETTHelper.openListBtn.check:Show()
        CHETTHelper.openListBtn.glow:Hide()
    elseif ready >= 3 then
        CHETTHelper.openListBtn.check:Hide()
        CHETTHelper.openListBtn.glow:Show()
    else
        CHETTHelper.openListBtn.check:Hide()
        CHETTHelper.openListBtn.glow:Hide()
    end
end

local function ProcessGossip()
    if not CHETTSettings.skipGossip and not CHETTSettings.autoTake and not CHETTSettings.skipDrills then return end
    if not GossipFrame or not GossipFrame:IsShown() then return end
    
    local targetGUID = UnitGUID("target")
    local npcID = targetGUID and select(6, strsplit("-", targetGUID))
    npcID = tonumber(npcID)
    
    local options = C_GossipInfo.GetOptions()
    if not options then return end
    
    for _, option in ipairs(options) do
        if CHETTSettings.autoTake and option.gossipOptionID == GOSSIP_LIST_OPTION then
            if not C_QuestLog.IsQuestFlaggedCompleted(WEEKLY_QUEST_ID) then
                local hasSpace = false
                for bag = 0, NUM_BAG_SLOTS do
                    local free = C_Container.GetContainerNumFreeSlots(bag)
                    if free and free > 0 then hasSpace = true break end
                end
                if hasSpace then
                    C_GossipInfo.SelectOption(option.gossipOptionID)
                    return
                end
            end
        end
        
        if CHETTSettings.skipGossip and GOSSIP_RARE_NPCS[npcID] and option.gossipOptionID == GOSSIP_RARE_OPTION then
            C_GossipInfo.SelectOption(option.gossipOptionID)
            C_Timer.After(0.1, function()
                if StaticPopup1 and StaticPopup1:IsShown() and StaticPopup1Button1 then
                    StaticPopup1Button1:Click()
                end
            end)
            return
        end
        
        if CHETTSettings.skipDrills and GOSSIP_DRILL_OPTIONS[option.gossipOptionID] then
            C_GossipInfo.SelectOption(option.gossipOptionID)
            C_Timer.After(0.8, function()
                if CinematicFrame and CinematicFrame:IsShown() then
                    CinematicFrame_CancelCinematic()
                end
            end)
            return
        end
    end
end

local function UpdateRepButton()
    -- CRITICAL FIX: Don't touch protected frames during combat
    if InCombatLockdown() then return end
    
    if not MerchantFrame or not MerchantFrame:IsShown() then 
        if CHETTHelper.buyRepBtn then CHETTHelper.buyRepBtn:Hide() end
        if CHETTHelper.openListBtn then CHETTHelper.openListBtn:Show() end
        return 
    end
    
    local itemID = GetMerchantItemID(8)
    if itemID and lastCompletedCount >= 4 then
        local guid = UnitGUID("target")
        if guid then
            local id = select(6, strsplit("-", guid))
            id = tonumber(id)
            if id and id >= 231405 and id <= 231408 then
                if CHETTHelper.openListBtn then CHETTHelper.openListBtn:Hide() end
                if CHETTHelper.buyRepBtn then CHETTHelper.buyRepBtn:Show() end
            end
        end
    end
end

local function CreateConfig()
    if CHETTHelper.configCreated then return end
    CHETTHelper.configCreated = true
    
    local settingsPanel = CreateFrame("FRAME", "CHETTHelperSettingsPanel")
    settingsPanel.name = "CHETT Helper"
    
    local title = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("CHETT Helper Options")
    
    local y = -50
    local questHeader = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    questHeader:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    questHeader:SetText("Quest Tracking")
    y = y - 40
    
    for _, quest in ipairs(QUESTS) do
        local cb = CreateFrame("CheckButton", "CHETTCheck"..quest.key, settingsPanel, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 16, y)
        cb.Text:SetText(quest.name)
        cb:SetChecked(CHETTSettings[quest.key])
        cb:SetScript("OnClick", function(self)
            CHETTSettings[quest.key] = self:GetChecked()
            CHETTHelperDB[quest.key] = self:GetChecked()
            UpdateQuestList()
        end)
        y = y - 25
    end
    
    y = y - 20
    local autoHeader = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    autoHeader:SetPoint("TOPLEFT", 16, y)
    autoHeader:SetText("Automation Options")
    y = y - 30
    
    local autoCB = CreateFrame("CheckButton", "CHETTAutoTake", settingsPanel, "InterfaceOptionsCheckButtonTemplate")
    autoCB:SetPoint("TOPLEFT", 16, y)
    autoCB.Text:SetText("Auto-take free weekly C.H.E.T.T. List")
    autoCB:SetChecked(CHETTSettings.autoTake)
    autoCB:SetScript("OnClick", function(self) 
        CHETTSettings.autoTake = self:GetChecked() 
        CHETTHelperDB.autoTake = self:GetChecked()
    end)
    y = y - 25
    
    local skipCB = CreateFrame("CheckButton", "CHETTSkipGossip", settingsPanel, "InterfaceOptionsCheckButtonTemplate")
    skipCB:SetPoint("TOPLEFT", 16, y)
    skipCB.Text:SetText("Auto-skip rare/scrap gossip")
    skipCB:SetChecked(CHETTSettings.skipGossip)
    skipCB:SetScript("OnClick", function(self) 
        CHETTSettings.skipGossip = self:GetChecked() 
        CHETTHelperDB.skipGossip = self:GetChecked()
    end)
    y = y - 25
    
    local drillCB = CreateFrame("CheckButton", "CHETTSkipDrills", settingsPanel, "InterfaceOptionsCheckButtonTemplate")
    drillCB:SetPoint("TOPLEFT", 16, y)
    drillCB.Text:SetText("Auto-skip drill gossip")
    drillCB:SetChecked(CHETTSettings.skipDrills)
    drillCB:SetScript("OnClick", function(self) 
        CHETTSettings.skipDrills = self:GetChecked() 
        CHETTHelperDB.skipDrills = self:GetChecked()
    end)
    
    local category = Settings.RegisterCanvasLayoutCategory(settingsPanel, settingsPanel.name)
    Settings.RegisterAddOnCategory(category)
    CHETTHelper.settingsCategory = category
end

CHETTHelper:RegisterEvent("PLAYER_ENTERING_WORLD")
CHETTHelper:RegisterEvent("PLAYER_REGEN_ENABLED")
CHETTHelper:RegisterEvent("BAG_UPDATE_DELAYED")
CHETTHelper:RegisterEvent("QUEST_LOG_UPDATE")
CHETTHelper:RegisterEvent("QUEST_WATCH_UPDATE")
CHETTHelper:RegisterEvent("GOSSIP_SHOW")
CHETTHelper:RegisterEvent("MERCHANT_SHOW")
CHETTHelper:RegisterEvent("MERCHANT_CLOSED")
CHETTHelper:RegisterEvent("MERCHANT_UPDATE")
CHETTHelper:RegisterEvent("ZONE_CHANGED_NEW_AREA")
CHETTHelper:RegisterEvent("QUEST_TURNED_IN")

CHETTHelper:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        if not CHETTHelperDB then 
            CHETTHelperDB = {} 
            for _, q in ipairs(QUESTS) do 
                if CHETTHelperDB[q.key] == nil then
                    CHETTHelperDB[q.key] = q.default 
                end
            end
            CHETTHelperDB.autoTake = true
            CHETTHelperDB.skipGossip = true
            CHETTHelperDB.skipDrills = true
        end
        
        for k, v in pairs(CHETTHelperDB) do
            CHETTSettings[k] = v
        end
        
        hadListPreviously = HasCHETTList()
        
        CreateUI()
        CreateConfig()
        UpdateQuestList()
        
    elseif event == "PLAYER_REGEN_ENABLED" then
        if needsUpdate then
            UpdateQuestList()
        end
        
    elseif event == "GOSSIP_SHOW" then
        ProcessGossip()
        
    elseif event == "MERCHANT_SHOW" or event == "MERCHANT_UPDATE" then
        UpdateRepButton()
        
    elseif event == "MERCHANT_CLOSED" then
        if not InCombatLockdown() then
            if CHETTHelper.buyRepBtn then CHETTHelper.buyRepBtn:Hide() end
            if CHETTHelper.openListBtn then CHETTHelper.openListBtn:Show() end
        end
        
    elseif event == "QUEST_TURNED_IN" then
        local questID = ...
        if SIDE_GIG_QUESTS[questID] then
            sideGigCompletionCache[questID] = true
        end
        
        if InCombatLockdown() then
            needsUpdate = true
        else
            C_Timer.After(0.2, UpdateQuestList)
        end
        
    else
        if InCombatLockdown() then
            needsUpdate = true
        else
            UpdateQuestList()
        end
    end
end)

CHETTHelper:SetScript("OnDragStart", CHETTHelper.StartMoving)
CHETTHelper:SetScript("OnDragStop", CHETTHelper.StopMovingOrSizing)

print("|cffffd100CHETT Helper|r loaded. Type /chb for options.")

SLASH_CHETTHELPER1 = "/chb"
SLASH_CHETTHELPER2 = "/chetthelper"
SlashCmdList["CHETTHELPER"] = function() 
    if CHETTHelper.settingsCategory then
        Settings.OpenToCategory(CHETTHelper.settingsCategory:GetID())
    else
        print("|cffffd100CHETT Helper:|r Settings not loaded yet")
    end
end
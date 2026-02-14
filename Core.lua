local addonName, addon = ...

-- Global settings table (accessible by other modules)
addon.Settings = {}
addon.lastCompletedCount = 0
addon.hadListPreviously = false
addon.needsUpdate = false

local function InitializeSettings()
    if not CHETTHelperDB then 
        CHETTHelperDB = {} 
        for _, q in ipairs(addon.QUESTS) do 
            if CHETTHelperDB[q.key] == nil then
                CHETTHelperDB[q.key] = q.default 
            end
        end
        CHETTHelperDB.autoTake = true
        CHETTHelperDB.skipGossip = true
        CHETTHelperDB.skipDrills = true
        CHETTHelperDB.fontSize = addon.DEFAULT_FONT_SIZE
        CHETTHelperDB.growDirection = "DOWN"
    end
    
    -- Migration for new settings
    if not CHETTHelperDB.fontSize then
        CHETTHelperDB.fontSize = addon.DEFAULT_FONT_SIZE
    end
    if not CHETTHelperDB.growDirection then
        CHETTHelperDB.growDirection = "DOWN"
    end
    
    -- Copy to working table
    for k, v in pairs(CHETTHelperDB) do
        addon.Settings[k] = v
    end
end

-- Save frame position
function addon:SaveFramePosition()
    if not self.CHETTHelper then return end
    
    local point, _, _, x, y = self.CHETTHelper:GetPoint()
    if point then
        CHETTHelperDB.framePos = {
            point = point,
            x = x,
            y = y
        }
    end
end

-- Load frame position
function addon:LoadFramePosition()
    if CHETTHelperDB.framePos then
        local pos = CHETTHelperDB.framePos
        self.CHETTHelper:ClearAllPoints()
        self.CHETTHelper:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:RegisterEvent("QUEST_LOG_UPDATE")
frame:RegisterEvent("QUEST_WATCH_UPDATE")
frame:RegisterEvent("GOSSIP_SHOW")
frame:RegisterEvent("MERCHANT_SHOW")
frame:RegisterEvent("MERCHANT_CLOSED")
frame:RegisterEvent("MERCHANT_UPDATE")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("QUEST_TURNED_IN")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        InitializeSettings()
        addon.hadListPreviously = addon:HasCHETTList()
        
        addon:CreateUI()
        addon:LoadFramePosition() -- Restore position after creating UI
        addon:CreateConfig()
        addon:UpdateQuestList()
        
    elseif event == "PLAYER_REGEN_ENABLED" then
        if addon.needsUpdate then
            addon:UpdateQuestList()
        end
        
    elseif event == "GOSSIP_SHOW" then
        addon:ProcessGossip()
        
    elseif event == "MERCHANT_SHOW" or event == "MERCHANT_UPDATE" then
        addon:UpdateRepButton()
        
    elseif event == "MERCHANT_CLOSED" then
        if not InCombatLockdown() then
            if addon.CHETTHelper.buyRepBtn then addon.CHETTHelper.buyRepBtn:Hide() end
            if addon.CHETTHelper.openListBtn then addon.CHETTHelper.openListBtn:Show() end
        end
        
    elseif event == "QUEST_TURNED_IN" then
        local questID = ...
        if addon:CheckQuestInList(questID) then
            addon:CacheQuestCompletion(questID)
        end
        
        if InCombatLockdown() then
            addon.needsUpdate = true
        else
            C_Timer.After(0.2, function() addon:UpdateQuestList() end)
        end
        
    else
        if InCombatLockdown() then
            addon.needsUpdate = true
        else
            addon:UpdateQuestList()
        end
    end
end)

-- Slash commands
SLASH_CHETTHELPER1 = "/chb"
SLASH_CHETTHELPER2 = "/chetthelper"
SlashCmdList["CHETTHELPER"] = function() 
    if addon.settingsCategory then
        Settings.OpenToCategory(addon.settingsCategory:GetID())
    else
        print("|cffffd100CHETT Helper:|r Settings not loaded yet")
    end
end

print("|cffffd100CHETT Helper|r loaded. Type /chb for options.")
local addonName, addon = ...

-- Cache and state
local questCompletionCache = {}

function addon:IsInValidZone()
    local mapID = C_Map.GetBestMapForUnit("player")
    return mapID and addon.VALID_ZONES[mapID] or false
end

function addon:HasCHETTList()
    return C_Item.GetItemCount(addon.C_HETT_LIST_ITEM, false) > 0
end

function addon:IsWeeklyCompleted()
    return C_QuestLog.IsQuestFlaggedCompleted(addon.WEEKLY_QUEST_ID)
end

function addon:IsSideGigCompleted()
    for questID, _ in pairs(addon.SIDE_GIG_QUESTS) do
        if C_QuestLog.IsQuestFlaggedCompleted(questID) or questCompletionCache[questID] then
            return true
        end
    end
    return false
end

function addon:IsSideGigReady()
    for questID, _ in pairs(addon.SIDE_GIG_QUESTS) do
        if C_QuestLog.IsOnQuest(questID) and C_QuestLog.ReadyForTurnIn(questID) then
            return true
        end
    end
    return false
end

function addon:GetCompletedCount()
    local count = 0
    for _, quest in ipairs(addon.QUESTS) do
        if quest.key == "gig" then
            if self:IsSideGigCompleted() then count = count + 1 end
        elseif C_QuestLog.IsQuestFlaggedCompleted(quest.id) or questCompletionCache[quest.id] then
            count = count + 1
        end
    end
    return count
end

function addon:GetReadyCount()
    local count = 0
    for _, quest in ipairs(addon.QUESTS) do
        if quest.key == "gig" then
            if self:IsSideGigReady() then count = count + 1 end
        elseif C_QuestLog.IsOnQuest(quest.id) and C_QuestLog.ReadyForTurnIn(quest.id) then
            count = count + 1
        end
    end
    return count
end

function addon:CacheQuestCompletion(questID)
    questCompletionCache[questID] = true
end

function addon:ClearQuestCache()
    questCompletionCache = {}
end

function addon:IsQuestCached(questID)
    return questCompletionCache[questID]
end

function addon:CheckQuestInList(questID)
    for _, quest in ipairs(addon.QUESTS) do
        if quest.id == questID then
            return true
        end
    end
    return addon.SIDE_GIG_QUESTS[questID] ~= nil
end
local addonName, addon = ...

function addon:ProcessGossip()
    if not self.Settings.skipGossip and not self.Settings.autoTake and not self.Settings.skipDrills then return end
    if not GossipFrame or not GossipFrame:IsShown() then return end
    
    local targetGUID = UnitGUID("target")
    local npcID = targetGUID and select(6, strsplit("-", targetGUID))
    npcID = tonumber(npcID)
    
    local options = C_GossipInfo.GetOptions()
    if not options then return end
    
    for _, option in ipairs(options) do
        if self.Settings.autoTake and option.gossipOptionID == addon.GOSSIP_LIST_OPTION then
            if not self:IsWeeklyCompleted() then
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
        
        if self.Settings.skipGossip and addon.GOSSIP_RARE_NPCS[npcID] and option.gossipOptionID == addon.GOSSIP_RARE_OPTION then
            C_GossipInfo.SelectOption(option.gossipOptionID)
            C_Timer.After(0.1, function()
                if StaticPopup1 and StaticPopup1:IsShown() and StaticPopup1Button1 then
                    StaticPopup1Button1:Click()
                end
            end)
            return
        end
        
        if self.Settings.skipDrills and addon.GOSSIP_DRILL_OPTIONS[option.gossipOptionID] then
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

function addon:UpdateRepButton()
    if InCombatLockdown() then return end
    
    if not MerchantFrame or not MerchantFrame:IsShown() then 
        if self.CHETTHelper.buyRepBtn then self.CHETTHelper.buyRepBtn:Hide() end
        if self.CHETTHelper.openListBtn then self.CHETTHelper.openListBtn:Show() end
        return 
    end
    
    local itemID = GetMerchantItemID(8)
    if itemID and self.lastCompletedCount >= 4 then
        local guid = UnitGUID("target")
        if guid then
            local id = select(6, strsplit("-", guid))
            id = tonumber(id)
            if id and id >= 231405 and id <= 231408 then
                if self.CHETTHelper.openListBtn then self.CHETTHelper.openListBtn:Hide() end
                if self.CHETTHelper.buyRepBtn then self.CHETTHelper.buyRepBtn:Show() end
            end
        end
    end
end
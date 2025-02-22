local lastCommandTime = 0 -- Throttler to reduce DB load

local function QuestReset(event, player, command)
    if command:find("quest reset %d+$") and player:GetGMRank() > 0 then
        local currentTime = os.time()
        if (currentTime - lastCommandTime) < 1 then
            player:SendAreaTriggerMessage("Please wait before using this command again.")
            player:SendBroadcastMessage("Please wait before using this command again.")
            return false
        end
        lastCommandTime = currentTime
        
        local questId = tonumber(command:match("%d+"))
        local target = player:GetSelection()
        
        if not target then
			target = player
        end
        
        if questId then
            local targetGuid = target:GetGUIDLow()
            
            -- Check if the quest exists for the target character
            local tables = {
                "character_queststatus",
                "character_queststatus_daily",
                "character_queststatus_monthly",
                "character_queststatus_rewarded",
                "character_queststatus_seasonal",
                "character_queststatus_weekly"
            }
            
            local questExists = false
            for _, tableName in ipairs(tables) do
                local result = CharDBQuery(string.format("SELECT 1 FROM %s WHERE guid = %d AND quest = %d LIMIT 1", tableName, targetGuid, questId))
                if result then
                    questExists = true
                    break
                end
            end
            
            if questExists then
                -- Set CanConfirm data and store quest info
                player:SetData("CanConfirm", true)
                player:SetData("QuestToReset", questId)
                player:SetData("TargetGuid", targetGuid)
                
                player:SendAreaTriggerMessage(string.format("Do you want to reset quest ID %d for player %s? Type '.confirm' to proceed or '.cancel' to cancel.", questId, target:GetName()))
                player:SendBroadcastMessage(string.format("Do you want to reset quest ID %d for player %s? Type '.confirm' to proceed or '.cancel' to cancel.", questId, target:GetName()))
            else
                player:SendAreaTriggerMessage("Selected player hasn't completed quest ID " .. questId .. ". Only completed quests can be reset.")
                player:SendBroadcastMessage("Selected player hasn't completed quest ID " .. questId .. ". Only completed quests can be reset.")
            end
            
            return false
        else
            player:SendAreaTriggerMessage("Invalid quest ID. Please use a number between 1 and 99999.")
            player:SendBroadcastMessage("Invalid quest ID. Please use a number between 1 and 99999.")
        end
    end
    if command == "confirm" and player:GetGMRank() > 0 and player:GetData("CanConfirm") then
        local questId = player:GetData("QuestToReset")
        local targetGuid = player:GetData("TargetGuid")
        
        local tables = {
            "character_queststatus",
            "character_queststatus_daily",
            "character_queststatus_monthly",
            "character_queststatus_rewarded",
            "character_queststatus_seasonal",
            "character_queststatus_weekly"
        }
        
        for _, tableName in ipairs(tables) do
            CharDBQuery(string.format("DELETE FROM %s WHERE guid = %d AND quest = %d", tableName, targetGuid, questId))
        end
        
        player:SendAreaTriggerMessage("Quest reset done for quest ID: " .. questId .. ". Target must relog for reset to become active.")
        player:SendBroadcastMessage("Quest reset done for quest ID: " .. questId .. ". Target must relog for reset to become active.")
        player:SetData("CanConfirm", false)
        return false
    elseif command == "cancel" and player:GetGMRank() > 0 and player:GetData("CanConfirm") then
        player:SendAreaTriggerMessage("Quest reset cancelled.")
        player:SendBroadcastMessage("Quest reset cancelled.")
        player:SetData("CanConfirm", false)
        return false
    end
end

RegisterPlayerEvent(42, QuestReset)
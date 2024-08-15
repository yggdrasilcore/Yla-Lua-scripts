local function QuestReset(event, player, command)
    if command:find("quest reset %d+$") and player:GetGMRank() > 0 then
        local guid = tonumber(command:match("%d+"))
        if guid and guid >= 1 and guid <= 99999 then
            local charGuid = player:GetGUIDLow()
            
            -- Cache the selected number (guid) and character GUID
            local cachedGuid = guid
            local cachedCharGuid = charGuid
            
            -- Check if the quest exists for the character in any of the tables
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
                local result = CharDBQuery(string.format("SELECT 1 FROM %s WHERE guid = %d AND quest = %d LIMIT 1", tableName, cachedCharGuid, cachedGuid))
                if result then
                    questExists = true
                    break
                end
            end
            
            if questExists then
                -- Send a popup message to the player
                player:SendAreaTriggerMessage("Do you really want to reset quest ID " ..cachedGuid.."? This will log you out! Type '.confirm' to proceed or '.cancel' to cancel.")
                
                -- Register an event to wait for the player's response
                player:RegisterEvent(function(eventId, delay, repeats, player)
                    local function ConfirmReset(event, player, command)
                        if command == "confirm" and player:GetGMRank() > 0 then
                            -- Perform CHARDBQUERY to delete the quest from all tables
                            for _, tableName in ipairs(tables) do
                                CharDBQuery(string.format("DELETE FROM %s WHERE guid = %d AND quest = %d", tableName, cachedCharGuid, cachedGuid))
                            end
                            
                            player:SendAreaTriggerMessage("Quest reset completed for quest ID: " .. cachedGuid)
                            
                            -- Schedule player logout after 200ms
                            player:RegisterEvent(function(eventId, delay, repeats, player)
                                player:LogoutPlayer()
                            end, 200, 1)
                            
                            return false
                        elseif command == "cancel" and player:GetGMRank() > 0 then
                            player:SendAreaTriggerMessage("Quest reset cancelled.")
                            return false
                        end
                    end
                    RegisterPlayerEvent(42, ConfirmReset)
                end, 100, 1)
            else
                player:SendAreaTriggerMessage("You haven't completed quest ID " .. cachedGuid .. ". Only completed quests can be reset.")
            end
            
            return false
        else
            player:SendAreaTriggerMessage("Invalid quest ID. Please use a number between 1 and 99999.")
        end
    end
end

RegisterPlayerEvent(42, QuestReset)

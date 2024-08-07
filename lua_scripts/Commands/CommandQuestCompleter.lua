local MSG_QC = "#qc" -- Message to complete the specified quest by ID.

-- Function to delete all items in the player's bag.
local function DeleteAllItemsInBag(player)
    -- Iterate over item positions from 25 to 38
    for slot = 25, 38 do
        local item = player:GetItemByPos(255, slot)
        -- Check if the slot is not empty
        if item then
            -- Delete the item
            player:RemoveItem(item:GetEntry(), item:GetCount())
        end
    end
    player:SendBroadcastMessage("All items in your bag have been deleted.")
end

-- Function to add a quest, complete it, and mark it as rewarded.
local function CompleteAndRewardQuest(player, questID)
    -- Add the quest to the player's quest log if they don't have it already.
    if not player:HasQuest(questID) then
        player:AddQuest(questID)
    end
    -- Complete the quest for the player.
    player:CompleteQuest(questID)
    -- Reward the quest for the player.
    player:RewardQuest(questID)
    -- Call the function to delete all items in the bag after rewarding the quest.
    DeleteAllItemsInBag(player)
    -- Send a message to the player confirming the quest completion and reward status.
    player:SendBroadcastMessage("Quest with ID: " .. questID .. " has been added to your quest log, completed, and marked as rewarded.")
end

local function QuestAutoComplete(event, player, msg, Type, lang)
    local gmRank = player:GetGMRank()
    if gmRank >= 3 then
        local lowerMsg = msg:lower()
        -- Check if the message starts with the command and has a quest ID.
        if string.sub(lowerMsg, 1, #MSG_QC) == MSG_QC then
            local questID = tonumber(string.sub(lowerMsg, #MSG_QC + 1))
            if questID then
                -- Query the database to check if the quest ID exists in the quest_template table.
                local result = WorldDBQuery("SELECT * FROM quest_template WHERE ID = " .. questID)
                if result then
                    local target = player:GetSelection()
                    if target and target:ToPlayer() then
                        -- Complete the quest with the specified ID and mark it as rewarded for the target player.
                        CompleteAndRewardQuest(target:ToPlayer(), questID)
                    else
                        -- Complete the quest with the specified ID and mark it as rewarded for the player.
                        CompleteAndRewardQuest(player, questID)
                    end
                else
                    -- Send a message if the quest ID is not valid.
                    player:Say("Non-existent quest ID: " .. questID, 0)
                end
            else
                -- Send a message if the quest ID is not valid.
                player:SendBroadcastMessage("Invalid quest ID.")
            end
            return false
        end
    end
end

-- Register the function to handle player chat events.
RegisterPlayerEvent(18, QuestAutoComplete)
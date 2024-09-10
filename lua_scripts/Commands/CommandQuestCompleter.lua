local MSG_QC = "#qc"

local function DeleteAllItemsInBag(player)
    for slot = 25, 38 do
        local item = player:GetItemByPos(255, slot)
        if item then
            player:RemoveItem(item:GetEntry(), item:GetCount())
        end
    end
    player:SendBroadcastMessage("All items in your bag have been deleted.")
end

local function CompleteAndRewardQuest(player, questID)
    if not player:HasQuest(questID) then
        player:AddQuest(questID)
    end
    player:CompleteQuest(questID)
    player:RewardQuest(questID)
    DeleteAllItemsInBag(player)
    player:SendBroadcastMessage("Quest with ID: " .. questID .. " has been added to your quest log, completed, and marked as rewarded.")
end

local function QuestAutoComplete(event, player, msg, Type, lang)
    local gmRank = player:GetGMRank()
    if gmRank >= 3 then
		name = player:GetName()
        local lowerMsg = msg:lower()
        if string.sub(lowerMsg, 1, #MSG_QC) == MSG_QC then
            local questID = tonumber(string.sub(lowerMsg, #MSG_QC + 1))
            if questID then
                WorldDBQueryAsync("SELECT * FROM quest_template WHERE ID = " .. questID, function(result)
					player = GetPlayerByName(name)
                    if result then
                        local target = player:GetSelection()
                        if target and target:ToPlayer() then
                            CompleteAndRewardQuest(target:ToPlayer(), questID)
                        else
                            CompleteAndRewardQuest(player, questID)
                        end
                    else
                        player:Say("Non-existent quest ID: " .. questID, 0)
                    end
                end)
            else
                player:SendBroadcastMessage("Invalid quest ID.")
            end
            return false
        end
    end
end

RegisterPlayerEvent(18, QuestAutoComplete)
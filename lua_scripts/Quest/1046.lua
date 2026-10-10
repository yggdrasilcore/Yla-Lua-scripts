-- Quest 1046: remove item 5462 from player (bags/bank/equip) on turn-in.
-- PLAYER_EVENT_ON_COMPLETE_QUEST (54) fires from Player::RewardQuest().
local QUEST_ID = 1046
local ITEM_ID = 5462

local function OnQuestComplete(event, player, quest)
    if quest:GetId() ~= QUEST_ID then
        return
    end

    -- true = include bank; RemoveItem -> DestroyItemCount covers
    -- inventory, bags, equip, bank, bank bags.
    local count = player:GetItemCount(ITEM_ID, true)
    if count > 0 then
        player:RemoveItem(ITEM_ID, count)
    end
end

RegisterPlayerEvent(54, OnQuestComplete)

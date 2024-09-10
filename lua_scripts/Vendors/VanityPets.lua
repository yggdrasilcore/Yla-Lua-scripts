-- WorldDB queries to insert data if not already done

--local flags_value = 134250560

--for _, item_id in ipairs(ItemsToSell) do
--    local update_query1 = string.format("UPDATE `item_template` SET `flags` = %d WHERE `entry` = %d", flags_value, item_id)
--    local update_query2 = string.format("UPDATE `item_template` SET `spellcharges_1` = 0 WHERE `entry` = %d", item_id)
--    WorldDBExecute(update_query1)
--    WorldDBExecute(update_query2)
--end

local NPC_ID = 600000
local model_ID = 21113
local VoteTokenItemID = 20880

local ItemsToSell = {
    13582, 13583, 13584, 25535, 33816, 48527, 20371, 20651, 22114,
    46802, 32233, 32616, 32617, 32622, 33816, 33818, 35349, 35350,
    33993, 34955, 38050, 39656, 41133, 43517, 43698, 49662, 49663,
    45180, 46767, 49646, 49693, 54847, 54857, 56806, 49665, 21168,
    19055, 19054, 18964, 45942, 32588, 34493, 34492, 34518, 34519,
    37297, 37298, 49343, 54810, 38658, 19450, 11903, 49362
}

local VotePointCost = 50
local ItemsPerPage = 11


local function GenerateMenu(page, player, object)
    local startIndex = ((page - 1) * ItemsPerPage) + 1
    local endIndex = math.min(startIndex + ItemsPerPage - 1, #ItemsToSell)

    for i = startIndex, endIndex do
        local itemId = ItemsToSell[i]
        local itemLink = GetItemLink(itemId)
        if itemLink then
            if player:HasItem(itemId) then
                player:GossipMenuAddItem(1, itemLink .. " (Already owned)", 0, itemId)
            else
                player:GossipMenuAddItem(1, "" .. itemLink .. " " .. VotePointCost .. " vote tokens", 0, itemId)
            end
        end
    end

    if page > 1 then
        player:GossipMenuAddItem(4, "Previous page", 1, page - 1)
    end

    if endIndex < #ItemsToSell then
        player:GossipMenuAddItem(4, "Next page", 1, page + 1)
    end

    player:GossipSendMenu(1, object)
end

local function OnGossipHello(event, player, object)
    GenerateMenu(1, player, object)
end

local function OnGossipSelect(event, player, object, sender, intid, code, menu_id)
    if sender == 0 then
        local itemId = intid
        local itemLink = GetItemLink(itemId)
        
        if not itemLink then
            player:SendBroadcastMessage("Error: Item not found.")
            player:GossipComplete()
            return
        end
        
        if player:HasItem(itemId) then
            player:SendBroadcastMessage("You already own " .. itemLink .. ".")
            player:GossipComplete()
            return
        end
        
        -- Add confirmation dialogue
        player:GossipMenuAddItem(0, "Are you sure you want to buy " .. itemLink .. " for " .. VotePointCost .. " vote tokens?", 2, itemId)
        player:GossipMenuAddItem(0, "No, I've changed my mind.", 1, 1)  -- Return to first page
        player:GossipSendMenu(1, object)
    elseif sender == 1 then
        GenerateMenu(intid, player, object)
    elseif sender == 2 then
        -- Confirmation to buy
        local itemId = intid
        local itemLink = GetItemLink(itemId)
        local voteTokens = player:GetItemCount(VoteTokenItemID)
        
        if voteTokens >= VotePointCost then
            player:RemoveItem(VoteTokenItemID, VotePointCost)
            player:AddItem(itemId, 1)
            player:SendBroadcastMessage("You have purchased " .. itemLink .. " for " .. VotePointCost .. " vote tokens.")
        else
            player:SendBroadcastMessage("You don't have enough vote tokens to purchase this item.")
        end
        player:GossipComplete()
    end
end

RegisterCreatureGossipEvent(NPC_ID, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ID, 2, OnGossipSelect)

local NPC_ID = 190099 -- Replace with your NPC entry ID
local ITEM_ID = 20739 -- Replace with the ID of the item to be sold
local ITEM_PRICE = 1 -- Price of the item in copper (1 copper in this case)

local function OnGossipHello(event, player, object)
    player:GossipClearMenu()
    player:GossipMenuAddItem(0, "I hear you're interested in flying in the old world...", 0, 1)
    player:GossipSendMenu(1, object)
end

local function OnGossipSelect(event, player, object, sender, intid, code)
    if intid == 1 then
        local goldCost = 50 -- Replace with the actual cost in gold (1 copper = 10000 gold)
        local itemLink = GetItemLink(ITEM_ID)

        player:GossipClearMenu()

        player:GossipMenuAddItem(1, "Do you want to buy " .. itemLink .. " for " .. goldCost .. " gold?", 0, 2)
        player:GossipMenuAddItem(0, "We have nothing to discuss.", 0, 3)

        player:GossipSendMenu(1, object)
    elseif intid == 2 then
        local hasEnoughGold = player:GetCoinage() >= 500000 -- Replace with the actual cost in copper
        if hasEnoughGold then
            player:ModifyMoney(-500000) -- Replace with the actual cost in copper

            player:AddItem(ITEM_ID, 1)

        else
            player:SendBroadcastMessage("You do not have enough gold.")
        end
        player:GossipComplete()
    elseif intid == 3 then
        player:GossipComplete()
    end
end

RegisterCreatureGossipEvent(NPC_ID, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ID, 2, OnGossipSelect)
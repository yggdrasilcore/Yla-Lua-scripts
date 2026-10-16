if GetStateMapId() ~= 37 then return end

local NPC_ID = 190099 -- Replace with your NPC entry ID
local ITEM_ID = 20739 -- Replace with the ID of the item to be sold

local function OnGossipHello(event, player, creature)
    player:GossipClearMenu()
    player:GossipMenuAddItem(0, "I hear you're interested in flying in the old world...", 0, 1)
    player:GossipSendMenu(12, creature)
end

local function OnGossipSelect(event, player, creature, sender, intid, code)
    if intid == 1 then
        local itemLink = GetItemLink(ITEM_ID)

        player:GossipClearMenu()

        player:GossipMenuAddItem(1, "Do you want to open the store to buy the " .. itemLink .. "?", 0, 2)
        player:GossipMenuAddItem(0, "We have nothing to discuss.", 0, 3)

        player:GossipSendMenu(12, creature)
    elseif intid == 2 then
        player:SendAddonMessage("CustomShop", "openstore", 7, player) -- No debug
        player:GossipComplete()
    elseif intid == 3 then
        player:GossipComplete()
    end
end

RegisterCreatureGossipEvent(NPC_ID, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ID, 2, OnGossipSelect)
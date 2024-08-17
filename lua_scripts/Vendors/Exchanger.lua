local GOSSIP_MENU_ID = 1000
local NPC_ID = 190000

local VOTE_TOKEN = 377420
local EMBLEM_OF_FROST = 49426
local EMBLEM_OF_TRIUMPH = 47241
local TRANSMOG_TOKEN = 37742

local function OnGossipHello(event, player, creature)
    print("OnGossipHello called")
    player:GossipMenuAddItem(0, "What currency would you like to buy?", GOSSIP_MENU_ID, 1)
    player:GossipMenuAddItem(1, "Emblem of Frost (5 Vote Token per)", GOSSIP_MENU_ID, 101)
    player:GossipMenuAddItem(1, "Emblem of Triumph (1 Vote Token per)", GOSSIP_MENU_ID, 102)
    player:GossipMenuAddItem(1, "Transmog Token (10 Vote Token per)", GOSSIP_MENU_ID, 103)
    player:GossipSendMenu(GOSSIP_MENU_ID, creature)
end

local function BuyCurrency(player, itemId, cost, amount, currencyName)
    print("BuyCurrency called:", itemId, cost, amount, currencyName)
    local totalCost = cost * amount
    if player:HasItem(VOTE_TOKEN, totalCost) then
        player:RemoveItem(VOTE_TOKEN, totalCost)
        player:AddItem(itemId, amount)
        player:SendBroadcastMessage(string.format("You've purchased %d %s for %d Vote Tokens.", amount, currencyName, totalCost))
    else
        player:SendBroadcastMessage("You don't have enough Vote Tokens.")
    end
    player:GossipComplete()
end

local function ShowAmountMenu(player, creature, currencyId, cost, currencyName)
    print("ShowAmountMenu called for currency ID:", currencyId, "Cost:", cost)
    player:GossipMenuAddItem(0, string.format("How many %s do you want to buy?", currencyName), GOSSIP_MENU_ID, 200)
    player:GossipMenuAddItem(1, string.format("Buy 1 for %d Vote Tokens", cost * 1), GOSSIP_MENU_ID, 201)
    player:GossipMenuAddItem(1, string.format("Buy 5 for %d Vote Tokens", cost * 5), GOSSIP_MENU_ID, 202)
    player:GossipMenuAddItem(1, string.format("Buy 10 for %d Vote Tokens", cost * 10), GOSSIP_MENU_ID, 203)
    player:GossipMenuAddItem(1, string.format("Buy 25 for %d Vote Tokens", cost * 25), GOSSIP_MENU_ID, 204)
    player:GossipMenuAddItem(1, string.format("Buy 50 for %d Vote Tokens", cost * 50), GOSSIP_MENU_ID, 205)
    player:GossipMenuAddItem(1, "Enter custom amount", GOSSIP_MENU_ID, 206, true)
    player:GossipMenuAddItem(4, "Back", GOSSIP_MENU_ID, 99)
    player:GossipSendMenu(GOSSIP_MENU_ID, creature)
    
    -- Store the currency info in the player's temporary storage
    player:SetData("SelectedCurrencyId", currencyId)
    player:SetData("SelectedCurrencyCost", cost)
    player:SetData("SelectedCurrencyName", currencyName)
end

local function OnGossipSelect(event, player, creature, sender, intid, code)
    if sender ~= GOSSIP_MENU_ID then return end

    print("OnGossipSelect called with intid:", intid)

    if intid == 1 then
        player:GossipComplete()
    elseif intid == 101 then
        print("Showing amount menu for Emblem of Frost")
        ShowAmountMenu(player, creature, EMBLEM_OF_FROST, 5, "Emblem of Frost")
    elseif intid == 102 then
        print("Showing amount menu for Emblem of Triumph")
        ShowAmountMenu(player, creature, EMBLEM_OF_TRIUMPH, 1, "Emblem of Triumph")
    elseif intid == 103 then
        print("Showing amount menu for Transmog Token")
        ShowAmountMenu(player, creature, TRANSMOG_TOKEN, 10, "Transmog Token")
    elseif intid == 99 then
        OnGossipHello(event, player, creature)
    elseif intid >= 200 and intid <= 206 then
        local amount
        if intid == 201 then amount = 1
        elseif intid == 202 then amount = 5
        elseif intid == 203 then amount = 10
        elseif intid == 204 then amount = 25
        elseif intid == 205 then amount = 50
        elseif intid == 206 then
            amount = tonumber(code)
            if not amount or amount <= 0 then
                player:SendBroadcastMessage("Invalid amount. Please enter a positive number.")
                player:GossipComplete()
                return
            end
        else
            print("Invalid amount option:", intid)
            player:SendBroadcastMessage("Invalid amount option selected.")
            player:GossipComplete()
            return
        end

        print("Selected amount:", amount)

        local currencyId = player:GetData("SelectedCurrencyId")
        local cost = player:GetData("SelectedCurrencyCost")
        local currencyName = player:GetData("SelectedCurrencyName")

        local totalCost = cost * amount
        local confirmMessage = string.format("Are you sure you want to purchase %d %s for %d Vote Tokens?", amount, currencyName, totalCost)
        player:GossipMenuAddItem(1, confirmMessage, GOSSIP_MENU_ID, 300, false, confirmMessage)
        player:GossipSendMenu(GOSSIP_MENU_ID, creature)
        
        -- Store the purchase info in the player's temporary storage
        player:SetData("BuyAmount", amount)
    elseif intid == 300 then
        local amount = player:GetData("BuyAmount")
        local currencyId = player:GetData("SelectedCurrencyId")
        local cost = player:GetData("SelectedCurrencyCost")
        local currencyName = player:GetData("SelectedCurrencyName")

        if not amount or not currencyId or not cost or not currencyName then
            player:SendBroadcastMessage("An error occurred. Please try again.")
            player:GossipComplete()
            return
        end

        BuyCurrency(player, currencyId, cost, amount, currencyName)
    else
        player:SendBroadcastMessage("Invalid option selected.")
        player:GossipComplete()
    end
end

RegisterCreatureGossipEvent(NPC_ID, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ID, 2, OnGossipSelect)

print("[NPC]: Exchanger script loaded")

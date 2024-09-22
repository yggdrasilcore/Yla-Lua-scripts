local NPC_ID = 190000

local VOTE_TOKEN_NAME = "Vote Tokens"
local TRANSMOG_TOKEN_NAME = "Transmog Tokens"

local VOTE_TOKEN = 20880
local EMBLEM_OF_FROST = 49426
local EMBLEM_OF_TRIUMPH = 47241
local TRANSMOG_TOKEN = 37742

local function OnGossipHello(event, player, creature)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-26:0|tWhat would you like to exchange?\n \n ", 0, 1)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_bijou_gold:32:32:-26:0|tExchange Vote Tokens:", 0, 1)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_frostemblem_01:32:32:-26:0|tEmblem of Frost (5 per)", 0, 101)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_holy_summonchampion:32:32:-26:0|tEmblem of Triumph (1 per)", 0, 102)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_coin_07:32:32:-26:0|tTransmog Token (1 per)\n \n ", 0, 104)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_coin_07:32:32:-26:0|tExchange Transmog Tokens:", 0, 1)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_holy_summonchampion:32:32:-26:0|tEmblem of Triumph (15 per)\n \n", 0, 103)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-26:0|tNevermind", 0, 99)
    player:GossipSendMenu(12, creature, 60)
end

local function BuyCurrency(player, itemId, cost, amount, currencyName, costCurrency)
    print("BuyCurrency called:", itemId, cost, amount, currencyName, costCurrency)
    local totalCost = cost * amount
    if player:HasItem(costCurrency, totalCost) then
        player:RemoveItem(costCurrency, totalCost)
        player:AddItem(itemId, amount)
        player:SendBroadcastMessage(string.format("You've purchased %d %s for %d %s.", amount, currencyName, totalCost, GetItemLink(costCurrency)))
    else
        player:SendBroadcastMessage("You don't have enough "..GetItemLink(costCurrency)..".")
    end
    player:GossipComplete()
end

local function ShowAmountMenu(player, creature, currencyId, cost, currencyName, costCurrency)
    player:GossipMenuAddItem(4, string.format("|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-26:0|tChoose amount:\n \n How many %s \n can I offer you today?\n ", currencyName), 0, 200)
    player:GossipMenuAddItem(4, string.format("|TInterface/ICONS/inv_misc_coin_05:32:32:-26:0|tBuy 1 for %d %s", cost * 1, GetItemLink(costCurrency)), 0, 201)
    player:GossipMenuAddItem(4, string.format("|TInterface/ICONS/inv_misc_coin_06:32:32:-26:0|tBuy 5 for %d %s", cost * 5, GetItemLink(costCurrency)), 0, 202)
    player:GossipMenuAddItem(4, string.format("|TInterface/ICONS/inv_misc_coin_03:32:32:-26:0|tBuy 10 for %d %s", cost * 10, GetItemLink(costCurrency)), 0, 203)
    player:GossipMenuAddItem(4, string.format("|TInterface/ICONS/inv_misc_coin_04:32:32:-26:0|tBuy 25 for %d %s", cost * 25, GetItemLink(costCurrency)), 0, 204)
    player:GossipMenuAddItem(4, string.format("|TInterface/ICONS/inv_misc_coin_01:32:32:-26:0|tBuy 50 for %d %s", cost * 50, GetItemLink(costCurrency)), 0, 205)
    player:GossipMenuAddItem(4, string.format("|TInterface/ICONS/inv_misc_coin_02:32:32:-26:0|tBuy 100 for %d %s", cost * 100, GetItemLink(costCurrency)), 0, 206)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_coin_17:32:32:-26:0|tEnter custom amount", 0, 207, true)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-26:0|tBack", 0, 99)
    player:GossipSendMenu(12, creature, 60)
    
    -- Store the currency info in the player's temporary storage
    player:SetData("SelectedCurrencyId", currencyId)
    player:SetData("SelectedCurrencyCost", cost)
    player:SetData("SelectedCurrencyName", currencyName)
    player:SetData("SelectedCostCurrency", costCurrency)
end

local function OnGossipSelect(event, player, creature, sender, intid, code)
    if sender ~= 0 then return end
    if intid == 1 then
        OnGossipHello(event, player, creature)
    elseif intid == 101 then
        ShowAmountMenu(player, creature, EMBLEM_OF_FROST, 5, "Emblem of Frost", VOTE_TOKEN)
    elseif intid == 102 then
        ShowAmountMenu(player, creature, EMBLEM_OF_TRIUMPH, 1, "Emblem of Triumph", VOTE_TOKEN)
    elseif intid == 103 then
        ShowAmountMenu(player, creature, EMBLEM_OF_TRIUMPH, 15, "Emblem of Triumph", TRANSMOG_TOKEN)
    elseif intid == 104 then
        ShowAmountMenu(player, creature, TRANSMOG_TOKEN, 1, "Transmog Token", VOTE_TOKEN)
    elseif intid == 99 then
        OnGossipHello(event, player, creature)
    elseif intid >= 200 and intid <= 206 then
        local amount
        if intid == 201 then amount = 1
        elseif intid == 202 then amount = 5
        elseif intid == 203 then amount = 10
        elseif intid == 204 then amount = 25
        elseif intid == 205 then amount = 50
        elseif intid == 206 then amount = 100
        elseif intid == 207 then
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
        local costCurrency = player:GetData("SelectedCostCurrency")

        local totalCost = cost * amount
        local confirmMessage = string.format("Are you sure you want to purchase %d %s for %d %s?", amount, currencyName, totalCost, GetItemLink(costCurrency))
        player:GossipMenuAddItem(1, confirmMessage, 0, 300, false, confirmMessage)
        player:GossipSendMenu(12, creature, 60)
        
        -- Store the purchase info in the player's temporary storage
        player:SetData("BuyAmount", amount)
    elseif intid == 300 then
        local amount = player:GetData("BuyAmount")
        local currencyId = player:GetData("SelectedCurrencyId")
        local cost = player:GetData("SelectedCurrencyCost")
        local currencyName = player:GetData("SelectedCurrencyName")
        local costCurrency = player:GetData("SelectedCostCurrency")

        if not amount or not currencyId or not cost or not currencyName then
            player:SendBroadcastMessage("An error occurred. Please try again.")
            player:GossipComplete()
            return
        end

        BuyCurrency(player, currencyId, cost, amount, currencyName, costCurrency)
    else
        player:SendBroadcastMessage("Invalid option selected.")
        player:GossipComplete()
    end
end

RegisterCreatureGossipEvent(NPC_ID, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ID, 2, OnGossipSelect)
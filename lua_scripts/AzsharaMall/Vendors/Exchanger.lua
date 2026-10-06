-- Multistate: Azshara Mall-only script (mall map 37).
if not IsCompatibilityMode() and GetStateMapId() ~= 37 then return end

local NPC_ID = 190000

local VOTE_TOKEN_NAME = "Vote Tokens"
local TRANSMOG_TOKEN_NAME = "Activity Tokens"
local COMMUNITY_TOKEN_NAME = "Community Tokens"

local VOTE_TOKEN = 20880
local COMMUNITY_TOKEN = 19322
local EMBLEM_OF_FROST = 49426
local EMBLEM_OF_TRIUMPH = 47241
local TRANSMOG_TOKEN = 37742

local function OnGossipHello(event, player, creature)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-26:0|tWhat would you like to exchange?\n \n ", 0, 1)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_bijou_gold:32:32:-26:0|tExchange Vote Tokens:", 0, 1)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_frostemblem_01:32:32:-26:0|tEmblem of Frost", 0, 101)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_holy_summonchampion:32:32:-26:0|tEmblem of Triumph", 0, 102)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_coin_07:32:32:-26:0|tActivity Token", 0, 106)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_rune_07:32:32:-26:0|tCommunity Token", 0, 105)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/achievement_pvp_a_h:32:32:-26:0|tHonor Points\n \n ", 0, 107)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_coin_07:32:32:-26:0|tExchange Activity Tokens:", 0, 1)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_holy_summonchampion:32:32:-26:0|tEmblem of Triumph\n \n", 0, 103)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_rune_07:32:32:-26:0|tExchange Community Tokens:", 0, 1)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_frostemblem_01:32:32:-26:0|tEmblem of Frost", 0, 108)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_holy_summonchampion:32:32:-26:0|tEmblem of Triumph\n \n", 0, 109)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-26:0|tNevermind", 0, 98)
    player:GossipSendMenu(12, creature, 60)
end

local function BuyCurrency(player, itemId, cost, amount, currencyName, costCurrency)
    print("BuyCurrency called:", itemId, cost, amount, currencyName, costCurrency)
    local totalCost = cost * amount
    local rewardMult = player:GetData("RewardMultiplier") or 1
    local actualAmount = amount * rewardMult
    if player:HasItem(costCurrency, totalCost) then
        player:RemoveItem(costCurrency, totalCost)
        player:AddItem(itemId, actualAmount)
        player:SendBroadcastMessage(string.format("You've purchased %d %s for %d %s.", actualAmount, currencyName, totalCost, GetItemLink(costCurrency)))
    else
        player:SendBroadcastMessage("You don't have enough "..GetItemLink(costCurrency)..".")
    end
    player:GossipComplete()
end

local function BuyHonorPoints(player, cost, amount, costCurrency)
    print("BuyHonorPoints called:", cost, amount, costCurrency)
    local totalCost = cost * amount
    local rewardMult = player:GetData("RewardMultiplier") or 1
    local honorAmount = rewardMult * amount
    if player:HasItem(costCurrency, totalCost) then
        player:RemoveItem(costCurrency, totalCost)
        player:ModifyHonorPoints(honorAmount)
        player:SendBroadcastMessage(string.format("You've purchased %d Honor Points for %d %s.", honorAmount, totalCost, GetItemLink(costCurrency)))
    else
        player:SendBroadcastMessage("You don't have enough "..GetItemLink(costCurrency)..".")
    end
    player:GossipComplete()
end

local function ShowAmountMenu(player, creature, currencyId, cost, currencyName, costCurrency, isHonor, rewardAmount)
    local paymentCurrency
    if costCurrency == 20880 then
        paymentCurrency = VOTE_TOKEN_NAME
    elseif costCurrency == 19322 then
        paymentCurrency = COMMUNITY_TOKEN_NAME
    else
        paymentCurrency = TRANSMOG_TOKEN_NAME
    end
    
    local priceText
    if rewardAmount then
        priceText = string.format("Our price is: %d %s costs %d %s", rewardAmount, currencyName, cost, paymentCurrency)
    else
        priceText = string.format("Our price is: 1 %s costs %d %s", currencyName, cost, paymentCurrency)
    end
    
    local mult = rewardAmount or 1
    
    player:GossipMenuAddItem(4, string.format("|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-26:0|tChoose amount:\n \nHow many %s\nwould you like to buy today?\n \n%s\n", currencyName, priceText), 0, 200)
    player:GossipMenuAddItem(4, string.format("|TInterface/ICONS/inv_misc_coin_05:32:32:-26:0|tBuy %d for %d %s", 1 * mult, cost * 1, paymentCurrency), 0, 201)
    player:GossipMenuAddItem(4, string.format("|TInterface/ICONS/inv_misc_coin_06:32:32:-26:0|tBuy %d for %d %s", 5 * mult, cost * 5, paymentCurrency), 0, 202)
    player:GossipMenuAddItem(4, string.format("|TInterface/ICONS/inv_misc_coin_03:32:32:-26:0|tBuy %d for %d %s", 10 * mult, cost * 10, paymentCurrency), 0, 203)
    player:GossipMenuAddItem(4, string.format("|TInterface/ICONS/inv_misc_coin_04:32:32:-26:0|tBuy %d for %d %s", 25 * mult, cost * 25, paymentCurrency), 0, 204)
    player:GossipMenuAddItem(4, string.format("|TInterface/ICONS/inv_misc_coin_01:32:32:-26:0|tBuy %d for %d %s", 50 * mult, cost * 50, paymentCurrency), 0, 205)
    player:GossipMenuAddItem(4, string.format("|TInterface/ICONS/inv_misc_coin_02:32:32:-26:0|tBuy %d for %d %s", 100 * mult, cost * 100, paymentCurrency), 0, 206)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_coin_17:32:32:-26:0|tEnter custom amount", 0, 207, true)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-26:0|tBack", 0, 99)
    player:GossipSendMenu(12, creature, 60)
    
    player:SetData("SelectedCurrencyId", currencyId)
    player:SetData("SelectedCurrencyCost", cost)
    player:SetData("SelectedCurrencyName", currencyName)
    player:SetData("SelectedCostCurrency", costCurrency)
    player:SetData("IsHonorPurchase", isHonor and 1 or 0)
    player:SetData("RewardMultiplier", mult)
end

local function OnGossipSelect(event, player, creature, sender, intid, code)
    if sender ~= 0 then return end
    if intid == 1 then
        OnGossipHello(event, player, creature)
    elseif intid == 101 then
        ShowAmountMenu(player, creature, EMBLEM_OF_FROST, 5, "Emblem of Frost", VOTE_TOKEN, false, 1)
    elseif intid == 102 then
        ShowAmountMenu(player, creature, EMBLEM_OF_TRIUMPH, 1, "Emblem of Triumph", VOTE_TOKEN, false, 1)
    elseif intid == 103 then
        ShowAmountMenu(player, creature, EMBLEM_OF_TRIUMPH, 15, "Emblem of Triumph", TRANSMOG_TOKEN, false, 1)
    elseif intid == 104 then
        ShowAmountMenu(player, creature, TRANSMOG_TOKEN, 1, "Activity Token", VOTE_TOKEN, false, 1)
    elseif intid == 105 then
        ShowAmountMenu(player, creature, COMMUNITY_TOKEN, 10, "Community Token", VOTE_TOKEN, false, 1)
    elseif intid == 106 then
        ShowAmountMenu(player, creature, TRANSMOG_TOKEN, 1, "Activity Tokens", VOTE_TOKEN, false, 10)
    elseif intid == 107 then
        ShowAmountMenu(player, creature, 0, 1, "Honor Points", VOTE_TOKEN, true, 500)
    elseif intid == 108 then
        ShowAmountMenu(player, creature, EMBLEM_OF_FROST, 1, "Emblem of Frost", COMMUNITY_TOKEN, false, 2)
    elseif intid == 109 then
        ShowAmountMenu(player, creature, EMBLEM_OF_TRIUMPH, 1, "Emblem of Triumph", COMMUNITY_TOKEN, false, 15)
    elseif intid == 99 then
        OnGossipHello(event, player, creature)
    elseif intid == 98 then
        player:GossipComplete()
    elseif intid >= 200 and intid <= 207 then
        local amount
        if intid == 200 then
            return
        elseif intid == 201 then amount = 1
        elseif intid == 202 then amount = 5
        elseif intid == 203 then amount = 10
        elseif intid == 204 then amount = 25
        elseif intid == 205 then amount = 50
        elseif intid == 206 then amount = 100
        elseif intid == 207 then
            local rewardMult = player:GetData("RewardMultiplier") or 1
            local desiredItems = tonumber(code)
            if not desiredItems or desiredItems <= 0 then
                player:SendBroadcastMessage("Invalid amount. Please enter a positive number.")
                player:GossipComplete()
                return
            end
            
            if desiredItems % rewardMult ~= 0 then
                player:SendBroadcastMessage(string.format("Amount must be a multiple of %d.", rewardMult))
                player:GossipComplete()
                return
            end
            
            amount = desiredItems / rewardMult
        end

        print("Selected amount:", amount)

        local currencyId = player:GetData("SelectedCurrencyId")
        local cost = player:GetData("SelectedCurrencyCost")
        local currencyName = player:GetData("SelectedCurrencyName")
        local costCurrency = player:GetData("SelectedCostCurrency")
        local isHonor = player:GetData("IsHonorPurchase") == 1
        local rewardMult = player:GetData("RewardMultiplier") or 1

        local totalCost = cost * amount
        local actualAmount = amount * rewardMult
        local confirmMessage = string.format("Are you sure you want to purchase %d %s for %d %s?", actualAmount, currencyName, totalCost, GetItemLink(costCurrency))
        player:GossipMenuAddItem(1, confirmMessage, 0, 300, false, confirmMessage)
        player:GossipSendMenu(12, creature, 60)
        
        player:SetData("BuyAmount", amount)
    elseif intid == 300 then
        local amount = player:GetData("BuyAmount")
        local currencyId = player:GetData("SelectedCurrencyId")
        local cost = player:GetData("SelectedCurrencyCost")
        local currencyName = player:GetData("SelectedCurrencyName")
        local costCurrency = player:GetData("SelectedCostCurrency")
        local isHonor = player:GetData("IsHonorPurchase") == 1

        if not amount or not currencyId or not cost or not currencyName then
            player:SendBroadcastMessage("An error occurred. Please try again.")
            player:GossipComplete()
            return
        end

        if isHonor then
            BuyHonorPoints(player, cost, amount, costCurrency)
        else
            BuyCurrency(player, currencyId, cost, amount, currencyName, costCurrency)
        end
    else
        player:SendBroadcastMessage("Invalid option selected.")
        player:GossipComplete()
    end
end

RegisterCreatureGossipEvent(NPC_ID, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ID, 2, OnGossipSelect)
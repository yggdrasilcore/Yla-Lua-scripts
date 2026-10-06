-- Multistate: Azshara Mall-only script (mall map 37).
if not IsCompatibilityMode() and GetStateMapId() ~= 37 then return end

local communityTokenItemId 	= 19322 -- ID for Community Tokens
local voteTokenItemId		= 20880 -- ID for Vote Tokens
local priceRename			= 5
local priceCustomize		= 5
local priceChangeFaction	= 10
local priceChangeRace 		= 15
local VoteTokenCoeff		= 10

local function updateAtLoginCache(player, bitmask)
    -- Check current flags individually
    local currentFlags = 0

    if player:HasAtLoginFlag(1) then currentFlags = bit32.bor(currentFlags, 1) end
    if player:HasAtLoginFlag(2) then currentFlags = bit32.bor(currentFlags, 2) end
    if player:HasAtLoginFlag(4) then currentFlags = bit32.bor(currentFlags, 4) end
    if player:HasAtLoginFlag(8) then currentFlags = bit32.bor(currentFlags, 8) end
    if player:HasAtLoginFlag(16) then currentFlags = bit32.bor(currentFlags, 16) end
    if player:HasAtLoginFlag(32) then currentFlags = bit32.bor(currentFlags, 32) end
    if player:HasAtLoginFlag(64) then currentFlags = bit32.bor(currentFlags, 64) end
    if player:HasAtLoginFlag(128) then currentFlags = bit32.bor(currentFlags, 128) end

    -- Add the new bitmask to currentFlags
    local newFlags = bit32.bor(currentFlags, bitmask)
    
    -- Set the new flags
    player:SetAtLoginFlag(newFlags)
end

local function OnGossipHello(event, player, creature)
    player:GossipClearMenu()
    player:GossipMenuAddItem(0, "|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-22:0|tAbout Character Services", 0, 99, false)
    player:GossipMenuAddItem(1, "|TInterface/ICONS/inv_scroll_11:32:32:-22:0|tRename Character", 0, 1, false)
    player:GossipMenuAddItem(1, "|TInterface/ICONS/inv_throwingknife_02:32:32:-22:0|tCustomize Character", 0, 2, false)
    player:GossipMenuAddItem(1, "|TInterface/ICONS/achievement_pvp_a_h:32:32:-22:0|tChange Faction", 0, 3, false)
    player:GossipMenuAddItem(1, "|TInterface/ICONS/achievement_character_orc_male:32:32:-22:0|tChange Race", 0, 4, false)
    player:GossipSendMenu(12, creature, 61)
end

local function OnGossipSelect(event, player, creature, sender, intid, code)
    if intid == 1 then -- Rename
        player:GossipClearMenu()
        player:GossipMenuAddItem(0, "|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-22:0|tChoose payment method", 0, 1, false)
        player:GossipMenuAddItem(1, "|TInterface/ICONS/inv_misc_rune_07:32:32:-22:0|tPay with "..priceRename.." Community Tokens", 0, 11, false, "Are you sure you want to pay "..priceRename.." Community Tokens to rename your character?")
        player:GossipMenuAddItem(1, "|TInterface/ICONS/Inv_bijou_gold:32:32:-22:0|tPay with "..priceRename * VoteTokenCoeff.." Vote Tokens", 0, 12, false, "Are you sure you want to pay "..priceRename * VoteTokenCoeff.." Vote Tokens to rename your character?")
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 98, false)
        player:GossipSendMenu(12, creature, 61)
    elseif intid == 2 then -- Customize
        player:GossipClearMenu()
        player:GossipMenuAddItem(4, "|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-22:0|tChoose payment method", 0, 2, false)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_rune_07:32:32:-22:0|tPay with "..priceCustomize.." Community Tokens", 0, 21, false, "Are you sure you want to pay "..priceCustomize.." Community Tokens to customize your character?")
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Inv_bijou_gold:32:32:-22:0|tPay with "..priceCustomize * VoteTokenCoeff.." Vote Tokens", 0, 22, false, "Are you sure you want to pay "..priceCustomize * VoteTokenCoeff.." Vote Tokens to customize your character?")
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 98, false)
        player:GossipSendMenu(12, creature, 61)
    elseif intid == 3 then -- Change Faction
        player:GossipClearMenu()
        player:GossipMenuAddItem(4, "|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-22:0|tChoose payment method", 0, 3, false)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_rune_07:32:32:-22:0|tPay with "..priceChangeFaction.." Community Tokens", 0, 31, false, "Are you sure you want to pay "..priceChangeFaction.." Community Tokens to change your faction?")
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Inv_bijou_gold:32:32:-22:0|tPay with "..priceChangeFaction * VoteTokenCoeff.." Vote Tokens", 0, 32, false, "Are you sure you want to pay "..priceChangeFaction * VoteTokenCoeff.." Vote Tokens to change your faction?")
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 98, false)
        player:GossipSendMenu(12, creature, 61)
    elseif intid == 4 then -- Change Race
        player:GossipClearMenu()
        player:GossipMenuAddItem(4, "|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-22:0|tChoose payment method", 0, 4, false)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_rune_07:32:32:-22:0|tPay with "..priceChangeRace.." Community Tokens", 0, 41, false, "Are you sure you want to pay "..priceChangeRace.." Community Tokens to change your race?")
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Inv_bijou_gold:32:32:-22:0|tPay with "..priceChangeRace * VoteTokenCoeff.." Vote Tokens", 0, 42, false, "Are you sure you want to pay "..priceChangeRace * VoteTokenCoeff.." Vote Tokens to change your race?")
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 98, false)
        player:GossipSendMenu(12, creature, 61)
    elseif intid == 98 then -- Reload gossip menu
        OnGossipHello(event, player, creature)
    elseif intid == 99 then -- Information
        player:GossipClearMenu()        
        player:GossipMenuAddItem(0, "|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-22:0|tAbout Character Services\n \nThrough pulling the strings of the Twisting Nether, I, the Ethereal Customizer, possess the power to change all aspects of your character. \n \nI charge Community Tokens or Vote Tokens for my services, which you may acquire through donating or voting for the server.\n \nCustomizing, race-changing and faction-changing your character includes a free rename.\n \nMy services are non-refundable.\n ", 0, 99, false)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tGo back", 0, 98, false)
        player:GossipSendMenu(12, creature, 61)
    elseif intid == 11 or intid == 21 or intid == 31 or intid == 41 then -- Pay with Community Tokens
        local communityTokenCost = 5
		if intid == 11 then
			communityTokenCost = priceRename
        elseif intid == 21 then
			communityTokenCost = priceCustomize
        elseif intid == 31 then
            communityTokenCost = priceChangeFaction
		elseif intid == 41 then
            communityTokenCost = priceChangeRace
        end
        local bitmask = 0
        if intid == 11 then
            bitmask = 8
        elseif intid == 21 then
            bitmask = 8
        elseif intid == 31 then
            bitmask = 64
        elseif intid == 41 then
            bitmask = 128
        end
        if player:HasAtLoginFlag(bitmask) then
            player:SendBroadcastMessage("You already have this service active.")
        elseif player:GetItemCount(communityTokenItemId) >= communityTokenCost then
            player:RemoveItem(communityTokenItemId, communityTokenCost)
			updateAtLoginCache(player, bitmask)
			player:SaveToDB()
			player:SendBroadcastMessage("Your request has been processed. Please log out and back in to apply the changes.")
        else
            player:SendBroadcastMessage("You do not have enough Community Tokens.")
        end
        player:GossipComplete()
    elseif intid == 12 or intid == 22 or intid == 32 or intid == 42 then -- Pay with Vote Tokens
        local voteCost = 50
		if intid == 12 then
			voteCost = priceRename * VoteTokenCoeff
		elseif intid == 22 then
			voteCost = priceCustomize * VoteTokenCoeff
        elseif intid == 32 then
			voteCost = priceChangeFaction * VoteTokenCoeff
		elseif intid == 42 then
            voteCost = priceChangeRace * VoteTokenCoeff
        end
        local bitmask = 0
        if intid == 12 then
            bitmask = 8
        elseif intid == 22 then
            bitmask = 8
        elseif intid == 32 then
            bitmask = 64
        elseif intid == 42 then
            bitmask = 128
        end
        if player:HasAtLoginFlag(bitmask) then
            player:SendBroadcastMessage("You already have this service active.")
        elseif player:GetItemCount(voteTokenItemId) >= voteCost then
            player:RemoveItem(voteTokenItemId, voteCost)
			updateAtLoginCache(player, bitmask)
			player:SaveToDB()
			player:SendBroadcastMessage("Your request has been processed. Please log out and back in to apply the changes.")
        else
            player:SendBroadcastMessage("You do not have enough Vote Tokens.")
        end
        player:GossipComplete()
    end
end

RegisterCreatureGossipEvent(190096, 1, OnGossipHello)
RegisterCreatureGossipEvent(190096, 2, OnGossipSelect)

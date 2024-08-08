local communityTokenItemId 	= 17829 -- ID for Community Tokens
local voteTokenItemId		= 20880 -- ID for Vote Tokens
local priceRename			= 5
local priceCustomize		= 5
local priceChangeFaction	= 10
local priceChangeRace 		= 15
local VoteTokenCoeff		= 10

local function hasSufficientCommunityTokens(player, amount)
    return player:GetItemCount(communityTokenItemId) >= amount
end

local function hasSufficientVoteTokens(player, amount)
    return player:GetItemCount(voteTokenItemId) >= amount
end

local function removeCommunityTokens(player, amount)
    player:RemoveItem(communityTokenItemId, amount)
end

local function removeVoteTokens(player, amount)
    player:RemoveItem(voteTokenItemId, amount)
end

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
    player:GossipMenuAddItem(0, "Information about Character Services", 0, 99, false)
    player:GossipMenuAddItem(1, "Rename Character", 0, 1, false)
    player:GossipMenuAddItem(1, "Customize Character", 0, 2, false)
    player:GossipMenuAddItem(1, "Change Faction", 0, 3, false)
    player:GossipMenuAddItem(1, "Change Race", 0, 4, false)
    player:GossipSendMenu(1, creature)
end

local function OnGossipSelect(event, player, creature, sender, intid, code)
    if intid == 1 then -- Rename
        player:GossipClearMenu()
        player:GossipMenuAddItem(0, "How do you want to pay to rename your character?", 0, 1, false)
        player:GossipMenuAddItem(1, "Pay with "..priceRename.." Community Tokens", 0, 11, false, "Are you sure you want to pay "..priceRename.." Community Tokens to rename your character?")
        player:GossipMenuAddItem(1, "Pay with "..priceRename * VoteTokenCoeff.." Vote Tokens", 0, 12, false, "Are you sure you want to pay "..priceRename * VoteTokenCoeff.." Vote Tokens to rename your character?")
        player:GossipMenuAddItem(4, "Back", 0, 98, false)
        player:GossipSendMenu(1, creature)
    elseif intid == 2 then -- Customize
        player:GossipClearMenu()
        player:GossipMenuAddItem(0, "How do you want to pay to customize your character?", 0, 2, false)
        player:GossipMenuAddItem(1, "Pay with "..priceCustomize.." Community Tokens", 0, 21, false, "Are you sure you want to pay "..priceCustomize.." Community Tokens to customize your character?")
        player:GossipMenuAddItem(1, "Pay with "..priceCustomize * VoteTokenCoeff.." Vote Tokens", 0, 22, false, "Are you sure you want to pay "..priceCustomize * VoteTokenCoeff.." Vote Tokens to customize your character?")
        player:GossipMenuAddItem(4, "Back", 0, 98, false)
        player:GossipSendMenu(1, creature)
    elseif intid == 3 then -- Change Faction
        player:GossipClearMenu()
        player:GossipMenuAddItem(0, "How do you want to pay to change your faction?", 0, 3, false)
        player:GossipMenuAddItem(1, "Pay with "..priceChangeFaction.." Community Tokens", 0, 31, false, "Are you sure you want to pay "..priceRename.." Community Tokens to change your faction?")
        player:GossipMenuAddItem(1, "Pay with "..priceChangeFaction * VoteTokenCoeff.." Vote Tokens", 0, 32, false, "Are you sure you want to pay "..priceChangeFaction * VoteTokenCoeff.." Vote Tokens to change your faction?")
        player:GossipMenuAddItem(4, "Back", 0, 98, false)
        player:GossipSendMenu(1, creature)
    elseif intid == 4 then -- Change Race
        player:GossipClearMenu()
        player:GossipMenuAddItem(0, "How do you want to pay to change your race?", 0, 4, false)
        player:GossipMenuAddItem(1, "Pay with "..priceChangeRace.." Community Tokens", 0, 41, false, "Are you sure you want to pay "..priceChangeRace.." Community Tokens to change your race?")
        player:GossipMenuAddItem(1, "Pay with "..priceChangeRace * VoteTokenCoeff.." Vote Tokens", 0, 42, false, "Are you sure you want to pay "..priceChangeRace * VoteTokenCoeff.." Vote Tokens to change your race?")
        player:GossipMenuAddItem(4, "Back", 0, 98, false)
        player:GossipSendMenu(1, creature)
    elseif intid == 98 then -- Reload gossip menu
        player:GossipClearMenu()
        player:GossipMenuAddItem(0, "Information about Character Services", 0, 98, false)
        player:GossipMenuAddItem(1, "Rename Character", 0, 1, false)
        player:GossipMenuAddItem(1, "Customize Character", 0, 2, false)
        player:GossipMenuAddItem(1, "Change Faction", 0, 3, false)
        player:GossipMenuAddItem(1, "Change Race", 0, 4, false)
        player:GossipSendMenu(1, creature)
    elseif intid == 99 then -- Information
        player:GossipClearMenu()
        player:GossipMenuAddItem(0, "Through pulling the strings of the Twisting Nether, I, the Ethereal Rebalancer, possess the power to change all aspects of your character. I charge Community Tokens or Vote Tokens for my services, which you may acquire through donating or voting for the server. My services are non-refundable.", 0, 98, false)
        player:GossipMenuAddItem(4, "Go back", 0, 98, false)
        player:GossipSendMenu(1, creature)
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
            bitmask = 1
        elseif intid == 21 then
            bitmask = 2
        elseif intid == 31 then
            bitmask = 64
        elseif intid == 41 then
            bitmask = 128
        end
        if player:HasAtLoginFlag(bitmask) then
            player:SendBroadcastMessage("You already have this service active.")
        elseif hasSufficientCommunityTokens(player, communityTokenCost) then
			removeCommunityTokens(player, communityTokenCost)
			updateAtLoginCache(player, bitmask)
			player:SaveToDB()
			player:SendBroadcastMessage("Your request has been processed. Please log out and log back in to apply the changes.")
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
            bitmask = 1
        elseif intid == 22 then
            bitmask = 2
        elseif intid == 32 then
            bitmask = 64
        elseif intid == 42 then
            bitmask = 128
        end
        if player:HasAtLoginFlag(bitmask) then
            player:SendBroadcastMessage("You already have this service active.")
        elseif hasSufficientVoteTokens(player, voteCost) then
			removeVoteTokens(player, voteCost)
			updateAtLoginCache(player, bitmask)
			player:SaveToDB()
			player:SendBroadcastMessage("Your request has been processed. Please log out and log back in to apply the changes.")
        else
            player:SendBroadcastMessage("You do not have enough Vote Tokens.")
        end
        player:GossipComplete()
    end
end

RegisterCreatureGossipEvent(190096, 1, OnGossipHello)
RegisterCreatureGossipEvent(190096, 2, OnGossipSelect)

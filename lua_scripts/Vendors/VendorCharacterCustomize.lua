local CommunityTokenItemId = 17829 -- ID for Community Tokens

local function hasSufficientCommunityTokens(player, amount)
    return player:GetItemCount(CommunityTokenItemId) >= amount
end

local function removeCommunityTokens(player, amount)
    player:RemoveItem(CommunityTokenItemId, amount)
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
    player:GossipMenuAddItem(3, "Rename Character (5 Community Tokens)", 0, 1, false, "Are you sure you want to rename your character for 5 Community Tokens?")
    player:GossipMenuAddItem(3, "Customize Character (5 Community Tokens)", 0, 2, false, "Are you sure you want to customize your character for 5 Community Tokens?")
    player:GossipMenuAddItem(3, "Change Faction (10 Community Tokens)", 0, 3, false, "Are you sure you want to change your faction for 10 Community Tokens?")
    player:GossipMenuAddItem(3, "Change Race (10 Community Tokens)", 0, 4, false, "Are you sure you want to change your race for 10 Community Tokens?")
    player:GossipSendMenu(1, creature)
end

local function OnGossipSelect(event, player, creature, sender, intid, code)
    local cost = 5
    local bitmask = 0

    if intid == 1 then -- Rename
        bitmask = 1
    elseif intid == 2 then -- Customize
        bitmask = 2
    elseif intid == 3 then -- Change Faction
        cost = 10
        bitmask = 64
    elseif intid == 4 then -- Change Race
        cost = 10
        bitmask = 128
	elseif intid == 98 then -- Reload gossip menu
        player:GossipClearMenu()
		player:GossipMenuAddItem(0, "Information about Character Services", 0, 99, false)
		player:GossipMenuAddItem(3, "Rename Character (5 Community Tokens)", 0, 1, false, "Are you sure you want to rename your character for 5 Community Tokens?")
		player:GossipMenuAddItem(3, "Customize Character (5 Community Tokens)", 0, 2, false, "Are you sure you want to customize your character for 5 Community Tokens?")
		player:GossipMenuAddItem(3, "Change Faction (10 Community Tokens)", 0, 3, false, "Are you sure you want to change your faction for 10 Community Tokens?")
		player:GossipMenuAddItem(3, "Change Race (10 Community Tokens)", 0, 4, false, "Are you sure you want to change your race for 10 Community Tokens?")
		player:GossipSendMenu(1, creature)
    elseif intid == 99 then -- Information
        player:GossipClearMenu()
		player:GossipMenuAddItem(0, "Through pulling the strings of the Twisting Nether, I, the Ethereal Rebalancer, possess the power to change all aspects of your character. I charge Community Tokens for my services, which you may aquire through donating to the server. My services are non-refundable.", 0, 99, false)
		player:GossipMenuAddItem(4, "Go back", 0, 98, false)
		player:GossipSendMenu(1, creature)
    end

	if intid == 1 or intid == 2 or intid == 3 or intid == 4 then
		if player:HasAtLoginFlag(bitmask) then
			player:SendBroadcastMessage("You already have this service active.")
		else
			if hasSufficientCommunityTokens(player, cost) then
				removeCommunityTokens(player, cost)
				updateAtLoginCache(player, bitmask)
				player:SaveToDB()
				player:SendBroadcastMessage("Your request has been processed. Please log out and log back in to apply the changes.")
			else
				player:SendBroadcastMessage("You do not have enough Community Tokens.")
			end
		end
		player:GossipComplete()
	end
end

RegisterCreatureGossipEvent(190096, 1, OnGossipHello)
RegisterCreatureGossipEvent(190096, 2, OnGossipSelect)

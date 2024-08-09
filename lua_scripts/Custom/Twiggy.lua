-- Start Mall TP vars
local ITEM_ID = 37430
local COOLDOWN = 3600 -- 1 hour cooldown in seconds
local MAP_ID = 573
local X = 250.504822
local Y = 504.449799
local Z = 24.741276
local ORIENTATION = 5.461457
-- End Mall TP vars

-- VIP vars
local vendorID = 26300
local vendorCD = 15 * 60 -- 15 minutes in seconds
local VIPVendorDuration = 1 * 60 * 1000 -- VIP vendor lasts for 1 minute
local timeMessage = 0
-- End VIP vars

-- Initiates VIP table if not already present
CharDBExecute("CREATE TABLE IF NOT EXISTS ACCOUNTS_VIP (ACCOUNT INT(6) NOT NULL PRIMARY KEY, VIPTIME INT(11) NOT NULL);")

-- Prepares Twiggy in the database
WorldDBExecute("UPDATE creature_template_model SET CreatureDisplayID = 13098, DisplayScale = 0.33 WHERE CreatureID = 23198;")
WorldDBExecute("UPDATE creature_template SET name = 'Twiggy', scale = 0.45 WHERE entry = 23198;")
WorldDBExecute("UPDATE item_template SET description = 'Teaches you how to summon Twiggy, your personal branch of Yggdrasil.', name = 'Twiggy''s Wooden Chip' WHERE entry = 32498;")

-- Prepares VIP trash vendor
WorldDBExecute("UPDATE creature_template SET name = 'All-Buying Hobgoblin Repair' WHERE entry = 26309;")
WorldDBExecute("UPDATE creature_template SET name = 'All-Buying Hobgoblin' WHERE entry = 26300;")

local function LoadCooldown(player) -- For mall stone
    local guid = player:GetGUIDLow()
    local query = CharDBQuery("SELECT cooldown_end FROM character_cooldowns WHERE guid = " .. guid .. " AND item_id = " .. ITEM_ID)
    if query then
        return query:GetUInt32(0)
    end
    return 0
end

local function LoadVIPVendorCooldown(player) -- For mall stone
    local guid = player:GetGUIDLow()
    local query = CharDBQuery("SELECT cooldown_end FROM character_cooldowns WHERE guid = " .. guid .. " AND item_id = " .. 99999)
    if query then
        return query:GetUInt32(0)
    end
    return 0
end

local function OnGossipHello(event, player, creature)
	print("OnGossipHello called!")
    player:GossipMenuAddItem(0, "I am Twiggy, your personal branch of Yggdrasil! How can I help you today?", 0, 1)
    player:GossipMenuAddItem(4, "VIP options", 0, 2)
    player:GossipMenuAddItem(4, "See my currencies", 0, 3)
    player:GossipMenuAddItem(2, "Let's go to the Mall!", 0, 4)
    player:GossipSendMenu(1, creature, 60)
end

local function OnGossipSelect(event, player, creature, sender, intId, code)
    if intId == 1 then
		player:GossipMenuAddItem(0, "I am Twiggy, your personal branch of Yggdrasil! How can I help you today?", 0, 1)
		player:GossipMenuAddItem(4, "VIP options", 0, 2)
		player:GossipMenuAddItem(4, "See my currencies", 0, 3)
		player:GossipMenuAddItem(2, "Let's go to the Mall!", 0, 4)
        player:GossipSendMenu(1, creature, 60)
	elseif intId == 2 then
		local result = CharDBQuery("SELECT VIPTIME FROM ACCOUNTS_VIP WHERE ACCOUNT = " .. player:GetAccountId() .. ";")
		if result then
			local vipTime = result:GetUInt32(0)
			local remainingTime = vipTime - os.time()

			if remainingTime >= 86400 then
				timeMessage = string.format("%d days left", math.ceil(remainingTime / 86400))
			elseif remainingTime >= 3600 then
				timeMessage = string.format("%d hours left", math.ceil(remainingTime / 3600))
			elseif remainingTime >= 60 then
				timeMessage = string.format("%d minutes left", math.ceil(remainingTime / 60))
			else
				timeMessage = "Less than a minute left"
			end

			print("VIPTIME for account " .. player:GetAccountId() .. " is: " .. timeMessage)
			player:GossipMenuAddItem(0, "VIP status: On (" .. timeMessage .. ")", 0, 2)
			player:GossipMenuAddItem(1, "VIP repair", 0, 12)
			player:GossipMenuAddItem(1, "VIP bank", 0, 13)
			player:GossipMenuAddItem(1, "VIP mail", 0, 14)
			--player:GossipMenuAddItem(1, "VIP flight", 0, 15) -- Doesn't work
			--player:GossipMenuAddItem(1, "VIP trainer", 0, 16) -- Doesn't work
			player:GossipMenuAddItem(1, "VIP vendor", 0, 17)
			player:GossipMenuAddItem(1, "VIP auction house", 0, 18)
		else 
			player:GossipMenuAddItem(0, "VIP status: Off. Activate VIP?", 0, 20)
			player:GossipMenuAddItem(0, "Why should I get VIP?", 0, 19)
			print("No VIPTIME found for account " .. player:GetAccountId())
		end
        player:GossipMenuAddItem(4, "Back", 0, 1)
        player:GossipSendMenu(1, creature, 60)
	elseif intId == 19 then
		player:GossipMenuAddItem(0, "As VIP, you get access to free repairs, banking, mailing, and a vendor to sell your accumulated items anywhere you are!",  0, 19)
        player:GossipMenuAddItem(4, "Back", 0, 2)
        player:GossipSendMenu(1, creature, 60)
	elseif intId == 20 then
        player:GossipMenuAddItem(1, "For how long do you want VIP?", 0, 20)
        player:GossipMenuAddItem(1, "7 days (7 Community Tokens)", 0, 21)
        player:GossipMenuAddItem(1, "14 days (12 Community Tokens)", 0, 22)
		player:GossipMenuAddItem(1, "21 days (15 Community Tokens)", 0, 23)
        player:GossipSendMenu(1, creature, 60)
	elseif intId == 21 then
		if player:HasItem(17829,7) then
			player:RemoveItem(17829,7)

			CharDBExecute("INSERT INTO ACCOUNTS_VIP (ACCOUNT, VIPTIME) VALUES (" .. player:GetAccountId() .. ", " .. (os.time() + 7 * 24 * 60 * 60) .. ") ON DUPLICATE KEY UPDATE VIPTIME = VALUES(VIPTIME);")

			player:GossipMenuAddItem(0, "VIP status: On (7 days)", 0, 2)
			player:GossipMenuAddItem(1, "VIP repair", 0, 12)
			player:GossipMenuAddItem(1, "VIP bank", 0, 13)
			player:GossipMenuAddItem(1, "VIP mail", 2, 14)
			player:GossipMenuAddItem(1, "VIP vendor", 0, 17)
			player:GossipMenuAddItem(1, "VIP auction house", 0, 18)
			player:GossipMenuAddItem(4, "Back", 0, 1)
			player:GossipSendMenu(1, creature, 60)
		else 
			player:SendAreaTriggerMessage("You don't have enough Community Tokens.")
		end
	elseif intId == 22 then
		if player:HasItem(17829,12) then
			player:RemoveItem(17829,12)

			CharDBExecute("INSERT INTO ACCOUNTS_VIP (ACCOUNT, VIPTIME) VALUES (" .. player:GetAccountId() .. ", " .. (os.time() + 14 * 24 * 60 * 60) .. ") ON DUPLICATE KEY UPDATE VIPTIME = VALUES(VIPTIME);")

			player:GossipMenuAddItem(0, "VIP status: On (14 days)", 0, 2)
			player:GossipMenuAddItem(1, "VIP repair", 0, 12)
			player:GossipMenuAddItem(1, "VIP bank", 0, 13)
			player:GossipMenuAddItem(1, "VIP mail", 2, 14)
			player:GossipMenuAddItem(1, "VIP vendor", 0, 17)
			player:GossipMenuAddItem(1, "VIP auction house", 0, 18)
			player:GossipMenuAddItem(4, "Back", 0, 1)
			player:GossipSendMenu(1, creature, 60)
		else 
			player:SendAreaTriggerMessage("You don't have enough Community Tokens.")
		end
	elseif intId == 23 then
		if player:HasItem(17829,15) then
			player:RemoveItem(17829,15)
			CharDBExecute("INSERT INTO ACCOUNTS_VIP (ACCOUNT, VIPTIME) VALUES (" .. player:GetAccountId() .. ", " .. (os.time() + 21 * 24 * 60 * 60) .. ") ON DUPLICATE KEY UPDATE VIPTIME = VALUES(VIPTIME);")

			player:GossipMenuAddItem(0, "VIP status: On (21 days)", 0, 2)
			player:GossipMenuAddItem(1, "VIP repair", 0, 12)
			player:GossipMenuAddItem(1, "VIP bank", 0, 13)
			player:GossipMenuAddItem(1, "VIP mail", 2, 14)
			player:GossipMenuAddItem(1, "VIP vendor", 0, 17)
			player:GossipMenuAddItem(1, "VIP auction house", 0, 18)
			player:GossipMenuAddItem(4, "Back", 0, 1)
			player:GossipSendMenu(1, creature, 60)
		else 
			player:SendAreaTriggerMessage("You don't have enough Community Tokens.")
		end
		
    elseif intId == 3 then
        player:GossipMenuAddItem(0, "What can I use my currencies for?", 0, 30)
		local CommunityTokenQuery = CharDBQuery("SELECT count FROM accountwide_currency WHERE accountId = " .. player:GetAccountId() .. " AND currencyId = " .. 17829)
		local CommunityToken = CommunityTokenQuery:GetUInt32(0)
		if not CommunityToken then CommunityToken = 0 end
        player:GossipMenuAddItem(0, "Community Tokens: "..CommunityToken, 0, 3)
		
		local TransmogTokenQuery = CharDBQuery("SELECT count FROM accountwide_currency WHERE accountId = " .. player:GetAccountId() .. " AND currencyId = " .. 37742)
		local TransmogToken = TransmogTokenQuery:GetUInt32(0)
		if not TransmogToken then TransmogToken = 0 end
        player:GossipMenuAddItem(0, "Transmog Tokens: "..TransmogToken, 0, 3)
		
		local VoteTokenQuery = CharDBQuery("SELECT count FROM accountwide_currency WHERE accountId = " .. player:GetAccountId() .. " AND currencyId = " .. 20880)
		local VoteToken = VoteTokenQuery:GetUInt32(0)
		if not VoteToken then VoteToken = 0 end
        player:GossipMenuAddItem(0, "Vote Tokens: "..VoteToken, 0, 3)
		
        player:GossipMenuAddItem(4, "Back", 0, 1)
        player:GossipSendMenu(1, creature, 60)
	elseif intId == 30 then
        player:GossipMenuAddItem(0, "Community Token: Earned through helping build the Yggdrasil community, these tokens can be traded for vanity pets, mounts, account services and more at the mall, or VIP services with me.", 0, 30)
        player:GossipMenuAddItem(0, "Transmog Token: This currency can be spent at the transmog item vendor to buy items under item level 200 taht you can then later wear as gear or transmog onto your higher item level gear. It is earned by completing end-game quests or slaying bosses above level 71 while at level 80", 0, 30)
        player:GossipMenuAddItem(0, "Vote Token: Earned through voting for the server, these tokens can be predominantly exchanged for vanity items at the mall, or traded down to Emblems of Frost or Emblems of Triumph at the Mall's exchanger.", 0, 30)	
        player:GossipMenuAddItem(4, "Back", 0, 3)
        player:GossipSendMenu(1, creature, 60)
    elseif intId == 4 then
	   if player:IsInCombat() then
			player:SendNotification("You teleport to the mall in combat.")
			return false
		end

		if player:GetBattlegroundId() ~= 0 then
			player:SendNotification("You teleport to the mall in a battleground.")
			return false
		end

		local currentTime = os.time()
		local cooldownEnd = LoadCooldown(player)
		local remainingCooldown = cooldownEnd - currentTime

		if remainingCooldown > 0 then
			local hours = math.floor(remainingCooldown / 3600)
			local minutes = math.floor((remainingCooldown % 3600) / 60)
			local seconds = math.floor(remainingCooldown % 60)
			player:SendAreaTriggerMessage("Your mall teleport is on cooldown for " .. minutes .. " minutes, and " .. seconds .. " seconds.")
			return false
		end

		cooldownEnd = currentTime + COOLDOWN
		CharDBExecute("REPLACE INTO character_cooldowns (guid, item_id, cooldown_end) VALUES (" .. player:GetGUIDLow() .. ", " .. 37430 .. ", " .. cooldownEnd .. ")")
		player:Teleport(MAP_ID, X, Y, Z, ORIENTATION)
		return true
    elseif intId == 11 then
		if timeMessage then 
			player:GossipMenuAddItem(0, "VIP status: On (" .. timeMessage .. ")", 0, 2)
		else 
			player:GossipMenuAddItem(0, "VIP status: On", 0, 2)
		end
		player:GossipMenuAddItem(1, "VIP repair", 0, 12)
		player:GossipMenuAddItem(1, "VIP bank", 0, 13)
		player:GossipMenuAddItem(1, "VIP mail", 2, 14)
		player:GossipMenuAddItem(1, "VIP vendor", 0, 17)
		player:GossipMenuAddItem(1, "VIP auction house", 0, 18)
		player:GossipMenuAddItem(4, "Back", 0, 1)
        player:GossipSendMenu(1, creature, 60)
    elseif intId == 12 then
		player:DurabilityRepairAll(false)
        player:SendBroadcastMessage("You have repaired your items.")
		
		if timeMessage then 
			player:GossipMenuAddItem(0, "VIP status: On (" .. timeMessage .. ")", 0, 2)
		else 
			player:GossipMenuAddItem(0, "VIP status: On", 0, 2)
		end
		player:GossipMenuAddItem(1, "VIP repair", 0, 12)
		player:GossipMenuAddItem(1, "VIP bank", 0, 13)
		player:GossipMenuAddItem(1, "VIP mail", 2, 14)
		player:GossipMenuAddItem(1, "VIP vendor", 0, 17)
		player:GossipMenuAddItem(1, "VIP auction house", 0, 18)
		player:GossipMenuAddItem(4, "Back", 0, 1)
        player:GossipSendMenu(1, creature, 60)
    elseif intId == 13 then
        player:SendShowBank(player)
    elseif intId == 14 then
        player:SendShowMailBox(player:GetGUID())
    elseif intId == 15 then
        player:SendTaxiMenu(creature)
    elseif intId == 16 then
        player:SendTrainerList(creature)
    elseif intId == 17 then
		
		local cooldownEnd = LoadVIPVendorCooldown(player)
		local remainingCooldown = cooldownEnd - os.time()
		
		if remainingCooldown > 0 then
			local hours = math.floor(remainingCooldown / 3600)
			local minutes = math.floor((remainingCooldown % 3600) / 60)
			local seconds = math.floor(remainingCooldown % 60)
			player:SendAreaTriggerMessage("Your VIP vendor is on cooldown for " .. minutes .. " minutes, and " .. seconds .. " seconds.")
		else

			cooldownEnd = os.time() + vendorCD
			
			local vendor = PerformIngameSpawn(1, vendorID, player:GetMapId(), player:GetInstanceId(), player:GetX(), player:GetY(), player:GetZ(), player:GetO(), false, VIPVendorDuration)
			CharDBExecute("REPLACE INTO character_cooldowns (guid, item_id, cooldown_end) VALUES (" .. player:GetGUIDLow() .. ", " .. 99999 .. ", " .. cooldownEnd .. ")")
		end
		
		if timeMessage then 
			player:GossipMenuAddItem(0, "VIP status: On (" .. timeMessage .. ")", 0, 2)
		else 
			player:GossipMenuAddItem(0, "VIP status: On", 0, 2)
		end
		player:GossipMenuAddItem(1, "VIP repair", 0, 12)
		player:GossipMenuAddItem(1, "VIP bank", 0, 13)
		player:GossipMenuAddItem(1, "VIP mail", 2, 14)
		player:GossipMenuAddItem(1, "VIP vendor", 0, 17)
		player:GossipMenuAddItem(1, "VIP auction house", 0, 18)
		player:GossipMenuAddItem(4, "Back", 0, 1)
        player:GossipSendMenu(1, creature, 60)
		
	elseif intId == 18 then
        player:SendAuctionMenu(creature)
    end
end

RegisterCreatureGossipEvent(23198, 1, OnGossipHello)
RegisterCreatureGossipEvent(23198, 2, OnGossipSelect)
print("[Custom]: Twiggy loaded!")

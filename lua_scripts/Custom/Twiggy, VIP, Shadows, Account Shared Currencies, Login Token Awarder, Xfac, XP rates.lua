-- Lazy cache sharing solution for most custom Yggdrasil features. Find the relevant function by indexing them from the event registration in the bottom and CTRL+F-ing your way to the functions

-- Shdows Configs Start
local BOT_TELE_VISUAL   = 64446
local BotSummonCD       = 30 * 60 -- 30 minutes
local minLevel          = 15
local dkLimit           = 70 -- Prevents DKs from zapping toons into the scarlet enclave area

local addCmdTimer       =   {}
local logoutEvent       =   {}
local isPlayerBot       =   {}
local botsAvailable     =   {}
local activeBots        =   {}
local botCount          =   {}
local botTeleTime       =   {}
local botMasters        =   {}
local botSummonTime     =   {}
local removalInProgress =   {}
local lastTeleTime      =   {}
local disallowedZones   =   {4298, 4197, 3628, 3666} -- Scarlet Enclave (DK start area), Wintergrasp, Halaa

-- Shadows Configs End

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
local VIPVendorDuration = 3 * 60 * 1000 -- VIP vendor lasts for 1 minute
local timeMessage = 0
local VIPtime = {}
-- End VIP vars

-- Twiggy Tables
local catCache, bearCache, birdCache, travelCache, owlCache, treeCache, aquaticCache = {}, {}, {}, {}, {}, {}, {}
local catCount, bearCount, birdCount, travelCount, owlCount, treeCount, aquaticCount = 0, 0, 0, 0, 0, 0, 0
local cacheChoice = {}
local intIdChoice = {}
local tickleCount = {}
local mailboxtime = {}

-- End Twiggy tables

-- ----------------------------------------------------------------------------------------------
-- ACCOUNTWIDE CURRENCY CONFIG 
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
-- Adapted to Yggdrasil WoW by mostly nick :)
-- ----------------------------------------------------------------------------------------------

local currencyItemIDs = {
    37742,  -- Activity Token 
    20880,  -- Vote Token 
    19322,  -- Community Token 
}

-- End account-shared currencies tables

-- Initiates VIP table if not already present
--CharDBExecute("CREATE TABLE IF NOT EXISTS ACCOUNTS_VIP (ACCOUNT INT(6) NOT NULL PRIMARY KEY, VIPTIME INT(11) NOT NULL);")

-- Prepares Twiggy in the database
--WorldDBExecute("UPDATE creature_template_model SET CreatureDisplayID = 13098, DisplayScale = 0.33 WHERE CreatureID = 23198;")
--WorldDBExecute("UPDATE creature_template SET name = 'Twiggy', npcflag = 2097153, scale = 0.23 WHERE entry = 23198;")
--WorldDBExecute("UPDATE item_template SET description = 'Teaches you how to summon Twiggy, your personal branch of Yggdrasil.', name = 'Twiggy''s Wooden Chip' WHERE entry = 32498;")

-- Prepares VIP trash vendor
--WorldDBExecute("UPDATE creature_template SET name = 'All-Buying Hobgoblin Repair' WHERE entry = 26309;")
--WorldDBExecute("UPDATE creature_template SET name = 'All-Buying Hobgoblin' WHERE entry = 26300;")

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

local function PopulateMorphCache()
    WorldDBQueryAsync([[
       SELECT entry, name 
       FROM creature_template 
       WHERE (family = 2 
          OR ((name LIKE '%panther%' 
          OR name LIKE '%gondria%' 
          OR name LIKE '%loque%') 
          AND type = 1))
          AND name NOT LIKE '%(%'
          AND name NOT LIKE '%"%'
          AND name NOT LIKE '%[%'
          AND name NOT LIKE '%UNUSED%'
          AND name NOT LIKE '%DESIGNER%'
          AND name NOT LIKE '%TEST%'
          AND name NOT LIKE '%STABLED%'
          AND name NOT LIKE '%TAMED%'
          AND name NOT LIKE '%TOTEM%'
    ]], function(catResults)
		if catResults then
			repeat
				local entry, name = catResults:GetUInt32(0), catResults:GetString(1)
				catCache[entry] = name
				catCount = catCount + 1
			until not catResults:NextRow()
		end
	end)

    WorldDBQueryAsync([[
       SELECT entry, name 
       FROM creature_template 
       WHERE (family = 4 
          OR name LIKE '%arcturis%' 
          OR name LIKE '%grizzly cub%')
          AND name NOT LIKE '%(%'
          AND name NOT LIKE '%"%'
          AND name NOT LIKE '%[%'
          AND name NOT LIKE '%UNUSED%'
          AND name NOT LIKE '%TEST%'
          AND name NOT LIKE '%STABLED%'
          AND name NOT LIKE '%TAMED%'
          AND name NOT LIKE '%TOTEM%'
    ]], function(bearResults)
		if bearResults then
			repeat
				local entry, name = bearResults:GetUInt32(0), bearResults:GetString(1)
				bearCache[entry] = name
				bearCount = bearCount + 1
			until not bearResults:NextRow()
		end
	end)

    WorldDBQueryAsync([[
       SELECT entry, name 
       FROM creature_template 
       WHERE (family IN (7, 26, 30, 33, 34, 37, 38) 
          OR ((name LIKE '%highperch%' 
          OR name LIKE '%wyvern%' 
          OR name LIKE '%heartrazor%') 
          AND type = 1))
          AND name NOT LIKE '%(%'
          AND name NOT LIKE '%"%'
          AND name NOT LIKE '%[%'
          AND name NOT LIKE '%UNUSED%'
          AND name NOT LIKE '%TEST%'
          AND name NOT LIKE '%STABLED%'
          AND name NOT LIKE '%TAMED%'
          AND name NOT LIKE '%TOTEM%'
    ]], function(birdResults)
		if birdResults then
			repeat
				local entry, name = birdResults:GetUInt32(0), birdResults:GetString(1)
				birdCache[entry] = name
				birdCount = birdCount + 1
			until not birdResults:NextRow()
		end
	end)
    
    WorldDBQueryAsync([[
       SELECT entry, name 
       FROM creature_template 
       WHERE (family IN (1, 11, 12, 39) 
          OR ((name LIKE '%riding wolf%' 
          OR name LIKE '%caribou%' 
          OR name LIKE '%fawn%' 
          OR name LIKE '%bach%' 
          OR name LIKE '%grazer%' 
          OR name LIKE '%giraffe%' 
          OR name LIKE '%gazelle%' 
          OR name LIKE '%zhevra%' 
          OR name LIKE '%snickerfang%' 
          OR name LIKE '%hyena%' 
          OR name LIKE '%mosshoof%' 
          OR name LIKE '%talbuk%' 
          OR name LIKE '%elk%' 
          OR name LIKE '%stag%' 
          OR name LIKE '%mammoth%' 
          OR name LIKE '%feathermoon%' 
          OR name LIKE '%hippogryph%' 
          OR name LIKE '%goat%' 
          OR name LIKE '%mustang%' 
          OR name LIKE '%buck%' 
          OR name LIKE '%ram%'
          OR name LIKE '%twilight serpent%') 
          AND type = 1))
          AND name NOT LIKE '%(%'
          AND name NOT LIKE '%"%'
          AND name NOT LIKE '%[%'
          AND name NOT LIKE '%UNUSED%'
          AND name NOT LIKE '%TEST%'
          AND name NOT LIKE '%STABLED%'
          AND name NOT LIKE '%TAMED%'
          AND name NOT LIKE '%TOTEM%'
    ]], function(travelResults)
		if travelResults then
			repeat
				local entry, name = travelResults:GetUInt32(0), travelResults:GetString(1)
				travelCache[entry] = name
				travelCount = travelCount + 1
			until not travelResults:NextRow()
		end
	end)
    
    WorldDBQueryAsync([[
       SELECT entry, name 
       FROM creature_template 
       WHERE (name LIKE '%owlkin%' 
          OR name LIKE '%wildkin%' 
          OR name LIKE '%owlbeast%' 
          OR name LIKE '%moonkin%')
          AND name NOT LIKE '%(%'
          AND name NOT LIKE '%"%'
          AND name NOT LIKE '%[%'
          AND name NOT LIKE '%UNUSED%'
          AND name NOT LIKE '%TEST%'
          AND name NOT LIKE '%STABLED%'
          AND name NOT LIKE '%TAMED%'
          AND name NOT LIKE '%TOTEM%'
    ]], function(owlResults)
		if owlResults then
			repeat
				local entry, name = owlResults:GetUInt32(0), owlResults:GetString(1)
				owlCache[entry] = name
				owlCount = owlCount + 1
			until not owlResults:NextRow()
		end
	end)
    
    WorldDBQueryAsync([[
       SELECT entry, name 
       FROM creature_template 
       WHERE (name LIKE '%root-walker%' 
          OR name LIKE '%treant%' 
          OR name LIKE '%withered green keeper%' 
          OR name LIKE '%Withered Ancient%' 
          OR name LIKE '%Wood Ent%' 
          OR name LIKE '%Unbound Ent%' 
          OR name LIKE '%Mangrove Ent%' 
          OR name LIKE '%Dispirited Ent%' 
          OR name LIKE '%sapling%' 
          OR name LIKE '%Darnassian Proector%' 
          OR name LIKE '%Crazed Ancient%' 
          OR name LIKE '%Crystalline Keeper%' 
          OR name LIKE '%Irontree%' 
          OR name LIKE '%Deeprot%' 
          OR name LIKE '%tender%')
          AND type = 4
          AND name NOT LIKE '%(%'
          AND name NOT LIKE '%"%'
          AND name NOT LIKE '%[%'
          AND name NOT LIKE '%UNUSED%'
          AND name NOT LIKE '%TEST%'
          AND name NOT LIKE '%STABLED%'
          AND name NOT LIKE '%TAMED%'
          AND name NOT LIKE '%TOTEM%'
    ]], function(treeResults)
		if treeResults then
			repeat
				local entry, name = treeResults:GetUInt32(0), treeResults:GetString(1)
				treeCache[entry] = name
				treeCount = treeCount + 1
			until not treeResults:NextRow()
		end
	end)
    
    WorldDBQueryAsync([[
       SELECT entry, name 
       FROM creature_template 
       WHERE (name LIKE '%sewer beast%' 
          OR name LIKE '%mako%' 
          OR name LIKE '%seal%' 
          OR name LIKE '%rippa%' 
          OR name LIKE '%orca%' 
          OR name LIKE '%lake frenzy%' 
          OR name LIKE '%sporewind frenzy%' 
          OR name LIKE '%underbog frenzy%' 
          OR name LIKE '%yellowgill frenzy%' 
          OR name LIKE '%reef frenzy%' 
          OR name LIKE '%canal frenzy%' 
          OR name LIKE '%muck frenzy%' 
          OR name LIKE '%coilfang frenzy%' 
          OR name LIKE '%sharptooth frenzy%' 
          OR name LIKE '%coastal frenzy%' 
          OR name LIKE '%drakkari frenzy%' 
          OR name LIKE '%loch frenzy%' 
          OR name LIKE '%hooktooth%' 
          OR name LIKE '%mudfin%' 
          OR name LIKE '%shark%' 
          OR name LIKE '%thresh%' 
          OR name LIKE '%eel%' 
          OR name LIKE '%hammerhead%' 
          OR name LIKE '%whitetail%' 
          OR name LIKE '%crocolisk%' 
          OR name LIKE '%sawfin%')
          AND type = 1
          AND name NOT LIKE '%(%'
          AND name NOT LIKE '%"%'
          AND name NOT LIKE '%[%'
          AND name NOT LIKE '%UNUSED%'
          AND name NOT LIKE '%TEST%'
          AND name NOT LIKE '%STABLED%'
          AND name NOT LIKE '%TAMED%'
          AND name NOT LIKE '%TOTEM%'
    ]], function(aquaticResults)
		if aquaticResults then
			repeat
				local entry, name = aquaticResults:GetUInt32(0), aquaticResults:GetString(1)
				aquaticCache[entry] = name
				aquaticCount = aquaticCount + 1
			until not aquaticResults:NextRow()
		end
	end)
end

local function ShowCategoryContents(player, creature, category, page)
    if page then print(page) end
    page = page or 1
    local itemsPerPage = 12
    local startIndex = (page - 1) * itemsPerPage + 1
    local endIndex = page * itemsPerPage
    player:GossipClearMenu()

    local cache = cacheChoice[player:GetGUIDLow()]

    -- Create a temporary table to hold the entries in a sortable format
    local tempTable = {}
    for entry, name in pairs(cache) do
        table.insert(tempTable, {entry = entry, name = name})
    end

    -- Sort the temporary table alphabetically by name
    table.sort(tempTable, function(a, b)
        return a.name < b.name
    end)

    local totalItems = #tempTable
    local itemCount = 0
    for _, entryData in ipairs(tempTable) do
        itemCount = itemCount + 1
        if itemCount >= startIndex and itemCount <= endIndex then
            local name = entryData.name
            if cache == catCache then
                player:GossipMenuAddItem(2, "|TInterface/ICONS/ability_druid_catform:32:32:-22:0|t" .. name, 0, 999)
            elseif cache == bearCache then
                player:GossipMenuAddItem(2, "|TInterface/ICONS/ability_racial_bearform:32:32:-22:0|t" .. name, 0, 999)
            elseif cache == travelCache then
                player:GossipMenuAddItem(2, "|TInterface/ICONS/ability_druid_travelform:32:32:-22:0|t" .. name, 0, 999)
            elseif cache == birdCache then
                player:GossipMenuAddItem(2, "|TInterface/ICONS/ability_druid_flightform:32:32:-22:0|t" .. name, 0, 999)
            elseif cache == treeCache then
                player:GossipMenuAddItem(2, "|TInterface/ICONS/ability_druid_treeoflife:32:32:-22:0|t" .. name, 0, 999)
            elseif cache == owlCache then
                player:GossipMenuAddItem(2, "|TInterface/ICONS/spell_nature_forceofnature:32:32:-22:0|t" .. name, 0, 999)
            elseif cache == aquaticCache then
                player:GossipMenuAddItem(2, "|TInterface/ICONS/ability_druid_aquaticform:32:32:-22:0|t" .. name, 0, 999)
            end
        end
        if itemCount >= endIndex then
            break
        end
    end

    -- Add pagination buttons
    if page > 1 then
        player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_map_01:32:32:-22:0|tPrevious Page", 0, 997)
    end
    if endIndex < totalItems then
        player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_map_01:32:32:-22:0|tNext Page", 0, 998)
    end

    player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 500)
    player:GossipSendMenu(12, creature, 60)

    -- Store the current category and page in the player's temporary storage
    player:SetData("CurrentCategory", category)
    player:SetData("CurrentPage", page)
end

local function VIPmenu(player, creature)
	if VIPtime[player:GetGUIDLow()] > os.time() then
		local vipTime = VIPtime[player:GetGUIDLow()]
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
		player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_holy_borrowedtime:32:32:-22:0|tVIP status: On (" .. timeMessage .. ")", 0, 2)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_blacksmithing:32:32:-22:0|tVIP repair", 0, 12)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/Inv_misc_coin_01:32:32:-22:0|tVIP bank", 0, 13)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/Inv_letter_01:32:32:-22:0|tVIP mail", 2, 14)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/Inv_misc_bag_07:32:32:-22:0|tVIP vendor", 0, 17)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/Racial_dwarf_findtreasure:32:32:-22:0|tVIP auction house", 0, 18)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_fire_burningspeed:32:32:-22:0|tVIP XP change", 0, 24)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 1)
	else 
		player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_holy_borrowedtime:32:32:-22:0|tVIP status: Off. Activate VIP?", 0, 20)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-22:0|tWhy should I get VIP?", 0, 19)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 1)
		print("No VIPTIME found for account " .. player:GetAccountId())
	end
	player:GossipSendMenu(12, creature, 60)
end

local function mainMenu(player, creature)
	if not VIPtime[player:GetGUIDLow()] then
		local name = player:GetName()
		CharDBQueryAsync("SELECT VIPTIME FROM ACCOUNTS_VIP WHERE ACCOUNT = " .. player:GetAccountId() .. ";", function(result)
			player = GetPlayerByName(name)
			if result then
				VIPtime[player:GetGUIDLow()] = result:GetUInt32(0)
			else
				VIPtime[player:GetGUIDLow()] = os.time()
			end
		end)
	end
    player:GossipMenuAddItem(4, "|TInterface/ICONS/ABILITY_DRUID_MANATREE:32:32:-22:0|tI'm Twiggy, your own branch of\n         Yggdrasil! How can I help you?\n ", 0, 1)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tVIP options", 0, 2)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_groupneedmore:32:32:-22:0|tRAF menu", 0, 6)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/INV_Misc_Coin_16:32:32:-22:0|tSee my currencies", 0, 3)
    if player:HasItem(20739) then
        player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_feather_13:32:32:-22:0|tManage Feathers of Azeroth", 0, 7)
	end
    if (player:GetClass() == 6 and player:GetLevel() >= dkLimit)
    or (player:GetClass() ~= 6 and player:GetLevel() >= minLevel)
    and (player:GetQuestStatus(30000) == 6)
    then
        player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_holy_prayerofshadowprotection:32:32:-22:0|tManage Shadows", 0, 8)
	end
    player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_gem_diamond_07:32:32:-22:0|tExplore Yggdrasil's features", 0, 5)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_arcane_teleportdarnassus:32:32:-22:0|tTeleport to mall", 0, 4)
    player:GossipSendMenu(12, creature, 60)
end

local function TwiggyGossipHello(event, player, creature)
	if creature:GetOwnerGUID() == player:GetGUID() then
		mainMenu(player, creature)
	else
		-- If it's someone else's companion, don't start gossip
		if not tickleCount[player:GetGUIDLow()] then
			tickleCount[player:GetGUIDLow()] = 0
		end
		
		if not tickleCount[player:GetGUIDLow()] or tickleCount[player:GetGUIDLow()] == 0 then
			creature:SendUnitWhisper("My roots have other matters to attend to. Try asking your own Twiggy.", 0, player)
			tickleCount[player:GetGUIDLow()] = tickleCount[player:GetGUIDLow()] + 1
			
			player:RegisterEvent(function(eventId, delay, repeats, player)
				tickleCount[player:GetGUIDLow()] = 0
				player:RemoveEventById(eventId)
			end, 15000, 1)
			
		elseif tickleCount[player:GetGUIDLow()] == 8 then
			
			local moveTimer = 0
			local moveInterval = 2 -- Move every 2 seconds
			local owner = creature:GetOwner()
			local startX, startY, startZ = creature:GetLocation()
			
			creature:SendUnitYell("Help! "..player:GetName().." is tickling my stump, someone ask them to stop!", 0)
			
			creature:MoveTo(1, startX + math.random(-5, 5), startY + math.random(-5, 5), startZ)
			
			tickleCount[player:GetGUIDLow()] = tickleCount[player:GetGUIDLow()] + 1

			creature:RegisterEvent(function(eventId, delay, repeats, creature)
				if creature then
					moveTimer = moveTimer + 1
					local owner = creature:GetOwner()

					if moveTimer % moveInterval == 0 then
						creature:MoveTo(1, startX + math.random(-5, 5), startY + math.random(-5, 5), startZ)
					end

					if moveTimer == 14 then
						creature:SendUnitYell("I need an adult!", 0)
					end

					if moveTimer >= 20 then
						creature:SendUnitSay("Please don't let that happen to me again, "..owner:GetName().."!", 0)
						creature:MoveFollow(owner, 1, 1.3)
						creature:RemoveEvents()
					end
				end
			end, 800, 20) -- Run every 1 second for 10 seconds
			
		else
			tickleCount[player:GetGUIDLow()] = tickleCount[player:GetGUIDLow()] + 1
			player:RegisterEvent(function(eventId, delay, repeats, player)
				tickleCount[player:GetGUIDLow()] = 0
				player:RemoveEventById(eventId)
			end, 15000, 1)
		end
		return
	end
end

local function TwiggyGossipSelect(event, player, creature, sender, intId, code)
	intIdChoice[player:GetGUIDLow()] = intId
    if intId == 1 then
		mainMenu(player, creature)
	elseif intId == 24 then
		player:RunCommand("xpchangemenu "..os.time())
	elseif intId == 8 then
		player:RunCommand("shadowsmenu")
	elseif intId == 7 then
		player:RunCommand("choosestandardfeathers")
	elseif intId == 6 then
		player:RunCommand("rafmenu")
	elseif intId == 5 then
		player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_fire_burningspeed:32:32:-22:0|tRates", 0, 49)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_helmet_89:32:32:-22:0|tTransmog and morph services", 0, 50)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/achievement_character_nightelf_female:32:32:-22:0|tCharacter services", 0, 51)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_hunter_beastcall:32:32:-22:0|tPets", 0, 52)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/Ability_Mount_RidingHorse:32:32:-22:0|tMounts and companions", 0, 56)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_coin_02:32:32:-22:0|tEconomy", 0, 53)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/achievement_zone_easternkingdoms_01:32:32:-22:0|tAzeroth flight", 0, 54)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_arcane_teleportdarnassus:32:32:-22:0|tMall information", 0, 55)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 1)
        player:GossipSendMenu(12, creature, 60)
	elseif intId == 49 then
		player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_fire_burningspeed:32:32:-22:0|tRates information:\n ", 0, 49)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/achievement_pvp_a_03:32:32:-22:0|tXP rates: \n \nFlexible between 1x and 10x. \nThe higher tiers cost Vote Tokens. \nVisit a Time-Warper at any starter zone, Orgrimmar or Stormwind to adjust your XP rate.\n ", 0, 49)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_coin_02:32:32:-22:0|tGold rates: 2x\n ", 0, 49)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/achievement_reputation_08:32:32:-22:0|tReputation rates: 2x\n ", 0, 49)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 5)
        player:GossipSendMenu(12, creature, 60)
	elseif intId == 55 then
		player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_arcane_teleportdarnassus:32:32:-22:0|tMall information:\n ", 0, 55)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/achievement_level_10:32:32:-22:0|tGeneral information: \n \n-Required level: 10 \n-Accessible from PvP areas: No.\n-Accessible in combat: No.\n-Mall teleport cooldown: 60 min\n ", 0, 55)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_gizmo_02:32:32:-22:0|tQuality of Life features: \n \n-Portals to all capitals \n-Training dummies\n-Profession trainers\n-Crafting corner\n ", 0, 55)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_helmet_89:32:32:-22:0|tVendor information: \n \n-Transmogrifyer\n-Transmog item vendor\n-Druid morph vendor\n-Demon pet morph vendor\n-Pet renamer\n-Hunter pet vendor\n-Feathers of Azeroth vendor\n-Vanity pets vendor\n-Currency Exchanger\n-Character services\n-Hierlooms\n-Flight paths vendor\n-And more!\n ", 0, 55)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 5)
        player:GossipSendMenu(12, creature, 60)
	elseif intId == 54 then
		player:GossipMenuAddItem(4, "|TInterface/ICONS/achievement_zone_easternkingdoms_01:32:32:-22:0|tAzeroth flight features:\n ", 0, 54)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_feather_13:32:32:-22:0|tThe Feathers of Azeroth: \n \nTo fly in Kalimdor and Eastern Kingdoms, you must buy the Feathers of Azeroth from the bird breeder at the Mall for 50 gold, given that you are already able to fly.\n ", 0, 54)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_flower_02:32:32:-22:0|tUse any mount: \n \nThe Feathers can wrap any mount of your choice in the Feathers of Azeroth, permitting its flight in old world areas.\n ", 0, 54)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/Spell_magic_featherfall:32:32:-22:0|tSupports shapeshifts: \n \nAll flying mounts and shapeshifts that can fly in all of Outland and Northrend, including Druid shapeshifts, can be wrapped in the Feathers of Azeroth. \n ", 0, 54)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 5)
        player:GossipSendMenu(12, creature, 60)
	elseif intId == 56 then
		player:GossipMenuAddItem(4, "|TInterface/ICONS/Ability_Mount_RidingHorse:32:32:-22:0|tMount and companion features:\n ", 0, 53)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_mount_gyrocoptor:32:32:-22:0|tAccount-shared: \n \nAll mounts are automatically synchronized across your eligible characters. All companions are account-bound and can be sent to your other characters.\n ", 0, 53)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_pet_babyblizzardbear:32:32:-22:0|tCompanion Carrier: \n \nAt the mall, the Companion Carrier breeds companions for players to purchase for 50 Vote Tokens or 5 Community Tokens each.\n ", 0, 52)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 5)
        player:GossipSendMenu(12, creature, 60)
	elseif intId == 53 then
		player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_coin_02:32:32:-22:0|tEconomy services:\n ", 0, 53)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/Inv_misc_bag_07:32:32:-22:0|tAuction house features: \n \nCross faction: Both factions can trade on the same auction house.\n \nAuction house bot: Pbtwelve, our beloved auction house bot, works tirelessly to keep the supply high.\n \nReduced auction cut: The auction house charges an 80% reduced cut on posting auctions.\n ", 0, 53)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_frostemblem_01:32:32:-22:0|tTertiary currency exchanger: \n \nAt the Mall, the Exchanger offers currency exchange services for Vote Tokens and can trade them for Emblems of Triumph (1:1), Emblems of Frost (5:1), or Activity Tokens (15:1).\n ", 0, 53)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 5)
        player:GossipSendMenu(12, creature, 60)
	elseif intId == 52 then
		player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_nature_groundingtotem:32:32:-22:0|t Available pet services at the Mall:\n ", 0, 52)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_scroll_11:32:32:-22:0|tRename demons: \n \nFor the mere price of 30 Vote Tokens or 3 Community Tokens, you can pick any morphologically correct Demonic name for your demons.\n ", 0, 52)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_shadow_demonictactics:32:32:-22:0|tDemon morphs: \n \nFor 50 Vote Tokens or 5 Community Tokens, Warlocks can purchase an item transcending the boundary between Azeroth and the demonic realms. This item lets you capture the forms of other demons and apply them onto your own demon pet of the same category as the claimed demon form.\n ", 0, 52)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_tracking:32:32:-22:0|tHunter pet beastmaster: \n \nFor 100 Vote Tokens or 10 Community Tokens, you can purchase virtually any hunter pet you want.\n ", 0, 52)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 5)
        player:GossipSendMenu(12, creature, 60)
	elseif intId == 51 then
		player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_nature_groundingtotem:32:32:-22:0|t Available customizations at the Mall:\n ", 0, 51)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_scroll_11:32:32:-22:0|tRename: \n \nFor the mere price of 50 Vote Tokens or 5 Community Tokens, you can select any name you want.\n ", 0, 51)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_throwingknife_02:32:32:-22:0|tCustomize: \n \nFor 50 Vote Tokens or 5 Community Tokens, you can get your character a makeover.\n ", 0, 51)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/achievement_pvp_a_h:32:32:-22:0|tChange faction: \n \nFor 100 Vote Tokens or 10 Community Tokens, you can change your faction.\n ", 0, 51)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/achievement_character_orc_male:32:32:-22:0|tChange race: \n \nFor 150 Vote Tokens or 15 Community Tokens, you can reroll your race to any other race compatible with your class.\n ", 0, 51)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 5)
        player:GossipSendMenu(12, creature, 60)
	elseif intId == 50 then
		player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_druid_travelform:32:32:-22:0|tDruid shapeshifts: \n \nThrough harnessing the powers of ancient Kaldorei magic, druids can learn the form of many unique beasts to apply them onto their own beastial forms. Note: Some creatures share the same creature model. Each model can only be claimed once.\n \nClick here for a full list of applicable creatures. \n ", 0, 500)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_helmet_89:32:32:-22:0|tTransmogrifyer: \n \nYggdrasil sports a transmogrifyer from the Cataclysm era, where you can apply the look of one item onto others by having both items in your bags and paying a transmogrifyer to apply the new look. Transmogrifyers are at the mall and all capital cities' enchanting trainers.\n ", 0, 50)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_bag_07_red:32:32:-22:0|tTransmog Item Vendor: \n \nThis mall vendor can search for almost any item in the world under item level 200 and sell it to you for Activity Tokens.\n ", 0, 50)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/Inv_misc_coin_07:32:32:-22:0|tActivity Tokens: \n \nBy completing quests while at level 80 and killing raid/dungeon bosses while the player is at level 80 and the boss is level 71 or higher, you earn Activity Tokens. These can be used to buy items at the Transmog Item Vendor.\n ", 0, 50)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 5)
        player:GossipSendMenu(12, creature, 60)
	elseif intId == 500 then
		player:GossipMenuAddItem(4, "|TInterface/ICONS/ABILITY_Druid_CatForm:32:32:-22:0|tCat Forms: " .. catCount, 0, 501)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_racial_bearform:32:32:-22:0|tBear Forms: " .. bearCount, 0, 502)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/ABILITY_Druid_FlightForm:32:32:-22:0|tFlight Forms: " .. birdCount, 0, 503)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/ABILITY_Druid_TravelForm:32:32:-22:0|tTravel Forms: " .. travelCount, 0, 504)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_druid_improvedmoonkinform:32:32:-22:0|tMoonkin Form: " .. owlCount, 0, 505)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_druid_treeoflife:32:32:-22:0|tTree Form: " .. treeCount, 0, 506)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/ABILITY_Druid_AquaticForm:32:32:-22:0|tAquatic Forms: " .. aquaticCount, 0, 507)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 50)
		player:GossipSendMenu(12, creature, 60)
	elseif intId == 998 or intId == 997 then
		local currentCategory = player:GetData("CurrentCategory")
		local currentPage = player:GetData("CurrentPage")
		local newPage = intId == 998 and currentPage + 1 or currentPage - 1
		ShowCategoryContents(player, creature, currentCategory, newPage)
	elseif intId == 999 then
		local currentCategory = player:GetData("CurrentCategory")
		local currentPage = player:GetData("CurrentPage")
		local newPage = intId == 999 and currentPage
		ShowCategoryContents(player, creature, currentCategory, newPage)
	elseif intId == 501 then
		cacheChoice[player:GetGUIDLow()] = catCache
		ShowCategoryContents(player, creature, "Cat Forms", 1)
	elseif intId == 502 then
		cacheChoice[player:GetGUIDLow()] = bearCache
		ShowCategoryContents(player, creature, "Bear Forms", 1)
	elseif intId == 503 then
		cacheChoice[player:GetGUIDLow()] = birdCache
		ShowCategoryContents(player, creature, "Flight Forms", 1)
	elseif intId == 504 then
		cacheChoice[player:GetGUIDLow()] = travelCache
		ShowCategoryContents(player, creature, "Travel Forms", 1)
	elseif intId == 505 then
		cacheChoice[player:GetGUIDLow()] = owlCache
		ShowCategoryContents(player, creature, "Moonkin Forms", 1)
	elseif intId == 506 then
		cacheChoice[player:GetGUIDLow()] = treeCache
		ShowCategoryContents(player, creature, "Tree Forms", 1)
	elseif intId == 507 then
		cacheChoice[player:GetGUIDLow()] = aquaticCache
		ShowCategoryContents(player, creature, "Aquatic Forms", 1)
	elseif intId == 2 then
		VIPmenu(player, creature)
	elseif intId == 19 then
		player:GossipMenuAddItem(4, "|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-22:0|tWhy should I get VIP?\n \nAs VIP, Twiggy can provide you with free repairs, free XP rate changes on all your characters, banking, mailing, the auction house, and a vendor to sell your accumulated items anywhere you are.\n ",  0, 19)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 2)
        player:GossipSendMenu(12, creature, 60)
	elseif intId == 20 then
        player:GossipMenuAddItem(4, "|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-22:0|tFor how long do you want VIP?", 0, 20)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_rune_07:32:32:-22:0|t7 days (7 Community Tokens)", 0, 21)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_rune_07:32:32:-22:0|t14 days (12 Community Tokens)", 0, 22)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_rune_07:32:32:-22:0|t21 days (15 Community Tokens)", 0, 23)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 2)
        player:GossipSendMenu(12, creature, 60)
	elseif intId == 21 then
		if player:HasItem(19322,7) then
			player:RemoveItem(19322,7)
			VIPtime[player:GetGUIDLow()] = (os.time() + 7 * 24 * 60 * 60)
			
			CharDBExecute("INSERT INTO ACCOUNTS_VIP (ACCOUNT, VIPTIME) VALUES (" .. player:GetAccountId() .. ", " .. (os.time() + 7 * 24 * 60 * 60) .. ") ON DUPLICATE KEY UPDATE VIPTIME = VALUES(VIPTIME);")

			VIPmenu(player, creature)
		else 
			player:SendAreaTriggerMessage("You don't have enough Community Tokens.")
            mainMenu(player, creature)
		end
	elseif intId == 22 then
		if player:HasItem(19322,12) then
			player:RemoveItem(19322,12)
			VIPtime[player:GetGUIDLow()] = (os.time() + 14 * 24 * 60 * 60)
			
			CharDBExecute("INSERT INTO ACCOUNTS_VIP (ACCOUNT, VIPTIME) VALUES (" .. player:GetAccountId() .. ", " .. (os.time() + 14 * 24 * 60 * 60) .. ") ON DUPLICATE KEY UPDATE VIPTIME = VALUES(VIPTIME);")

			VIPmenu(player, creature)
		else 
			player:SendAreaTriggerMessage("You don't have enough Community Tokens.")
            mainMenu(player, creature)
		end
	elseif intId == 23 then
		if player:HasItem(19322,15) then
			player:RemoveItem(19322,15)
			VIPtime[player:GetGUIDLow()] = (os.time() + 21 * 24 * 60 * 60)
			
			CharDBExecute("INSERT INTO ACCOUNTS_VIP (ACCOUNT, VIPTIME) VALUES (" .. player:GetAccountId() .. ", " .. (os.time() + 21 * 24 * 60 * 60) .. ") ON DUPLICATE KEY UPDATE VIPTIME = VALUES(VIPTIME);")
			
			VIPmenu(player, creature)
		else 
			player:SendAreaTriggerMessage("You don't have enough Community Tokens.")
            mainMenu(player, creature)
		end
		
    elseif intId == 3 then
        player:GossipMenuAddItem(4, "|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-22:0|tWhat can I use my currencies for?", 0, 30)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_rune_07:32:32:-22:0|tCommunity Tokens: "..player:GetItemCount(19322), 0, 3)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Inv_misc_coin_07:32:32:-22:0|tActivity Tokens: "..player:GetItemCount(37742), 0, 3)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Inv_bijou_gold:32:32:-22:0|tVote Tokens: "..player:GetItemCount(20880), 0, 3)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 1)
        player:GossipSendMenu(12, creature, 60)
	elseif intId == 30 then
        player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_rune_07:32:32:-22:0|tCommunity Token: \n \nEarned through helping build the Yggdrasil community, these tokens can be traded for vanity pets, mounts, account services and more at the mall, or VIP services with Twiggy.\n \n ", 0, 30)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Inv_misc_coin_07:32:32:-22:0|tActivity Token: \n \nThis currency can be spent at the transmog item vendor to buy items under item level 200 that you can then later wear as gear or transmog onto your higher item level gear. It is earned by completing end-game quests or slaying bosses above level 71 while at level 80.\n \n ", 0, 30)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Inv_bijou_gold:32:32:-22:0|tVote Token: \n \nEarned through voting for the server, these tokens can be predominantly exchanged for vanity items at the mall, or traded down to Emblems of Frost or Emblems of Triumph at the Mall's exchanger.\n \n ", 0, 30)	
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 3)
        player:GossipSendMenu(12, creature, 60)
    elseif intId == 4 then
	   if player:IsInCombat() then
			player:SendAreaTriggerMessage("You can't teleport to the mall in combat.")
			mainMenu(player, creature)
		elseif player:GetBattlegroundId() ~= 0 then
			player:SendAreaTriggerMessage("You can't teleport to the mall in a battleground.")
			mainMenu(player, creature)
		elseif player:GetLevel() <= 9 then
			player:SendAreaTriggerMessage("You have to be at least level 10 to teleport to the mall.")
			mainMenu(player, creature)
		else
		
			local currentTime = os.time()
			local cooldownEnd = LoadCooldown(player)
			local remainingCooldown = cooldownEnd - currentTime

			if remainingCooldown > 0 then
				local hours = math.floor(remainingCooldown / 3600)
				local minutes = math.floor((remainingCooldown % 3600) / 60)
				local seconds = math.floor(remainingCooldown % 60)
				player:SendAreaTriggerMessage("Your mall teleport is on cooldown for " .. minutes .. " minutes and " .. seconds .. " seconds.")
				mainMenu(player, creature)
			else
				cooldownEnd = currentTime + COOLDOWN
				CharDBExecute("REPLACE INTO character_cooldowns (guid, item_id, cooldown_end) VALUES (" .. player:GetGUIDLow() .. ", " .. 37430 .. ", " .. cooldownEnd .. ")")
				player:Teleport(MAP_ID, X, Y, Z, ORIENTATION)
				return true
			end
		end
    elseif intId == 12 then
		player:DurabilityRepairAll(false)
        player:SendBroadcastMessage("You have repaired your items.")
		VIPmenu(player, creature)
    elseif intId == 13 then
        player:SendShowBank(player)
    elseif intId == 14 then
		player:GossipComplete()
		local guid = player:GetGUIDLow()
		local currentTime = os.time()

		if not mailboxtime[guid] then 
			mailboxtime[guid] = 0
		end
		
		if mailboxtime[guid] <= currentTime then
			player:CastSpell(player, 54710, true)
			mailboxtime[guid] = currentTime + 900
		else
			local remainingTime = mailboxtime[guid] - currentTime
			local minutes = math.floor(remainingTime / 60)
			local seconds = remainingTime % 60
			
			player:SendAreaTriggerMessage(string.format("Your VIP mailbox is on cooldown for %d minutes and %d seconds.", minutes, seconds))
		end
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
			player:SendAreaTriggerMessage("Your VIP vendor is on cooldown for " .. minutes .. " minutes and " .. seconds .. " seconds.")
		else

			cooldownEnd = os.time() + vendorCD
			
			local vendor = PerformIngameSpawn(1, vendorID, player:GetMapId(), player:GetInstanceId(), player:GetX(), player:GetY()+2, player:GetZ(), player:GetO()-1.8, false, VIPVendorDuration)
			vendor:PerformEmote(3)
			vendor:SetRooted(true)
			vendor:MoveFollow(player, 2)
			vendor:SendUnitSay("Ah, another potential treasure arrives! Let's see what you've brought, "..player:GetName().."!",0)
			
			vendor:RegisterEvent(function(eventId, delay, repeats, creature)
				creature:SetRooted(false)
			end, 5000, 1)
			
			vendor:RegisterEvent(function(eventId, delay, repeats, creature)
				creature:SetRooted(true)
				creature:PerformEmote(3)
				creature:SendUnitSay("Until next time, when your trash is truly treasure.",0)
			end, VIPVendorDuration-3000, 1)
			
			CharDBExecute("REPLACE INTO character_cooldowns (guid, item_id, cooldown_end) VALUES (" .. player:GetGUIDLow() .. ", " .. 99999 .. ", " .. cooldownEnd .. ")")
		end
		
		VIPmenu(player, creature)	
		
	elseif intId == 18 then
        player:SendAuctionMenu(creature)
    end
end

local function OnPlayerLogin(event, player)
    if player:HasItem(32498) or player:HasSpell(40405) then
		if player:HasItem(37430) then
			player:RemoveItem(37430, 1)
			player:SendBroadcastMessage("Twiggy has removed your mall stone to provide this service for you.", 0)
		end
        return
    else
        player:AddItem(32498, 1)
    end
end

-- Twiggy and VIP script end

-- Shadows Script Start

function GetClassName(classId)
    local classNames = {
        [1] = "Warrior",
        [2] = "Paladin",
        [3] = "Hunter",
        [4] = "Rogue",
        [5] = "Priest",
        [6] = "Death Knight",
        [7] = "Shaman",
        [8] = "Mage",
        [9] = "Warlock",
        [11] = "Druid"
    }
    return classNames[classId] or "Unknown"
end

function GetRaceName(raceId)
    local raceNames = {
        [1] = "Human",
        [2] = "Orc",
        [3] = "Dwarf",
        [4] = "Night Elf",
        [5] = "Undead",
        [6] = "Tauren",
        [7] = "Gnome",
        [8] = "Troll",
        [10] = "Blood Elf",
        [11] = "Draenei"
    }
    return raceNames[raceId] or "Unknown"
end

function GetClassIconPath(classId)
    local classIcons = {
        [1] = "Ability_Warrior_SavageBlow",      -- Warrior
        [2] = "Spell_Holy_HolyBolt",             -- Paladin
        [3] = "INV_Weapon_Bow_07",               -- Hunter
        [4] = "Ability_Stealth",                 -- Rogue
        [5] = "Spell_Holy_PowerWordShield",      -- Priest
        [6] = "Spell_Deathknight_ClassIcon",     -- Death Knight
        [7] = "Spell_Nature_BloodLust",          -- Shaman
        [8] = "Spell_Holy_MagicalSentry",        -- Mage
        [9] = "Spell_Shadow_CurseOfTounges",     -- Warlock
        [11] = "Spell_Nature_Regeneration"       -- Druid
    }
    return classIcons[classId] or "INV_Misc_QuestionMark"
end

function GetRaceIconPath(raceId, gender)
    local raceIcons = {
        [1] = {
            [0] = "achievement_character_human_male",
            [1] = "achievement_character_human_female"
        },
        [2] = {
            [0] = "achievement_character_orc_male",
            [1] = "achievement_character_orc_female"
        },
        [3] = {
            [0] = "achievement_character_dwarf_male",
            [1] = "inv_misc_head_dwarf_02"
        },
        [4] = {
            [0] = "achievement_character_nightelf_male",
            [1] = "achievement_character_nightelf_female"
        },
        [5] = {
            [0] = "inv_misc_head_undead_01",
            [1] = "inv_misc_head_undead_02"
        },
        [6] = {
            [0] = "achievement_character_tauren_male",
            [1] = "achievement_character_tauren_female"
        },
        [7] = {
            [0] = "inv_misc_head_gnome_01",
            [1] = "inv_misc_head_gnome_02"
        },
        [8] = {
            [0] = "achievement_character_troll_male",
            [1] = "achievement_character_troll_female"
        },
        [10] = {
            [0] = "achievement_character_bloodelf_male",
            [1] = "achievement_character_bloodelf_female"
        },
        [11] = {
            [0] = "achievement_character_draenei_male",
            [1] = "achievement_character_draenei_female"
        }
    }
    
    if raceIcons[raceId] and raceIcons[raceId][gender] then
        return raceIcons[raceId][gender]
    end
    return "INV_Misc_QuestionMark"
end

local commandCategories = {
   movement = {
       name = "Movement",
       intid = 20,
       commands = {
           {cmd = "follow", name = "Follow", desc = "Your shadows will follow the player. Say 'follow' in group chat or whisper to instruct shadow."},
           {cmd = "flee", name = "Flee", desc = "Your shadows will try to move away from their target while in combat. Say 'flee' in group chat or whisper to instruct shadow."},
           {cmd = "runaway", name = "Run Away", desc = "Your shadows will try to kite their currently aggroed mobs by whispering or saying 'runaway' in group chat."},
           {cmd = "@tank flee", name = "Tank Flee", desc = "Your shadows will command the tank to flee from combat. Say '@tank flee' in group chat or whisper to instruct shadow."},
           {cmd = "@dps flee", name = "DPS Flee", desc = "Your shadows will command the DPS to flee from combat. Say '@dps flee' in group chat or whisper to instruct shadow."},
           {cmd = "@heal flee", name = "Healer Flee", desc = "Your shadows will command the healer to flee from combat. Say '@heal flee' in group chat or whisper to instruct shadow."},
           {cmd = "@melee flee", name = "Melee Flee", desc = "Your shadows will command melee players to flee from combat. Say '@melee flee' in group chat or whisper to instruct shadow."},
           {cmd = "@ranged flee", name = "Ranged Flee", desc = "Your shadows will command ranged players to flee from combat. Say '@ranged flee' in group chat or whisper to instruct shadow."},
           {cmd = "stay", name = "Stay", desc = "Your shadows will stay in its current position. Say 'stay' in group chat or whisper to instruct shadow."},
           {cmd = "reset botAI", name = "Reset botAI", desc = "Say 'reset botAI' (case sensitive) in group chat or whispers to a shadow to reset its current settings."},
       }
   },
   combat = {
       name = "Combat",
       intid = 21,
       commands = {
           {cmd = "attack", name = "Attack", desc = "Your shadows will engage and attack the target. Say 'attack' in group chat or whisper to instruct shadow."},
           {cmd = "@tank attack", name = "Tank Attack", desc = "Your shadows will command the tank to attack the target. Say '@tank attack' in group chat or whisper to instruct shadow."},
           {cmd = "@dps attack", name = "DPS Attack", desc = "Your shadows will command the DPS to attack the target. Say '@dps attack' in group chat or whisper to instruct shadow."},
           {cmd = "@heal attack", name = "Healer Attack", desc = "Your shadows will command the healer to attack the target. Say '@heal attack' in group chat or whisper to instruct shadow."},
           {cmd = "@melee attack", name = "Melee Attack", desc = "Your shadows will command melee players to attack the target. Say '@melee attack' in group chat or whisper to instruct shadow."},
           {cmd = "@ranged attack", name = "Ranged Attack", desc = "Your shadows will command ranged players to attack the target. Say '@ranged attack' in group chat or whisper to instruct shadow."},
           {cmd = "grind", name = "Grind", desc = "Make all shadows automatically attack nearby creatures that yield experience points. Say 'grind' in group chat to activate grind mode."},
           {cmd = "reset botAI", name = "Reset botAI", desc = "Say 'reset botAI' (case sensitive) in group chat or whispers to a shadow to reset its current settings."},
       }
   },
   formation = {
       name = "Formation",
       intid = 22,
       commands = {
           {cmd = "formation arrow", name = "Arrow Formation", desc = "Your shadows will arrange itself in an arrow formation. Say 'formation arrow' in group chat or whisper to instruct shadow."},
           {cmd = "formation queue", name = "Queue Formation", desc = "Your shadows will arrange itself in a queue formation. Say 'formation queue' in group chat or whisper to instruct shadow."},
           {cmd = "formation near", name = "Near Formation", desc = "Your shadows will arrange itself in a close formation. Say 'formation near' in group chat or whisper to instruct shadow."},
           {cmd = "formation melee", name = "Melee Formation", desc = "Your shadows will arrange itself in a melee formation. Say 'formation melee' in group chat or whisper to instruct shadow."},
           {cmd = "formation line", name = "Line Formation", desc = "Your shadows will arrange itself in a line formation. Say 'formation line' in group chat or whisper to instruct shadow."},
           {cmd = "formation circle", name = "Circle Formation", desc = "Your shadows will arrange itself in a circular formation. Say 'formation circle' in group chat or whisper to instruct shadow."},
           {cmd = "formation chaos", name = "Chaos Formation", desc = "Your shadows will arrange itself in a chaotic formation. Say 'formation chaos' in group chat or whisper to instruct shadow."},
           {cmd = "formation shield", name = "Shield Formation", desc = "Your shadows will arrange itself in a shield formation. Say 'formation shield' in group chat or whisper to instruct shadow."},
           {cmd = "formation", name = "Default Formation", desc = "Your shadows will revert to its default formation. Say 'formation' in group chat or whisper to instruct shadow."},
           {cmd = "reset botAI", name = "Reset botAI", desc = "Say 'reset botAI' (case sensitive) in group chat or whispers to a shadow to reset its settings."},
       }
   },
   worldinteraction = {
       name = "World Interaction", 
       intid = 23,
       commands = {
           {cmd = "repair", name = "Repair", desc = "Your shadows will repair at a nearby eligible vendor if you say 'repair' in group chat or whispers."},
           {cmd = "talk", name = "Talk", desc = "By saying 'talk' in group chat or whispers to a shadow, your shadows will talk to your current target. This can be used to hand in quests or learn flight paths, for example."},
           {cmd = "trainer learn", name = "Learn Skills", desc = "Your shadows will learn applicable skills from the trainer you are currently talking to. Say 'trainer learn' in group chat or whisper to instruct shadow."},
           {cmd = "release", name = "Release Spirit", desc = "Your shadows will release its spirit upon death. Say 'release' in group chat or whisper to instruct shadow."},
           {cmd = "quests", name = "View Quests", desc = "Your shadows will display available quests. Say 'quests' in group chat or whisper to instruct shadow."},
           {cmd = "stats", name = "View Stats", desc = "Your shadows will display current stats. Say 'stats' in group chat or whisper to instruct shadow."},
           {cmd = "add all loot", name = "Loot All", desc = "Your shadows will loot all items from defeated enemies. Say 'add all loot' in group chat or whisper to instruct shadow."},
           {cmd = "reset botAI", name = "Reset botAI", desc = "Say 'reset botAI' (case sensitive) in group chat or whispers to a shadow to reset its settings."},
        }
   },
   spell = {
       name = "Spells", 
       intid = 24,
       commands = {
           {cmd = "cast <spell>", name = "cast <spell name>", desc = "You may instruct your shadows to cast specific spells in their spell book by saying 'cast <spell name>'.\n \nFor example, if you want your Death Knight shadow to change presence, say 'cast Blood Presence' in group chat or whisper.\n \nThis is also how one can assign paladin and other class buffs.\n \n"},
       }
   },
   playerinteraction = {
       name = "Player Interaction", 
       intid = 26,
       commands = {
           {cmd = "stats", name = "Stats", desc = "By saying 'stats' in group chat or whispers, your shadows will display their experience percentage, number of free bag slots, and money."},
           {cmd = "c", name = "Inventory", desc = "By whispering 'c' to a shadow, the shadow will whisper back its full inventory."},
           {cmd = "e", name = "Equip Inventory", desc = "By whispering 'e <item>' to a shadow, the shadow will equip a named or linked from its inventory."},
           {cmd = "s", name = "Sell Inventory", desc = "By whispering 's' to a shadow, a shadow can vendor specific items. Specify further with grey, vendor, item link, and more."},
           {cmd = "u", name = "Use Inventory", desc = "Whisper 'u' to a shadow to make it use any available item specified in the message. If no item specified, your shadow will say which items can be used."},
           {cmd = "destroy", name = "Destroy Inventory", desc = "By whispering 'destroy' to a shadow, you can select items to destroy from its inventory."},
           {cmd = "rep", name = "Reputation", desc = "By whispering 'rep' or 'reputation' to a shadow, the shadow will tell you its current reputation standing of the faction of whichever NPC you are currently targetting."},
           {cmd = "t", name = "Trade", desc = "You may trade your shadows to distribute loot, free up inventory, pass mats around, and so on. Whisper them 't' or trade them directly to get started. They will whisper you their inventory. To select items to trade, whisper them which item from their inventory you want traded. \n \nNote: Shadows cannot trade you soulbound items even if they have a valid trade timer."},
       }
   },
   talents = {
       name = "Talents", 
       intid = 27,
       commands = {
           {cmd = "talents", name = "Talents", desc = "Your shadows are capable of flexibly utilizing their talents. Whisper your shadow 'talents' to get started."},
           {cmd = "talents spec list", name = "Talents Spec List", desc = "Your shadows come with preset talents you can assign them. They can list applicable talent presets by whispering them 'talents spec list'."},
           {cmd = "talents switch", name = "Talents Switch", desc = "By whispering 'talents switch 1' or 'talents switch 2' to a shadow, the shadow will switch to its main specialization (1) or its secondary specialization (2)."},
           {cmd = "talents spec <specName>", name = "Talents Spec <specName>", desc = "By whispering 'talents spec' with a specialization as listed by 'talents spec list', your shadow will swap out its current set of talents for the chosen preset."},
           {cmd = "talents autopick", name = "Talents Autopick", desc = "Your shadows can automatically select their preferred talents by whispering them 'talents autopick', assuming they have free talent points."},
           {cmd = "note", name = "Note", desc = "Using flexible shadow talents will not influence your glyphs. The talents your shadows apply will remain after the shadow session ends. It is free for shadows to respec."},
       }
   }
}

local function Hello(player)
    local accountId = player:GetAccountId()
    local guidlow = player:GetGUIDLow()
    local name = player:GetName()
    local maxBotCount       = 2
    local maxVIPCount       = 4
    
    player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_gizmo_02:40:40:-24:0|tHow to use shadows", 0, 2)
    
    if not botCount[name] or botCount[name] < 0 then
        botCount[name] = 0
    end
        
    if not botsAvailable[accountId] then
        print("Querying for bots available for "..player:GetName())
        botsAvailable[accountId] = {}
        CharDBQueryAsync("SELECT name, race, class, gender, level FROM characters WHERE account = " .. accountId, function(query)
            if query then
                repeat
                    local name = query:GetString(0)
                    local race = query:GetUInt8(1)
                    local class = query:GetUInt8(2)
                    local gender = query:GetUInt8(3)
                    local level = query:GetUInt8(4)
                    
                    table.insert(botsAvailable[accountId], {
                        name = name,
                        race = race,
                        class = class,
                        gender = gender,
                        level = level
                    })
                    
                until not query:NextRow()

                table.sort(botsAvailable[accountId], function(a, b)
                    return a.level > b.level
                end)
            end
        end)
    end

    if VIPtime[player:GetGUIDLow()] and VIPtime[player:GetGUIDLow()] > os.time() then -- Increased bot limit for VIP
        maxBotCount = maxVIPCount
    end
    
    player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_groupneedmore:40:40:-24:0|tAdd shadow (" .. botCount[name] .. "/"..maxBotCount..")", 0, 10)
    if botCount[name] > 0 then
        --player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_hunter_improvedtracking:40:40:-24:0|tCommand follow", 0, 3)
        --player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_ghoulfrenzy:40:40:-24:0|tCommand attack", 0, 4)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_unused2:40:40:-24:0|tSummon shadows", 0, 5, false, "Are you sure you want to summon your shadow(s) here?\n \nThis will induce a 30-minute summon cooldown.")
        player:GossipMenuAddItem(4, "|TInterface/PaperDollInfoFrame/UI-GearManager-Undo:40:40:-24:0|tRemove shadow", 0, 6)
    end
    player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:40:40:-24:0|tExit", 0, 1000)
    player:GossipSendMenu(12, player, 200)
end

local function ListActiveShadows(player)
    local name = player:GetName()
    player:GossipClearMenu()

    player:GossipMenuAddItem(0, "|TInterface/PaperDollInfoFrame/UI-GearManager-Undo:40:40:-24:0|tActive shadows:\n \n ", 0, 6)

    if activeBots[name] then
       for index, botName in ipairs(activeBots[name]) do
           local menuText = string.format(
               "|TInterface/ICONS/ability_vehicle_loadselfcatapult:40:40:-24:0|t%s\n \n ", 
               botName
           )
           
           player:GossipMenuAddItem(0, menuText, 0, 200 + index)
       end
    end

    player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:40:40:-24:0|tBack", 0, 999)
    player:GossipSendMenu(12, player, 200)
end

local function ShadowsGossipSelect(event, player, object, sender, intid, code, menu_id)
    local accountId = player:GetAccountId()
    local guid = player:GetGUIDLow()
    local name = player:GetName()
    local maxBotCount       = 2
    local maxVIPCount       = 4
    
    if VIPtime[player:GetGUIDLow()] > os.time() then -- Increased bot limit for VIP
        maxBotCount = maxVIPCount
    end
    
    if intid == 2 then -- Settings main menu
       player:GossipClearMenu()
       player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_gizmo_02:40:40:-24:0|tHow to use shadows\n \nBy reaching through the Twisting Nether, you are able to summon shadows of the other characters on your account.\n \nTo control and summon a shadow, it must be within ten levels of you.\n \nYour active shadows adjust to your faction.\n \nYou may control up to 2 shadows at a time, or 4 shadows at a time if you have VIP.\n \nSee below for how to control your shadows.\n \n", 0, 2)
       
       -- Add main category options
       for _, category in pairs(commandCategories) do
           player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_gizmo_02:40:40:-24:0|t"..category.name, 0, category.intid)
       end
       
       player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:40:40:-24:0|tBack", 0, 999)
       player:GossipSendMenu(12, player, 200)
       
   elseif intid >= 20 and intid <= 27 then -- Category submenus
       player:GossipClearMenu()
       
       -- Find the selected category
       local selectedCategory
       for _, category in pairs(commandCategories) do
           if category.intid == intid then
               selectedCategory = category
               break
           end
       end
       
        function GetCategoryIcon(categoryName)
           local icons = {
               ["Movement"] = "ability_hunter_improvedtracking",
               ["Combat"] = "ability_warrior_battleshout",
               ["Formation"] = "achievement_arena_5v5_3",
               ["World Interaction"] = "achievement_zone_northrend_01",
               ["Spells"] = "ability_mage_frostfirebolt",
               ["Trade"] = "inv_misc_coin_06",
               ["Player Interaction"] = "inv_misc_bag_07_red",
               ["Talents"] = "ability_dualwieldspecialization",
           }
           return icons[categoryName] or "inv_misc_questionmark"
        end

        if selectedCategory then
           -- Header with gizmo icon
           player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_gizmo_02:40:40:-24:0|t"..selectedCategory.name.." Commands:\n \n ", 0, selectedCategory.intid)
           
           -- Get the appropriate icon for this category
           local categoryIcon = GetCategoryIcon(selectedCategory.name)
           
           for _, command in ipairs(selectedCategory.commands) do
               local menuText = string.format(
                   "|TInterface/ICONS/%s:40:40:-24:0|t%s\n \n%s\n \n ",
                   categoryIcon,
                   command.name,
                   command.desc
               )
               player:GossipMenuAddItem(0, menuText, 0, selectedCategory.intid)
           end
        end
       
       player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:40:40:-24:0|tBack", 0, 2)
       player:GossipSendMenu(12, player, 200)
        
   -- elseif intid >= 300 and intid < 399 then -- Execute command
   --     local categoryIntid = math.floor((intid - 300) / 100) + 20
   --     local commandIndex = (intid - 300) % 100
   --     
   --     for _, category in pairs(commandCategories) do
   --         if category.intid == categoryIntid then
   --             local command = category.commands[commandIndex]
   --             if command then
   --                 player:RunCommand(".playerbots " .. command.cmd)
   --                 player:GossipComplete()
   --                 break
   --             end
   --         end
   --     end

    elseif intid == 3 then -- Follow
        for _, name in pairs(activeBots[name]) do 
            if name ~= player:GetName() then
                bot = GetPlayerByName(name)
                if bot then
                    bot:MoveFollow(player, math.random(-6, 6), math.random(-6, 6))
                    if bot:IsInCombat() and bot:GetSelection() then
                        bot:GetSelection():ClearInCombat()
                    end
                    bot:ClearInCombat()
                end
            end
        end
        player:SendAreaTriggerMessage("Your shadows are now following you.")
        Hello(player)
    elseif intid == 4 then -- Attack
        for _, name in pairs(activeBots[name]) do 
            if name ~= player:GetName() then
                bot = GetPlayerByName(name)
                if bot then
                    player:Say("/p attack", 0)
                end
            end
        end
        Hello(player)
    elseif intid == 5 then -- Summon
        if not botTeleTime[accountId] then botTeleTime[accountId] = 0 end
        
        if botTeleTime[accountId] < os.time() then
            for _, name in pairs(activeBots[name]) do 
                if name ~= player:GetName() then
                    bot = GetPlayerByName(name)
                    if bot then
                        if bot:GetMapId() == player:GetMapId() then
                            bot:Teleport(player:GetMapId(), player:GetX() + math.random(-3, 3), player:GetY() + math.random(-3, 3), player:GetZ() + math.random(0, 0.1), player:GetO() + math.random(-6, 6))
                            player:CastSpell(bot, BOT_TELE_VISUAL, true)
                            bot:CastSpell(bot, BOT_TELE_VISUAL, true)
                        else
                            bot:Teleport(player:GetMapId(), player:GetX() + math.random(-3, 3), player:GetY() + math.random(-3, 3), player:GetZ() + math.random(0, 0.1), player:GetO() + math.random(-6, 6))
                            player:CastSpell(bot, BOT_TELE_VISUAL, true)
                            local name = player:GetName()
                            bot:RegisterEvent(function(eventId, delay, repeats, bot) 
                                bot:CastSpell(bot, BOT_TELE_VISUAL, true)
                            end, 500, 1)
                        end
                    end
                end
            end
            botTeleTime[accountId] = os.time() + (BotSummonCD)
        else
            player:SendAreaTriggerMessage("Your shadows summon is on cooldown for " .. math.floor((botTeleTime[accountId] - os.time()) / 60) .." minutes.")
        end
        Hello(player)
    elseif intid == 6 then  -- Show list of active shadows to remove
        ListActiveShadows(player)
    elseif intid >= 200 and intid < 299 then  -- Bot removal selection
        local selectedIndex = intid - 200

        if activeBots[name] and activeBots[name][selectedIndex] then
           local selectedBot = activeBots[name][selectedIndex]
           player:RunCommand(".playerbots bot remove " .. selectedBot)
           print("Removing bot "..selectedBot.." from gossip menu")
           ListActiveShadows(player)
        end
    elseif intid == 10 then  -- "Add bot" option
        local group = player:GetGroup()
        local groupMembers = {}
        local groupNames = {}
        
        player:GossipClearMenu()
        player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_groupneedmore:40:40:-24:0|tAvailable shadows:\n \n ", 0, 10)
        
        if group then
            groupMembers = group:GetMembers()
            for _, member in pairs(groupMembers) do
                if member then
                    groupNames[member:GetName()] = true
                end
            end
        end
        
        if botsAvailable[accountId] then
            local found = false
            for index, charInfo in ipairs(botsAvailable[accountId]) do
                if charInfo.name ~= player:GetName() then
                    local className = GetClassName(charInfo.class)
                    local raceName = GetRaceName(charInfo.race)
                    
                    local raceIcon = GetRaceIconPath(charInfo.race, charInfo.gender)
                    local classIcon = GetClassIconPath(charInfo.class)
                    
                    if charInfo.name and not groupNames[charInfo.name] then
                        if charInfo.level >= minLevel and charInfo.level > 9 and math.abs(player:GetLevel() - charInfo.level) <= 10 then
                            player:GossipMenuAddItem(4, "|TInterface/ICONS/" .. raceIcon .. ":40:40:-24:0|t |TInterface/ICONS/" .. classIcon .. ":40:40:-24:0|t |TInterface/ICONS/achievement_level_" .. (math.floor(charInfo.level / 10) * 10) .. ":40:40:-24:0|t \n \n \n \nName:  " .. charInfo.name .. "\n \nLevel:  " .. charInfo.level .. "\n \nRace:  " .. raceName .. "\n \nClass:  " .. className .. "\n ", 0, 100 + index)
                            found = true
                        elseif charInfo.level >= minLevel and math.abs(player:GetLevel() - charInfo.level) <= 10 then
                            player:GossipMenuAddItem(4, "|TInterface/ICONS/" .. raceIcon .. ":40:40:-24:0|t |TInterface/ICONS/" .. classIcon .. ":40:40:-24:0|t |TInterface/ICONS/inv_misc_desecrated_clothchest:40:40:-24:0|t\n \n \n \nName:  " .. charInfo.name .. "\n \nLevel:  " .. charInfo.level .. "\n \nRace:  " .. raceName .. "\n \nClass:  " .. className .. "\n ", 0, 100 + index)
                            found = true
                        end
                    end
                end
            end
            if not found then
                player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_rogue_shadowstep:40:40:-24:0|tNo available shadows \n \nThere are no shadows available in the range you can mind control. Your shadows must be within ten levels of you and at least level 15.\n \n", 0, 10)
            end
        end
                
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:40:40:-24:0|tBack", 0, 999)
        
        player:GossipSendMenu(12, player, 200)
    elseif intid >= 100 and intid < 199 then  -- Bot selection
        player:GossipClearMenu()
        for _, zone in pairs(disallowedZones) do
            if player:GetZoneId() == zone or player:GetAreaId() == zone then
                player:GossipComplete()
                player:SendAreaTriggerMessage("You cannot use shadows in "..GetAreaName(player:GetAreaId())..".")
                return
            end
        end
        if player:GetLevel() < minLevel then
            player:SendAreaTriggerMessage("You need to be at least level ".. minLevel .. " to use shadows!")
            Hello(player)
            return
        end
        if botCount[name] < maxBotCount then
            local selectedIndex = intid - 100
            
            if addCmdTimer[guid] and not (os.time() - addCmdTimer[guid] > 1) then
                player:SendAreaTriggerMessage("You can't add shadows that fast!")
                Hello(player)
                return
            end
            
            if botsAvailable[accountId] and botsAvailable[accountId][selectedIndex] then
                local selectedChar = botsAvailable[accountId][selectedIndex]
                botCount[name] = (botCount[name] or 0) + 1

                -- Initialize activeBots[name] as a table if it is nil
                if not activeBots[name] then 
                    activeBots[name] = {} 
                end

                table.insert(activeBots[name], selectedChar.name)

                if not botMasters[guid] then 
                    botMasters[guid] = {} 
                end

                table.insert(botMasters[guid], player:GetName())
                botSummonTime[guid] = os.time()
                player:RunCommand(".playerbots bot add " .. selectedChar.name) -- Add bot
                if not isPlayerBot[selectedChar.name] then
                    isPlayerBot[selectedChar.name] = name
                elseif not (isPlayerBot[selectedChar.name] == name) then
                    isPlayerBot[selectedChar.name] = name
                end
                Hello(player)
            end
        else
            player:SendAreaTriggerMessage("You can't summon more shadows until you remove one.")
            Hello(player)
        end
    elseif intid == 999 then  -- "Back" option
        player:GossipClearMenu()
        Hello(player)
    elseif intid == 1000 then  -- "Exit" option
        player:GossipComplete()
    end
end

local function Logout(event, player)
    local accountId = player:GetAccountId()
    local guidlow = player:GetGUIDLow()
    local name = player:GetName()
    
    -- Check if player is set as active anywhere in the table
    for playerName, bots in pairs(activeBots) do
        for i, botName in ipairs(bots) do
            if botName == name then
                -- Found the player as a bot somewhere, remove them from that player's list
                table.remove(activeBots[playerName], i)
                player:RemoveFromGroup()
                if botCount[playerName] then
                    botCount[playerName] = botCount[playerName] - 1
                end
                break
            end
        end
    end

    isPlayerBot[name]           = nil
    botsAvailable[accountId]    = nil
    activeBots[name]            = nil
    botCount[name]              = nil
    botMasters[guidlow]         = nil
end

local function ShadowsLoginHook(event, player)
    local guidlow = player:GetGUIDLow()
    CharDBExecute("REPLACE INTO character_cooldowns (guid, item_id, cooldown_end) VALUES (" .. guidlow .. ", 0, " .. os.time() .. ")"); -- Lazy persistent storage solution. Could probably just use characters table directly. Initially wanted cache-persistent value attached to world but not possible in standard AC ELUNA
end

function CheckActiveBots(eventid, delay, repeats, uninvitedPlayer)
    local uninvitedPlayerName = uninvitedPlayer:GetName()
    if isPlayerBot[uninvitedPlayerName] then
        local player = GetPlayerByName(isPlayerBot[uninvitedPlayerName])
        local bot = GetPlayerByName(uninvitedPlayerName)
        if player and bot then
            player:RegisterEvent(function(_, _, _, player)
                player:RunCommand(".playerbots bot remove " .. uninvitedPlayerName)
                print("Bot removed: " ..uninvitedPlayerName.. ".")
                print("Leader: " ..player:GetName())
            end, 100, 1)
        end
        logoutEvent[uninvitedPlayerName] = nil
    end
end

function UninviteGroupGUID(event, packet, player)
    local guid = packet:ReadGUID()
    local reason = packet:ReadString()
    local uninvitedPlayer = GetPlayerByGUID(guid)
    if uninvitedPlayer then
        if not logoutEvent[uninvitedPlayer:GetName()] then
            logoutEvent[uninvitedPlayer:GetName()] = uninvitedPlayer:RegisterEvent(CheckActiveBots, 100, 1)
        end
    end
end

function UninviteGroup(event, packet, player)
    local uninvitedPlayerName = packet:ReadString()
    local uninvitedPlayer = GetPlayerByName(uninvitedPlayerName)
    if uninvitedPlayer then
        if not logoutEvent[uninvitedPlayer:GetName()] then
            logoutEvent[uninvitedPlayer:GetName()] = uninvitedPlayer:RegisterEvent(CheckActiveBots, 100, 1)
        end
    end
end

local function LeaveGroup(event, group, guid, method, kicker, reason)
    local uninvitedPlayer = GetPlayerByGUID(guid)
    if uninvitedPlayer then
        if not logoutEvent[uninvitedPlayer:GetName()] then
            logoutEvent[uninvitedPlayer:GetName()] = uninvitedPlayer:RegisterEvent(CheckActiveBots, 100, 1)
        end
    end
end

local function DisbandGroup(event, group)
    for _, member in ipairs (group:GetMembers()) do
        if isPlayerBot[member:GetName()] then
            local botName = member:GetName()
            local player = GetPlayerByName(isPlayerBot[botName])
            if player and not logoutEvent[botName] then
                logoutEvent[botName] = player:RegisterEvent(function(_, _, _, player)
                    player:RunCommand(".playerbots bot remove " .. botName)
                    print("Removing "..botName.." from disbanded group")
                    logoutEvent[botName] = nil
                end, 100, 1)
            end
        end
    end
end

function Teleport(player, sameMap)
    local name = player:GetName()
    if isPlayerBot[name] then
        return
    end
    local guid = player:GetGUIDLow()
    if not player:IsInGroup() then
        return -- Should probably add a sanity check here to disconnect bots not in your party in case party affiliation fails somehow
    end
    if player:IsDead() then
        return
    end
    if not botCount[name] or botCount[name] == 0 then
        return
    end
    if lastTeleTime[guid] and os.time() <= lastTeleTime[guid] then
        return
    end
    if ((player:GetMapId() == 0 or player:GetMapId() == 1 -- Kalimdor, Eastern Kingdoms
    or player:GetMapId() == 530 or player:GetMapId() == 571) -- Outlands, Northrend
    and (sameMap == "yes"))
    or (player:InArena() or player:InBattleground()) -- PVP exclusions from teleport
    then
        return
    end
    if not botCount[name] or botCount[name] == 0 then
        return
    end
    for i, botName in ipairs(activeBots[name]) do
        local bot = GetPlayerByName(botName)
        if bot and not player:IsInCombat() then
            if bot:GetMapId() ~= player:GetMapId() and sameMap == "yes" then
                return
            end
            isInLos = bot:IsWithinLoS(player)
            if not isInLos and (((bot:GetZ() < player:GetZ() - 20) or (bot:GetZ() > player:GetZ() + 20)) or not ((bot:GetMapId() == player:GetMapId()))) then
                bot:Teleport(player:GetMapId(), player:GetX() + math.random(-1, 1), player:GetY() + math.random(-1, 1), player:GetZ(), player:GetO() + math.random(-6, 6))
                print("Teleporting bot "..botName.." to "..name)
            end
        end
    end
    lastTeleTime[guid] = os.time() + 1
end

local function PacketTeleDelay(_, _, player)
    local name = player:GetName()
    if isPlayerBot[name] then
        return
    end
    local sameMap = "openWorld"
    player:RegisterEvent(function(_, _, _, player)
        Teleport(player, sameMap)
    end, 1000, 1)
end

local function PacketMoveDelay(_, _, player)
    local name = player:GetName()
    if isPlayerBot[name] then
        return
    end
    local sameMap = "yes"
    player:RegisterEvent(function(_, _, _, player)
        Teleport(player, sameMap)
    end, 1000, 1)
end

local function buildCommandList()
    local commands = {}
    for _, category in pairs(commandCategories) do
        for _, cmd in ipairs(category.commands) do
            commands[cmd.cmd] = true
        end
    end
    return commands
end

local validCommands = buildCommandList()

local function OnWhisper(event, player, msg, Type, lang, receiver)
    local receiverName = receiver:GetName()
    local playerName = player:GetName()
    
    if activeBots[playerName] then
        for _, botName in ipairs(activeBots[playerName]) do
            if receiverName == botName then
                local isValidCommand = false
                for cmd, _ in pairs(validCommands) do
                    if string.match(msg:lower(), "^" .. cmd:lower()) then
                        isValidCommand = true
                        break
                    end
                end
                
                if not isValidCommand then
                    local bot = GetPlayerByName(botName)
                    bot:SendUnitWhisper("I don't understand what you mean! Please check Twiggy for commands I can react to.", 0, player)
                end
            end
        end
    end
end

local function OnBotCommand(event, player, command)
    if command == "shadowsmenu" then
        Hello(player)
        return false
    end
    if string.find(command, "^playerb") then
        local guid = player:GetGUIDLow()
        if (string.find(command, "^playerbots bot add ") and (not addCmdTimer[guid] or (os.time() - addCmdTimer[guid] > 1))
        and (botSummonTime[guid] and (os.time() - botSummonTime[guid] < 5)))
        then
            addCmdTimer[guid] = os.time()
            return true
        end
        if string.find(command, "^playerbots bot remove ") then
            return true
        end
        return false
    end
end

local function OnPlayerMapEnter(event, map, player)
    local name = player:GetName()
    if isPlayerBot[name] then
        return
    end
    local sameMap = "openWorld"
    Teleport(player, sameMap)
end

local function OnDisallowedZones(event, player, newZone, newArea)
    local name = player:GetName()
    if player:IsDead() then
        return
    end
    if isPlayerBot[name] then
        return
    end
    if not botCount[name] or botCount[name] <= 0 then
        return
    end
    for _, zone in pairs(disallowedZones) do
        if newZone == zone or newArea == zone then
            local botsToRemove = {}

            if botCount[name] and botCount[name] > 0 then
                for i, botName in ipairs(activeBots[name]) do
                    table.insert(botsToRemove, botName)
                end
            end

            player:RegisterEvent(function(eventId, delay, repeats, player) 
                if #botsToRemove > 0 then 
                    for _, botName in ipairs(botsToRemove) do
                        local bot = GetPlayerByName(botName)
                        if bot then
                            bot:RemoveFromGroup()
                            player:RunCommand(".playerbots bot remove " .. botName)
                            table.remove(activeBots[name], i)
                            botCount[name] = botCount[name] - 1
                            print("Logging out bot in disallowed zone")
                        end
                    end
                    player:SendAreaTriggerMessage("You cannot use shadows in "..GetAreaName(player:GetAreaId())..".")
                end
            end, 100, 1)
        end
    end
end

function SetActiveBots()
    activeBots = {}
    botCount = {}
    local playersByAccount = {}
    local allGuids = {}
    
    -- Group players by their account ID and collect all GUIDs
    for _, player in pairs(GetPlayersInWorld()) do
        if player then
            local accountId = player:GetAccountId()
            if not playersByAccount[accountId] then
                playersByAccount[accountId] = {}
            end
            local playerData = {
                name = player:GetName(),
                guid = player:GetGUIDLow()
            }
            table.insert(playersByAccount[accountId], playerData)
            table.insert(allGuids, playerData.guid)
        end
    end

    if #allGuids > 0 then
        local guidString = table.concat(allGuids, ",")
        
        CharDBQueryAsync(string.format(
            "SELECT guid, cooldown_end FROM character_cooldowns WHERE guid IN (%s) AND item_id = 0",
            guidString
        ),
        function(query)
            local cooldowns = {}
            
            if query then
                repeat
                    local guid = query:GetUInt32(0)
                    local cooldownEnd = query:GetUInt32(1)
                    cooldowns[guid] = cooldownEnd
                until not query:NextRow()
            end

            -- Process each account
            for accountId, players in pairs(playersByAccount) do
                if #players > 1 then
                    local lowestCooldown = nil
                    local mainPlayer = nil

                    -- Find player with lowest cooldown in this account
                    for _, playerData in pairs(players) do
                        local cooldown = cooldowns[playerData.guid] or 0
                        if not lowestCooldown or cooldown < lowestCooldown then
                            lowestCooldown = cooldown
                            mainPlayer = playerData
                        end
                    end

                    -- Set up activeBots for the main player
                    if mainPlayer then
                        activeBots[mainPlayer.name] = {}
                        botCount[mainPlayer.name] = 0
                        
                        -- Add other characters as bots
                        for _, playerData in pairs(players) do
                            if playerData.guid ~= mainPlayer.guid then
                                table.insert(activeBots[mainPlayer.name], playerData.name)
                                botCount[mainPlayer.name] = (botCount[mainPlayer.name] or 0) + 1
                                isPlayerBot[playerData.name] = mainPlayer.name
                                print("Player "..playerData.name.." is a bot, setting var on script load!")
                            end
                        end
                    end
                end
            end
        end)
    end
end

----------------------------------------------------------------------------------------------------
-- Shadows script end
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Account-shared currencies script start
----------------------------------------------------------------------------------------------------

local function FetchAccountCurrency(accountId, currencyId)
    local query = CharDBQuery("SELECT count FROM accountwide_currency WHERE accountId = " .. accountId .. " AND currencyId = " .. currencyId)
    return query and query:GetUInt32(0) or 0
end

local function UpdateAccountCurrency(accountId, currencyId, newCount)
    CharDBExecute("INSERT INTO accountwide_currency (accountId, currencyId, count) VALUES (" .. accountId .. ", " .. currencyId .. ", " .. newCount .. ") ON DUPLICATE KEY UPDATE count = " .. newCount)
end

local function InitializeAccountCurrencyOnEmptyTable(accountId)
    local checkQuery = CharDBQuery("SELECT 1 FROM accountwide_currency WHERE accountId = " .. accountId .. " LIMIT 1")

    if not checkQuery then
        for _, currencyId in ipairs(currencyItemIDs) do
            local itemQuery = CharDBQuery("SELECT SUM(count) FROM item_instance WHERE itemEntry = " .. currencyId .. " AND owner_guid IN (SELECT guid FROM characters WHERE account = " .. accountId .. ")")
            if itemQuery then
                local count = itemQuery:GetUInt32(0)
                UpdateAccountCurrency(accountId, currencyId, count)
            end
        end
    end
end

local function SyncCurrencyOnLogin(player, accountId)
    for _, currencyId in ipairs(currencyItemIDs) do
        local accountCurrencyCount = FetchAccountCurrency(accountId, currencyId)
        local playerCurrencyCount = player:GetItemCount(currencyId)

        if playerCurrencyCount < accountCurrencyCount then
            player:AddItem(currencyId, accountCurrencyCount - playerCurrencyCount)
        elseif playerCurrencyCount > accountCurrencyCount then
            player:RemoveItem(currencyId, playerCurrencyCount - accountCurrencyCount)
        end
    end
end

local function AccountWideCurrency(event, player)
    if isPlayerBot[player:GetName()] then
        return
    end
    local accountId = player:GetAccountId()

    if event == 3 then        
        InitializeAccountCurrencyOnEmptyTable(accountId)
        player:RegisterEvent(function(_, _, _, player)
            SyncCurrencyOnLogin(player, accountId)
        end, 1000, 1) -- Delay of 1000 milliseconds (1 second) to ensure that the InitializeAccountCurrencyOnEmptyTable() function finishes populating the empty table
    elseif event == 4 or event == 25 then
        for _, currencyId in ipairs(currencyItemIDs) do
            local playerCurrencyCount = player:GetItemCount(currencyId)
            local accountCurrencyCount = FetchAccountCurrency(accountId, currencyId)

            if playerCurrencyCount ~= accountCurrencyCount then
                UpdateAccountCurrency(accountId, currencyId, playerCurrencyCount)
            end
        end
    end
end

-------------------------------------------------------------------------------------------------------------------
-- This ELUNA module sets the faction of all players in an instance to the same as the first player to enter it.
-- Written by mostly nick :) for Yggdrasil WoW
-------------------------------------------------------------------------------------------------------------------

local cachedFaction = {}

local function OnPlayerMapChange(event, map, player)
    local instanceId = player:GetInstanceId()
    local mapId = player:GetMapId()
	
	if (mapId == 631 or mapId == 658 -- ICC and the Frozen Halls maps
	or mapId == 632 or mapId == 668) -- The Frozen Halls maps
	then
		if instanceId and instanceId > 0 then
            player:RegisterEvent(function(eventId, delay, repeats, player)
                if not cachedFaction[instanceId] then    
                    if (mapId == 631 and (player:GetNearestCreature(1000, 39372) or player:GetNearestCreature(20000, 37187)))
                    or (mapId == 632 and player:GetNearestCreature(1000, 37596))
                    or (mapId == 658 and player:GetNearestCreature(1000, 36990))
                    or (mapId == 668 and player:GetNearestCreature(1000, 37223))
                    or (mapId == 631 and player:HasAura(73822))
                    then -- horde instance. 39372 hellscream at entrance. maps 632, 658, and 668 are Sylvanas Windrunner
                        cachedFaction[instanceId] = 1801
                        print("ICC, instance ID "..instanceId..": Horde instance detected! Setting player faction to horde.")
                        if player:IsAlliance() then
                            player:SetFaction(1801) -- horde faction adjustment
                        end
                    elseif (mapId == 631 and (player:GetNearestCreature(1000, 39372) or player:GetNearestCreature(20000, 37200)))
                    or (mapId == 632 and player:GetNearestCreature(1000, 37597))
                    or (mapId == 658 and player:GetNearestCreature(1000, 36993))
                    or (mapId == 668 and player:GetNearestCreature(1000, 37221))
                    or (mapId == 631 and player:HasAura(73828))
                    then -- ally instance. 39371 is wrynn at entrance. maps 632, 658, and 668 are Lady Jaina Proudmoore
                        cachedFaction[instanceId] = 1802
                        print("ICC, instance ID "..instanceId..": Ally instance detected! Setting player faction to alliance.")
                        if not player:IsAlliance() then
                            player:SetFaction(1802) -- ally  faction adjustment
                        end
                    end
                else
                    print("ICC Xfac - player "..player:GetName().." just entered map ID "..mapId.."! Instance faction: "..instanceId..": "..cachedFaction[instanceId])
                    for _, playersInInstances in pairs(GetPlayersInWorld()) do
                        if playersInInstances:GetInstanceId() == instanceId then
                            if cachedFaction[instanceId] == 1801 and playersInInstances:IsAlliance() then -- Horde faction adjustment
                                playersInInstances:SetFaction(35)
                                playersInInstances:SetFaction(1801)
                                print("Player name: "..playersInInstances:GetName().." is horde, setting to ally player to horde faction 1801.")
                            elseif cachedFaction[instanceId] == 1802 and not playersInInstances:IsAlliance() then
                                playersInInstances:SetFaction(35)
                                playersInInstances:SetFaction(1802)
                                print("Player name: "..playersInInstances:GetName().." is horde, setting horde player to to alliance faction 1802.")
                            else
                                playersInInstances:SetFaction(35)
                                playersInInstances:SetFactionForRace(playersInInstances:GetRace())
                            end
                        end
                    end
                end
            end, 500, 1)
        end
    elseif isPlayerBot[player:GetName()]
    and not map:IsBattleground()
    and not map:IsArena()
    then -- Faction adjustment for bots on xfac bot 
        master = GetPlayerByName(isPlayerBot[player:GetName()])
        if not master then -- Don't adjust if player isn't accessible; assume bot's faction was already adjusted on initial spawn
            return
        end
        if (master:GetRace() == 1
        or master:GetRace() == 3 or master:GetRace() == 4
        or master:GetRace() == 7 or master:GetRace() == 11)
        then -- Alliance master
            if (player:GetRace() == 1 or player:GetRace() == 3
            or player:GetRace() == 4 or player:GetRace() == 7
            or player:GetRace() == 11) 
            then
                return -- Bot is already alliance, do nothing
            else
                player:SetFaction(1802)
            end
        else -- Horde master
            if (player:GetRace() == 2 or player:GetRace() == 5
            or player:GetRace() == 6 or player:GetRace() == 8
            or player:GetRace() == 10)
            then
                return -- Bot is already horde, do nothing
            else
                player:SetFaction(1801)
            end
        end
    else
        if player and not (
        (player:GetRace() == 1 and player:GetFaction() == 1) or -- Human
        (player:GetRace() == 2 and player:GetFaction() == 2) or -- Orc
        (player:GetRace() == 3 and player:GetFaction() == 3) or -- Dwarf
        (player:GetRace() == 4 and player:GetFaction() == 4) or -- Night Elf
        (player:GetRace() == 5 and player:GetFaction() == 5) or -- Undead
        (player:GetRace() == 6 and player:GetFaction() == 6) or -- Tauren
        (player:GetRace() == 7 and player:GetFaction() == 115) or -- Gnome
        (player:GetRace() == 8 and player:GetFaction() == 116) or -- Troll
        (player:GetRace() == 10 and player:GetFaction() == 1610) or -- Blood elf
        (player:GetRace() == 11 and player:GetFaction() == 1629)) -- Draenei
        then
            print("Faction discrepancy detected, resetting player "..player:GetName().."! Current faction: "..player:GetFaction())
            player:SetFactionForRace(player:GetRace())
            print("Faction discrepancy detected, resetting player "..player:GetName().."! New faction: "..player:GetFaction())
        end
    end
end

-------------------------------------------------------------------------------------------------------------------
-- End custom Xfac
-------------------------------------------------------------------------------------------------------------------

function CacheCurrentInstances()
    local validMaps = {631, 632, 658, 668}
    local allianceFactions = {1, 3, 4, 115, 1629, 1802}
    
    local function isValidMap(mapId)
        for _, validMap in pairs(validMaps) do
            if mapId == validMap then
                return true
            end
        end
        return false
    end
    
    local function isAllianceFaction(factionId)
        for _, allianceFaction in pairs(allianceFactions) do
            if factionId == allianceFaction then
                return true
            end
        end
        return false
    end
    
    for _, player in pairs(GetPlayersInWorld()) do
        local instanceId = player:GetInstanceId()
        local mapId = player:GetMapId()
        
        if instanceId > 0 and isValidMap(mapId) then
            if not cachedFaction[instanceId] then
                for _, instancePlayer in pairs(GetPlayersInWorld()) do
                    if instancePlayer:GetInstanceId() == instanceId then
                        local faction = instancePlayer:GetFaction()
                        
                        if isAllianceFaction(faction) then
                            cachedFaction[instanceId] = 1802 -- Alliance
                            print("Instance ID "..instanceId..": Cached as Alliance (1802)")
                            break
                        else
                            cachedFaction[instanceId] = 1801 -- Horde
                            print("Instance ID "..instanceId..": Cached as Horde (1801)")
                            break
                        end
                    end
                end
            end
        end
    end
end

local function SendBroadcastWithCheck(playerGUID, message, itemEntry, itemCount)
    local player = GetPlayerByGUID(playerGUID)
    if player then
		local accountId = player:GetAccountId()
        if itemEntry and itemCount then
            player:AddItem(itemEntry, itemCount)
			player:SendBroadcastMessage(message)
			if itemEntry == 20880 then
				print("Awarding Vote Tokens to Account ID: " .. accountId)  -- Debugging line
				CharDBExecute("UPDATE account_currencies SET vp = 0 WHERE id = " .. accountId)
			else
				print("Awarding Community Tokens to Account ID: " .. accountId)  -- Debugging line
				CharDBExecute("UPDATE account_currencies SET dp = 0 WHERE id = " .. accountId)
			end
        end
    end
end

local function TokensOnLogin(event, player)
    if isPlayerBot[player:GetName()] then
        return
    end
    local accountId = player:GetAccountId()

    local playerGUID = player:GetGUID()
    local communitymessage = false
    local votemessage = false
    
	CharDBQueryAsync("SELECT dp FROM account_currencies WHERE id = " .. accountId, function(dpquery)
		if dpquery then
			local dpValue = dpquery:GetInt32(0)
			if dpValue and dpValue > 0 then
				local itemCount = dpValue
				CreateLuaEvent(function() 
					SendBroadcastWithCheck(playerGUID, "You have been awarded " .. itemCount .. " Community Tokens. Thank you for supporting our community!", 19322, itemCount)
				end, 3000, 1)
				communitymessage = true
			end
		end
	end)
    
	CharDBQueryAsync("SELECT vp FROM account_currencies WHERE id = " .. accountId, function(vpquery)
		if vpquery then
			local vpValue = vpquery:GetInt32(0)
			if vpValue and vpValue > 0 then
				local itemCount = vpValue
				CreateLuaEvent(function() 
					SendBroadcastWithCheck(playerGUID, "You have been awarded " .. itemCount .. " Vote Tokens, which can be redeemed for XP boosts, transmogs, and vanity items. Thank you for your vote!", 20880, itemCount)
				end, 3000, 1)
				votemessage = true
			end
		end
	end)
    
    if not (communitymessage or votemessage) then
		player:SendBroadcastMessage("Please remember to vote on Yggdrasilwow.com. Vote Tokens can be redeemed for XP boosts, transmogs, and vanity items.")
    end
end

-------------------------------------------------------------------------------------------------------------------------
-- XP changer script start
-------------------------------------------------------------------------------------------------------------------------

local charactersSQL = [[ CREATE TABLE IF NOT EXISTS `character_rate_xp` (`guid` int(11) unsigned NOT NULL, `rate` int(11) NOT NULL DEFAULT 0, PRIMARY KEY (`guid`)) ENGINE=InnoDB DEFAULT CHARSET=utf8;]]
CharDBQuery(charactersSQL)

local currencyID = 20880
local currencyNameSingular = "Vote Token"
local currencyName = "Vote Tokens"

local XPCache = {}

local function OnXPRateChanger(event, player, object)
    local guid = player:GetGUIDLow()
    local currentRate = XPCache[guid] or 1
	if not VIPtime[player:GetGUIDLow()] then
		local name = player:GetName()
		CharDBQueryAsync("SELECT VIPTIME FROM ACCOUNTS_VIP WHERE ACCOUNT = " .. player:GetAccountId() .. ";", function(result)
			local player = GetPlayerByName(name)
            local object = player:GetNearestCreature(10, 190023) or player
			if result then
				VIPtime[player:GetGUIDLow()] = result:GetUInt32(0)
			else
				VIPtime[player:GetGUIDLow()] = os.time()
			end
            
            local cost6 = " (1x "..currencyNameSingular..")"
            local cost7 = " (2x "..currencyName..")"
            local cost8 = " (3x "..currencyName..")"
            local cost9 = " (4x "..currencyName..")"
            local cost10 = " (5x "..currencyName..")"
            
            if object == player or (VIPtime[player:GetGUIDLow()] and VIPtime[player:GetGUIDLow()] > os.time()) then
                cost6 = ""
                cost7 = ""
                cost8 = ""
                cost9 = ""
                cost10 = ""
            end
            
            player:GossipClearMenu()
            
            if player:GetLevel() == 80 then
                player:GossipMenuAddItem(0, "|TINTERFACE/ICONS/achievement_level_80:32:32:-22:0|tNo services available\n \nThere are no experience services available at level 80.\n \n ", 0, 999)
            else
                player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/spell_fire_burningspeed:32:32:-22:0|tYour experience rate is: x"..currentRate, 0, 999)
                player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x1", 0, 1, false, "Are you sure you want to change your experience rate to: x1?")
                player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x2", 0, 2, false, "Are you sure you want to change your experience rate to: x2?")
                player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x3", 0, 3, false, "Are you sure you want to change your experience rate to: x3?")
                player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x4", 0, 4, false, "Are you sure you want to change your experience rate to: x4?")
                player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x5", 0, 5, false, "Are you sure you want to change your experience rate to: x5?")
                player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x6"..cost6, 0, 6, false, "Are you sure you want to change your experience rate to: x6?")
                player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x7"..cost7, 0, 7, false, "Are you sure you want to change your experience rate to: x7?")
                player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x8"..cost8, 0, 8, false, "Are you sure you want to change your experience rate to: x8?")
                player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x9"..cost9, 0, 9, false, "Are you sure you want to change your experience rate to: x9?")
                player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x10"..cost10, 0, 10, false, "Are you sure you want to change your experience rate to: x10?")
            end
            if not (object == player) then
                player:GossipMenuAddItem(0, "|TINTERFACE/ICONS/inv_misc_enggizmos_27:32:32:-22:0|tClose", 0, 998)
                player:GossipSendMenu(12, object)
            else
                player:GossipMenuAddItem(0, "|TINTERFACE/ICONS/inv_misc_enggizmos_27:32:32:-22:0|tClose", 0, 998)
                player:GossipSendMenu(12, player, 35353)
            end
		end)
	end
    local cost6 = " (1x "..currencyNameSingular..")"
    local cost7 = " (2x "..currencyName..")"
    local cost8 = " (3x "..currencyName..")"
    local cost9 = " (4x "..currencyName..")"
    local cost10 = " (5x "..currencyName..")"
    
    if object == player or (VIPtime[player:GetGUIDLow()] and VIPtime[player:GetGUIDLow()] > os.time()) then
        cost6 = ""
        cost7 = ""
        cost8 = ""
        cost9 = ""
        cost10 = ""
    end
    
    player:GossipClearMenu()
    
    if player:GetLevel() == 80 then
        player:GossipMenuAddItem(0, "|TINTERFACE/ICONS/achievement_level_80:32:32:-22:0|tNo services available\n \nThere are no experience services available at level 80.\n \n ", 0, 999)
    else
        player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/spell_fire_burningspeed:32:32:-22:0|tYour experience rate is: x"..currentRate, 0, 999)
        player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x1", 0, 1, false, "Are you sure you want to change your experience rate to: x1?")
        player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x2", 0, 2, false, "Are you sure you want to change your experience rate to: x2?")
        player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x3", 0, 3, false, "Are you sure you want to change your experience rate to: x3?")
        player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x4", 0, 4, false, "Are you sure you want to change your experience rate to: x4?")
        player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x5", 0, 5, false, "Are you sure you want to change your experience rate to: x5?")
        player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x6"..cost6, 0, 6, false, "Are you sure you want to change your experience rate to: x6?")
        player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x7"..cost7, 0, 7, false, "Are you sure you want to change your experience rate to: x7?")
        player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x8"..cost8, 0, 8, false, "Are you sure you want to change your experience rate to: x8?")
        player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x9"..cost9, 0, 9, false, "Are you sure you want to change your experience rate to: x9?")
        player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x10"..cost10, 0, 10, false, "Are you sure you want to change your experience rate to: x10?")
    end
    if not (object == player) then
        player:GossipMenuAddItem(0, "|TINTERFACE/ICONS/inv_misc_enggizmos_27:32:32:-22:0|tClose", 0, 998)
        player:GossipSendMenu(12, object)
    else
        player:GossipMenuAddItem(0, "|TINTERFACE/ICONS/inv_misc_enggizmos_27:32:32:-22:0|tClose", 0, 998)
        player:GossipSendMenu(12, player, 35353)
    end
end 

local function OnSelectXP(event, player, object, sender, intid, code, menu_id)
    local currentRate = XPCache[player:GetGUIDLow()] or 1
    if intid == 999 then
        OnXPRateChanger(event, player, object)
    elseif intid == 998 then
        player:GossipComplete()
    elseif intid < 11 then
        if currentRate > intid then
            XPCache[player:GetGUIDLow()] = intid
            CharDBExecute("REPLACE INTO character_rate_xp (guid, rate) VALUES ('"..player:GetGUIDLow().."', '"..intid.."')")
            messagestring = "Congratulations, you changed your experience rate to: x"..intid
            if object == player then
                player:SendBroadcastMessage(messagestring)
            else
                object:SendUnitWhisper(messagestring, 0, player)
            end
            player:CastSpell(player, 47292, true)
            player:GossipComplete()
            return
        elseif intid > 5 and not (VIPtime[player:GetGUIDLow()] and (VIPtime[player:GetGUIDLow()] > os.time())) then -- Charge if higher tier XP and not VIP
            if not player:HasItem(currencyID, intid - 5) then
                player:GossipComplete()
                messagestring = "You don't have sufficient funds!"
                if object == player then
                    player:SendBroadcastMessage(messagestring)
                else
                    object:SendUnitWhisper(messagestring, 0, player)
                end
                return
            end
            player:RemoveItem(currencyID, intid - 5)
        end
        XPCache[player:GetGUIDLow()] = intid
        CharDBExecute("REPLACE INTO character_rate_xp (guid, rate) VALUES ('"..player:GetGUIDLow().."', '"..intid.."')")
        messagestring = "Congratulations, you changed your experience rate to: x"..intid
        if object == player then
            player:SendBroadcastMessage(messagestring)
        else
            object:SendUnitWhisper(messagestring, 0, player)
        end
        player:CastSpell(player, 47292, true)
    end
    player:GossipComplete()
end

local function OnGiveXP(event, player, amount, victim)
    if XPCache[player:GetGUIDLow()] then
        amount = amount * XPCache[player:GetGUIDLow()]
        return amount
    end
end 

local function LoadXPCache()
    local result = CharDBQuery("SELECT guid, rate FROM character_rate_xp")
    if result then
        repeat
            XPCache[result:GetUInt32(0)] = result:GetUInt8(1)
        until not result:NextRow()
    end
end

local function onXPCommand(event, player, command)
    if command:match("^%s*xpchangemenu%s+(%d+)%s*$") then
        local _, _, timestring = command:find("^%s*xpchangemenu%s+(%d+)%s*$")
        local verificationtime = tonumber(timestring)
        if verificationtime and verificationtime == os.time() then
            OnXPRateChanger(event, player, player)
        end
        return false
    end
end

------------------------------------------------------------------------------------------------
-- VIP commands start
------------------------------------------------------------------------------------------------

local function HandleVIPCommands(event, player, command)
    if not command:lower():find("^vip") then
        return
    end
    
    if not VIPtime[player:GetGUIDLow()] then
		local name = player:GetName()
		CharDBQueryAsync("SELECT VIPTIME FROM ACCOUNTS_VIP WHERE ACCOUNT = " .. player:GetAccountId() .. ";", function(result)
			player = GetPlayerByName(name)
			if result then
				VIPtime[player:GetGUIDLow()] = result:GetUInt32(0)

                local cmd = command:lower()
                
                if cmd == "vip repair" then
                    player:DurabilityRepairAll(false, 0, false)
                    player:SendBroadcastMessage("All items have been repaired.")
                    return false
                    
                elseif cmd == "vip mail" then
                    player:SendShowMailBox(player:GetGUID())
                    return false
                    
                elseif cmd == "vip bank" then
                    player:SendShowBank(player)
                    return false
                    
                elseif cmd == "vip xp" then
                    player:RunCommand("xpchangemenu "..os.time())
                    return false
                end
			else
				VIPtime[player:GetGUIDLow()] = os.time()
                player:SendBroadcastMessage("You don't have an active Yggdrasil VIP subscription.")
			end
		end)
        return false
	end

    if not (VIPtime[player:GetGUIDLow()] and VIPtime[player:GetGUIDLow()] > os.time()) then
        player:SendBroadcastMessage("You don't have an active Yggdrasil VIP subscription.")
        return false
    end

    local cmd = command:lower()
    
    if cmd == "vip repair" then
        player:DurabilityRepairAll(false, 0, false)
        player:SendBroadcastMessage("All items have been repaired.")
        return false
        
    elseif cmd == "vip mail" then
        player:SendShowMailBox(player:GetGUID())
        return false
        
    elseif cmd == "vip bank" then
        player:SendShowBank(player)
        return false
        
    elseif cmd == "vip xp" then
		player:RunCommand("xpchangemenu "..os.time())
        return false
    end
end

RegisterPlayerEvent(42, HandleVIPCommands)
------------------------------------------------------------------------------------------------
-- VIP commands end
------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------
-- XP rate changer event registrations
------------------------------------------------------------------------------------------------

LoadXPCache() -- Loads XPCache on script load (server startup/reload ELUNA)
RegisterPlayerEvent(12, OnGiveXP)
RegisterCreatureGossipEvent(190023, 1, OnXPRateChanger)
RegisterCreatureGossipEvent(190023, 2, OnSelectXP)
RegisterPlayerEvent(42, onXPCommand)
RegisterPlayerGossipEvent(35353, 2, OnSelectXP)

------------------------------------------------------------------------------------------------
-- End XP rate changer event registrations
------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------
-- Faction adjustment event registrations
------------------------------------------------------------------------------------------------

CacheCurrentInstances()
RegisterServerEvent(21, OnPlayerMapChange)

------------------------------------------------------------------------------------------------
-- End faction adjustment event registrations
------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------
-- Twiggy event registrations
------------------------------------------------------------------------------------------------

PopulateMorphCache()
RegisterPlayerEvent(3, OnPlayerLogin)
RegisterCreatureGossipEvent(23198, 1, TwiggyGossipHello)
RegisterCreatureGossipEvent(23198, 2, TwiggyGossipSelect)

------------------------------------------------------------------------------------------------
-- End Twiggy event registrations
------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------
-- Shadows event registrations
------------------------------------------------------------------------------------------------

SetActiveBots()
RegisterPlayerEvent(3, ShadowsLoginHook)
RegisterPlayerEvent(4, Logout)
RegisterPlayerEvent(19, OnWhisper)
RegisterServerEvent(21, OnPlayerMapEnter)
RegisterPlayerEvent(27, OnDisallowedZones)
RegisterPlayerEvent(42, OnBotCommand)
RegisterPlayerGossipEvent(200, 2, ShadowsGossipSelect)
RegisterGroupEvent(3, LeaveGroup)
RegisterGroupEvent(5, DisbandGroup)
RegisterPacketEvent(0x075, 5, UninviteGroup)
RegisterPacketEvent(0x076, 5, UninviteGroupGUID)
RegisterPacketEvent(0x0C7, 5, PacketTeleDelay)
RegisterPacketEvent(0x0C9, 5, PacketMoveDelay)
RegisterPacketEvent(0x0CA, 5, PacketMoveDelay)
RegisterPacketEvent(0x0CB, 5, PacketMoveDelay)

------------------------------------------------------------------------------------------------
-- End shadows event registrations
------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------
-- Account-wide currencies event registrations
------------------------------------------------------------------------------------------------

RegisterPlayerEvent(3, AccountWideCurrency) -- PLAYER_EVENT_ON_LOGIN
RegisterPlayerEvent(4, AccountWideCurrency) -- PLAYER_EVENT_ON_LOGOUT
RegisterPlayerEvent(25, AccountWideCurrency) -- EVENT_ON_SAVE

------------------------------------------------------------------------------------------------
-- End account-wide currencies event registrations
------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------
-- Token on login awarder event registrations
------------------------------------------------------------------------------------------------

RegisterPlayerEvent(3, TokensOnLogin)

------------------------------------------------------------------------------------------------
-- End token on login awarder event registrations
------------------------------------------------------------------------------------------------
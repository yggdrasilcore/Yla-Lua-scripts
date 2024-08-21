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
local VIPtime = {}
-- End VIP vars

-- Tables
local catCache, bearCache, birdCache, travelCache, owlCache, treeCache, aquaticCache = {}, {}, {}, {}, {}, {}, {}
local catCount, bearCount, birdCount, travelCount, owlCount, treeCount, aquaticCount = 0, 0, 0, 0, 0, 0, 0
local cacheChoice = {}
local intIdChoice = {}
local tickleCount = {}
local mailboxtime = {}


-- Constants
local cachePopulated

-- End tables

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
    local catResults = WorldDBQuery([[
       SELECT entry, name 
       FROM creature_template 
       WHERE (family = 2 
          OR ((name LIKE '%panther%' 
          OR name LIKE '%gondria%' 
          OR name LIKE '%loque%') 
          AND type = 1))
          AND name NOT LIKE '%(%'
          AND name NOT LIKE '%"%'
          AND name NOT LIKE '%UNUSED%'
          AND name NOT LIKE '%TEST%'
          AND name NOT LIKE '%STABLED%'
          AND name NOT LIKE '%TAMED%'
          AND name NOT LIKE '%TOTEM%'
    ]])
    if catResults then
        repeat
            local entry, name = catResults:GetUInt32(0), catResults:GetString(1)
            catCache[entry] = name
            catCount = catCount + 1
        until not catResults:NextRow()
    end

    local bearResults = WorldDBQuery([[
       SELECT entry, name 
       FROM creature_template 
       WHERE (family = 4 
          OR name LIKE '%arcturis%' 
          OR name LIKE '%grizzly cub%')
          AND name NOT LIKE '%(%'
          AND name NOT LIKE '%"%'
          AND name NOT LIKE '%UNUSED%'
          AND name NOT LIKE '%TEST%'
          AND name NOT LIKE '%STABLED%'
          AND name NOT LIKE '%TAMED%'
          AND name NOT LIKE '%TOTEM%'
    ]])
    if bearResults then
        repeat
            local entry, name = bearResults:GetUInt32(0), bearResults:GetString(1)
            bearCache[entry] = name
            bearCount = bearCount + 1
        until not bearResults:NextRow()
    end

    local birdResults = WorldDBQuery([[
       SELECT entry, name 
       FROM creature_template 
       WHERE (family IN (7, 26, 30, 33, 34, 37, 38) 
          OR ((name LIKE '%highperch%' 
          OR name LIKE '%wyvern%' 
          OR name LIKE '%heartrazor%') 
          AND type = 1))
          AND name NOT LIKE '%(%'
          AND name NOT LIKE '%"%'
          AND name NOT LIKE '%UNUSED%'
          AND name NOT LIKE '%TEST%'
          AND name NOT LIKE '%STABLED%'
          AND name NOT LIKE '%TAMED%'
          AND name NOT LIKE '%TOTEM%'
    ]])
    if birdResults then
        repeat
            local entry, name = birdResults:GetUInt32(0), birdResults:GetString(1)
            birdCache[entry] = name
            birdCount = birdCount + 1
        until not birdResults:NextRow()
    end
    
    local travelResults = WorldDBQuery([[
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
          OR name LIKE '%goat%' 
          OR name LIKE '%mustang%' 
          OR name LIKE '%buck%' 
          OR name LIKE '%ram%') 
          AND type = 1))
          AND name NOT LIKE '%(%'
          AND name NOT LIKE '%"%'
          AND name NOT LIKE '%UNUSED%'
          AND name NOT LIKE '%TEST%'
          AND name NOT LIKE '%STABLED%'
          AND name NOT LIKE '%TAMED%'
          AND name NOT LIKE '%TOTEM%'
    ]])
    if travelResults then
        repeat
            local entry, name = travelResults:GetUInt32(0), travelResults:GetString(1)
            travelCache[entry] = name
            travelCount = travelCount + 1
        until not travelResults:NextRow()
    end
    
    local owlResults = WorldDBQuery([[
       SELECT entry, name 
       FROM creature_template 
       WHERE (name LIKE '%owlkin%' 
          OR name LIKE '%wildkin%' 
          OR name LIKE '%owlbeast%' 
          OR name LIKE '%moonkin%')
          AND name NOT LIKE '%(%'
          AND name NOT LIKE '%"%'
          AND name NOT LIKE '%UNUSED%'
          AND name NOT LIKE '%TEST%'
          AND name NOT LIKE '%STABLED%'
          AND name NOT LIKE '%TAMED%'
          AND name NOT LIKE '%TOTEM%'
    ]])
    if owlResults then
        repeat
            local entry, name = owlResults:GetUInt32(0), owlResults:GetString(1)
            owlCache[entry] = name
            owlCount = owlCount + 1
        until not owlResults:NextRow()
    end
    
    local treeResults = WorldDBQuery([[
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
          OR name LIKE '%tender%')
          AND type = 4
          AND name NOT LIKE '%(%'
          AND name NOT LIKE '%"%'
          AND name NOT LIKE '%UNUSED%'
          AND name NOT LIKE '%TEST%'
          AND name NOT LIKE '%STABLED%'
          AND name NOT LIKE '%TAMED%'
          AND name NOT LIKE '%TOTEM%'
    ]])
    if treeResults then
        repeat
            local entry, name = treeResults:GetUInt32(0), treeResults:GetString(1)
            treeCache[entry] = name
            treeCount = treeCount + 1
        until not treeResults:NextRow()
    end
    
    local aquaticResults = WorldDBQuery([[
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
          AND name NOT LIKE '%UNUSED%'
          AND name NOT LIKE '%TEST%'
          AND name NOT LIKE '%STABLED%'
          AND name NOT LIKE '%TAMED%'
          AND name NOT LIKE '%TOTEM%'
    ]])
    if aquaticResults then
        repeat
            local entry, name = aquaticResults:GetUInt32(0), aquaticResults:GetString(1)
            aquaticCache[entry] = name
            aquaticCount = aquaticCount + 1
        until not aquaticResults:NextRow()
    end
end

local function ShowCategoryContents(player, creature, category, page)
	if intId then print(intId) end
	if page then print(page) end
    page = page or 1
    local itemsPerPage = 12
    local startIndex = (page - 1) * itemsPerPage + 1
    local endIndex = page * itemsPerPage
    player:GossipClearMenu()
    
    local cache = cacheChoice[player:GetGUIDLow()]
    
    local totalItems = 0
    for _ in pairs(cache) do
        totalItems = totalItems + 1
    end
    local itemCount = 0
    for entry, name in pairs(cache) do
        itemCount = itemCount + 1
        if itemCount >= startIndex and itemCount <= endIndex then
            player:GossipMenuAddItem(4, name, 0, 999)
        end
        if itemCount >= endIndex then
            break
        end
    end
    -- Add pagination buttons
    if page > 1 then
        player:GossipMenuAddItem(4, "Previous Page", 0, 997)
    end
    if endIndex < totalItems then
        player:GossipMenuAddItem(4, "Next Page", 0, 998)
    end
    player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 500)
    player:GossipSendMenu(1, creature, 60)
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
		player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 1)
	else 
		player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_holy_borrowedtime:32:32:-22:0|tVIP status: Off. Activate VIP?", 0, 20)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-22:0|tWhy should I get VIP?", 0, 19)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 1)
		print("No VIPTIME found for account " .. player:GetAccountId())
	end
	player:GossipSendMenu(1, creature, 60)
end

local function mainMenu(player, creature)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/ABILITY_DRUID_MANATREE:32:32:-22:0|tI'm Twiggy, your personal branch of\n         Yggdrasil! How can I help you?\n ", 0, 1)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tVIP options", 0, 2)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/INV_Misc_Coin_16:32:32:-22:0|tSee my currencies", 0, 3)
	player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_gem_diamond_07:32:32:-22:0|tExplore Yggdrasil's features", 0, 5)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_arcane_teleportdarnassus:32:32:-22:0|tLet's go to the Mall!", 0, 4)
    player:GossipSendMenu(1, creature, 60)
end

local function OnGossipHello(event, player, creature)
	if creature:GetOwnerGUID() == player:GetGUID() then
		mainMenu(player, creature)
		
		if not VIPtime[player:GetGUIDLow()] then
			local result = CharDBQuery("SELECT VIPTIME FROM ACCOUNTS_VIP WHERE ACCOUNT = " .. player:GetAccountId() .. ";")
			if result then
				VIPtime[player:GetGUIDLow()] = result:GetUInt32(0)
			else
				VIPtime[player:GetGUIDLow()] = os.time()
			end
		end
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
			creature:SendUnitSay("Help! "..player:GetName().." is tickling my stump, someone ask them to stop!", 0)
			tickleCount[player:GetGUIDLow()] = tickleCount[player:GetGUIDLow()] + 1
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

local function OnGossipSelect(event, player, creature, sender, intId, code)
	intIdChoice[player:GetGUIDLow()] = intId
    if intId == 1 then
		mainMenu(player, creature)
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
        player:GossipSendMenu(1, creature, 60)
	elseif intId == 49 then
		player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_fire_burningspeed:32:32:-22:0|tRates information:\n ", 0, 49)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/achievement_pvp_a_03:32:32:-22:0|tXP rates: \n \nFlexible between 1x and 10x. \nThe higher tiers cost Vote Tokens. \nVisit a Time-Warper at any starter zone, Orgrimmar or Stormwind to adjust your XP rate.\n ", 0, 49)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_coin_02:32:32:-22:0|tGold rates: 2x\n ", 0, 49)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/achievement_reputation_08:32:32:-22:0|tReputation rates: 2x\n ", 0, 49)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 5)
        player:GossipSendMenu(1, creature, 60)
	elseif intId == 55 then
		player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_arcane_teleportdarnassus:32:32:-22:0|tMall information:\n ", 0, 55)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/achievement_level_10:32:32:-22:0|tGeneral information: \n \n-Required level: 10 \n-Accessible from PvP areas: No.\n-Accessible in combat: No.\n-Mall teleport cooldown: 60 min\n ", 0, 55)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_gizmo_02:32:32:-22:0|tQuality of Life features: \n \n-Portals to all capitals \n-Training dummies\n-Profession trainers\n-Crafting corner\n ", 0, 55)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_helmet_89:32:32:-22:0|tVendor information: \n \n-Transmogrifyer\n-Transmog item vendor\n-Druid morph vendor\n-Demon pet morph vendor\n-Pet renamer\n-Hunter pet vendor\n-Feathers of Azeroth vendor\n-Vanity pets vendor\n-Currency Exchanger\n-Character services\n-Hierlooms\n-Flight paths vendor\n-And more!\n ", 0, 55)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 5)
        player:GossipSendMenu(1, creature, 60)
	elseif intId == 54 then
		player:GossipMenuAddItem(4, "|TInterface/ICONS/achievement_zone_easternkingdoms_01:32:32:-22:0|tAzeroth flight features:\n ", 0, 54)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_feather_13:32:32:-22:0|tThe Feathers of Azeroth: \n \nTo fly in Kalimdor and Eastern Kingdoms, you must buy the Feathers of Azeroth from the bird breeder at the Mall for 50 gold, given that you are already able to fly. This item lets you shapeshift into flight form regardless of your class.\n ", 0, 54)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_flower_02:32:32:-22:0|tGathering: \n \nThe Feathers of Azeroth permit gathering in the old world as if you were a druid; a gatherer's dream!\n ", 0, 54)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/Spell_magic_featherfall:32:32:-22:0|tIntegrated parachute: \n \nLike an engineer's rocket boots, the Feathers have a slight failure rate. Worry not, the integrated parachute will keep you safe. \n ", 0, 54)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_druid_flightform:32:32:-22:0|tSafety net: \n \nWhen falling at altitudes of 3 yards or move above the ground of an obstacle, the Feathers will automatically catch you. \n ", 0, 54)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 5)
        player:GossipSendMenu(1, creature, 60)
	elseif intId == 56 then
		player:GossipMenuAddItem(4, "|TInterface/ICONS/Ability_Mount_RidingHorse:32:32:-22:0|tMount and companion features:\n ", 0, 53)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_mount_gyrocoptor:32:32:-22:0|tAccount-shared: \n \nAll mounts are automatically synchronized across your eligible characters. All companions are account-bound and can be sent to your other characters.\n ", 0, 53)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_pet_babyblizzardbear:32:32:-22:0|tCompanion Carrier: \n \nAt the mall, the Companion Carrier breeds companions for players to purchase for 50 Vote Tokens or 5 Community Tokens each.\n ", 0, 52)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 5)
        player:GossipSendMenu(1, creature, 60)
	elseif intId == 53 then
		player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_coin_02:32:32:-22:0|tEconomy services:\n ", 0, 53)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/Inv_misc_bag_07:32:32:-22:0|tAuction house features: \n \nCross faction: Both factions can trade on the same auction house.\n \nAuction house bot: Pbtwelve, our beloved auction house bot, works tirelessly to keep the supply high.\n \nReduced auction cut: The auction house charges an 80% reduced cut on posting auctions.\n ", 0, 53)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_frostemblem_01:32:32:-22:0|tTertiary currency exchanger: \n \nAt the Mall, the Exchanger offers currency exchange services for Vote Tokens and can trade them for Emblems of Triumph (1:1), Emblems of Frost (5:1), or Transmog Tokens (10:1).\n ", 0, 53)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 5)
        player:GossipSendMenu(1, creature, 60)
	elseif intId == 52 then
		player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_nature_groundingtotem:32:32:-22:0|t Available pet services at the Mall:\n ", 0, 52)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_scroll_11:32:32:-22:0|tRename demons: \n \nFor the mere price of 30 Vote Tokens or 3 Community Tokens, you can pick any morphologically correct Demonic name for your demons.\n ", 0, 52)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_shadow_demonictactics:32:32:-22:0|tDemon morphs: \n \nFor 50 Vote Tokens or 5 Community Tokens, youy other race compatible with your class.\n ", 0, 52)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_tracking:32:32:-22:0|tHunter pet beastmaster: \n \nFor 100 Vote Tokens or 10 Community Tokens, you can purchase virtually any hunter pet you want.\n ", 0, 52)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 5)
        player:GossipSendMenu(1, creature, 60)
	elseif intId == 51 then
		player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_nature_groundingtotem:32:32:-22:0|t Available customizations at the Mall:\n ", 0, 51)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_scroll_11:32:32:-22:0|tRename: \n \nFor the mere price of 50 Vote Tokens or 5 Community Tokens, you can select any name you want.\n ", 0, 51)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_throwingknife_02:32:32:-22:0|tCustomize: \n \nFor 50 Vote Tokens or 5 Community Tokens, you can get your character a makeover.\n ", 0, 51)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/achievement_pvp_a_h:32:32:-22:0|tChange faction: \n \nFor 100 Vote Tokens or 10 Community Tokens, you can change your faction.\n ", 0, 51)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/achievement_character_orc_male:32:32:-22:0|tChange race: \n \nFor 150 Vote Tokens or 15 Community Tokens, you can reroll your race to any other race compatible with your class.\n ", 0, 51)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 5)
        player:GossipSendMenu(1, creature, 60)
	elseif intId == 50 then
		player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_druid_travelform:32:32:-22:0|tDruid shapeshifts: \n \nThrough harnessing the powers of ancient Kaldorei magic, druids can learn the form of many unique beasts to apply them onto their own beastial forms. Note: Some creatures share the same creature model. Each model can only be claimed once.\n \nClick here for a full list of applicable creatures. \n ", 0, 500)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_helmet_89:32:32:-22:0|tTransmogrifyer: \n \nYggdrasil sports a transmogrifyer from the Cataclysm era, where you can apply the look of one item onto others by having both items in your bags and paying a transmogrifyer to apply the new look. Transmogrifyers are at the mall and all capital cities' enchanting trainers.\n ", 0, 50)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_bag_07_red:32:32:-22:0|tTransmog Item Vendor: \n \nThis mall vendor can search for almost any item in the world under item level 200 and sell it to you for Transmog Tokens.\n ", 0, 50)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/Inv_misc_coin_07:32:32:-22:0|tTransmog Tokens: \n \nBy completing quests while at level 80 and killing raid/dungeon bosses while the player is at level 80 and the boss is level 71 or higher, you earn Transmog Tokens. These can be used to buy items at the Transmog Item Vendor.\n ", 0, 50)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 5)
        player:GossipSendMenu(1, creature, 60)
	elseif intId == 500 then
		if not cachePopulated then
			PopulateMorphCache()
			cachePopulated = true
		end
		player:GossipMenuAddItem(4, "|TInterface/ICONS/ABILITY_Druid_CatForm:32:32:-22:0|tCat Forms: " .. catCount, 0, 501)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_racial_bearform:32:32:-22:0|tBear Forms: " .. bearCount, 0, 502)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/ABILITY_Druid_FlightForm:32:32:-22:0|tFlight Forms: " .. birdCount, 0, 503)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/ABILITY_Druid_TravelForm:32:32:-22:0|tTravel Forms: " .. travelCount, 0, 504)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_druid_improvedmoonkinform:32:32:-22:0|tMoonkin Form: " .. owlCount, 0, 505)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_druid_treeoflife:32:32:-22:0|tTree Form: " .. treeCount, 0, 506)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/ABILITY_Druid_AquaticForm:32:32:-22:0|tAquatic Forms: " .. aquaticCount, 0, 507)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 50)
		player:GossipSendMenu(1, creature, 60)
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
		player:GossipMenuAddItem(4, "|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-22:0|tWhy should I get VIP?\n \nAs VIP, you get access to free repairs, banking, mailing, an auction house, and a vendor to sell your accumulated items anywhere you are!\n ",  0, 19)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 2)
        player:GossipSendMenu(1, creature, 60)
	elseif intId == 20 then
        player:GossipMenuAddItem(4, "|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-22:0|tFor how long do you want VIP?", 0, 20)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Inv_misc_coin_08:32:32:-22:0|t7 days (7 Community Tokens)", 0, 21)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Inv_misc_coin_08:32:32:-22:0|t14 days (12 Community Tokens)", 0, 22)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/Inv_misc_coin_08:32:32:-22:0|t21 days (15 Community Tokens)", 0, 23)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 2)
        player:GossipSendMenu(1, creature, 60)
	elseif intId == 21 then
		if player:HasItem(386440,7) then
			player:RemoveItem(386440,7)
			VIPtime[player:GetGUIDLow()] = (os.time() + 7 * 24 * 60 * 60)
			
			CharDBExecute("INSERT INTO ACCOUNTS_VIP (ACCOUNT, VIPTIME) VALUES (" .. player:GetAccountId() .. ", " .. (os.time() + 7 * 24 * 60 * 60) .. ") ON DUPLICATE KEY UPDATE VIPTIME = VALUES(VIPTIME);")

			VIPmenu(player, creature)
		else 
			player:SendAreaTriggerMessage("You don't have enough Community Tokens.")
		end
	elseif intId == 22 then
		if player:HasItem(386440,12) then
			player:RemoveItem(386440,12)
			VIPtime[player:GetGUIDLow()] = (os.time() + 14 * 24 * 60 * 60)
			
			CharDBExecute("INSERT INTO ACCOUNTS_VIP (ACCOUNT, VIPTIME) VALUES (" .. player:GetAccountId() .. ", " .. (os.time() + 14 * 24 * 60 * 60) .. ") ON DUPLICATE KEY UPDATE VIPTIME = VALUES(VIPTIME);")

			VIPmenu(player, creature)
		else 
			player:SendAreaTriggerMessage("You don't have enough Community Tokens.")
		end
	elseif intId == 23 then
		if player:HasItem(386440,15) then
			player:RemoveItem(386440,15)
			VIPtime[player:GetGUIDLow()] = (os.time() + 21 * 24 * 60 * 60)
			
			CharDBExecute("INSERT INTO ACCOUNTS_VIP (ACCOUNT, VIPTIME) VALUES (" .. player:GetAccountId() .. ", " .. (os.time() + 21 * 24 * 60 * 60) .. ") ON DUPLICATE KEY UPDATE VIPTIME = VALUES(VIPTIME);")
			
			VIPmenu(player, creature)
		else 
			player:SendAreaTriggerMessage("You don't have enough Community Tokens.")
		end
		
    elseif intId == 3 then
		local CommunityToken
		local TransmogToken 
		local VoteToken
		
        player:GossipMenuAddItem(4, "|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-22:0|tWhat can I use my currencies for?", 0, 30)
		
		local CommunityTokenQuery = CharDBQuery("SELECT count FROM accountwide_currency WHERE accountId = " .. player:GetAccountId() .. " AND currencyId = " .. 386440)
		
		if not CommunityTokenQuery then
			CommunityToken = 0
		else 
			CommunityToken = CommunityTokenQuery:GetUInt32(0)
		end
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Inv_misc_coin_08:32:32:-22:0|tCommunity Tokens: "..CommunityToken, 0, 3)
		
		local TransmogTokenQuery = CharDBQuery("SELECT count FROM accountwide_currency WHERE accountId = " .. player:GetAccountId() .. " AND currencyId = " .. 37742)
		if not TransmogTokenQuery then 
			TransmogToken = 0
		else
			TransmogToken = TransmogTokenQuery:GetUInt32(0)
		end
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Inv_misc_coin_07:32:32:-22:0|tTransmog Tokens: "..TransmogToken, 0, 3)
		
		local VoteTokenQuery = CharDBQuery("SELECT count FROM accountwide_currency WHERE accountId = " .. player:GetAccountId() .. " AND currencyId = " .. 20880)
		if not VoteTokenQuery then
			VoteToken = 0
		else
			VoteToken = VoteTokenQuery:GetUInt32(0)
		end
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Inv_bijou_gold:32:32:-22:0|tVote Tokens: "..VoteToken, 0, 3)
		
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 1)
        player:GossipSendMenu(1, creature, 60)
	elseif intId == 30 then
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Inv_misc_coin_08:32:32:-22:0|tCommunity Token: \n \nEarned through helping build the Yggdrasil community, these tokens can be traded for vanity pets, mounts, account services and more at the mall, or VIP services with Twiggy.", 0, 30)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Inv_misc_coin_07:32:32:-22:0|tTransmog Token: \n \nThis currency can be spent at the transmog item vendor to buy items under item level 200 that you can then later wear as gear or transmog onto your higher item level gear. It is earned by completing end-game quests or slaying bosses above level 71 while at level 80", 0, 30)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Inv_bijou_gold:32:32:-22:0|tVote Token: \n \nEarned through voting for the server, these tokens can be predominantly exchanged for vanity items at the mall, or traded down to Emblems of Frost or Emblems of Triumph at the Mall's exchanger.", 0, 30)	
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 3)
        player:GossipSendMenu(1, creature, 60)
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
			local mailbox = player:SummonGameObject(176404, player:GetX(), player:GetY()+2, player:GetZ(), player:GetO())
		
			mailbox:RegisterEvent(function(eventid, delay, repeats, mailbox)
				mailbox:Despawn()
			end, 45000, 1)
			
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
	if not VIPtime[player:GetGUIDLow()] then
		local result = CharDBQuery("SELECT VIPTIME FROM ACCOUNTS_VIP WHERE ACCOUNT = " .. player:GetAccountId() .. ";")
		if result then
			VIPtime[player:GetGUIDLow()] = result:GetUInt32(0)
		else
			VIPtime[player:GetGUIDLow()] = os.time()
		end
	end
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

RegisterPlayerEvent(3, OnPlayerLogin)
RegisterCreatureGossipEvent(23198, 1, OnGossipHello)
RegisterCreatureGossipEvent(23198, 2, OnGossipSelect)
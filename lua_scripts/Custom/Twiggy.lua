local Multistate = require("Multistate")
local EMQ = require("EMQ")

-- Runs a .command in the global state (ChatHandler parsing must not run on map
-- threads): directly in compatibility mode, otherwise forwarded via EMQ.
EMQ.RegisterQueue("TwiggyRunCommand", function(player, data)
    if player and data and data.cmd then
        player:RunCommand(data.cmd)
    end
end)

-- Mall teleport runs on a world verdict: map closes gossip first, world
-- owns the cooldown and answers allow/deny.
local HandleTwiggyWorld
local HandleTwiggyView
EMQ.RegisterQueue("TwiggyToWorld", function(player, data)
    if HandleTwiggyWorld and (Multistate.IsWorld() or Multistate.IsCompat()) then
        HandleTwiggyWorld(player, data)
    end
end)
EMQ.RegisterQueue("TwiggyToMap", function(player, data)
    if HandleTwiggyView and (Multistate.IsMap() or Multistate.IsCompat()) then
        HandleTwiggyView(player, data)
    end
end)

local function TwiggyRunCommand(player, cmd)
    if not player or not cmd then
        return
    end
    if Multistate.IsCompat() or Multistate.IsWorld() then
        player:RunCommand(cmd)
    else
        player:SendEMQMessage("TwiggyRunCommand", { cmd = cmd })
    end
end
-- Welcome to the Twiggy script :)

-- Start Mall TP vars
local ITEM_ID = 37430 -- Old mall stone. Currently used as index for mall CD in DB
local COOLDOWN = 30 * 60 -- 30 minutes
local MAP_ID = 37
local X = 888.082
local Y = 119.53
local Z = 288.031
local ORIENTATION = 1.09494
-- End Mall TP vars

-- VIP vars
local vendorID = 26300
local vendorCD = 15 * 60 -- 15 minutes in seconds
local VIPVendorCD = {}
local VIPVendorDuration = 3 * 60 * 1000 -- VIP vendor lasts for 1 minute
local timeMessage = 0

-- End VIP vars

-- Twiggy Tables
local cacheChoice = {}
local intIdChoice = {}
local tickleCount = {}
mailboxtime = {}

-- End Twiggy tables


-- Initiates VIP table if not already present
AuthDBExecute("CREATE TABLE IF NOT EXISTS accounts_vip (ACCOUNT INT(6) NOT NULL PRIMARY KEY, VIPTIME INT(11) NOT NULL);")

-- Prepares Twiggy in the database
--WorldDBExecute("UPDATE creature_template_model SET CreatureDisplayID = 13098, DisplayScale = 0.33 WHERE CreatureID = 23198;")
--WorldDBExecute("UPDATE creature_template SET name = 'Twiggy', npcflag = 2097153, scale = 0.23 WHERE entry = 23198;")
--WorldDBExecute("UPDATE item_template SET description = 'Teaches you how to summon Twiggy, your personal branch of Yggdrasil.', name = 'Twiggy''s Wooden Chip' WHERE entry = 32498;")

-- Prepares VIP trash vendor
--WorldDBExecute("UPDATE creature_template SET name = 'All-Buying Hobgoblin Repair' WHERE entry = 26309;")
--WorldDBExecute("UPDATE creature_template SET name = 'All-Buying Hobgoblin' WHERE entry = 26300;")

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
	if Multistate.GetData(player, "VIPTime") and Multistate.GetData(player, "VIPTime") > os.time() then
		local vipTime = Multistate.GetData(player, "VIPTime")
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

		player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_holy_borrowedtime:32:32:-22:0|tVIP status: On (" .. timeMessage .. ")", 0, 2)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_rune_07:32:32:-22:0|tVIP extension", 0, 20)
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
    player:GossipMenuAddItem(4, "|TInterface/ICONS/ABILITY_DRUID_MANATREE:32:32:-22:0|tI'm Twiggy, your own branch of\n         Yggdrasil! How can I help you?\n ", 0, 1)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tVIP options", 0, 2)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_groupneedmore:32:32:-22:0|tRAF menu", 0, 6)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/INV_Misc_Coin_16:32:32:-22:0|tSee my currencies", 0, 3)
    if player:HasItem(20739) then
        player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_feather_13:32:32:-22:0|tManage Feathers of Azeroth", 0, 7)
	end
    if (player:GetMapId() ~= 609)
    and (player:GetLevel() >= minShadowsLevel)
    and (player:GetQuestStatus(30000) == 6)
    then
        player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_holy_prayerofshadowprotection:32:32:-22:0|tManage Shadows", 0, 8)
	end
    player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_gem_diamond_07:32:32:-22:0|tExplore Yggdrasil's features", 0, 5)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_arcane_teleportdarnassus:32:32:-22:0|tTeleport to mall", 0, 4, false, "Are you sure you want to teleport to the mall?\n \nThis will induce a 30-minute teleport cooldown.")
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

HandleTwiggyWorld = function(player, data)
    if not player or not data or data.op ~= "malltele" then return end
    if player:GetMapId() == MAP_ID then
        player:SendAreaTriggerMessage("You are already at the mall.")
        return
    end
    local remaining = (Multistate.GetData(player, "MallTeleCD") or 0) - os.time()
    if remaining > 0 then
        player:SendAreaTriggerMessage("Your mall teleport is on cooldown for " .. math.floor((remaining % 3600) / 60) .. " minutes and " .. math.floor(remaining % 60) .. " seconds.")
        return
    end
    Multistate.SetData(player, "MallTeleCD", os.time() + COOLDOWN)
    player:SendEMQMessage("TwiggyToMap", { map = MAP_ID, x = X, y = Y, z = Z, o = ORIENTATION })
end

HandleTwiggyView = function(player, data)
    if not player or not data or not data.map then return end
    player:Teleport(data.map, data.x, data.y, data.z, data.o)
end

local function TwiggyGossipSelect(event, player, creature, sender, intId, code)
	intIdChoice[player:GetGUIDLow()] = intId
    if intId == 1 then
		mainMenu(player, creature)
	elseif intId == 24 then
		TwiggyRunCommand(player, "xpchangemenu "..os.time())
	elseif intId == 8 then
		TwiggyRunCommand(player, "shadowsmenu")
	elseif intId == 7 then
		TwiggyRunCommand(player, "choosestandardfeathers")
	elseif intId == 6 then
		TwiggyRunCommand(player, "rafmenu")
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
		player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_feather_13:32:32:-22:0|tThe Feathers of Azeroth: \n \nTo fly in Kalimdor and Eastern Kingdoms, you must buy the Feathers of Azeroth from the bird breeder at the Mall, given that you are already able to fly.\n ", 0, 54)
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
		player:GossipMenuAddItem(4, "|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-22:0|tWhy should I get VIP?\n \nAs VIP, Twiggy can provide you with free repairs, free XP rate changes on all your characters, banking, portable VIP mailbox, the auction house, and a vendor to sell your accumulated items anywhere you are.\n \nYou can also access your bank, portable VIP mailbox, repair your items, and change your XP through commands .vip bank, .vip mail, vip. repair, and .vip xp.\n \nFurthermore, you can control up to "..maxVIPCount.." shadows with VIP, and your shadows will repair automatically on resurrecting, as opposed to "..maxBotCount.." shadows and manual repairs.\n \n ",  0, 19)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 2)
        player:GossipSendMenu(12, creature, 60)
	elseif intId == 20 then
        player:GossipMenuAddItem(4, "|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-22:0|tChoose duration\n \nHow many days of VIP do you want to add?\n ", 0, 20)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_rune_07:32:32:-22:0|t7 days (7 Community Tokens)", 0, 21, false, "Are you sure you want to purchase 7 days of VIP for 7 Community Tokens?")
        player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_rune_07:32:32:-22:0|t14 days (12 Community Tokens)", 0, 22, false, "Are you sure you want to purchase 14 days of VIP for 12 Community Tokens?")
        player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_rune_07:32:32:-22:0|t21 days (15 Community Tokens)", 0, 23, false, "Are you sure you want to purchase 21 days of VIP for 15 Community Tokens?")
        player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_rune_07:32:32:-22:0|t31 days (20 Community Tokens)", 0, 25, false, "Are you sure you want to purchase 31 days of VIP for 20 Community Tokens?")
		player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 2)
        player:GossipSendMenu(12, creature, 60)
    elseif intId == 21 or intId == 22 or intId == 23 or intId == 25 then
        local costs = {[21]=7, [22]=12, [23]=15, [25]=20}
        local durations = {[21]=7, [22]=14, [23]=21, [25]=31}
        if player:HasItem(19322, costs[intId]) then
            player:RemoveItem(19322, costs[intId])
            local newTime = math.max(os.time(), Multistate.GetData(player, "VIPTime") or 0) + durations[intId] * 24 * 60 * 60
            Multistate.SetData(player, "VIPTime", newTime)
            AuthDBExecute("INSERT INTO accounts_vip (account, viptime) VALUES (" .. player:GetAccountId() .. ", " .. newTime .. ") ON DUPLICATE KEY UPDATE VIPTIME = VALUES(VIPTIME);")
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
			player:GossipComplete()
			player:SendEMQMessage("TwiggyToWorld", { op = "malltele", playerName = player:GetName() })
			return true
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
        player:SendTaxiMenu(creature) -- Disabled, doesn't work
    elseif intId == 16 then
        player:SendTrainerList(creature) -- Disabled, doesn't work
    elseif intId == 17 then
		
		local cooldownEnd = VIPVendorCD[player:GetGUIDLow()] or 0
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
			vendor:SetFacingToObject(player)
			vendor:SendUnitSay("Ah, another potential treasure arrives! Let's see what you've brought, "..player:GetName().."!",0)
			
			vendor:RegisterEvent(function(eventId, delay, repeats, creature)
				creature:SetRooted(false)
			end, 5000, 1)
			
			vendor:RegisterEvent(function(eventId, delay, repeats, creature)
				creature:SetRooted(true)
				creature:PerformEmote(3)
				creature:SendUnitSay("Until next time, when your trash is truly treasure.",0)
			end, VIPVendorDuration-3000, 1)
			
			VIPVendorCD[player:GetGUIDLow()] = cooldownEnd
		end
		
		VIPmenu(player, creature)	
		
	elseif intId == 18 then
        player:SendAuctionMenu(creature)
    end
end

local function OnPlayerLogin(event, player)
    if player:HasItem(32498) or player:HasSpell(40405) then
        return
    else
        player:AddItem(32498, 1)
    end
end

------------------------------------------------------------------------------------------------
-- Twiggy event registrations
------------------------------------------------------------------------------------------------

RegisterPlayerEvent(3, OnPlayerLogin)
RegisterCreatureGossipEvent(23198, 1, TwiggyGossipHello)
RegisterCreatureGossipEvent(23198, 2, TwiggyGossipSelect)

------------------------------------------------------------------------------------------------
-- End Twiggy event registrations
------------------------------------------------------------------------------------------------

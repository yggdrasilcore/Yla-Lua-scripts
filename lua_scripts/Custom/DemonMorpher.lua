-- Welcome to mostly nick's Eluna demon morph module for AzerothCore :)
-- This module lets Warlocks kill demons and claim their models to apply on their own summoned demons
-- It is demo, ie. *not* a finished product, but it works out of the box.

-----------------------------------------------------------------------------------------
-- Config: 
-----------------------------------------------------------------------------------------

-- Should the module create the morph table, vendor, and item in the database for us?
local MakeMorphTable 	= true
local MakeMorphItem		= true
local MakeMorphVendor	= true

-- Morph vars
local ITEM_ID 				= 5041	-- This is the item ID used to open the morph menu and apply/remove morphs from your demons. Default: 5041, which matches the item_template replace in MakeMorphItem. 
local MorphApplicationDelay = 15 	-- We can't apply the display ID immediately on pet spawn, so we're doing it with a short delay, in ms, instead.
local MaxMorphSkill 		= 100	-- Can be used to award players on gathering more morphs, increase/decrease as you see fit. This isn't a hard cap on max number of gatherable morphs
local MorphReqEliteandRare 	= 50 	-- Elite and rare creatures require a minimum proficiency (morph count) of 50 by default

-- Vendor vars
local NPC_ID 		= 190087 	-- Change npc ID to use custom NPC. Default: 190087, matches MakeMorphVendor inserts.
local ChargeTokens 	= false		-- false means free
local TokenID 		= 12345		-- Replace with your own Token's Item ID if ChargeTokens = true
local TokenPrice 	= 10		-- Number of custom Tokens to charge


-----------------------------------------------------------------------------------------
-- End config 
-----------------------------------------------------------------------------------------

-- Add more creatures by altering the below tables
local familyNames = {
    [15] = "Felhunter",
    [16] = "Voidwalker",
    [17] = "Succubus",
    [19] = "Doomguard",
    [23] = "Imp",
    [29] = "Felguard",
    [30] = "Infernal"
}

local customFamilyNames = {
    ["wrathwalker"] = 29,
    ["Wrathguard"] = 29,
    ["Wrath Master"] = 29,
    ["Reth'Hedron"] = 29,
    ["Death's Might"] = 29,
    ["Illidari Centurion"] = 29,
    ["Illidari Nightlord"] = 29,
    ["Illidan Stormrage"] = 29,
    ["Baelmon"] = 29,
    ["Shocktrooper"] = 29,
    ["Dreadwarden"] = 29,
    ["Jaraxxus"] = 29,
    ["Sathrovarr"] = 29,
    ["jaeden"] = 29,
    ["Terrormaster"] = 29, --This looks like a Doomguard but no one uses that so let's put it as Felguard mog
    ["Terrorfiend"] = 29, --This looks like a Doomguard but no one uses that so let's put it as Felguard mog
    ["Dreadbringer"] = 29, --This looks like a Doomguard but no one uses that so let's put it as Felguard mog
    ["Illidari Fearbringer"] = 29, --This looks like a Doomguard but no one uses that so let's put it as Felguard mog
    ["Terrordar"] = 29, --This looks like a Doomguard but no one uses that so let's put it as Felguard mog
    ["Soldier of Terror"] = 29, --This looks like a Doomguard but no one uses that so let's put it as Felguard mog
    ["Terrorguard"] = 29, --This looks like a Doomguard but no one uses that so let's put it as Felguard mog
    ["Lothros"] = 29,
    ["Demos"] = 29,
    ["Hellion"] = 29,
    ["Anger Guard"] = 29,
    ["Terror-fire"] = 29,
    ["Terrorslayer"] = 29,
    ["Hederine Slayer"] = 29,
    ["Furnace Guard"] = 29,
    ["Vorakem"] = 29,
    ["Dread Tactician"] = 29,
    ["Jerrikar"] = 29,
    ["Satyr"] = 29,
    ["Felmusk"] = 29,
    ["Jadefire"] = 29,
    ["Xavathras"] = 29,
    ["Fel Handler"] = 29,
    ["Forge Camp Legionnaire"] = 29,
    ["Wrath Herald"] = 29,
    ["Wrath Enforcer"] = 29,
    ["Fel Soldier"] = 29,
    ["Dreadlord"] = 29,
    ["Dreadcaller"] = 29,
    ["Manahound"] = 15,
    ["Netherhound"] = 15,
    ["Fel Guardhound"] = 15,
    ["Felstalker"] = 15,
    ["Felboar"] = 15,
    ["Helboar"] = 15,
    ["hound"] = 15,
    ["Mage Slayer"] = 15,
    ["Felstalker"] = 15,
    ["Collidus"] = 15,
    ["Voidcaller"] = 16,
    ["Voidhunter"] = 16,
    ["Voidwalker"] = 16,
    ["Tainted Arcane Wrath"] = 16,
    ["Nexus Terror"] = 16,
    ["Crazed Mana-Surge"] = 16,
    ["Arcane Devourer"] = 16,
    ["Arcanimus"] = 16,
    ["Manawraith"] = 16,
    ["Tainted Arcane Wraith"] = 16,
    ["Doomwhisperer"] = 17,
    ["Sathal"] = 17,
    ["Deathwhisperer"] = 17,
    ["Irespeaker"] = 17,
    ["Painmistress"] = 17,
    ["Hederine Initiate"] = 17,
    ["Priestess"] = 17,
    ["Mother Shahraz"] = 17,
    ["Prophetess"] = 17,
    ["Wrath Speaker"] = 17,
    ["Painlasher"] = 17,
    ["Yalqiz"] = 17,
    ["Sister"] = 17,
    ["Fel Sprite"] = 23,
    ["Shadow Sprite"] = 23,
    ["Dark Sprite"] = 23,
    ["Vile Sprite"] = 23,
    ["Threggil"] = 23,
    ["Flamekin Sprite"] = 23,
    ["Heckling Fel Sprite"] = 23,
    ["Rascal Sprite"] = 23,
    ["Imp"] = 23,
    ["Poison Sprite"] = 23,
    ["Grell"] = 23,
    ["Illidari Agonizer"] = 23,
    ["Vile Familiar"] = 23,
    ["Kraator"] = 30,
    ["Abyssal Flamebringer"] = 30,
    ["Infernal"] = 30,
    ["Supremus"] = 30,
    ["Abyssal Flamewalker"] = 30
}


if not (GetCoreName() == "AzerothCore") then
	print("[Demon Morph Module]: Incompatible core detected. This module only works on AzerothCore as it requires RegisterPlayerEvent PLAYER_EVENT_ON_PET_ADDED_TO_WORLD.")
	return
end

if MakeMorphTable then
	CharDBExecute("CREATE TABLE IF NOT EXISTS acore_eluna.character_morphs (`guid` int DEFAULT NULL, `name` text, `id` int DEFAULT NULL, `form` int DEFAULT NULL, `active` smallint DEFAULT NULL, UNIQUE KEY `unique_guid_form` (`guid`, `id`))")
end
if MakeMorphItem then
	WorldDBExecute("REPLACE INTO `item_template` (`entry`, `class`, `subclass`, `SoundOverrideSubclass`, `name`, `displayid`, `Quality`, `Flags`, `FlagsExtra`, `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`, `RequiredSkill`, `RequiredSkillRank`, `requiredspell`, `requiredhonorrank`, `RequiredCityRank`, `RequiredReputationFaction`, `RequiredReputationRank`, `maxcount`, `stackable`, `ContainerSlots`, `stat_type1`, `stat_value1`, `stat_type2`, `stat_value2`, `stat_type3`, `stat_value3`, `stat_type4`, `stat_value4`, `stat_type5`, `stat_value5`, `stat_type6`, `stat_value6`, `stat_type7`, `stat_value7`, `stat_type8`, `stat_value8`, `stat_type9`, `stat_value9`, `stat_type10`, `stat_value10`, `ScalingStatDistribution`, `ScalingStatValue`, `dmg_min1`, `dmg_max1`, `dmg_type1`, `dmg_min2`, `dmg_max2`, `dmg_type2`, `armor`, `holy_res`, `fire_res`, `nature_res`, `frost_res`, `shadow_res`, `arcane_res`, `delay`, `ammo_type`, `RangedModRange`, `spellid_1`, `spelltrigger_1`, `spellcharges_1`, `spellppmRate_1`, `spellcooldown_1`, `spellcategory_1`, `spellcategorycooldown_1`, `spellid_2`, `spelltrigger_2`, `spellcharges_2`, `spellppmRate_2`, `spellcooldown_2`, `spellcategory_2`, `spellcategorycooldown_2`, `spellid_3`, `spelltrigger_3`, `spellcharges_3`, `spellppmRate_3`, `spellcooldown_3`, `spellcategory_3`, `spellcategorycooldown_3`, `spellid_4`, `spelltrigger_4`, `spellcharges_4`, `spellppmRate_4`, `spellcooldown_4`, `spellcategory_4`, `spellcategorycooldown_4`, `spellid_5`, `spelltrigger_5`, `spellcharges_5`, `spellppmRate_5`, `spellcooldown_5`, `spellcategory_5`, `spellcategorycooldown_5`, `bonding`, `description`, `PageText`, `LanguageID`, `PageMaterial`, `startquest`, `lockid`, `Material`, `sheath`, `RandomProperty`, `RandomSuffix`, `block`, `itemset`, `MaxDurability`, `area`, `Map`, `BagFamily`, `TotemCategory`, `socketColor_1`, `socketContent_1`, `socketColor_2`, `socketContent_2`, `socketColor_3`, `socketContent_3`, `socketBonus`, `GemProperties`, `RequiredDisenchantSkill`, `ArmorDamageModifier`, `duration`, `ItemLimitCategory`, `HolidayId`, `ScriptName`, `DisenchantID`, `FoodType`, `minMoneyLoot`, `maxMoneyLoot`, `flagsCustom`, `VerifiedBuild`) values('5041','0','8','-1','Demonic Scroll','6423','6','8388608','0','1','0','0','0','256','-1','0','0','0','0','0','0','0','0','0','1','1','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','24312','0','0','0','-1','0','-1','0','0','0','0','-1','0','-1','0','0','0','0','-1','0','-1','0','0','0','0','-1','0','-1','0','0','0','0','-1','0','-1','0','This scroll lets you absorb the forms of demon enemies to apply them on your demon pets.','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','-1','0','0','0','0','','0','0','0','0','0','1');")
end
if MakeMorphVendor then
	WorldDBExecute("REPLACE INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `scale`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `trainer_type`, `trainer_spell`, `trainer_class`, `trainer_race`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `mechanic_immune_mask`, `spell_school_immune_mask`, `flags_extra`, `ScriptName`, `VerifiedBuild`) values('190087','0','0','0','0','0','Ethereal Pet Morpher','Pet Morph Vendor','','0','80','80','0','35','1','1','1.14286','1','1','20','1.1','3','0','0','0','0','1','1','1','0','2048','0','0','0','0','0','0','0','0','0','0','0','0','0','1','1','','1','1','1','0','0','1','0','0','0','0','0','0','','0')")
	WorldDBExecute("REPLACE INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) values('190087','0','19647','1','1','0');")
end

local demonCache = {}

-- Per-player morph state lives in player:Data() (reload-proof, per-player,
-- destroyed on logout) instead of file-local guid-keyed tables that bled
-- between players and broke across states/reloads. The demon creature cache
-- below stays shared via WorldData.
local DEMON_DATA_KEY = "DemonMorphs"
local DEMON_COUNT_KEY = "DemonCount"

local function LoadDemonData(player)
    if not player then
        return nil
    end
    local stored = player:Data():Get(DEMON_DATA_KEY)
    if stored ~= nil and type(stored) == "table" and stored.AsTable then
        return stored:AsTable()
    end
    if type(stored) == "table" then
        return stored
    end
    return nil
end

local function SaveDemonData(player, d)
    if player then
        player:Data():Set(DEMON_DATA_KEY, d)
    end
end

-- State-aware re-resolve for async CharDBQueryAsync callbacks (cf. DruidMorpher):
-- map states only see their own map players, so GetPlayerByName is world-only.
local function ResolveDemonPlayer(name)
    if not name then
        return nil
    end
    if GetStateMapId() == -1 then
        return GetPlayerByName(name)
    end
    for _, pl in pairs(GetStateMap():GetPlayers()) do
        if pl:GetName() == name then
            return pl
        end
    end
end

-- Multistate: per-player morph caches are filled on login (global state) and on
-- reload (every state), but map states also see fresh logins that never run
-- their loader. This lazy loader fills the LOCAL state's cache synchronously
-- from the DB, so all map-side readers stay correct without cross-state
-- sharing (morph progression itself is persisted in character_morphs).
local Multistate = require("Multistate")

local function EnsureMorphCache(player)
    if not player then
        return
    end
    if LoadDemonData(player) then
        return
    end
    local guid = player:GetGUIDLow()
    local d = { ids = {}, f = {} }
    local count = 0
    local result = CharDBQuery("SELECT id, form FROM acore_eluna.character_morphs WHERE guid = " .. guid)
    if result then
        repeat
            local morphId = result:GetUInt32(0)
            local morphForm = result:GetUInt32(1)
            table.insert(d.ids, morphId)
            count = count + 1
            if familyNames[morphForm] then
                d.f[morphForm] = morphId
            end
        until not result:NextRow()
    end
    SaveDemonData(player, d)
    player:Data():Set(DEMON_COUNT_KEY, count)
end

local function CacheCreatures()
    local demonCount = 0

    -- Demon cache
    WorldDBQueryAsync("SELECT entry, name FROM creature_template WHERE type = 3 OR name = 'Arcane Devourer' OR name = 'Corruptor' OR name = 'Tainted Arcane Wrath' OR name = 'Vile Familiar' OR name = 'Grell'", function(demonResults)

		if demonResults then
			repeat
				local entry = demonResults:GetUInt32(0)
				local name = demonResults:GetString(1)
				demonCache[entry] = {name = name}
				demonCount = demonCount + 1
			until not demonResults:NextRow()
		end
        SetWorldData("DemonMorpherCache", {cache = demonCache})
	end)
end

local function AdoptDemonMorpherCache()
    local shared = GetWorldData("DemonMorpherCache")
    if type(shared) == "table" and shared.AsTable then
        shared = shared:AsTable()
    end
    if type(shared) ~= "table" or type(shared.cache) ~= "table" then
        return false
    end
    demonCache = shared.cache
    return true
end

local function CountTotalMorphs(player)
    local cached = player:Data():Get(DEMON_COUNT_KEY)
    if type(cached) == "number" then
        return cached
    else
        local result = CharDBQuery("SELECT COUNT(*) FROM acore_eluna.character_morphs WHERE guid = "..player:GetGUIDLow())
        if result then
            local total = math.min(result:GetUInt32(0), MaxMorphSkill)
            player:Data():Set(DEMON_COUNT_KEY, total)
            return total
        end
        return 0
    end
end

local function OnKillCreature(event, player, creature)
    EnsureMorphCache(player)
    if player:GetClass() ~= 9 then return end
    if not player:HasItem(ITEM_ID) then return end
    local guid = player:GetGUIDLow()
    local entry = creature:GetEntry()
    local displayId = creature:GetDisplayId()
    local creatureName = creature:GetName()
    
    if displayId == 7949 -- Disallowed display IDs (identical to standard Felhunter). Consider making this a table to feed all non-unique display models
    or displayId == 6172
    or displayId == 6173
    or displayId == 1913
    or displayId == 7126
	or displayId == 19595 -- Invisible imp
    then
        return
    end

    local matchedFamily = nil

    if entry == 12217 then -- Imp corruptor
        matchedFamily = 23
    else
        if demonCache[entry] then
            matchedFamily = demonCache[entry].family
        else
            for familyId, familyName in pairs(familyNames) do
                if string.find(string.lower(creatureName), string.lower(familyName)) then
                    matchedFamily = familyId
                    break
                end
            end
        end

        if not matchedFamily then
            for customName, customFamily in pairs(customFamilyNames) do
                if string.find(string.lower(creatureName), string.lower(customName)) then
                    matchedFamily = customFamily
                    break
                end
            end
        end
    end

    if matchedFamily then
        local escapedName = string.gsub(creatureName, "'", "''")

		local demonKnown = LoadDemonData(player)
		if demonKnown and demonKnown.ids then
			local found = false
			for _, id in ipairs(demonKnown.ids) do
				if id == displayId then
					found = true
					break
				end
			end

			-- If `displayId` is already in the cache, exit
			if found then
				return
			end
		end
		
        CharDBExecute("REPLACE INTO acore_eluna.character_morphs (guid, name, id, form, active) VALUES (" .. guid .. ", '" .. escapedName .. "', " .. displayId .. ", " .. (matchedFamily or 0) .. ", 0)") -- Consider moving db saves to onPlayerSave instead of creature kill
        local familyNames = {
            [15] = "Felhunter",
            [16] = "Voidwalker",
            [17] = "Succubus",
            [19] = "Doomguard",
            [23] = "Imp",
            [29] = "Felguard",
            [30] = "Infernal"
        }

        local familyName = familyNames[matchedFamily] or "demon"
		
		local demonTotal = player:Data():Get(DEMON_COUNT_KEY)
		if type(demonTotal) == "number" then player:Data():Set(DEMON_COUNT_KEY, demonTotal + 1) end
		
        local skillMessage = CountTotalMorphs(player) < MaxMorphSkill and " Your morph skill has increased to " .. CountTotalMorphs(player)+1 .. "." or ""

        player:SendBroadcastMessage("You have captured " .. creatureName .. "'s essence and learned how to morph your " .. familyName .. " into their form." .. skillMessage)
		
		local demonNew = LoadDemonData(player) or { ids = {}, f = {} }
		demonNew.ids = demonNew.ids or {}
		table.insert(demonNew.ids, displayId)
		SaveDemonData(player, demonNew)
	end
end

local function ShowInitialGossipMenu(player)
    player:GossipClearMenu()

    player:GossipMenuAddItem(4, "How does demon morphing work?", 0, 997)

    for familyId, familyName in pairs(familyNames) do
        player:GossipMenuAddItem(0, familyName, 0, familyId)
    end

    player:GossipMenuAddItem(0, "Reset current morph", 0, 998)

	player:GossipSendMenu(1, player, 99)
end

local function OnItemGossipHello(event, player, item, object)
    EnsureMorphCache(player)
	if player:GetClass() == 9 then
        player:GossipComplete()
        ShowInitialGossipMenu(player)
    return false
	end
end

local function OnPlayerGossipHello(player, object)
    player:GossipClearMenu()

	player:GossipMenuAddItem(4, "How does demon morphing work?", 0, 997)
    for familyId, familyName in pairs(familyNames) do
        player:GossipMenuAddItem(0, familyName, 0, familyId)
    end
    player:GossipMenuAddItem(0, "Reset current morph", 0, 998)

    player:GossipSendMenu(1, object, 99)
end

local function OnItemGossipSelect(event, player, object, sender, intid, code)
    EnsureMorphCache(player)	
    if intid == 999 then
        OnPlayerGossipHello(player, object)
        return
    end
    
    if intid == 997 then
        player:GossipClearMenu()
        player:GossipMenuAddItem(0, "Through channeling the spirits of the underworld, you may allow your demon to take on the forms of its enemies.\n \nTo claim an enemy's form, you must slay it.\n \nEvery unique form claimed increases your morphing skill by 1.\n \nTo claim the form of elite or rare creatures, you need to have a morphing skill of at least "..MorphReqEliteandRare..".\n ", 0, 997)
        player:GossipMenuAddItem(4, "Go back", 0, 999)
        player:GossipSendMenu(1, player, 99)
        return
    end
    
    if intid == 998 then
        local guid = player:GetGUIDLow()
        local petGUID = player:GetPetGUID()
        if petGUID then
            local nearbyUnits = player:GetCreaturesInRange(100)
            local pet = nil
            for _, unit in ipairs(nearbyUnits) do
                if unit:GetGUID() == petGUID then
                    pet = unit
                    break
                end
            end
            if pet then
                pet:DeMorph()
                CharDBExecute("UPDATE acore_eluna.character_morphs SET active = 0 WHERE guid = " .. player:GetGUIDLow() .. " AND form = " .. pet:GetCreatureFamily())
                local demonReset = LoadDemonData(player) or { ids = {}, f = {} }
                demonReset.f = demonReset.f or {}
                demonReset.f[pet:GetCreatureFamily()] = nil
                SaveDemonData(player, demonReset)
            else
                player:SendBroadcastMessage("Your demon is too far away!")
            end
        else
            player:SendBroadcastMessage("No demon pet found.")
        end
        OnPlayerGossipHello(player, player)
        return
    end
    
    -- Function to show specific page of morphs
    local function ShowMorphsPage(player, formId, page)
        local guid = player:GetGUIDLow()
        local playername = player:GetName()
        local ITEMS_PER_PAGE = 10
        
        CharDBQueryAsync("SELECT name, id FROM acore_eluna.character_morphs WHERE guid = "..guid.." AND form = "..formId, function(results)
            local player = ResolveDemonPlayer(playername)
            if not player then return end
            
            if results then
                -- Store all results in a table for pagination
                local morphList = {}
                repeat
                    table.insert(morphList, {
                        name = results:GetString(0),
                        displayId = results:GetUInt32(1)
                    })
                until not results:NextRow()
                
                -- Sort alphabetically by name
                table.sort(morphList, function(a, b)
                    return a.name < b.name
                end)
                
                player:GossipClearMenu()
                
                local startIndex = (page - 1) * ITEMS_PER_PAGE + 1
                local endIndex = math.min(startIndex + ITEMS_PER_PAGE - 1, #morphList)
                
                local nameCounts = {}
                
                for i = startIndex, endIndex do
                    local morph = morphList[i]
                    local name = morph.name
                    local displayId = morph.displayId
                    
                    -- Increment the count for this name
                    nameCounts[name] = (nameCounts[name] or 0) + 1
                    local displayName = name
                    
                    -- Append count if there are duplicates
                    if nameCounts[name] > 1 then
                        displayName = name .. " " .. nameCounts[name]
                    end
                    
                    -- Use regular display ID for morph selection
                    player:GossipMenuAddItem(0, displayName, 0, displayId)
                end
                
                -- Add pagination controls with special ID format (900000+ instead of 90000+)
                if page > 1 then
                    player:GossipMenuAddItem(4, "Previous Page", 0, 900000 + (formId * 1000) + (page - 1))
                end
                
                if endIndex < #morphList then
                    player:GossipMenuAddItem(4, "Next Page", 0, 900000 + (formId * 1000) + (page + 1))
                end
                
                player:GossipMenuAddItem(4, "Go back", 0, 999)
                player:GossipSendMenu(1, player, 99)
            else
                player:SendAreaTriggerMessage("You don't have any morphs for this demon!")
                OnPlayerGossipHello(player, player)
            end
        end)
    end
    
    -- Check if this is a pagination request (using 900000+ range)
    if intid >= 900000 then
        local formId = math.floor((intid - 900000) / 1000)
        local page = intid - 900000 - (formId * 1000)
        ShowMorphsPage(player, formId, page)
        return
    end
    
    -- Handle demon family selection (15-30)
    if familyNames[intid] then
        local demonFam = LoadDemonData(player) or { ids = {}, f = {} }
        demonFam.choice = intid
        SaveDemonData(player, demonFam)
        ShowMorphsPage(player, intid, 1)
        return
    end
    
    -- This is morph selection (display ID)
    local guid = player:GetGUIDLow()
    local name = player:GetName()
    
    local demonSel = LoadDemonData(player) or { ids = {}, f = {} }
    local chosenFamily = demonSel.choice
    if not chosenFamily then
        OnPlayerGossipHello(player, player)
        return
    end
    demonSel.lastChoice = intid
    SaveDemonData(player, demonSel)
    local petGUID = player:GetPetGUID()
    if petGUID then
        local nearbyUnits = player:GetCreaturesInRange(100)
        local pet = nil
        for _, unit in ipairs(nearbyUnits) do
            if unit:GetGUID() == petGUID then
                pet = unit
                break
            end
        end
        if pet then
            local summonedPetFamily = pet:GetCreatureFamily()
            if summonedPetFamily == chosenFamily then
                pet:SetDisplayId(intid)
            end
        end
    end
    
    local selFamily, selId, selName = chosenFamily, intid, name
    CharDBQueryAsync("SELECT name FROM acore_eluna.character_morphs WHERE guid = " .. guid .. " AND form = " .. selFamily .. " AND id = " .. selId, function(morphNameResult)
        local player = ResolveDemonPlayer(selName)
        if not player then return end
        local morphName = "Unknown Morph"
        if morphNameResult then
            morphName = morphNameResult:GetString(0)
        end
        player:SendBroadcastMessage("You have morphed your "..familyNames[selFamily].." into "..morphName..".")
    end)
    
    CharDBExecute("UPDATE acore_eluna.character_morphs SET active = (form = " .. chosenFamily .. " AND id = " .. intid .. ") WHERE guid = " .. guid .. " AND form = " .. chosenFamily)
    
    local demonApply = LoadDemonData(player) or { ids = {}, f = {} }
    demonApply.f = demonApply.f or {}
    for _, famForm in ipairs({15, 16, 17, 19, 23, 29, 30}) do
        demonApply.f[famForm] = nil
    end
    demonApply.f[chosenFamily] = intid
    SaveDemonData(player, demonApply)
    OnPlayerGossipHello(player, player)
end

local function OnPetAddedToWorld(event, player, pet)
    EnsureMorphCache(player)
    local demonData = LoadDemonData(player) or { ids = {}, f = {} }
    demonData.f = demonData.f or {}
	local summonedPetFamily = pet:GetCreatureFamily()
	local petName = pet:GetName()
	if petName == "Infernal" then
		summonedPetFamily = 30
	end
	
	if summonedPetFamily == 15 and demonData.f[15] then
		pet:SetDisplayId(demonData.f[15])
	elseif pet:GetCreatureFamily() == 16 and demonData.f[16] then
		pet:SetDisplayId(demonData.f[16])
	elseif pet:GetCreatureFamily() == 17 and demonData.f[17] then
		pet:SetDisplayId(demonData.f[17])
	elseif pet:GetCreatureFamily() == 19 and demonData.f[19] then
		pet:SetDisplayId(demonData.f[19])
	elseif pet:GetCreatureFamily() == 23 and demonData.f[23] then
		pet:SetDisplayId(demonData.f[23])
	elseif pet:GetCreatureFamily() == 29 and demonData.f[29] then
		pet:SetDisplayId(demonData.f[29])
	elseif pet:GetCreatureFamily() == 30 and demonData.f[30] then
		pet:SetDisplayId(demonData.f[30])
	elseif not demonData.login then
		demonData.login = true
		SaveDemonData(player, demonData)
		pet:RegisterEvent(function(eventId, delay, repeats, pet) -- Circumvents async db delay on login
			if summonedPetFamily == 15 and demonData.f[15] then
				pet:SetDisplayId(demonData.f[15])
				pet:RemoveEventById(eventId)
			elseif pet:GetCreatureFamily() == 16 and demonData.f[16] then
				pet:SetDisplayId(demonData.f[16])
				pet:RemoveEventById(eventId)
			elseif pet:GetCreatureFamily() == 17 and demonData.f[17] then
				pet:SetDisplayId(demonData.f[17])
				pet:RemoveEventById(eventId)
			elseif pet:GetCreatureFamily() == 19 and demonData.f[19] then
				pet:SetDisplayId(demonData.f[19])
				pet:RemoveEventById(eventId)
			elseif pet:GetCreatureFamily() == 23 and demonData.f[23] then
				pet:SetDisplayId(demonData.f[23])
				pet:RemoveEventById(eventId)
			elseif pet:GetCreatureFamily() == 29 and demonData.f[29] then
				pet:SetDisplayId(demonData.f[29])
				pet:RemoveEventById(eventId)
			elseif pet:GetCreatureFamily() == 30 and demonData.f[30] then
				pet:SetDisplayId(demonData.f[30])
				pet:RemoveEventById(eventId)
			end
		end, 20, 4)
	end
end

local function OnGossipHello(event, player, object)
    EnsureMorphCache(player)
	if player:GetClass() == 9 then
		player:GossipClearMenu()
		player:GossipMenuAddItem(0, "I hear you're interested in transforming your demon pets' forms...", 0, 1)
		player:GossipSendMenu(1, object)
	else
		player:SendBroadcastMessage("I only cater to Warlocks.")
	end
end

local function OnGossipSelect(event, player, object, sender, intid, code)
    EnsureMorphCache(player)
    if intid == 1 then

        player:GossipClearMenu()
		
		if ChargeTokens then
			player:GossipMenuAddItem(1, "Do you want to buy a "..GetItemLink(ITEM_ID).." for " .. TokenPrice .. " "..GetItemLink(TokenID).."?", 0, 2)
        else
			player:GossipMenuAddItem(1, "Do you want a "..GetItemLink(ITEM_ID).."?", 0, 2)
		end
		player:GossipMenuAddItem(0, "We have nothing to discuss.", 0, 3)

        player:GossipSendMenu(1, object)
    elseif intid == 2 then
        local hasEnoughVT = player:GetItemCount(TokenID) >= 50
        local hasMorphItem = player:GetItemCount(ITEM_ID) > 0
		if not ChargeTokens then
			if not hasMorphItem then
				player:AddItem(ITEM_ID, 1)
			else
				player:SendBroadcastMessage("You already have a "..GetItemLink(ITEM_ID)..".")
			end
		else
			if hasEnoughVT and not hasMorphItem then
				player:RemoveItem(TokenID, TokenPrice)

				player:AddItem(ITEM_ID, 1)

			elseif hasEnoughVT and hasMorphItem then
				player:SendBroadcastMessage("You already have a "..GetItemLink(ITEM_ID)..".")
			elseif not hasEnoughVT and hasMorphItem then
				player:SendBroadcastMessage("You already have a "..GetItemLink(ITEM_ID)..".")
			elseif not hasEnoughVT and not hasMorphItem then
				player:SendBroadcastMessage("You do not have enough "..GetItemLink(TokenID)..".")
			end
		end
        player:GossipComplete()
    elseif intid == 3 then
        player:GossipComplete()
    end
end

local function OnReloadEluna(event)
    Multistate.ForEachPlayer(function(player)
		if player:HasItem(ITEM_ID) then
			local guid = player:GetGUIDLow()
			local name = player:GetName()
			
			CharDBQueryAsync("SELECT id, form, active FROM acore_eluna.character_morphs WHERE guid = " .. guid, function(result)
				local player = ResolveDemonPlayer(name)
				if not player then return end
				-- Rebuild (not append): player:Data() survives reloads, unlike the old file-local tables.
				local d = { ids = {}, f = {} }
				local count = 0
				if result then
					repeat
						local morphId = result:GetUInt32(0)
						local morphForm = result:GetUInt32(1)
						local isActive = result:GetUInt32(2)
						table.insert(d.ids, morphId)
						count = count + 1
						if familyNames[morphForm] then
							d.f[morphForm] = morphId
						end
					until not result:NextRow()
				end
				SaveDemonData(player, d)
				player:Data():Set(DEMON_COUNT_KEY, count)
			end)
		end
    end)
end

-- Cache player's morphs on login if they have the required item
local function OnPlayerLogin(event, player)
    if player:HasItem(ITEM_ID) then
		local guid = player:GetGUIDLow()
		local name = player:GetName()
		
        CharDBQueryAsync("SELECT id, form, active FROM acore_eluna.character_morphs WHERE guid = " .. guid, function(result)
			local player = ResolveDemonPlayer(name)
			if not player then return end
			-- Rebuild (not append): player:Data() is fresh at login but may already
			-- hold a synchronous EnsureMorphCache fill; either way DB is the truth.
			local d = { ids = {}, f = {} }
			local count = 0
			if result then
				repeat
					local morphId = result:GetUInt32(0)
					local morphForm = result:GetUInt32(1)
					local isActive = result:GetUInt32(2)
					table.insert(d.ids, morphId)
					count = count + 1
					if familyNames[morphForm] then
						d.f[morphForm] = morphId
					end
				until not result:NextRow()
			end
			SaveDemonData(player, d)
			player:Data():Set(DEMON_COUNT_KEY, count)
		end)
    end
end

local function OnPlayerLogout(event, player)
    -- Per-player morph state lives in player:Data() and is destroyed on logout.
end

if GetStateMapId() == -1 then
    CacheCreatures()
else
    CreateLuaEvent(function(eventId)
        if AdoptDemonMorpherCache() then
            RemoveEventById(eventId)
        end
    end, 5000, 0)
end
RegisterPlayerEvent(3, OnPlayerLogin)
RegisterPlayerEvent(4, OnPlayerLogout)
RegisterPlayerEvent(7, OnKillCreature)
RegisterServerEvent(33, OnReloadEluna)
RegisterPlayerEvent(43, OnPetAddedToWorld)
RegisterItemGossipEvent(ITEM_ID, 1, OnItemGossipHello)
RegisterPlayerGossipEvent(99, 1, OnPlayerGossipHello)
RegisterPlayerGossipEvent(99, 2, OnItemGossipSelect)
RegisterCreatureGossipEvent(NPC_ID, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ID, 2, OnGossipSelect)
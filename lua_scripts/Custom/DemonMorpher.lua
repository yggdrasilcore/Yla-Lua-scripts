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

-- DB setup and world queries below only run in the world state.
if GetStateMapId() == -1 then
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
end -- world-only DB setup (WorldDBExecute/CharDBExecute above must not run on maps)

-- Shared demon list: world publishes entry -> family with SetWorldData,
-- maps adopt it on demand with GetWorldData (never the other way around).
-- Per-player morphs live on player:Data() under DATA_KEY.
local demonCache

local DATA_KEY = "DemonMorphState"

local function LoadDemonCache()
    if demonCache then return demonCache end
    local shared = GetWorldData("DemonMorpherCache")
    if not shared then return end
    if type(shared) == "table" and shared.AsTable then
        shared = shared:AsTable()
    end
    if type(shared) ~= "table" then return end
    demonCache = shared
    return demonCache
end

local function FamilyForName(creatureName)
    local lower = string.lower(creatureName)
    for familyId, familyName in pairs(familyNames) do
        if string.find(lower, string.lower(familyName), 1, true) then
            return familyId
        end
    end
    for customName, customFamily in pairs(customFamilyNames) do
        if string.find(lower, string.lower(customName), 1, true) then
            return customFamily
        end
    end
end

local function MatchFamily(entry, creatureName)
    local cache = LoadDemonCache()
    if not cache then return end
    if cache[entry] then
        return cache[entry]
    end
    return FamilyForName(creatureName)
end

-- World-only: build entry -> family once and publish it.
local function CacheCreatures()
    WorldDBQueryAsync("SELECT entry, name FROM creature_template WHERE type = 3 OR name = 'Arcane Devourer' OR name = 'Corruptor' OR name = 'Tainted Arcane Wrath' OR name = 'Vile Familiar' OR name = 'Grell'", function(demonResults)
        local cache = {}
        if demonResults then
            repeat
                local entry = demonResults:GetUInt32(0)
                local name = demonResults:GetString(1)
                cache[entry] = FamilyForName(name) or 0
            until not demonResults:NextRow()
        end
        SetWorldData("DemonMorpherCache", cache)
    end)
end

local function LoadData(player)
    local stored = player:Data():Get(DATA_KEY)
    if stored then
        return stored:AsTable()
    end
    return {}
end

local function SaveData(player, d)
    player:Data():Set(DATA_KEY, d)
end

local function Find(list, displayId)
    for n = 1, #list do
        if list[n] == displayId then
            return true
        end
    end
    return false
end

local function Skill(d)
    return math.min(#(d.ids or {}), MaxMorphSkill)
end

-- Map-only, druid-style lazy loader: returns nil while the async DB read is
-- in flight; callers must bail out until d.ids exists.
local function PlayerData(player)
    local d = LoadData(player)
    if d.ids then return d end
    if d.loading then return end
    d.loading = true
    SaveData(player, d)
    local name = player:GetName()
    local guid = player:GetGUIDLow()
    CharDBQueryAsync("SELECT id, form, active FROM acore_eluna.character_morphs WHERE guid = " .. guid, function(result)
        local p
        for _, pl in pairs(GetStateMap():GetPlayers()) do
            if pl:GetName() == name then
                p = pl
                break
            end
        end
        if not p then return end
        local ids, active = {}, {}
        if result then
            repeat
                local morphId = result:GetUInt32(0)
                local morphForm = result:GetUInt32(1)
                table.insert(ids, morphId)
                if result:GetUInt32(2) == 1 and familyNames[morphForm] then
                    active[morphForm] = morphId
                end
            until not result:NextRow()
        end
        local pd = LoadData(p)
        pd.ids, pd.active, pd.loading = ids, active, nil
        SaveData(p, pd)
    end)
end

local function FindPlayerOnMap(name)
    for _, pl in pairs(GetStateMap():GetPlayers()) do
        if pl:GetName() == name then
            return pl
        end
    end
end

local function OnKillCreature(event, player, creature)
    if player:GetClass() ~= 9 then return end
    if not player:HasItem(ITEM_ID) then return end
    if not LoadDemonCache() then return end
    local d = PlayerData(player)
    if not d or not d.ids then return end
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
        matchedFamily = MatchFamily(entry, creatureName)
    end

    if matchedFamily and matchedFamily ~= 0 then
        if Find(d.ids, displayId) then
            return
        end

        local guid = player:GetGUIDLow()
        local escapedName = string.gsub(creatureName, "'", "''")

        CharDBExecute("REPLACE INTO acore_eluna.character_morphs (guid, name, id, form, active) VALUES (" .. guid .. ", '" .. escapedName .. "', " .. displayId .. ", " .. matchedFamily .. ", 0)") -- Consider moving db saves to onPlayerSave instead of creature kill

        local familyName = familyNames[matchedFamily] or "demon"

        table.insert(d.ids, displayId)
        SaveData(player, d)

        local skill = Skill(d)
        local skillMessage = skill < MaxMorphSkill and " Your morph skill has increased to " .. skill .. "." or ""

        player:SendBroadcastMessage("You have captured " .. creatureName .. "'s essence and learned how to morph your " .. familyName .. " into their form." .. skillMessage)
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
    if not LoadDemonCache() then return false end
    local d = PlayerData(player)
    if not d or not d.ids then
        player:SendAreaTriggerMessage("Loading your morphs, try again in a moment.")
        return false
    end
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
    local d = PlayerData(player)
    if not d or not d.ids then
        player:SendAreaTriggerMessage("Loading your morphs, try again in a moment.")
        return
    end
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
                local rd = LoadData(player)
                rd.active = rd.active or {}
                rd.active[pet:GetCreatureFamily()] = nil
                SaveData(player, rd)
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
    local function ShowMorphsPage(p, formId, page)
        local guid = p:GetGUIDLow()
        local playername = p:GetName()
        local ITEMS_PER_PAGE = 10

        CharDBQueryAsync("SELECT name, id FROM acore_eluna.character_morphs WHERE guid = "..guid.." AND form = "..formId, function(results)
            local player = FindPlayerOnMap(playername)
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
        d.choice = intid
        SaveData(player, d)
        ShowMorphsPage(player, intid, 1)
        return
    end
    
    -- This is morph selection (display ID)
    local guid = player:GetGUIDLow()
    local name = player:GetName()
    
    local chosenFamily = d.choice
    if not chosenFamily then
        OnPlayerGossipHello(player, player)
        return
    end
    d.lastChoice = intid
    SaveData(player, d)
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
        local p = FindPlayerOnMap(selName)
        if not p then return end
        local morphName = "Unknown Morph"
        if morphNameResult then
            morphName = morphNameResult:GetString(0)
        end
        p:SendBroadcastMessage("You have morphed your "..familyNames[selFamily].." into "..morphName..".")
    end)
    
    CharDBExecute("UPDATE acore_eluna.character_morphs SET active = (form = " .. chosenFamily .. " AND id = " .. intid .. ") WHERE guid = " .. guid .. " AND form = " .. chosenFamily)
    
    local da = LoadData(player)
    da.active = da.active or {}
    da.active[chosenFamily] = intid
    SaveData(player, da)
    OnPlayerGossipHello(player, player)
end

local function PetFamily(pet)
    local family = pet:GetCreatureFamily()
    if pet:GetName() == "Infernal" then
        family = 30
    end
    return family
end

local function ApplyPetMorph(pet, playerName)
    local p = FindPlayerOnMap(playerName)
    if not p then return end
    local d = LoadData(p)
    if not d or not d.active then return end
    local family = PetFamily(pet)
    if d.active[family] then
        pet:SetDisplayId(d.active[family])
        return true
    end
end

local function OnPetAddedToWorld(event, player, pet)
    local d = PlayerData(player)
    if d and d.active then
        local family = PetFamily(pet)
        if d.active[family] then
            pet:SetDisplayId(d.active[family])
            return
        end
    end
    local playerName = player:GetName()
    pet:RegisterEvent(function(eventId, delay, repeats, p) -- Circumvents async db delay on login
        if ApplyPetMorph(p, playerName) then
            p:RemoveEventById(eventId)
        end
    end, 20, 4)
end

local function OnGossipHello(event, player, object)
    local d = PlayerData(player)
    if not d or not d.ids then
        player:SendAreaTriggerMessage("Loading your morphs, try again in a moment.")
        return
    end
	if player:GetClass() == 9 then
		player:GossipClearMenu()
		player:GossipMenuAddItem(0, "I hear you're interested in transforming your demon pets' forms...", 0, 1)
		player:GossipSendMenu(1, object)
	else
		player:SendBroadcastMessage("I only cater to Warlocks.")
	end
end

local function OnGossipSelect(event, player, object, sender, intid, code)
    LoadDemonCache()
    PlayerData(player)
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

-- Map-only: adopt the world-published demon list and lazy-load the player's
-- morphs when they enter. Async work re-resolves the player by map walk.
local function OnPlayerEnterMap(event, player)
    if player:GetClass() ~= 9 then return end
    if not player:HasItem(ITEM_ID) then return end
    LoadDemonCache()
    PlayerData(player)
end

-- World publishes the shared demon list; maps register gameplay events.
if GetStateMapId() == -1 then -- World stuff
    CacheCreatures()
else -- Map stuff
    RegisterPlayerEvent(7, OnKillCreature)
    RegisterPlayerEvent(28, OnPlayerEnterMap)
    RegisterPlayerEvent(43, OnPetAddedToWorld)
    RegisterItemGossipEvent(ITEM_ID, 1, OnItemGossipHello)
    RegisterPlayerGossipEvent(99, 1, OnPlayerGossipHello)
    RegisterPlayerGossipEvent(99, 2, OnItemGossipSelect)
    RegisterCreatureGossipEvent(NPC_ID, 1, OnGossipHello)
    RegisterCreatureGossipEvent(NPC_ID, 2, OnGossipSelect)
end
-- Run these first:

-- CHAR DB
--CREATE TABLE character_gift_events (
--    guid INT NOT NULL,
--    EVENT VARCHAR(255) NOT NULL,
--    awarded BOOLEAN NOT NULL,
--    DATE DATETIME NOT NULL
--);


-- WORLD DB
--replace into `item_template` (`entry`, `class`, `subclass`, `SoundOverrideSubclass`, `name`, `displayid`, `Quality`, `Flags`, `FlagsExtra`, `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`, `RequiredSkill`, `RequiredSkillRank`, `requiredspell`, `requiredhonorrank`, `RequiredCityRank`, `RequiredReputationFaction`, `RequiredReputationRank`, `maxcount`, `stackable`, `ContainerSlots`, `StatsCount`, `stat_type1`, `stat_value1`, `stat_type2`, `stat_value2`, `stat_type3`, `stat_value3`, `stat_type4`, `stat_value4`, `stat_type5`, `stat_value5`, `stat_type6`, `stat_value6`, `stat_type7`, `stat_value7`, `stat_type8`, `stat_value8`, `stat_type9`, `stat_value9`, `stat_type10`, `stat_value10`, `ScalingStatDistribution`, `ScalingStatValue`, `dmg_min1`, `dmg_max1`, `dmg_type1`, `dmg_min2`, `dmg_max2`, `dmg_type2`, `armor`, `holy_res`, `fire_res`, `nature_res`, `frost_res`, `shadow_res`, `arcane_res`, `delay`, `ammo_type`, `RangedModRange`, `spellid_1`, `spelltrigger_1`, `spellcharges_1`, `spellppmRate_1`, `spellcooldown_1`, `spellcategory_1`, `spellcategorycooldown_1`, `spellid_2`, `spelltrigger_2`, `spellcharges_2`, `spellppmRate_2`, `spellcooldown_2`, `spellcategory_2`, `spellcategorycooldown_2`, `spellid_3`, `spelltrigger_3`, `spellcharges_3`, `spellppmRate_3`, `spellcooldown_3`, `spellcategory_3`, `spellcategorycooldown_3`, `spellid_4`, `spelltrigger_4`, `spellcharges_4`, `spellppmRate_4`, `spellcooldown_4`, `spellcategory_4`, `spellcategorycooldown_4`, `spellid_5`, `spelltrigger_5`, `spellcharges_5`, `spellppmRate_5`, `spellcooldown_5`, `spellcategory_5`, `spellcategorycooldown_5`, `bonding`, `description`, `PageText`, `LanguageID`, `PageMaterial`, `startquest`, `lockid`, `Material`, `sheath`, `RandomProperty`, `RandomSuffix`, `block`, `itemset`, `MaxDurability`, `area`, `Map`, `BagFamily`, `TotemCategory`, `socketColor_1`, `socketContent_1`, `socketColor_2`, `socketContent_2`, `socketColor_3`, `socketContent_3`, `socketBonus`, `GemProperties`, `RequiredDisenchantSkill`, `ArmorDamageModifier`, `duration`, `ItemLimitCategory`, `HolidayId`, `ScriptName`, `DisenchantID`, `FoodType`, `minMoneyLoot`, `maxMoneyLoot`, `flagsCustom`, `VerifiedBuild`) values('41404','15','0','-1','Yggdrasil\'s Winter Veil Wish List','12333','4','0','0','1','0','0','0','-1','-1','70','0','0','0','0','0','0','0','0','1','1','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','32783','0','0','0','-1','0','-1','0','0','0','0','-1','0','-1','0','0','0','0','-1','0','-1','0','0','0','0','-1','0','-1','0','0','0','0','-1','0','-1','1','Yggdrasil\'s Santa Claus wishes you a happy Winter Veil! Use this item to select your Winter Veil present.','0','0','0','0','0','-1','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','-1','0','0','0','0','','0','0','0','0','0','1');

--DELETE FROM spell_linked_spell WHERE spell_trigger = 24707;

--replace into `item_template` (`entry`, `class`, `subclass`, `SoundOverrideSubclass`, `name`, `displayid`, `Quality`, `Flags`, `FlagsExtra`, `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`, `RequiredSkill`, `RequiredSkillRank`, `requiredspell`, `requiredhonorrank`, `RequiredCityRank`, `RequiredReputationFaction`, `RequiredReputationRank`, `maxcount`, `stackable`, `ContainerSlots`, `StatsCount`, `stat_type1`, `stat_value1`, `stat_type2`, `stat_value2`, `stat_type3`, `stat_value3`, `stat_type4`, `stat_value4`, `stat_type5`, `stat_value5`, `stat_type6`, `stat_value6`, `stat_type7`, `stat_value7`, `stat_type8`, `stat_value8`, `stat_type9`, `stat_value9`, `stat_type10`, `stat_value10`, `ScalingStatDistribution`, `ScalingStatValue`, `dmg_min1`, `dmg_max1`, `dmg_type1`, `dmg_min2`, `dmg_max2`, `dmg_type2`, `armor`, `holy_res`, `fire_res`, `nature_res`, `frost_res`, `shadow_res`, `arcane_res`, `delay`, `ammo_type`, `RangedModRange`, `spellid_1`, `spelltrigger_1`, `spellcharges_1`, `spellppmRate_1`, `spellcooldown_1`, `spellcategory_1`, `spellcategorycooldown_1`, `spellid_2`, `spelltrigger_2`, `spellcharges_2`, `spellppmRate_2`, `spellcooldown_2`, `spellcategory_2`, `spellcategorycooldown_2`, `spellid_3`, `spelltrigger_3`, `spellcharges_3`, `spellppmRate_3`, `spellcooldown_3`, `spellcategory_3`, `spellcategorycooldown_3`, `spellid_4`, `spelltrigger_4`, `spellcharges_4`, `spellppmRate_4`, `spellcooldown_4`, `spellcategory_4`, `spellcategorycooldown_4`, `spellid_5`, `spelltrigger_5`, `spellcharges_5`, `spellppmRate_5`, `spellcooldown_5`, `spellcategory_5`, `spellcategorycooldown_5`, `bonding`, `description`, `PageText`, `LanguageID`, `PageMaterial`, `startquest`, `lockid`, `Material`, `sheath`, `RandomProperty`, `RandomSuffix`, `block`, `itemset`, `MaxDurability`, `area`, `Map`, `BagFamily`, `TotemCategory`, `socketColor_1`, `socketContent_1`, `socketColor_2`, `socketContent_2`, `socketColor_3`, `socketContent_3`, `socketBonus`, `GemProperties`, `RequiredDisenchantSkill`, `ArmorDamageModifier`, `duration`, `ItemLimitCategory`, `HolidayId`, `ScriptName`, `DisenchantID`, `FoodType`, `minMoneyLoot`, `maxMoneyLoot`, `flagsCustom`, `VerifiedBuild`) values('1072','0','5','-1','Sap of Yggdrasil','33681','4','134217728','0','1','0','0','0','32767','-1','65','1','0','0','0','0','0','0','0','0','20','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','24707','0','0','-1','0','11','1000','0','0','0','0','-1','0','-1','0','0','0','0','-1','0','-1','0','0','0','0','-1','0','-1','0','0','0','0','-1','0','-1','1','The sweet sap of Yggdrasil has an extraordinary ability to energize you. The sap is never fully consumed.','0','0','0','0','0','-1','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','-1','0','0','0','0','','0','0','0','0','0','12340');

local christmasGiftID = 41404

local function OnUseItem(event, player, item, target)
   player:GossipClearMenu()
   player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_gift_01:32:32:-22:0|tGreetings, "..player:GetName().."!\n \nYggdrasil's Santa Claus has a few gifts you can choose between. Which gift would you like to receive?\n \n ", 0, 10)
   player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_drink_11:32:32:-22:0|tSap of Yggdrasil\n \nRestores 3% of your health and mana per second for 25 sec. Binds to account. Can be consumed infinitely.\n \n ", 0, 1, false, "Are you sure you want to select the following Winter Veil gift?\n\nThis will consume your wish list.\n \n|TInterface/ICONS/inv_drink_11:32:32:-22:0|tSap of Yggdrasil")
   player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_frostemblem_01:32:32:-22:0|t100 Emblems of Frost\n \nPurchase gear, Primordial Saronite and more with Emblems of Frost.\n \n ", 0, 2, false, "Are you sure you want to select the following Winter Veil gift?\n\nThis will consume your wish list.\n \n|TInterface/ICONS/inv_misc_frostemblem_01:32:32:-22:0|t100 Emblems of Frost")
   player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_rune_07:32:32:-22:0|t25 Community Tokens\n \nCan be spent on VIP and vanity objects at the mall.\n \n ", 0, 3, false, "Are you sure you want to select the following Winter Veil gift?\n\nThis will consume your wish list.\n \n|TInterface/ICONS/inv_misc_rune_07:32:32:-22:0|t25 Community Tokens")
   player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_fishingchair:32:32:-22:0|tFishing Chair\n \nRelax in Azeroth on a brand new reclined Fishing Chair.\n \n ", 0, 4, false, "Are you sure you want to select the following Winter Veil gift?\n\nThis will consume your wish list.\n \n|TInterface/ICONS/inv_fishingchair:32:32:-22:0|tFishing Chair")
   player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_gem_sapphire_01:32:32:-22:0|tFrost Wyrm Mount\n \nThis is a 280% Frost Wyrm mount. It requires Artisan Riding.\n \n ", 0, 5, false, "Are you sure you want to select the following Winter Veil gift?\n\nThis will consume your wish list.\n \n|TInterface/ICONS/inv_misc_gem_sapphire_01:32:32:-22:0|tFrost Wyrm Mount")
   player:GossipSendMenu(12, player, 1035980)
   return false
end

local function OnGossipSelect(event, player, object, sender, intid, code, menu_id)
   if intid == 10 then
       player:GossipClearMenu()
       player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_gift_01:32:32:-22:0|tGreetings, "..player:GetName().."!\n \nYggdrasil's Santa Claus has a few gifts you can choose between. Which gift would you like to receive?\n \n ", 0, 10)
       player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_drink_11:32:32:-22:0|tSap of Yggdrasil\n \nRestores 3% of your health and mana per second for 25 sec. Binds to account. Can be consumed infinitely.\n \n ", 0, 1, false, "Are you sure you want to select the following Winter Veil gift?\n\nThis will consume your wish list.\n \n|TInterface/ICONS/inv_drink_11:32:32:-22:0|tSap of Yggdrasil")
       player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_frostemblem_01:32:32:-22:0|t100 Emblems of Frost\n \nPurchase gear, Primordial Saronite and more with Emblems of Frost.\n \n ", 0, 2, false, "Are you sure you want to select the following Winter Veil gift?\n\nThis will consume your wish list.\n \n|TInterface/ICONS/inv_misc_frostemblem_01:32:32:-22:0|t100 Emblems of Frost")
       player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_rune_07:32:32:-22:0|t25 Community Tokens\n \nCan be spent on VIP and vanity objects at the mall.\n \n ", 0, 3, false, "Are you sure you want to select the following Winter Veil gift?\n\nThis will consume your wish list.\n \n|TInterface/ICONS/inv_misc_rune_07:32:32:-22:0|t25 Community Tokens")
       player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_fishingchair:32:32:-22:0|tFishing Chair\n \nRelax in Azeroth on a brand new reclined Fishing Chair.\n \n ", 0, 4, false, "Are you sure you want to select the following Winter Veil gift?\n\nThis will consume your wish list.\n \n|TInterface/ICONS/inv_fishingchair:32:32:-22:0|tFishing Chair")
       player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_gem_sapphire_01:32:32:-22:0|tFrost Wyrm Mount\n \nThis is a 280% Frost Wyrm mount. It requires Artisan Riding.\n \n ", 0, 5, false, "Are you sure you want to select the following Winter Veil gift?\n\nThis will consume your wish list.\n \n|TInterface/ICONS/inv_misc_gem_sapphire_01:32:32:-22:0|tFrost Wyrm Mount")
       player:GossipSendMenu(12, player, 1035980)
       return false
   elseif intid == 1 then
       player:AddItem(1072, 1)
       player:RemoveItem(christmasGiftID, 1)
   elseif intid == 2 then
       if not (player:GetLevel() == 80) then
           player:SendAreaTriggerMessage("You must be level 80 to accept this gift!")
           player:GossipComplete()
           return false
       end
       player:AddItem(49426, 100)
       player:RemoveItem(christmasGiftID, 1)
   elseif intid == 3 then
       player:AddItem(19322, 25)
       player:RemoveItem(christmasGiftID, 1)
   elseif intid == 4 then
       if player:HasItem(33223, 1, true) then
           player:SendAreaTriggerMessage("You already have this item!")
           player:GossipComplete()
           return false
       end
       player:AddItem(33223, 1)
       player:RemoveItem(christmasGiftID, 1)
   elseif intid == 5 then
       if player:HasSpell(51960) then
           player:SendAreaTriggerMessage("You already have this mount!")
           player:GossipComplete()
           return false
       end
       if player:IsDead() then
           player:SendAreaTriggerMessage("You cannot accept this gift right now")
           player:GossipComplete()
           return false
       end
       player:LearnSpell(51960)
       if player:HasSpell(51960) then -- In case learn spell fails
           player:RemoveItem(christmasGiftID, 1)
       end
   end
   player:GossipComplete()
end

local function OnLogin(event, player)
    local name = player:GetName()
    local currentDate = tonumber(os.date("%m%d"))
    
    -- Check if date is between Dec 24 and Jan 2
    if (currentDate >= 1224 and currentDate <= 1231) or (currentDate >= 101 and currentDate <= 102) then
        local guid = player:GetGUIDLow()
        
        CharDBQueryAsync(string.format("SELECT guid FROM character_gift_events WHERE guid = %d AND event = 'Veil2024'", guid), function(result)
            if not result then
                local player = GetPlayerByName(name)
                if not player:HasItem(41404, 1, true) then
                    player:AddItem(41404, 1)
                end
                if player:HasItem(41404, 1) then
                    CharDBExecute(string.format("INSERT INTO character_gift_events (guid, event, awarded, date) VALUES (%d, 'Veil2024', 1, '%s')", guid, os.date("%Y-%m-%d %H:%M:%S")))
                end
            end
        end)
    end
end

RegisterPlayerEvent(3, OnLogin)
RegisterItemEvent(christmasGiftID, 2, OnUseItem)
RegisterPlayerGossipEvent(1035980, 2, OnGossipSelect)

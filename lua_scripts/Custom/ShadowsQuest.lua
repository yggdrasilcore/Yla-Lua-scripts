-- Make quest
WorldDBExecute([[
REPLACE INTO `quest_template` (
    `ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`,
    `RequiredFactionId1`, `RequiredFactionId2`, `RequiredFactionValue1`, `RequiredFactionValue2`,
    `RewardNextQuest`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `RewardDisplaySpell`,
    `RewardSpell`, `RewardHonor`, `RewardKillHonor`, `StartItem`, `Flags`, `RequiredPlayerKills`,
    `RewardItem1`, `RewardAmount1`, `RewardItem2`, `RewardAmount2`, `RewardItem3`, `RewardAmount3`,
    `RewardItem4`, `RewardAmount4`, `ItemDrop1`, `ItemDropQuantity1`, `ItemDrop2`, `ItemDropQuantity2`,
    `ItemDrop3`, `ItemDropQuantity3`, `ItemDrop4`, `ItemDropQuantity4`, `RewardChoiceItemID1`,
    `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`,
    `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`,
    `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `POIContinent`,
    `POIx`, `POIy`, `POIPriority`, `RewardTitle`, `RewardTalents`, `RewardArenaPoints`,
    `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `RewardFactionID2`,
    `RewardFactionValue2`, `RewardFactionOverride2`, `RewardFactionID3`, `RewardFactionValue3`,
    `RewardFactionOverride3`, `RewardFactionID4`, `RewardFactionValue4`, `RewardFactionOverride4`,
    `RewardFactionID5`, `RewardFactionValue5`, `RewardFactionOverride5`, `TimeAllowed`,
    `AllowableRaces`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`,
    `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`,
    `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`,
    `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`,
    `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`,
    `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`,
    `Unknown0`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`
) VALUES (
    30000, 2, 15, 15, -284, 0, 0,
    0, 0, 0, 0,
    0, 3, 0, 0, 0,
    0, 0, 0, 21878, 0, 0,
    0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0,
    0, 'Save Your Shadows!', 'Use the Time-Lost Void Teleport to save your shadows from the Twisting Nether.',
    'Through the swirls of the Twisting Nether, you hear the sounds of someone familiar yelling back at you... It sounds like... Yourself? How can this be? Words swirl out of the item... Shadows... Captured... Black Dragonflight... Sounds like you are in danger and should go help yourself.',
    '', '', 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0,
    0, 'Save your shadows from the Twisting Nether.', '', '', ''
);
]])

-- Make quest start item
WorldDBExecute([[
REPLACE INTO `item_template` (`entry`, `class`, `subclass`, `SoundOverrideSubclass`, `name`, `displayid`, `Quality`, `Flags`, `FlagsExtra`, `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`, `RequiredSkill`, `RequiredSkillRank`, `requiredspell`, `requiredhonorrank`, `RequiredCityRank`, `RequiredReputationFaction`, `RequiredReputationRank`, `maxcount`, `stackable`, `ContainerSlots`, `StatsCount`, `stat_type1`, `stat_value1`, `stat_type2`, `stat_value2`, `stat_type3`, `stat_value3`, `stat_type4`, `stat_value4`, `stat_type5`, `stat_value5`, `stat_type6`, `stat_value6`, `stat_type7`, `stat_value7`, `stat_type8`, `stat_value8`, `stat_type9`, `stat_value9`, `stat_type10`, `stat_value10`, `ScalingStatDistribution`, `ScalingStatValue`, `dmg_min1`, `dmg_max1`, `dmg_type1`, `dmg_min2`, `dmg_max2`, `dmg_type2`, `armor`, `holy_res`, `fire_res`, `nature_res`, `frost_res`, `shadow_res`, `arcane_res`, `delay`, `ammo_type`, `RangedModRange`, `spellid_1`, `spelltrigger_1`, `spellcharges_1`, `spellppmRate_1`, `spellcooldown_1`, `spellcategory_1`, `spellcategorycooldown_1`, `spellid_2`, `spelltrigger_2`, `spellcharges_2`, `spellppmRate_2`, `spellcooldown_2`, `spellcategory_2`, `spellcategorycooldown_2`, `spellid_3`, `spelltrigger_3`, `spellcharges_3`, `spellppmRate_3`, `spellcooldown_3`, `spellcategory_3`, `spellcategorycooldown_3`, `spellid_4`, `spelltrigger_4`, `spellcharges_4`, `spellppmRate_4`, `spellcooldown_4`, `spellcategory_4`, `spellcategorycooldown_4`, `spellid_5`, `spelltrigger_5`, `spellcharges_5`, `spellppmRate_5`, `spellcooldown_5`, `spellcategory_5`, `spellcategorycooldown_5`, `bonding`, `description`, `PageText`, `LanguageID`, `PageMaterial`, `startquest`, `lockid`, `Material`, `sheath`, `RandomProperty`, `RandomSuffix`, `block`, `itemset`, `MaxDurability`, `area`, `Map`, `BagFamily`, `TotemCategory`, `socketColor_1`, `socketContent_1`, `socketColor_2`, `socketContent_2`, `socketColor_3`, `socketContent_3`, `socketBonus`, `GemProperties`, `RequiredDisenchantSkill`, `ArmorDamageModifier`, `duration`, `ItemLimitCategory`, `HolidayId`, `ScriptName`, `DisenchantID`, `FoodType`, `minMoneyLoot`, `maxMoneyLoot`, `flagsCustom`, `VerifiedBuild`) values('39163','12','0','-1','Time-Lost Void','41122','4','96','0','1','0','0','0','-1','-1','1','15','0','0','0','0','0','0','0','0','1','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','32783','0','0','0','-1','330','3000','0','0','0','0','-1','0','-1','0','0','0','0','-1','0','-1','0','0','0','0','-1','0','-1','0','0','0','0','-1','0','-1','4','You hear swirly voices come out of the item... They sound like yourself! Listen to the item to find out more...','0','0','0','30000','0','-1','0','0','0','0','0','0','0','0','16384','0','0','0','0','0','0','0','0','0','-1','0','0','0','0','','0','0','0','0','0','1');
]])

-- Make quest teleport item
WorldDBExecute([[
REPLACE INTO `item_template` (`entry`, `class`, `subclass`, `SoundOverrideSubclass`, `name`, `displayid`, `Quality`, `Flags`, `FlagsExtra`, `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`, `RequiredSkill`, `RequiredSkillRank`, `requiredspell`, `requiredhonorrank`, `RequiredCityRank`, `RequiredReputationFaction`, `RequiredReputationRank`, `maxcount`, `stackable`, `ContainerSlots`, `StatsCount`, `stat_type1`, `stat_value1`, `stat_type2`, `stat_value2`, `stat_type3`, `stat_value3`, `stat_type4`, `stat_value4`, `stat_type5`, `stat_value5`, `stat_type6`, `stat_value6`, `stat_type7`, `stat_value7`, `stat_type8`, `stat_value8`, `stat_type9`, `stat_value9`, `stat_type10`, `stat_value10`, `ScalingStatDistribution`, `ScalingStatValue`, `dmg_min1`, `dmg_max1`, `dmg_type1`, `dmg_min2`, `dmg_max2`, `dmg_type2`, `armor`, `holy_res`, `fire_res`, `nature_res`, `frost_res`, `shadow_res`, `arcane_res`, `delay`, `ammo_type`, `RangedModRange`, `spellid_1`, `spelltrigger_1`, `spellcharges_1`, `spellppmRate_1`, `spellcooldown_1`, `spellcategory_1`, `spellcategorycooldown_1`, `spellid_2`, `spelltrigger_2`, `spellcharges_2`, `spellppmRate_2`, `spellcooldown_2`, `spellcategory_2`, `spellcategorycooldown_2`, `spellid_3`, `spelltrigger_3`, `spellcharges_3`, `spellppmRate_3`, `spellcooldown_3`, `spellcategory_3`, `spellcategorycooldown_3`, `spellid_4`, `spelltrigger_4`, `spellcharges_4`, `spellppmRate_4`, `spellcooldown_4`, `spellcategory_4`, `spellcategorycooldown_4`, `spellid_5`, `spelltrigger_5`, `spellcharges_5`, `spellppmRate_5`, `spellcooldown_5`, `spellcategory_5`, `spellcategorycooldown_5`, `bonding`, `description`, `PageText`, `LanguageID`, `PageMaterial`, `startquest`, `lockid`, `Material`, `sheath`, `RandomProperty`, `RandomSuffix`, `block`, `itemset`, `MaxDurability`, `area`, `Map`, `BagFamily`, `TotemCategory`, `socketColor_1`, `socketContent_1`, `socketColor_2`, `socketContent_2`, `socketColor_3`, `socketContent_3`, `socketBonus`, `GemProperties`, `RequiredDisenchantSkill`, `ArmorDamageModifier`, `duration`, `ItemLimitCategory`, `HolidayId`, `ScriptName`, `DisenchantID`, `FoodType`, `minMoneyLoot`, `maxMoneyLoot`, `flagsCustom`, `VerifiedBuild`) values('21878','15','0','-1','Time-Lost Void Teleport','41122','4','96','0','1','0','0','0','-1','-1','1','15','0','0','0','0','0','0','0','0','1','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','32783','0','0','0','-1','330','3000','0','0','0','0','-1','0','-1','0','0','0','0','-1','0','-1','0','0','0','0','-1','0','-1','0','0','0','0','-1','0','-1','1','You hear swirly voices come out of the item... They sound like yourself! This item can teleport you to the source of the sounds.','0','0','0','0','0','-1','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','-1','0','0','0','0','','0','0','0','0','0','1');
]])

-- Constants
local QUEST_ID = 30000
local TELEPORT_ITEM = 21878
local QUEST_ITEM = 39163
local AREA_ID = 268 -- Azshara crater temple 
local MAP_ID = 37 -- Azshara crater
local SHADOW_ENTRY = 30842 -- Player shadows
local TIMERENDER_ENTRY = 27900 -- Hostile NPC
local SWIRL_ENTRY = 17838 -- Swirly texture from time warp
local SHACKLE_AURA = 38505 -- Shackle permanent spell
local STUN_AURA = 52165 -- Stun permanent spell, prevents NPC from killing player
local SHADOWFORM_AURA = 58001 -- Makes shadows seem less janky textured
local IMMUNE_ALL = 29230 -- Prevents premature dragon death
local HEARTHSTONE = 8690 -- Teleport player away when done, if no cached location saved
local DespawnTimer = 180000 -- 3 minutes quest time
local shadowsEvent = os.time()
local eventState = 0
local oldMap = 0
local oldX = 0
local oldY = 0
local oldZ = 0
local oldO = 0
local locationChar = 0
local minLevel = 15
local dkLimit = 70 -- Prevents DKs from zapping toons into the scarlet enclave area
local EventLocation = {-639.76, -259.62, 352.58, 2.27}

-- Item use event

local function ShadowsTeleItem(event, player, item, target)
    if player:GetAreaId() == AREA_ID then 
        player:SendAreaTriggerMessage("You can't save your shadows from this location! Try again someplace else.")
        player:SendBroadcastMessage("You can't save your shadows from this location! Try again someplace else.")
        return false
    end
    
    if shadowsEvent > os.time() then
        player:SendAreaTriggerMessage("You can't save your shadows right now! Try again in a few minutes.")
        player:SendBroadcastMessage("You can't save your shadows right now! Try again in a few minutes.")
        return false
    end
    
    oldMap = player:GetMapId()
    oldX = player:GetX()
    oldY = player:GetY()
    oldZ = player:GetZ()
    oldO = player:GetO()
    locationChar = player:GetGUIDLow()
    
    player:Teleport(MAP_ID, EventLocation[1], EventLocation[2], EventLocation[3], EventLocation[4])

    return false
end

local function ShadowsMap(event, player)
    if player:GetAreaId() == AREA_ID then
        if player:HasQuest(QUEST_ID) and (shadowsEvent <= os.time()) then
        
            local playerLocation = {player:GetLocation()}
            if not ((player:GetX() >= EventLocation[1]-1 and player:GetX() <= EventLocation[1]+1) and
                    (player:GetY() >= EventLocation[2]-1 and player:GetY() <= EventLocation[2]+1)) then
                    player:SetData("ShadowsQuestEvent", nil)
                return
            end

            player:SetData("ShadowsQuestEvent", true)
            
            shadowsEvent = os.time() + 180
            
            player:RegisterEvent(function(eventId, delay, repeats, player)
                if player and player:GetAreaId() == AREA_ID and (player:HasItem(TELEPORT_ITEM) or player:HasItem(QUEST_ITEM)) then
                    player:RemoveItem(TELEPORT_ITEM, 1)
                    player:RemoveItem(QUEST_ITEM, 1)
                    player:RemoveQuest(QUEST_ID)
                    player:AddItem(QUEST_ITEM, 1)
                    if locationChar == player:GetGUIDLow() then
                        player:Teleport(oldMap, oldX, oldY, oldZ, oldO)
                    else
                        player:CastSpell(player, HEARTHSTONE, true)
                    end
                    player:SendAreaTriggerMessage("You didn't help your shadows in time and they got pulled into the Twisting Nether! Try again later.")
                    player:SendBroadcastMessage("You didn't help your shadows in time and they got pulled into the Twisting Nether! Try again later.")
                end
            end, 180000, 1)
            
            local shadows = player:GetCreaturesInRange(50, SHADOW_ENTRY)
            for _, shadow in pairs(shadows) do
                shadow:DespawnOrUnsummon()
            end

            local timerender = player:GetNearestCreature(50, TIMERENDER_ENTRY)
            local swirl = player:GetNearestCreature(50, SWIRL_ENTRY)
           
            if timerender then timerender:DespawnOrUnsummon() end
            if swirl then swirl:DespawnOrUnsummon() end
            
            eventState = 0
            
            local x, y, z, o = player:GetLocation()
            local facing = player:GetO()
            
            -- Spawn shadows in cone
            for i = -1, 1 do
                local angle = facing + (i * 0.5)
                local sx = x + (math.cos(angle) * 20)
                local sy = y + (math.sin(angle) * 20)
                local shadow = player:SpawnCreature(SHADOW_ENTRY, sx, sy, z, angle + math.pi, 1, DespawnTimer)
                shadow:SetLevel(player:GetLevel())
                shadow:SetDisplayId(player:GetDisplayId())
                shadow:SetFaction(35)
                shadow:AddAura(SHADOWFORM_AURA, shadow)
                shadow:AddAura(SHACKLE_AURA, shadow)
                shadow:AddAura(STUN_AURA, shadow)
            end
            
            -- Spawn Timerender
            local tx = x + (math.cos(facing) * 30)
            local ty = y + (math.sin(facing) * 30)
            local timerender = player:SpawnCreature(TIMERENDER_ENTRY, tx, ty, z, facing + math.pi, 1, DespawnTimer)
            timerender:SetLevel(player:GetLevel() + 3)
            timerender:AddAura(STUN_AURA, timerender)
            timerender:AddAura(IMMUNE_ALL, timerender)
            
            -- Spawn Swirl
            local twx = x + (math.cos(facing) * 35)
            local twy = y + (math.sin(facing) * 35)
            player:SpawnCreature(SWIRL_ENTRY, twx, twy, z, facing + math.pi, 1, DespawnTimer)
            
            player:AddAura(SHACKLE_AURA, player)
            player:AddAura(IMMUNE_ALL, player)
            print("Scheduling first event")
            player:RegisterEvent(function(eventId, delay, repeats, player)
                print("first event firing")
                local shadowSpeak = player:GetNearestCreature(50, SHADOW_ENTRY)
                shadowSpeak:SendUnitSay("Help us, "..player:GetName().."! We are shadows of your characters and have been trapped in time by the Black Dragonflight! Quickly, instruct us to break these chains and fight back!", 0)
                player:RegisterEvent(function(eventId, delay, repeats, player)
                    print("firing defend call")
                    player:SendAreaTriggerMessage("Instruct your shadows to defend themselves! Say \"formation shield\"!")
                    player:SendBroadcastMessage("Instruct your shadows to defend themselves! Say \"formation shield\"!")
                end, 5000)
            end, 5000)
        else
            player:SetData("ShadowsQuestEvent", nil)
            player:RemoveAura(IMMUNE_ALL)
            player:RemoveAura(SHACKLE_AURA)
        end
    end
end

local function Talk(event, player, msg, Type, lang)
    if player:GetAreaId() ~= AREA_ID then return end
    
    if not player:GetData("ShadowsQuestEvent") then print("event not active on player") return end
    
    local shadowSpeak = player:GetNearestCreature(50, SHADOW_ENTRY)
    
    if not shadowSpeak then return end
    
    if msg:lower() == "formation shield" and eventState == 0 then
        local shadows = player:GetCreaturesInRange(50, SHADOW_ENTRY)
        local timerender = player:GetNearestCreature(50, TIMERENDER_ENTRY)
        if timerender then
            for _, shadow in pairs(shadows) do
                shadow:SetFacingToObject(timerender)
            end
        end
        
        player:RegisterEvent(function(eventId, delay, repeats, player)
            local shadowSpeak = player:GetNearestCreature(50, SHADOW_ENTRY)
            shadowSpeak:SendUnitSay("Great! Now instruct us to attack our captor!", 0)
            player:RegisterEvent(function(eventId, delay, repeats, player)
                player:SendAreaTriggerMessage("Say \"Attack\" to make your shadows attack the captor!")
                player:SendBroadcastMessage("Say \"Attack\" to make your shadows attack the captor!")
                eventState = 1
            end, 2000, 1)
        end, 5000, 1)
    elseif msg:lower() == "attack" and eventState == 1 then
        local shadowSpeak = player:GetNearestCreature(50, SHADOW_ENTRY)
        local shadows = player:GetCreaturesInRange(50, SHADOW_ENTRY)
        local timerender = player:GetNearestCreature(50, TIMERENDER_ENTRY)
        for _, shadow in pairs(shadows) do
            shadow:RemoveAura(SHACKLE_AURA)
            shadow:RemoveAura(STUN_AURA)
        end
        shadowSpeak:RegisterEvent(function(eventId, delay, repeats, shadowSpeak)
            shadowSpeak:SendUnitSay("We need further directions!", 0)
            local timerender = shadowSpeak:GetNearestCreature(50, TIMERENDER_ENTRY)
            local shadows = shadowSpeak:GetCreaturesInRange(50, SHADOW_ENTRY)
            for _, shadow in pairs(shadows) do
                shadow:Attack(timerender)
            end
            shadowSpeak:Attack(timerender)
        end, 2000, 1)
        player:RegisterEvent(function(eventId, delay, repeats, player)
            player:SendAreaTriggerMessage("Target the Infinite Timerender and say \"cast Frostbolt\"!")
            player:SendBroadcastMessage("Target the Infinite Timerender and say \"cast Frostbolt\"!")
            eventState = 2
        end, 4000, 1)
    elseif msg:lower() == "cast frostbolt" and eventState == 2 and player:GetSelection() then
        local shadows = player:GetCreaturesInRange(50, SHADOW_ENTRY)
        local timerender = player:GetNearestCreature(50, TIMERENDER_ENTRY)
        
        if player:GetSelection() == timerender then
            timerender:RemoveAura(IMMUNE_ALL)
            local shadows = player:GetCreaturesInRange(50, SHADOW_ENTRY)
            for _, shadow in pairs(shadows) do
                shadow:CastSpell(timerender, 116, false)
            end
            
            player:RegisterEvent(function(eventId, delay, repeats, player)
                local timerender = player:GetNearestCreature(50, TIMERENDER_ENTRY)
                if timerender then
                    player:Kill(timerender)
                    timerender:DespawnOrUnsummon(5000)
                end
                
                player:CompleteQuest(QUEST_ID)
                
                local shadows = player:GetCreaturesInRange(50, SHADOW_ENTRY)
                for _, shadow in pairs(shadows) do
                    shadow:DespawnOrUnsummon(9000)
                end
                
                local shadowSpeak = player:GetNearestCreature(50, SHADOW_ENTRY)
                shadowSpeak:RegisterEvent(function(eventId, delay, repeats, shadowSpeak)
                    shadowSpeak:SendUnitSay("Thank you, we are free! You can now control your shadows. Speak to your Twiggy to learn more.", 0)
                end, 2000, 1)
                
                shadowSpeak:RegisterEvent(function(eventId, delay, repeats, shadowSpeak)
                    shadowSpeak:SendUnitSay("Allow us to teleport you back to your original location.", 0)
                end, 10000, 1)
                
                player:RegisterEvent(function(eventId, delay, repeats, player)
                    local shadows = player:GetCreaturesInRange(50, SHADOW_ENTRY)
                    for _, shadow in pairs(shadows) do
                        shadow:CastSpell(shadow, 32783, false)
                        player:RemoveItem(QUEST_ITEM, 1)
                        player:RemoveItem(TELEPORT_ITEM, 1)
                        --player:SetQuestStatus(QUEST_ID, 6)
                        player:RewardQuest(QUEST_ID)
                        shadowsEvent = os.time()
                    end
                end, 12000, 1)
                
                local swirl = player:GetCreaturesInRange(50, SWIRL_ENTRY)[1]
                if swirl then
                    swirl:DespawnOrUnsummon(5000)
                end
                
                player:RegisterEvent(function(eventId, delay, repeats, player)
                    eventState = 0
                    if locationChar == player:GetGUIDLow() then
                        player:Teleport(oldMap, oldX, oldY, oldZ, oldO)
                    else
                        player:CastSpell(player, HEARTHSTONE, true)
                    end
                end, 13000, 1)
                
            end, 4000, 1)
        end
    end
end


function AddLostAura(event, shadow, target)
    if shadow:GetAreaId() == AREA_ID then
        shadow:RegisterEvent(function(eventId, delay, repeats, shadow)
            shadow:AddAura(SHADOWFORM_AURA, shadow)
        end, 10, 1)
    end
end

local function OnLevelUp(event, player, oldLevel)
    if (player:GetClass() == 6 and oldLevel == dkLimit - 1) or
    (player:GetClass() ~= 6 and oldLevel == minLevel - 1)
    and not (player:GetQuestStatus(QUEST_ID) == 6)
    then
        player:AddItem(39163, 1)
        player:SendBroadcastMessage("You hear mysterious whispers echo in the horizon... An unknown item from the void appears!")
    end
end

local function OnLogin(event, player)
    if player:GetLevel() < minLevel then
        return
    end
    if player:HasQuest(QUEST_ID) and not player:HasItem(TELEPORT_ITEM, 1) then
        player:AddItem(TELEPORT_ITEM, 1)
    end
    if not player:HasQuest(QUEST_ID) and not (player:GetQuestStatus(QUEST_ID) == 6) and not player:HasItem(QUEST_ITEM) then
        if player:HasItem(TELEPORT_ITEM, 1) then
            player:RemoveItem(TELEPORT_ITEM, 1)
        end
        player:AddItem(QUEST_ITEM, 1)
        player:RegisterEvent(function(eventId, delay, repeats, player)
            player:SendBroadcastMessage("You hear mysterious whispers echo in the horizon... An unknown item from the void appears!")
        end, 1000, 1)
    end
    if player:HasItem(TELEPORT_ITEM, 1) and (player:GetQuestStatus(30000) == 6) then
        player:RemoveItem(TELEPORT_ITEM, 1)
        if player:HasQuest(QUEST_ID) then
            player:RemoveQuest(QUEST_ID)
        end
    end
    if player:HasItem(QUEST_ITEM, 1) and (player:GetQuestStatus(30000) == 6) then
        player:RemoveItem(QUEST_ITEM, 1)
        if player:HasQuest(QUEST_ID) then
            player:RemoveQuest(QUEST_ID)
        end
    end
end

local function OnQuestAbandon(event, player, questId)
    if questId == QUEST_ID then
        player:AddItem(QUEST_ITEM, 1)
    end
end

RegisterPlayerEvent(3, OnLogin)
RegisterPlayerEvent(13, OnLevelUp)
RegisterPlayerEvent(18, Talk)
RegisterPlayerEvent(28, ShadowsMap)
RegisterPlayerEvent(38, OnQuestAbandon)
RegisterItemEvent(TELEPORT_ITEM, 2, ShadowsTeleItem)
RegisterCreatureEvent(SHADOW_ENTRY, 1, AddLostAura)
RegisterCreatureEvent(SHADOW_ENTRY, 2, AddLostAura)
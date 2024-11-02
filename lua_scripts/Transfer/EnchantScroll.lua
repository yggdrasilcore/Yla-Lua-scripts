local requiredItemID = 4427
local requiredItemCount = 1

local T = {
    ["Menu"] = {
        {"|TInterface/ICONS/INV_Misc_QuestionMark:31:31:-24:0|tChoose item to enchant", 500},
        {"|TInterface/PaperDoll/UI-PaperDoll-Slot-Head:31:31:-24:0|tEnchant Headpiece", 0},
        {"|TInterface/PaperDoll/UI-PaperDoll-Slot-Shoulder:31:31:-24:0|tEnchant Shoulders", 2},
        {"|TInterface/PaperDoll/UI-PaperDoll-Slot-Chest:31:31:-24:0|tEnchant Chest", 4},
        {"|TInterface/PaperDoll/UI-PaperDoll-Slot-Legs:31:31:-24:0|tEnchant Legs", 6},
        {"|TInterface/PaperDoll/UI-PaperDoll-Slot-Feet:31:31:-24:0|tEnchant Boots", 7},
        {"|TInterface/PaperDoll/UI-PaperDoll-Slot-Wrists:31:31:-24:0|tEnchant Bracers", 8},
        {"|TInterface/PaperDoll/UI-PaperDoll-Slot-Hands:31:31:-24:0|tEnchant Gloves", 9},
        {"|TInterface/PaperDoll/UI-PaperDoll-Slot-Chest:31:31:-24:0|tEnchant Cloak", 14},
        {"|TInterface/PaperDoll/UI-PaperDoll-Slot-MainHand:31:31:-24:0|tEnchant Main Hand Weapons", 15},
        {"|TInterface/PaperDoll/UI-PaperDoll-Slot-MainHand:31:31:-24:0|tEnchant Two-Handed Weapons", 151},
        {"|TInterface/PaperDoll/UI-PaperDoll-Slot-SecondaryHand:31:31:-24:0|tEnchant Off Hand Weapons", 16},
        {"|TInterface/PaperDoll/UI-PaperDoll-Slot-SecondaryHand:31:31:-24:0|tEnchant Shields", 161}
    },
    
    [0] = { -- Headpiece
        {"|TInterface/PaperDoll/UI-PaperDoll-Slot-Head:31:31:-24:0|tEnchant Headpiece\n \n ", 0},
        {"|TInterface/ICONS/spell_fire_masterofelements:31:31:-24:0|tArcanum of Burning Mysteries\n \nStats: +30 spell power, +20 crit rating\n \n ", 3820, false},
        {"|TInterface/ICONS/ability_warrior_shieldmastery:31:31:-24:0|tArcanum of Blissful Mending\n \nStats: +30 spell power, +10 mana per 5 sec\n \n ", 3819, false},
        {"|TInterface/ICONS/ability_warrior_swordandboard:31:31:-24:0|tArcanum of the Stalward Protector\n \nStats: +37 stamina, +20 defense rating\n \n ", 3818, false},
        {"|TInterface/ICONS/ability_warrior_rampage:31:31:-24:0|tArcanum of Torment\n \nStats: +50 attack power, +20 crit rating\n \n ", 3817, false},
        {"|TInterface/ICONS/ability_warrior_shieldmastery:31:31:-24:0|tArcanum of the Savage Gladiator\n \nStats: +30 stamina, +25 resilience\n \n ", 3842, false},
        {"|TInterface/ICONS/ability_warrior_shieldmastery:31:31:-24:0|tArcanum of Triumph\n \nStats: +50 attack power, +20 resilience\n \n ", 3795, false},
        {"|TInterface/ICONS/spell_arcane_arcaneresilience:31:31:-24:0|tArcanum of Dominance\n \nStats: +29 spell power, +20 resilience\n \n ", 3797, false};
    },

    [2] = { -- Shoulders
        {"|TInterface/PaperDoll/UI-PaperDoll-Slot-Shoulder:31:31:-24:0|tEnchant Shoulders\n \n ", 2},
        {"|TInterface/ICONS/spell_holy_weaponmastery:31:31:-24:0|tInscription of Triumph\n \nStats: +40 attack power, +15 resilience\n \n ", 3793, false},
        {"|TInterface/ICONS/spell_holy_powerinfusion:31:31:-24:0|tInscription of Dominance\n \nStats: +23 spell power, +15 resilience\n \n ", 3794, false},
        {"|TInterface/ICONS/inv_shoulder_61:31:31:-24:0|tGreater Inscription of the Gladiator\n \nStats: +30 stamina, +15 resilience\n \n ", 3852, false},
        {"|TInterface/ICONS/inv_axe_85:31:31:-24:0|tGreater Inscription of the Axe\n \nStats: +40 attack power, +15 crit rating\n \n ", 3808, false},
        {"|TInterface/ICONS/spell_arcane_teleportorgrimmar:31:31:-24:0|tGreater Inscription of the Crag\n \nStats: +24 spell power, +8 mana per 5 sec\n \n ", 3809, false},
        {"|TInterface/ICONS/spell_holy_divinepurpose:31:31:-24:0|tGreater Inscription of the Pinnacle\n \nStats: +20 dodge rating, +15 defense rating\n \n ", 3811, false},
        {"|TInterface/ICONS/spell_nature_lightningoverload:31:31:-24:0|tGreater Inscription of the Storm\n \nStats: +24 spell power, +15 crit rating\n \n ", 3810, false};
    },

    [4] = { -- Chest
        {"|TInterface/PaperDoll/UI-PaperDoll-Slot-Chest:31:31:-24:0|tEnchant Chest\n \n ", 4},
        {"|TInterface/ICONS/inv_enchant_formulagood_01:31:31:-24:0|tPowerful Stats\n \nStats: +10 all stats\n \n ", 3832, false},
        {"|TInterface/ICONS/trade_engraving:31:31:-24:0|tSuper Health\n \nStats: +275 health\n \n ", 3297, false},
        {"|TInterface/ICONS/trade_engraving:31:31:-24:0|tGreater Mana Restoration\n \nStats: +10 mana per 5 sec\n \n ", 2381, false},
        {"|TInterface/ICONS/inv_enchant_formulagood_01:31:31:-24:0|tExceptional Resilience\n \nStats: +20 resilience\n \n ", 3245, false},
        {"|TInterface/ICONS/inv_enchant_formulagood_01:31:31:-24:0|tGreater Defense\n \nStats: +22 defense rating\n \n ", 1953, false};
    },

    [6] = { -- Legs
        {"|TInterface/PaperDoll/UI-PaperDoll-Slot-Legs:31:31:-24:0|tEnchant Legs\n \n ", 6},
        {"|TInterface/ICONS/inv_misc_armorkit_18:31:31:-24:0|tEarthen Leg Armor\n \nStats: +40 resilience, +28 stamina\n \n ", 3853, false},
        {"|TInterface/ICONS/inv_misc_armorkit_32:31:31:-24:0|tFrosthide Leg Armor\n \nStats: +55 stamina, +22 agility\n \n ", 3822, false},
        {"|TInterface/ICONS/inv_misc_armorkit_33:31:31:-24:0|tIcescale Leg Armor\n \nStats: +75 attack power, +22 crit rating\n \n ", 3823, false},
        {"|TInterface/ICONS/spell_nature_astralrecalgroup:31:31:-24:0|tBrilliant Spellthread\n \nStats: +50 spell power, +20 spirit\n \n ", 3719, false},
        {"|TInterface/ICONS/spell_nature_astralrecalgroup:31:31:-24:0|tSapphire Spellthread\n \nStats: +50 spell power, +30 stamina\n \n ", 3721, false};
    },    

    [7] = { -- Boots
        {"|TInterface/PaperDoll/UI-PaperDoll-Slot-Feet:31:31:-24:0|tEnchant Boots\n \n ", 7},
        {"|TInterface/ICONS/inv_enchant_formulagood_01:31:31:-24:0|tGreater Assault\n \nStats: +50 attack power\n \n ", 1597, false},
        {"|TInterface/ICONS/inv_enchant_formulagood_01:31:31:-24:0|tTuskars Vitality\n \nStats: +15 stamina, minor speed increase\n \n ", 3232, false},
        {"|TInterface/ICONS/inv_misc_note_01:31:31:-24:0|tSuperior Agility\n \nStats: +15 agility\n \n ", 983, false},
        {"|TInterface/ICONS/trade_engraving:31:31:-24:0|tGreater Spirit\n \nStats: +18 spirit\n \n ", 1147, false},
        {"|TInterface/ICONS/trade_engraving:31:31:-24:0|tGreater Vitality\n \nStats: +7 mana per sec\n \n ", 3244, false},
        {"|TInterface/ICONS/trade_engraving:31:31:-24:0|tIcewalker\n \nStats: +12 crit rating, +12 hit rating\n \n ", 3826, false},
        {"|TInterface/ICONS/trade_engraving:31:31:-24:0|tGreater Fortitude\n \nStats: +22 stamina\n \n ", 1075, false};
    },

    [8] = { -- Bracers
        {"|TInterface/PaperDoll/UI-PaperDoll-Slot-Wrists:31:31:-24:0|tEnchant Bracers\n \n ", 8},
        {"|TInterface/ICONS/inv_enchant_formulasuperior_01:31:31:-24:0|tMajor Stamina\n \nStats: +40 stamina\n \n ", 3850, false},
        {"|TInterface/ICONS/inv_enchant_formulagood_01:31:31:-24:0|tSuperior Spellpower\n \nStats: +30 spell power\n \n ", 2332, false},
        {"|TInterface/ICONS/inv_enchant_formulagood_01:31:31:-24:0|tGreater Assault\n \nStats: +50 attack power\n \n ", 3845, false},
        {"|TInterface/ICONS/inv_enchant_formulagood_01:31:31:-24:0|tMajor Spirit\n \nStats: +18 spirit\n \n ", 1147, false},
        {"|TInterface/ICONS/inv_enchant_formulagood_01:31:31:-24:0|tExpertise\n \nStats: +15 expertise rating\n \n ", 3231, false},
        {"|TInterface/ICONS/inv_enchant_formulagood_01:31:31:-24:0|tGreater Stats\n \nStats: +6 all stats\n \n ", 2661, false},
        {"|TInterface/ICONS/trade_engraving:31:31:-24:0|tExceptional Intellect\n \nStats: +16 intellect\n \n ", 1119, false};
    },

    [9] = { -- Gloves
        {"|TInterface/PaperDoll/UI-PaperDoll-Slot-Hands:31:31:-24:0|tEnchant Gloves\n \n ", 9},
        {"|TInterface/ICONS/trade_engraving:31:31:-24:0|tGreater Blasting\n \nStats: +16 crit rating\n \n ", 3249, false},
        {"|TInterface/ICONS/inv_enchant_formulagood_01:31:31:-24:0|tArmsman\n \nStats: +2% threat, +10 parry rating\n \n ", 3253, false},
        {"|TInterface/ICONS/trade_engraving:31:31:-24:0|tCrusher\n \nStats: +44 attack power\n \n ", 1603, false},
        {"|TInterface/ICONS/inv_enchant_formulasuperior_01:31:31:-24:0|tAgility\n \nStats: +15 agility", 3222, false},
        {"|TInterface/ICONS/spell_holy_greaterheal:31:31:-24:0|tPrecision\n \nStats: +20 hit rating\n \n ", 3234, false},
        {"|TInterface/ICONS/trade_engraving:31:31:-24:0|tExpertise\n \nStats: +15 expertise rating\n \n ", 3231, false},
        {"|TInterface/ICONS/trade_engraving:31:31:-24:0|tExceptional Spellpower\n \nStats: +28 spell power\n \n ", 3246, false};
    },

    [14] = { -- Cloak
        {"|TInterface/PaperDoll/UI-PaperDoll-Slot-Chest:31:31:-24:0|tEnchant Cloak\n \n ", 14},
        {"|TInterface/ICONS/inv_enchant_formulagood_01:31:31:-24:0|tShadow Armor\n \nStats: +10 agility, slight stealth increase\n \n ", 3256, false},
        {"|TInterface/ICONS/inv_enchant_formulagood_01:31:31:-24:0|tWisdom\n \nStats: +10 spirit, slightly reduced threat\n \n ", 3296, false},
        {"|TInterface/ICONS/inv_enchant_formulagood_01:31:31:-24:0|tTitanweave\n \nStats: +16 defense rating\n \n ", 1951, false},
        {"|TInterface/ICONS/inv_enchant_formulagood_01:31:31:-24:0|tGreater Speed\n \nStats: +23 haste rating\n \n ", 3831, false},
        {"|TInterface/ICONS/inv_enchant_formulagood_01:31:31:-24:0|tMighty Armor\n \nStats: +225 armor\n \n ", 3294, false},
        {"|TInterface/ICONS/trade_engraving:31:31:-24:0|tMajor Agility\n \nStats: +22 agility\n \n ", 1099, false},
        {"|TInterface/ICONS/trade_engraving:31:31:-24:0|tSpell Piercing\n \nStats: +35 spell penetration\n \n ", 1262, false};
    },

    [15] = {
        -- Main Hand
        {"|TInterface/ICONS/inv_enchant_formulasuperior_01:31:31:-24:0|tTitanguard\n \nStats: +50 stamina\n \n ", 3851, false},
        {"|TInterface/ICONS/inv_enchant_formulasuperior_01:31:31:-24:0|tAccuracy\n \nStats: +25 hit rating, +25 crit rating\n \n ", 3788, false},
        {"|TInterface/ICONS/inv_enchant_formulasuperior_01:31:31:-24:0|tBerserking\n \nStats: +400 attack power and reduced armor proc\n \n ", 3789, false},
        {"|TInterface/ICONS/inv_enchant_formulasuperior_01:31:31:-24:0|tBlack Magic\n \nStats: +250 haste proc on harmful spells\n \n ", 3790, false},
        {"|TInterface/ICONS/inv_enchant_formulasuperior_01:31:31:-24:0|tMighty Spellpower\n \nStats: +63 spell power\n \n ", 3834, false},
        {"|TInterface/ICONS/inv_enchant_formulasuperior_01:31:31:-24:0|tSuperior Potency\n \nStats: +65 attack power\n \n ", 3833, false},
        {"|TInterface/ICONS/inv_enchant_formulasuperior_01:31:31:-24:0|tIcebreaker\n \nStats: Fire damage proc on melee hit\n \n ", 3239, false},
        {"|TInterface/ICONS/inv_enchant_formulasuperior_01:31:31:-24:0|tLifeward\n \nStats: Heal proc on melee hit\n \n ", 3241, false},
        {"|TInterface/ICONS/inv_enchant_formulaepic_01:31:31:-24:0|tBlood Draining\n \nStats: Heal proc under 35%\n \n ", 3870, false},
        {"|TInterface/ICONS/inv_enchant_formulaepic_01:31:31:-24:0|tBlade Ward\n \nStats: Parry and damage proc on melee hit\n \n ", 3869, false},
        {"|TInterface/ICONS/inv_enchant_formulagood_01:31:31:-24:0|tExceptional Agility\n \nStats: +26 agility\n \n ", 1103, false},
        {"|TInterface/ICONS/inv_enchant_formulagood_01:31:31:-24:0|tExceptional Spirit\n \nStats: +45 spirit\n \n ", 3844, false},
        {"|TInterface/ICONS/inv_enchant_formulasuperior_01:31:31:-24:0|tExecutioner\n \nStats: +120 armor penetration proc\n \n ", 3225, false},
        {"|TInterface/ICONS/inv_enchant_formulasuperior_01:31:31:-24:0|tMongoose\n \nStats: +120 agility and haste proc\n \n ", 2673, false},
        
        -- Two-Handed
        {"|TInterface/ICONS/inv_enchant_formulasuperior_01:31:31:-24:0|tMassacre\n \nStats: +110 attack power\n \n ", 3827, true},
        {"|TInterface/ICONS/inv_enchant_formulasuperior_01:31:31:-24:0|tScourgebane\n \nStats: +140 attack power against undeads\n \n ", 3247, true},
        {"|TInterface/ICONS/inv_enchant_formulasuperior_01:31:31:-24:0|tGiant Slayer\n \nStats: Proc to slow and damage giants\n \n ", 3251, true},
        {"|TInterface/ICONS/inv_enchant_formulasuperior_01:31:31:-24:0|tGreater Spellpower\n \nStats: +81 spell power\n \n ", 3854, true};
    },
    
    [16] = {
        -- Offhand
        {"|TInterface/ICONS/inv_enchant_formulasuperior_01:31:31:-24:0|tTitanguard\n \nStats: +50 stamina\n \n ", 3851, false},
        {"|TInterface/ICONS/inv_enchant_formulasuperior_01:31:31:-24:0|tAccuracy\n \nStats: +25 hit rating, +25 crit rating\n \n ", 3788, false},
        {"|TInterface/ICONS/inv_enchant_formulasuperior_01:31:31:-24:0|tBerserking\n \nStats: +400 attack power and reduced armor proc\n \n ", 3789, false},
        {"|TInterface/ICONS/inv_enchant_formulasuperior_01:31:31:-24:0|tBlack Magic\n \nStats: +250 haste proc on harmful spells\n \n ", 3790, false},
        {"|TInterface/ICONS/inv_enchant_formulasuperior_01:31:31:-24:0|tMighty Spellpower\n \nStats: +63 spell power\n \n ", 3834, false},
        {"|TInterface/ICONS/inv_enchant_formulasuperior_01:31:31:-24:0|tSuperior Potency\n \nStats: +65 attack power\n \n ", 3833, false},
        {"|TInterface/ICONS/inv_enchant_formulasuperior_01:31:31:-24:0|tIcebreaker\n \nStats: Fire damage proc on melee hit\n \n ", 3239, false},
        {"|TInterface/ICONS/inv_enchant_formulasuperior_01:31:31:-24:0|tLifeward\n \nStats: Heal proc on melee hit\n \n ", 3241, false},
        {"|TInterface/ICONS/inv_enchant_formulaepic_01:31:31:-24:0|tBlood Draining\n \nStats: Heal proc under 35%\n \n ", 3870, false},
        {"|TInterface/ICONS/inv_enchant_formulaepic_01:31:31:-24:0|tBlade Ward\n \nStats: Parry and damage proc on melee hit\n \n ", 3869, false},
        {"|TInterface/ICONS/inv_enchant_formulagood_01:31:31:-24:0|tExceptional Agility\n \nStats: +26 agility\n \n ", 1103, false},
        {"|TInterface/ICONS/inv_enchant_formulagood_01:31:31:-24:0|tExceptional Spirit\n \nStats: +45 spirit\n \n ", 3844, false},
        {"|TInterface/ICONS/inv_enchant_formulasuperior_01:31:31:-24:0|tExecutioner\n \nStats: +120 armor penetration proc\n \n ", 3225, false},
        {"|TInterface/ICONS/inv_enchant_formulasuperior_01:31:31:-24:0|tMongoose\n \nStats: +120 agility and haste proc\n \n ", 2673, false},
        
        -- Shields
        {"|TInterface/ICONS/trade_engraving:31:31:-24:0|tDefense\n \nStats: +20 defense rating\n \n ", 1952, true},
        {"|TInterface/ICONS/trade_engraving:31:31:-24:0|tGreater Intellect\n \nStats: +25 intellect\n \n ", 1128, true},
        {"|TInterface/ICONS/inv_enchant_formulagood_01:31:31:-24:0|tShield Block\n \nStats: +15 block rating\n \n ", 2655, true},
        {"|TInterface/ICONS/spell_holy_greaterheal:31:31:-24:0|tResilience\n \nStats: +12 resilience\n \n ", 3229, true},
        {"|TInterface/ICONS/inv_misc_note_01:31:31:-24:0|tMajor Stamina\n \nStats: +18 stamina\n \n ", 1071, true},
        {"|TInterface/ICONS/spell_holy_greaterheal:31:31:-24:0|tTough Shield\n \nStats: +36 block rating\n \n ", 2653, true};
    },
};

local pVar = {};

local function Enchanter(event, player, item)
    if player:GetLevel() < 80 then
        player:SendBroadcastMessage("You need to be level 80 to use this item.")
        return false
    end
    pVar[player:GetName()] = nil
    for _, v in ipairs(T["Menu"]) do
        player:GossipMenuAddItem(3, v[1].."|R", 0, v[2])
    end
    player:GossipSendMenu(12, item)
    return false
end

local function EnchanterSelect(event, player, item, sender, intid, code)
    if (intid < 500) then
        local ID = intid
        local f
        if(intid == 161 or intid == 151) then
            ID = math.floor(intid/10)
            f = true
        end
        if intid == 161 then
            player:GossipMenuAddItem(3, "|TInterface/PaperDoll/UI-PaperDoll-Slot-SecondaryHand:31:31:-24:0|tEnchant Shields\n \n ", 0, 161)
        end
        if intid == 151 then
            player:GossipMenuAddItem(3, "|TInterface/PaperDoll/UI-PaperDoll-Slot-MainHand:31:31:-24:0|tEnchant Two-Handed Weapons\n \n ", 0, 161)
        end
        if intid == 15 then
            player:GossipMenuAddItem(3, "|TInterface/PaperDoll/UI-PaperDoll-Slot-MainHand:31:31:-24:0|tEnchant Main Hand Weapons\n \n ", 0, 161)
        end
        if intid == 16 then
            player:GossipMenuAddItem(3, "|TInterface/PaperDoll/UI-PaperDoll-Slot-SecondaryHand:31:31:-24:0|tEnchant Off Hand Weapons\n \n ", 0, 161)
        end
        pVar[player:GetName()] = intid
        if(T[ID]) then
            for i, v in ipairs(T[ID]) do
                if((not f and not v[3]) or (f and v[3])) then
                    player:GossipMenuAddItem(3, v[1].."|R", 0, v[2] + 900, false, "Are you sure you want to use:\n \n1x Enchanting Scroll for\n \n "..v[1])
                end
            end
        end
        player:GossipMenuAddItem(3, "|TInterface/ICONS/Trade_Engineering:31:31:-24:0|tBack", 0, 500)
        player:GossipSendMenu(12, item)
    elseif (intid == 500) then
        Enchanter(event, player, item)
    elseif (intid >= 900) then
        local ID = pVar[player:GetName()]
        if(ID == 161 or ID == 151) then
            ID = math.floor(ID/10)
        end
        for k, v in pairs(T[ID]) do
            if v[2] == (intid - 900) then
                local equipment = player:GetEquippedItemBySlot(ID)
                if equipment then
                    if player:GetItemCount(requiredItemID) >= requiredItemCount then
                        player:GossipComplete()
                        if v[3] then
                            local WType = equipment:GetSubClass()
                            if pVar[player:GetName()] == 151 then
                                if(WType == 1 or WType == 5 or WType == 6 or WType == 8 or WType == 10) then
                                    equipment:ClearEnchantment(0,0)
                                    equipment:SetEnchantment(intid - 900, 0, 0)
                                else
                                    player:SendAreaTriggerMessage("You do not have a Two-Handed Weapon equipped!")
                                end    
                            elseif pVar[player:GetName()] == 161 then
                                if(WType == 6) then
                                    equipment:ClearEnchantment(0,0)
                                    equipment:SetEnchantment(intid - 900, 0, 0)
                                else
                                    player:SendAreaTriggerMessage("You do not have a Shield equipped!")
                                end
                            end
                        else
                            local offHand = player:GetEquippedItemBySlot(16)
                            if ID == 16 and offHand and offHand:GetSubClass() ~= 0 then
                                equipment:ClearEnchantment(0,0)
                                equipment:SetEnchantment(intid - 900, 0, 0)
                                player:CastSpell(player, 36937)
                            elseif ID == 16 then
                                player:SendAreaTriggerMessage("You do not have an Off Hand Weapon equipped!")
                            else
                                equipment:ClearEnchantment(0,0)
                                equipment:SetEnchantment(intid - 900, 0, 0)
                                player:CastSpell(player, 36937)
                            end
                        end
                    else
                        player:SendAreaTriggerMessage("You do not have enough Enchanting Scrolls!")
                    end
                else
                    player:SendAreaTriggerMessage("You have no item to enchant in the selected slot!")
                end
                return
            end
        end
        EnchanterSelect(event, player, item, sender, pVar[player:GetName()], nil)
    end
end

RegisterItemGossipEvent(4427, 1, Enchanter)
RegisterItemGossipEvent(4427, 2, EnchanterSelect)

local query = [[
    UPDATE item_template
    SET spellid_1 = 47292,
        description = 'Use this scroll to choose a new enchant for your transferred items. Consumed on use.',
        bonding = 1,
        RequiredLevel = 80,
        maxcount = 99,
        stackable = 99,
        quality = 6,
        name = 'Scroll of Limitless Enchanting'
    WHERE entry = 4427;
]]

--WorldDBQuery(query) -- Commented out completed worlddbquery to reduce load
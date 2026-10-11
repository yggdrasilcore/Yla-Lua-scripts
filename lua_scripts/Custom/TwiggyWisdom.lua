local ITEM_ENTRY = 41415
if GetStateMapId() == -1 then return end

local SCROLL_SPELLS = {
    [1] = 58449, -- Strength VIII
    [2] = 58451, -- Agility VIII
    [3] = 48104, -- Spirit VIII
    [4] = 48102, -- Stamina VIII
    [5] = 48100, -- Intellect VIII
    [6] = 58453  -- Protection VIII
}

local function ShowMainMenu(player, item)
    player:GossipClearMenu()
    player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_groupneedmore:32:32:-22:0|tGroup Buffs\n \nApply buff to all group/raid members\n \n ", 0, 100)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/achievement_pvp_a_12:32:32:-22:0|tIndividual Buffs\n \nApply buff to selected target or yourself\n \n ", 0, 200)
    player:GossipSendMenu(12, item)
end

local function ShowScrollMenu(player, item, isGroup)
    player:GossipClearMenu()
    local prefix = isGroup and "Group " or ""
    local menuOffset = isGroup and 1000 or 0
    
    player:GossipMenuAddItem(4, "|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-22:0|tWhich " .. prefix .. "Scroll do you want to use?\n \n ", 0, 0)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_nature_strength:32:32:-22:0|t" .. prefix .. "Scroll of Strength VIII\n \nIncreases the target's Strength by 30 for 30 min. Only one scroll effect can be active at a time.\n \n ", 0, 1 + menuOffset)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_holy_blessingofagility:32:32:-22:0|t" .. prefix .. "Scroll of Agility VIII\n \nIncreases the target's Agility by 30 for 30 min. Only one scroll effect can be active at a time.\n \n ", 0, 2 + menuOffset)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_shadow_burningspirit:32:32:-22:0|t" .. prefix .. "Scroll of Spirit VIII\n \nIncreases the target's Spirit by 64 for 30 min. Only one scroll effect can be active at a time.\n \n ", 0, 3 + menuOffset)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_holy_blessingofstamina:32:32:-22:0|t" .. prefix .. "Scroll of Stamina VIII\n \nIncreases the target's Stamina by 132 for 30 min. Only one scroll effect can be active at a time.\n \n ", 0, 4 + menuOffset)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_holy_arcaneintellect:32:32:-22:0|t" .. prefix .. "Scroll of Intellect VIII\n \nIncreases the target's Intellect by 48 for 30 min. Only one scroll effect can be active at a time.\n \n ", 0, 5 + menuOffset)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_warrior_defensivestance:32:32:-22:0|t" .. prefix .. "Scroll of Protection VIII\n \nIncreases the target's Armor by 750 for 30 min. Only one scroll effect can be active at a time.\n \n ", 0, 6 + menuOffset)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/trade_engineering:32:32:-22:0|tBack to Main Menu\n \n ", 0, 999)
    player:GossipSendMenu(12, item)
end

local function OnUse(event, player, item, target)
    if player:IsDead() or player:IsMounted() or player:InBattleground() or player:InArena() then
        player:SendBroadcastMessage("You can't use this item right now.")
        player:SendAreaTriggerMessage("You can't use this item right now.")
        return false
    end
    ShowMainMenu(player, item)
    return false
end

local function CastOnGroup(player, spellId)
    player:CastSpell(player, spellId, true)
    local playerPet = player:GetPet()
    if playerPet then
        player:CastSpell(playerPet, spellId, true)
    end
    for _, member in pairs(player:GetPlayersInRange(100)) do
        if member and member ~= player and member:IsAlive() and member:IsInWorld()
            and (player:IsInSameGroupWith(member) or player:IsInSameRaidWith(member)) then
            player:CastSpell(member, spellId, true)
            local pet = member:GetPet()
            if pet then
                player:CastSpell(pet, spellId, true)
            end
        end
    end
end

local function OnGossipSelect(event, player, item, sender, intid, code)
    if intid == 100 then
        -- Group buffs selected
        ShowScrollMenu(player, item, true)
        return
    elseif intid == 200 then
        -- Individual buffs selected
        ShowScrollMenu(player, item, false)
        return
    elseif intid == 999 then
        -- Back to main menu
        ShowMainMenu(player, item)
        return
    elseif intid >= 1001 and intid <= 1006 then
        -- Group buff spell selected
        local spellIndex = intid - 1000
        if SCROLL_SPELLS[spellIndex] then
            CastOnGroup(player, SCROLL_SPELLS[spellIndex])
            ShowScrollMenu(player, item, true)
        end
        return
    elseif intid >= 1 and intid <= 6 then
        -- Individual buff spell selected
        local target = player:GetSelection()
        if not target then
            target = player
        end
        if (target == player) or (target:IsPlayer() and
        ((player:IsAlliance() and target:IsAlliance()) or
        (player:IsInSameGroupWith(target) or player:IsInSameRaidWith(target))) and
        (target:IsAlive() or target:GetLevel() >= 70))
        then
            player:CastSpell(target, SCROLL_SPELLS[intid], true)
            local pet = target:GetPet()
            if pet then
                player:CastSpell(pet, SCROLL_SPELLS[intid], true)
            end
            ShowScrollMenu(player, item, false)
        else
            player:SendBroadcastMessage("You can't use this item on this target.")
            player:SendAreaTriggerMessage("You can't use this item on this target.")
            player:GossipComplete()
        end
        return
    else
        -- Unknown option, show main menu
        ShowMainMenu(player, item)
        return
    end
end

RegisterItemEvent(ITEM_ENTRY, 2, OnUse)
RegisterItemGossipEvent(ITEM_ENTRY, 2, OnGossipSelect)
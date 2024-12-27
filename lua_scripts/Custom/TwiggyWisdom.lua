local ITEM_ENTRY = 41415

local SCROLL_SPELLS = {
    [1] = 58449, -- Strength VIII
    [2] = 58451, -- Agility VIII
    [3] = 48104, -- Spirit VIII
    [4] = 48102, -- Stamina VIII
    [5] = 48100, -- Intellect VIII
    [6] = 58453  -- Protection VIII
}

local function OnUse(event, player, item, target)
    if player:IsDead() or player:IsMounted() or player:InBattleground() or player:InArena() then
        player:SendBroadcastMessage("You can't use this item right now.")
        player:SendAreaTriggerMessage("You can't use this item right now.")
        return false
    end

    player:GossipClearMenu()
    player:GossipMenuAddItem(4, "|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-22:0|tWhich Scroll do you want to use?\n \n ", 0, 0)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_nature_strength:32:32:-22:0|tScroll of Strength VIII\n \nIncreases the target's Strength by 30 for 30 min. Only one scroll effect can be active at a time.\n \n ", 0, 1)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_holy_blessingofagility:32:32:-22:0|tScroll of Agility VIII\n \nIncreases the target's Agility by 30 for 30 min. Only one scroll effect can be active at a time.\n \n ", 0, 2)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_shadow_burningspirit:32:32:-22:0|tScroll of Spirit VIII\n \nIncreases the target's Spirit by 64 for 30 min. Only one scroll effect can be active at a time.\n \n ", 0, 3)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_holy_blessingofstamina:32:32:-22:0|tScroll of Stamina VIII\n \nIncreases the target's Stamina by 132 for 30 min. Only one scroll effect can be active at a time.\n \n ", 0, 4)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_holy_arcaneintellect:32:32:-22:0|tScroll of Intellect VIII\n \nIncreases the target's Intellect by 48 for 30 min. Only one scroll effect can be active at a time.\n \n ", 0, 5)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_warrior_defensivestance:32:32:-22:0|tScroll of Protection VIII\n \nIncreases the target's Armor by 750 for 30 min. Only one scroll effect can be active at a time.\n \n ", 0, 6)
    player:GossipSendMenu(12, item)
    return false
end

local function OnGossipSelect(event, player, item, sender, intid, code)
    if not SCROLL_SPELLS[intid] then
        OnUse(_, player, item, player:GetSelection())
        return
    end

    local target = player:GetSelection()
    if not target then
        target = player
    end

    if target:IsPlayer() and
    ((player:IsAlliance() and not target:IsAlliance()) or 
    (not player:IsAlliance() and target:IsAlliance()) or
    (player:IsInSameGroupWith(target) or player:IsInSameRaidWith(target)))
    and target ~= player and (not target:IsAlive() or target:GetLevel() < 70) then
        player:SendBroadcastMessage("You can't use this item on this target.")
        player:SendAreaTriggerMessage("You can't use this item on this target.")
    else
        player:CastSpell(target, SCROLL_SPELLS[intid], true)
    end
    
    player:GossipComplete()
end

RegisterItemEvent(ITEM_ENTRY, 2, OnUse)
RegisterItemGossipEvent(ITEM_ENTRY, 2, OnGossipSelect)
-- Azshara Mall-only script (mall map 37).
if GetStateMapId() ~= 37 then return end

-- WorldDB queries to insert data if not already done

--local flags_value = 134250560

--for _, item_id in ipairs(ItemsToSell) do
--    local update_query1 = string.format("UPDATE `item_template` SET `flags` = %d WHERE `entry` = %d", flags_value, item_id)
--    local update_query2 = string.format("UPDATE `item_template` SET `spellcharges_1` = 0 WHERE `entry` = %d", item_id)
--    WorldDBExecute(update_query1)
--    WorldDBExecute(update_query2)
--end

local NPC_ID = 600000
local model_ID = 21113
local VoteTokenItemID = 20880
local price = 50
local CurrencyName = "Vote Tokens"

local ItemsToSell = {
    13582, 13583, 13584, 25535, 33816, 48527, 20371, 20651, 22114,
    46802, 32233, 32616, 32617, 32622, 33816, 33818, 35349, 35350,
    33993, 34955, 38050, 39656, 41133, 43517, 43698, 49662, 49663,
    45180, 46767, 49646, 49693, 54847, 54857, 56806, 49665, 21168,
    19055, 19054, 18964, 45942, 32588, 34493, 34492, 34518, 34519,
    37297, 37298, 49343, 54810, 38658, 19450, 11903, 49362
}

local VotePointCost = 50
local ItemsPerPage = 11

-- Static icon index, dumped from ycore_yla.icons (see SQL below).
local icons = {
[11903]="INV_Box_PetCarrier_01",
[13582]="Spell_Shadow_SummonFelHunter",
[13583]="INV_Belt_05",
[13584]="INV_DiabloStone",
[18964]="INV_Egg_02",
[19054]="INV_Misc_Orb_05",
[19055]="INV_Misc_Orb_01",
[19450]="INV_Egg_04",
[20371]="INV_Egg_03",
[20651]="INV_Egg_03",
[21168]="inv_pet_babyshark",
[22114]="inv_pet_pinkmurlocegg",
[25535]="INV_Netherwhelp",
[32233]="INV_Drink_13",
[32588]="INV_Misc_Food_24",
[32616]="inv_pet_egbert",
[32617]="inv_pet_sleepywilly",
[32622]="INV_Belt_16",
[33816]="INV_Drink_19",
[33818]="INV_Drink_19",
[33993]="Spell_Shaman_Hex",
[34492]="INV_Misc_EngGizmos_RocketChicken",
[34493]="INV_Misc_DragonKite_02",
[34518]="INV_Misc_Coin_01",
[34519]="INV_Misc_Coin_03",
[34955]="inv_pet_scorchedstone",
[35349]="INV_Drink_19",
[35350]="INV_Drink_19",
[37297]="INV_Jewelry_Amulet_03",
[37298]="INV_Jewelry_Talisman_10",
[38050]="Spell_Nature_GroundingTotem",
[38658]="Ability_Hunter_Pet_Bat",
[39656]="INV_Sword_07",
[41133]="inv_misc_penguinpet",
[43517]="inv_misc_penguinpet",
[43698]="INV_Misc_MonsterTail_03",
[45180]="INV_Spear_05",
[45942]="achievement_boss_xt002deconstructor_01",
[46767]="INV_Misc_Key_05",
[46802]="INV_Egg_03",
[48527]="INV_Misc_QirajiCrystal_05",
[49343]="ability_mount_spectraltiger",
[49362]="INV_Misc_Head_Dragon_Black",
[49646]="ability_hunter_pet_corehound",
[49662]="inv_misc_pet_02",
[49663]="inv_misc_pet_04",
[49665]="inv_misc_pet_03",
[49693]="INV_Misc_Urn_01",
[54810]="inv_pet_celestialdragon",
[54847]="achievement_boss_xt002deconstructor_01",
[54857]="INV_Spear_05",
[56806]="t_roboticon",
}

local function GenerateMenu(page, player, object)
    local startIndex = ((page - 1) * ItemsPerPage) + 1
    local endIndex = math.min(startIndex + ItemsPerPage - 1, #ItemsToSell)

    player:GossipMenuAddItem(1, "|TInterface/ICONS/Inv_bijou_gold:32:32:-22:0|tCompanions cost "..price.." "..CurrencyName.." ea.", 0, 12)
    for i = startIndex, endIndex do
        local itemId = ItemsToSell[i]
        local itemLink = GetItemLink(itemId)
        if itemLink then
            player:GossipMenuAddItem(1, "|TInterface/ICONS/"..icons[itemId]..":32:32:-22:0|t" .. itemLink .. "", 0, itemId)
        end
    end

    if page > 1 then
        player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_spy:31:31:-24:0|tPrevious page", 1, page - 1)
    end

    if endIndex < #ItemsToSell then
        player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_spy:31:31:-24:0|tNext page", 1, page + 1)
    end

    player:GossipSendMenu(1, object)
end

local function OnGossipHello(event, player, object)
    GenerateMenu(1, player, object)
end

local function OnGossipSelect(event, player, object, sender, intid, code, menu_id)
    if intid == 12 then
        OnGossipHello(event, player, object)
    end
    if sender == 0 then
        local itemId = intid
        local itemLink = GetItemLink(itemId)
        
        if not itemLink then
            player:SendBroadcastMessage("Error: Item not found.")
            player:GossipComplete()
            return
        end
        
        if player:HasItem(itemId) then
            player:SendBroadcastMessage("You already own " .. itemLink .. ".")
            player:GossipComplete()
            return
        end
        
        -- Add confirmation dialogue
        player:GossipMenuAddItem(0, "|TInterface/ICONS/"..icons[itemId]..":32:32:-22:0|tConfirm purchase\n \n Are you sure you want to buy " .. itemLink .. " for " .. VotePointCost .. " "..CurrencyName.."?\n \n ", 2, itemId)
        player:GossipMenuAddItem(0, "|TInterface/ICONS/ability_spy:31:31:-24:0|tNo, I've changed my mind.", 1, 1)  -- Return to first page
        player:GossipSendMenu(1, object)
    elseif sender == 1 then
        GenerateMenu(intid, player, object)
    elseif sender == 2 then
        -- Confirmation to buy
        local itemId = intid
        local itemLink = GetItemLink(itemId)
        local voteTokens = player:GetItemCount(VoteTokenItemID)
        
        if voteTokens >= VotePointCost then
            player:RemoveItem(VoteTokenItemID, VotePointCost)
            player:AddItem(itemId, 1)
            player:SendBroadcastMessage("You have purchased " .. itemLink .. " for " .. VotePointCost .. " vote tokens.")
        else
            player:SendBroadcastMessage("You don't have enough vote tokens to purchase this item.")
        end
        player:GossipComplete()
    end
end

RegisterCreatureGossipEvent(NPC_ID, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ID, 2, OnGossipSelect)
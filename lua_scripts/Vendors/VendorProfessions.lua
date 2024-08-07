local NPC_ID = 190013
local EMBLEM_OF_FROST_ITEM_ID = 49426
local EMBLEMS_COST = 100
local SKILL_LEVEL = 450

local professions = {
    {id = 171, name = "Alchemy", icon = "TRADE_ALCHEMY", unlearn = 415, learn = 416, unlearn_spell = 51303, learn_spells = {2259, 3101, 3464, 11611, 28596, 51303, 51304}},
    {id = 164, name = "Blacksmithing", icon = "TRADE_BLACKSMITHING", unlearn = 417, learn = 418, unlearn_spell = 51298, learn_spells = {2018, 3100, 9785, 29844, 51298, 9788, 9787, 17041, 17040, 17039, 51300}},
    {id = 333, name = "Enchanting", icon = "INV_Enchant_DustArcane", unlearn = 419, learn = 420, unlearn_spell = 51312, learn_spells = {7411, 7412, 7413, 13920, 28029, 51312, 51313}},
    {id = 202, name = "Engineering", icon = "TRADE_ENGINEERING", unlearn = 421, learn = 422, unlearn_spell = 51305, learn_spells = {4036, 4037, 4038, 12656, 30350, 51305, 20219, 20222, 51306}},
    {id = 182, name = "Herbalism", icon = "TRADE_HERBALISM", unlearn = 423, learn = 424, unlearn_spell = 50301, learn_spells = {51005}},
    {id = 773, name = "Inscription", icon = "INV_Inscription_Tradeskill01", unlearn = 425, learn = 426, unlearn_spell = 45380, learn_spells = {45357, 45358, 45359, 45360, 45361, 45363}},
    {id = 755, name = "Jewelcrafting", icon = "INV_MISC_GEM_BLOODGEM_01", unlearn = 427, learn = 428, unlearn_spell = 51310, learn_spells = {25229, 25230, 28894, 28895, 28897, 51311, 31252}},
    {id = 165, name = "Leatherworking", icon = "TRADE_LEATHERWORKING", unlearn = 429, learn = 430, unlearn_spell = 51301, learn_spells = {2108, 3104, 3811, 10662, 32549, 51302}},
    {id = 186, name = "Mining", icon = "TRADE_MINING", unlearn = 431, learn = 432, unlearn_spell = 50309, learn_spells = {2575, 2576, 3564, 10248, 29354, 50310}},
    {id = 393, name = "Skinning", icon = "INV_Misc_Pelt_Wolf_01", unlearn = 433, learn = 434, unlearn_spell = 50307, learn_spells = {8613, 8617, 8618, 10768, 32678, 50305}},
    {id = 185, name = "Cooking", icon = "INV_MISC_FOOD_15", unlearn = 435, learn = 436, unlearn_spell = 51295, learn_spells = {2550, 3102, 3413, 18260, 33359, 51295, 51296}},
    {id = 129, name = "First Aid", icon = "INV_Misc_Bandage_01", unlearn = 437, learn = 438, unlearn_spell = 50299, learn_spells = {50299}},
    {id = 356, name = "Fishing", icon = "TRADE_FISHING", unlearn = 439, learn = 440, unlearn_spell = 51293, learn_spells = {7620, 7731, 7732, 18248, 33095, 51293, 51294}},
    {id = 197, name = "Tailoring", icon = "TRADE_TAILORING", unlearn = 441, learn = 442, unlearn_spell = 51308, learn_spells = {3908, 3909, 3910, 12180, 26790, 51308, 26798, 26801, 26797, 51309}}
}

local primary_professions = {171, 164, 333, 202, 182, 773, 755, 165, 186, 393, 197}

local function CountPrimaryProfessions(player)
    local count = 0
    for _, prof_id in ipairs(primary_professions) do
        if player:HasSkill(prof_id) then
            count = count + 1
        end
    end
    return count
end

local function GetPlayerSkillLevel(player, skillID)
    local skillValue, maxSkillValue = player:GetSkillValue(skillID), player:GetMaxSkillValue(skillID)
    return skillValue, maxSkillValue
end

local function OnGossipHello(event, player, object)
    for _, prof in ipairs(professions) do
        player:GossipMenuAddItem(0, "|TINTERFACE/ICONS/" .. prof.icon .. ":28:28:-25:0|t" .. prof.name, 0, prof.id, false, "Are you sure you want to learn " .. prof.name .. " for " .. EMBLEMS_COST .. " Emblems of Frost?", 0)
    end
    player:GossipSendMenu(1, object)
end

local function LearnProfession(event, player, object, profession)
    if CountPrimaryProfessions(player) >= 2 and table.contains(primary_professions, profession.id) then
        player:SendBroadcastMessage("You cannot learn more than two primary professions.")
        player:GossipComplete()
        return
    end

    -- Check if the player already has the profession at 450/450
    local currentSkillLevel, maxSkillLevel = GetPlayerSkillLevel(player, profession.id)
    if currentSkillLevel == 450 and maxSkillLevel == 450 then
        player:SendBroadcastMessage("You already have " .. profession.name .. " learned at the maximum skill level.")
        player:GossipComplete()
        return
    end

    -- Check if player has enough Emblems of Frost
    local emblemCount = player:GetItemCount(EMBLEM_OF_FROST_ITEM_ID)
    if emblemCount < EMBLEMS_COST then
        player:SendBroadcastMessage("You don't have enough Emblems of Frost to learn this profession.")
        player:GossipComplete()
        return
    end

    -- Deduct Emblems of Frost
    player:RemoveItem(EMBLEM_OF_FROST_ITEM_ID, EMBLEMS_COST)

    -- Learn the profession
    for _, spellId in ipairs(profession.learn_spells) do
        player:LearnSpell(spellId)
    end

    -- Set skill level to 450
    player:SetSkill(profession.id, 450, 450, 450)

    player:GossipComplete()
    player:SendBroadcastMessage("You have learned " .. profession.name .. " and your skill level is now " .. SKILL_LEVEL .. "!")
end

local function OnGossipSelect(event, player, object, sender, intid, code)
    for _, prof in ipairs(professions) do
        if intid == prof.id then
            LearnProfession(event, player, object, prof)
            return
        end
    end

    if intid == 999 then
        OnGossipHello(event, player, object)
        return
    end
end

RegisterCreatureGossipEvent(NPC_ID, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ID, 2, OnGossipSelect)

-- Utility function to check if a table contains a value
function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

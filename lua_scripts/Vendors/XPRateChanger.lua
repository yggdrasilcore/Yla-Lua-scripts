local charactersSQL = [[ CREATE TABLE IF NOT EXISTS `character_rate_xp` (`guid` int(11) unsigned NOT NULL, `rate` int(11) NOT NULL DEFAULT 0, PRIMARY KEY (`guid`)) ENGINE=InnoDB DEFAULT CHARSET=utf8;]]
CharDBQuery(charactersSQL)
local npc = 190023
local rates = {
    --     rate,     gold,   token,     amount
    [1] = { 1,         0,        0,       0},
    [2] = { 2,         0,        0,       0},
    [3] = { 3,         0,        0,       0},
    [4] = { 4,         0,        0,       0},
    [5] = { 5,         0,        0,       0},
    [6] = { 6,         0,    20880,       1},
    [7] = { 7,         0,    20880,       2},
    [8] = { 8,         0,    20880,       3},
    [9] = { 9,         0,    20880,       4},
    [10] = { 10,       0,    20880,       5},
}
local Cache = {}
local function LoadCache()
    local result = CharDBQuery("SELECT guid, rate FROM character_rate_xp")
    if result then
        repeat
            Cache[result:GetUInt32(0)] = result:GetUInt8(1)
        until not result:NextRow()
    end
end LoadCache()
local function OnGossipHello(event, player, object)
    player:GossipClearMenu()
    
    local currentRate = Cache[player:GetGUIDLow()] or 1
    if player:GetLevel() < 80 then
		object:SendUnitWhisper("Your experience rate is: x"..currentRate, 0, player)
    end
    for k, v in ipairs(rates) do
        local cost = ""
        if v[4] > 0 and currentRate < v[1] then
            cost = "("..v[4].." x Vote Token)"
        end
        if player:GetLevel() <= 79 then
			player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:28:28:-15:0|tRates x"..v[1].." "..cost, 0, v[1], false, "Are you sure you want to change your experience rate to: x"..v[1], v[2]*10000)
		end
    end
    player:GossipSendMenu(1, object)
end RegisterCreatureGossipEvent(npc, 1, OnGossipHello)

local function OnGossipSelect(event, player, object, sender, intid, code, menu_id)
    
    local currentRate = Cache[player:GetGUIDLow()] or 1
    
    -- Free to go to a lower XP tier
    if currentRate > intid then
        Cache[player:GetGUIDLow()] = intid
        CharDBExecute("REPLACE INTO character_rate_xp (guid, rate) VALUES ('"..player:GetGUIDLow().."', '"..intid.."')")
        object:SendUnitWhisper("Congratulations, you changed your experience rate to: x"..intid, 0, player)
        player:CastSpell(player, 47292, true)
        player:GossipComplete()
        return
    end
    
    if rates[intid][4] > 0 then
        if not player:HasItem(rates[intid][3], rates[intid][4]) then
            player:GossipComplete()
            object:SendUnitWhisper("You don't have sufficient funds!", 0, player)
            return
        end
        player:RemoveItem(rates[intid][3], rates[intid][4])
    end
    
    player:ModifyMoney(-rates[intid][2]*10000)
    Cache[player:GetGUIDLow()] = intid
    CharDBExecute("REPLACE INTO character_rate_xp (guid, rate) VALUES ('"..player:GetGUIDLow().."', '"..intid.."')")
    object:SendUnitWhisper("Congratulations, you changed your experience rate to: x"..intid, 0, player)
    player:CastSpell(player, 47292, true)
    player:GossipComplete()
end RegisterCreatureGossipEvent(npc, 2, OnGossipSelect)

local function OnGiveXP(event, player, amount, victim)
    if Cache[player:GetGUIDLow()] then
        amount = amount * Cache[player:GetGUIDLow()]
        return amount
    end
end RegisterPlayerEvent(12, OnGiveXP)
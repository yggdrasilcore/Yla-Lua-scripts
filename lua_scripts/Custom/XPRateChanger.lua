local Multistate = require("Multistate")
-------------------------------------------------------------------------------------------------------------------------
-- XP changer script start
-------------------------------------------------------------------------------------------------------------------------

CharDBExecute("CREATE TABLE IF NOT EXISTS `character_rate_xp` (`guid` int(11) unsigned NOT NULL, `rate` int(11) NOT NULL DEFAULT 0, `max_paid_rate` int(11) NOT NULL DEFAULT 0, PRIMARY KEY (`guid`)) ENGINE=InnoDB DEFAULT CHARSET=utf8;")

local currencyID = 20880
local currencyNameSingular = "Vote Token"
local currencyName = "Vote Tokens"

local XPCache = {}
local MaxPaidCache = {}

local function OnTalkToGreetingTwig(event, player, object)
    local guid = player:GetGUIDLow()
    local currentRate = XPCache[guid] or 1
    
    player:GossipClearMenu()
    
    local cost6 = " (1x "..currencyNameSingular..")"
    local cost7 = " (2x "..currencyName..")"
    local cost8 = " (3x "..currencyName..")"
    local cost9 = " (4x "..currencyName..")"
    local cost10 = " (5x "..currencyName..")"
    
    if object == player or (Multistate.GetData(player, "VIPTime") and Multistate.GetData(player, "VIPTime") > os.time()) then
        cost6 = ""
        cost7 = ""
        cost8 = ""
        cost9 = ""
        cost10 = ""
    end

    local maxPaid = MaxPaidCache[guid] or 0
    if maxPaid >= 6 then cost6 = "" end
    if maxPaid >= 7 then cost7 = "" end
    if maxPaid >= 8 then cost8 = "" end
    if maxPaid >= 9 then cost9 = "" end
    if maxPaid >= 10 then cost10 = "" end

    if not (object == player) then
		local area = object:GetAreaId()
        player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/ABILITY_DRUID_MANATREE:40:40:-28:0|tTell me about Yggdrasil", 0, 11)
        player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/spell_fire_burningspeed:40:40:-28:0|tLet me change my XP rate", 0, 12)
		if (area == 188 or area == 3431 or area == 2117 or area == 363 or area == 221 or area == 3526 or area == 132 or area == 9) then
			player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/inv_misc_map02:40:40:-28:0|tChange starting zone", 0, 13)
        end
		player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/inv_misc_enggizmos_27:40:40:-28:0|tClose", 0, 997)
        player:GossipSendMenu(12, object)
    else
        if player:GetLevel() == 80 and not (player:GetClass() == 3) then
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/achievement_level_80:40:40:-28:0|tNo services available\n \nThere are no experience services available at level 80.\n \n ", 0, 12)
        else
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/spell_fire_burningspeed:40:40:-28:0|tYour experience rate is: x"..currentRate, 0, 12)
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:40:40:-28:0|tSet rates x1", 0, 1, false, "Are you sure you want to change your experience rate to: x1?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:40:40:-28:0|tSet rates x2", 0, 2, false, "Are you sure you want to change your experience rate to: x2?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:40:40:-28:0|tSet rates x3", 0, 3, false, "Are you sure you want to change your experience rate to: x3?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:40:40:-28:0|tSet rates x4", 0, 4, false, "Are you sure you want to change your experience rate to: x4?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:40:40:-28:0|tSet rates x5", 0, 5, false, "Are you sure you want to change your experience rate to: x5?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:40:40:-28:0|tSet rates x6"..cost6, 0, 6, false, "Are you sure you want to change your experience rate to: x6?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:40:40:-28:0|tSet rates x7"..cost7, 0, 7, false, "Are you sure you want to change your experience rate to: x7?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:40:40:-28:0|tSet rates x8"..cost8, 0, 8, false, "Are you sure you want to change your experience rate to: x8?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:40:40:-28:0|tSet rates x9"..cost9, 0, 9, false, "Are you sure you want to change your experience rate to: x9?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:40:40:-28:0|tSet rates x10"..cost10, 0, 10, false, "Are you sure you want to change your experience rate to: x10?")
        end
        if not (object == player) then
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/inv_misc_enggizmos_27:40:40:-28:0|tClose", 0, 997)
            player:GossipSendMenu(12, object)
        else
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/inv_misc_enggizmos_27:40:40:-28:0|tClose", 0, 997)
            player:GossipSendMenu(12, player, 35353)
        end
    end
end 

local function OnSelectXP(event, player, object, sender, intid, code, menu_id)
    local currentRate = XPCache[player:GetGUIDLow()] or 1
    if intid == 11 then
    
        player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/ABILITY_DRUID_MANATREE:40:40:-28:0|tTell me about Yggdrasil\n \nThe realms of Azeroth are connected in many ways, including through the Twisting Nether. However, in recent times, it has become apparent that an earthern force connects our realms as well. We've come to call this force Yggdrasil.\n \nThe roots of Yggdrasil have, since the dawn of time, come to grow new spurs, from which the world's Twiggies have risen.\n \nUs Twiggies have since taken it upon them to ease the burden of travelers in Azeroth. Every newcomer receives their own Branch of Yggdrasil, also known as Twiggy, to guide them.\n \nTwiggy can inform you of the features Yggdrasil brings, teleport you to the mall, and more.\n \n ", 0, 11)
        player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/inv_misc_enggizmos_27:40:40:-28:0|tGo back", 0, 998)
        if not (object == player) then
            player:GossipSendMenu(12, object)
        else
            player:GossipSendMenu(12, player, 35355)
        end
	elseif intid == 13 then
		player:GossipClearMenu()
		
		if player:GetLevel() > 5 then
			player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/inv_misc_note_05:40:40:-28:0|tStarting zone changes unavailable\n \nYou are too high level to change starting zone. Only players at level 5 or under can change their starting zone.\n \n ", 0, 13)
			player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/inv_misc_enggizmos_27:40:40:-28:0|tGo back", 0, 998)
		else
			player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/inv_misc_note_05:40:40:-28:0|tChange starting zone\n \nUntil level 5, you can freely change your starter zone between the other zones for your faction. Which zone would you like to go to?\n \n ", 0, 13)
			
			if player:GetTeam() == 0 then -- Alliance
				player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/achievement_zone_elwynnforest:40:40:-28:0|tElwynn Forest", 0, 101, false, "Are you sure you want to go to Elwynn Forest?")
				player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/achievement_zone_dunmorogh:40:40:-28:0|tDun Morogh", 0, 102, false, "Are you sure you want to go to Dun Morogh?")
				player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/achievement_zone_darnassus:40:40:-28:0|tTeldrassil", 0, 103, false, "Are you sure you want to go to Teldrassil?")
				player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/achievement_zone_azuremystisle_01:40:40:-28:0|tAzuremyst Isle", 0, 104, false, "Are you sure you want to go to Azuremyst Isle?")
			else -- Horde
				player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/achievement_zone_durotar:40:40:-28:0|tDurotar", 0, 105, false, "Are you sure you want to go to Durotar?")
				player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/achievement_zone_tirisfalglades_01:40:40:-28:0|tTirisfal Glades", 0, 106, false, "Are you sure you want to go to Tirisfal Glades?")
				player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/achievement_zone_mulgore_01:40:40:-28:0|tMulgore", 0, 107, false, "Are you sure you want to go to Mulgore?")
				player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/achievement_zone_eversongwoods:40:40:-28:0|tEversong Woods", 0, 108, false, "Are you sure you want to go to Eversong Woods?")
			end
			
			player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/inv_misc_enggizmos_27:40:40:-28:0|tGo back", 0, 998)
		end
		
		if not (object == player) then
			player:GossipSendMenu(12, object)
		else
			player:GossipSendMenu(12, player, 35353)
		end
		
	elseif intid >= 101 and intid <= 108 then
		if player:IsInCombat() then
			player:GossipComplete()
			player:SendAreaTriggerMessage("You cannot do this in combat.")
			return
		end
		
		local teleportData = {
			[101] = {map = 0, x = -8955.64, y = -131.42, z = 83, o = 6.18}, -- Elwynn Forest
			[102] = {map = 0, x = -6239.23, y = 335.24, z = 382.92, o = 5.45}, -- Dun Morogh
			[103] = {map = 1, x = 10310, y = 818.60, z = 1326.63, o = 1.31}, -- Teldrassil
			[104] = {map = 530, x = -3962.25, y = -13930.63, z = 100.6, o = 1.88}, -- Azuremyst Isle
			
			[105] = {map = 1, x = -618.7529, y = -4249.429, z = 38.62, o = 6.12}, -- Durotar
			[106] = {map = 0, x = 1663.64, y = 1685.66, z = 120.53, o = 4.744}, -- Tirisfal Glades
			[107] = {map = 1, x = -2919.35, y = -263.535, z = 53.62, o = 0.41}, -- Mulgore
			[108] = {map = 530, x = 10344.32, y = -6357.85, z = 33.18, o = 0.02} -- Eversong Woods
		}
		
		local loc = teleportData[intid]
		if loc then
			player:Teleport(loc.map, loc.x, loc.y, loc.z, loc.o)
		end
		
		player:GossipComplete()
	
    elseif intid == 12 then

        local cost6 = " (1x "..currencyNameSingular..")"
        local cost7 = " (2x "..currencyName..")"
        local cost8 = " (3x "..currencyName..")"
        local cost9 = " (4x "..currencyName..")"
        local cost10 = " (5x "..currencyName..")"
        
        if object == player or (Multistate.GetData(player, "VIPTime") and Multistate.GetData(player, "VIPTime") > os.time()) then
            cost6 = ""
            cost7 = ""
            cost8 = ""
            cost9 = ""
            cost10 = ""
        end

        local maxPaid = MaxPaidCache[player:GetGUIDLow()] or 0
        if maxPaid >= 6 then cost6 = "" end
        if maxPaid >= 7 then cost7 = "" end
        if maxPaid >= 8 then cost8 = "" end
        if maxPaid >= 9 then cost9 = "" end
        if maxPaid >= 10 then cost10 = "" end
    
        player:GossipClearMenu()
        if player:GetLevel() == 80 and not (player:GetClass() == 3) then
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/achievement_level_80:40:40:-28:0|tNo services available\n \nThere are no experience services available at level 80.\n \n ", 0, 12)
        else
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/spell_fire_burningspeed:40:40:-28:0|tYour experience rate is: x"..currentRate, 0, 12)
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:40:40:-28:0|tSet rates x1", 0, 1, false, "Are you sure you want to change your experience rate to: x1?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:40:40:-28:0|tSet rates x2", 0, 2, false, "Are you sure you want to change your experience rate to: x2?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:40:40:-28:0|tSet rates x3", 0, 3, false, "Are you sure you want to change your experience rate to: x3?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:40:40:-28:0|tSet rates x4", 0, 4, false, "Are you sure you want to change your experience rate to: x4?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:40:40:-28:0|tSet rates x5", 0, 5, false, "Are you sure you want to change your experience rate to: x5?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:40:40:-28:0|tSet rates x6"..cost6, 0, 6, false, "Are you sure you want to change your experience rate to: x6?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:40:40:-28:0|tSet rates x7"..cost7, 0, 7, false, "Are you sure you want to change your experience rate to: x7?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:40:40:-28:0|tSet rates x8"..cost8, 0, 8, false, "Are you sure you want to change your experience rate to: x8?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:40:40:-28:0|tSet rates x9"..cost9, 0, 9, false, "Are you sure you want to change your experience rate to: x9?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:40:40:-28:0|tSet rates x10"..cost10, 0, 10, false, "Are you sure you want to change your experience rate to: x10?")
        end
        if not (object == player) then
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/inv_misc_enggizmos_27:40:40:-28:0|tClose", 0, 997)
            player:GossipSendMenu(12, object)
        else
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/inv_misc_enggizmos_27:40:40:-28:0|tClose", 0, 997)
            player:GossipSendMenu(12, player, 35353)
        end
    elseif intid == 997 then
        player:GossipComplete()
    elseif intid == 998 then
        OnTalkToGreetingTwig(event, player, object)
    elseif intid < 11 then
        local guid = player:GetGUIDLow()
        if currentRate > intid then
            XPCache[guid] = intid
            CharDBExecute("REPLACE INTO character_rate_xp (guid, rate, max_paid_rate) VALUES ('"..guid.."', '"..intid.."', '"..(MaxPaidCache[guid] or 0).."')")
            messagestring = "Congratulations, you changed your experience rate to: x"..intid
            if object == player then
                player:SendBroadcastMessage(messagestring)
            else
                object:SendUnitWhisper(messagestring, 0, player)
            end
            player:CastSpell(player, 47292, true)
            player:GossipComplete()
            return
        elseif intid > 5 and not (Multistate.GetData(player, "VIPTime") and (Multistate.GetData(player, "VIPTime") > os.time())) then -- Charge if higher tier XP and not VIP
            local maxPaid = MaxPaidCache[guid] or 0
            if intid > maxPaid then
                if not player:HasItem(currencyID, intid - 5) then
                    player:GossipComplete()
                    messagestring = "You don't have sufficient funds!"
                    if object == player then
                        player:SendBroadcastMessage(messagestring)
                    else
                        object:SendUnitWhisper(messagestring, 0, player)
                    end
                    return
                end
                player:RemoveItem(currencyID, intid - 5)
                MaxPaidCache[guid] = intid
            end
        end
        XPCache[guid] = intid
        CharDBExecute("REPLACE INTO character_rate_xp (guid, rate, max_paid_rate) VALUES ('"..guid.."', '"..intid.."', '"..(MaxPaidCache[guid] or 0).."')")
        messagestring = "Congratulations, you changed your experience rate to: x"..intid
        if object == player then
            player:SendBroadcastMessage(messagestring)
        else
            object:SendUnitWhisper(messagestring, 0, player)
        end
        player:CastSpell(player, 47292, true)
        player:GossipComplete()
    end
end

local function OnGiveXP(event, player, amount, victim)
    if XPCache[player:GetGUIDLow()] then
        amount = amount * XPCache[player:GetGUIDLow()]
        return amount
    end
end 

local function LoadXPCache()
   CharDBQueryAsync("SELECT guid, rate, max_paid_rate FROM character_rate_xp", function(result)
       if result then
           repeat
               XPCache[result:GetUInt32(0)] = result:GetUInt8(1)
               MaxPaidCache[result:GetUInt32(0)] = result:GetUInt8(2)
           until not result:NextRow()
       end
   end)
end

local function onXPCommand(event, player, command)
    if command:match("^%s*xpchangemenu%s+(%d+)%s*$") then
        local _, _, timestring = command:find("^%s*xpchangemenu%s+(%d+)%s*$")
        local verificationtime = tonumber(timestring)
        -- Multistate: the menu command may arrive via EMQ (Twiggy gossip runs on
        -- map states), so allow a small transit window instead of an exact second.
        if verificationtime and math.abs(os.time() - verificationtime) <= 5 then
            OnTalkToGreetingTwig(event, player, player)
        end
        return false
    end
end

------------------------------------------------------------------------------------------------
-- XP rate changer event registrations
------------------------------------------------------------------------------------------------

LoadXPCache() -- Loads XPCache on script load (server startup/reload ELUNA)
RegisterPlayerEvent(12, OnGiveXP)
RegisterCreatureGossipEvent(190023, 1, OnTalkToGreetingTwig)
RegisterCreatureGossipEvent(190023, 2, OnSelectXP)
RegisterPlayerEvent(42, onXPCommand)
RegisterPlayerGossipEvent(35353, 2, OnSelectXP)
RegisterPlayerGossipEvent(35354, 2, OnSelectXP)
RegisterPlayerGossipEvent(35355, 2, OnSelectXP)
RegisterCreatureGossipEvent(1900230, 1, OnTalkToGreetingTwig)
RegisterCreatureGossipEvent(1900230, 2, OnSelectXP)

------------------------------------------------------------------------------------------------
-- End XP rate changer event registrations
------------------------------------------------------------------------------------------------
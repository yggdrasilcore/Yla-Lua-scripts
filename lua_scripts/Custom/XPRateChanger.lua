

-------------------------------------------------------------------------------------------------------------------------
-- XP changer script start
-------------------------------------------------------------------------------------------------------------------------

CharDBExecute("CREATE TABLE IF NOT EXISTS `character_rate_xp` (`guid` int(11) unsigned NOT NULL, `rate` int(11) NOT NULL DEFAULT 0, PRIMARY KEY (`guid`)) ENGINE=InnoDB DEFAULT CHARSET=utf8;")

local currencyID = 20880
local currencyNameSingular = "Vote Token"
local currencyName = "Vote Tokens"

local XPCache = {}

local function OnXPRateChanger(event, player, object)
    local guid = player:GetGUIDLow()
    local currentRate = XPCache[guid] or 1
    
    player:GossipClearMenu()
    
    local cost6 = " (1x "..currencyNameSingular..")"
    local cost7 = " (2x "..currencyName..")"
    local cost8 = " (3x "..currencyName..")"
    local cost9 = " (4x "..currencyName..")"
    local cost10 = " (5x "..currencyName..")"
    
    if object == player or (player:GetData("VIPTime") and player:GetData("VIPTime") > os.time()) then
        cost6 = ""
        cost7 = ""
        cost8 = ""
        cost9 = ""
        cost10 = ""
    end

    if not (object == player) then
        player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/ABILITY_DRUID_MANATREE:32:32:-22:0|tTell me about Yggdrasil", 0, 11)
        player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/spell_fire_burningspeed:32:32:-22:0|tLet me change my XP rate", 0, 12)
        player:GossipMenuAddItem(0, "|TINTERFACE/ICONS/inv_misc_enggizmos_27:32:32:-22:0|tClose", 0, 997)
        player:GossipSendMenu(12, object)
    else
        if player:GetLevel() == 80 and not (player:GetClass() == 3) then
            player:GossipMenuAddItem(0, "|TINTERFACE/ICONS/achievement_level_80:32:32:-22:0|tNo services available\n \nThere are no experience services available at level 80.\n \n ", 0, 12)
        else
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/spell_fire_burningspeed:32:32:-22:0|tYour experience rate is: x"..currentRate, 0, 2)
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x1", 0, 1, false, "Are you sure you want to change your experience rate to: x1?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x2", 0, 2, false, "Are you sure you want to change your experience rate to: x2?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x3", 0, 3, false, "Are you sure you want to change your experience rate to: x3?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x4", 0, 4, false, "Are you sure you want to change your experience rate to: x4?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x5", 0, 5, false, "Are you sure you want to change your experience rate to: x5?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x6"..cost6, 0, 6, false, "Are you sure you want to change your experience rate to: x6?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x7"..cost7, 0, 7, false, "Are you sure you want to change your experience rate to: x7?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x8"..cost8, 0, 8, false, "Are you sure you want to change your experience rate to: x8?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x9"..cost9, 0, 9, false, "Are you sure you want to change your experience rate to: x9?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x10"..cost10, 0, 10, false, "Are you sure you want to change your experience rate to: x10?")
        end
        if not (object == player) then
            player:GossipMenuAddItem(0, "|TINTERFACE/ICONS/inv_misc_enggizmos_27:32:32:-22:0|tClose", 0, 997)
            player:GossipSendMenu(12, object)
        else
            player:GossipMenuAddItem(0, "|TINTERFACE/ICONS/inv_misc_enggizmos_27:32:32:-22:0|tClose", 0, 997)
            player:GossipSendMenu(12, player, 35353)
        end
    end
end 

local function OnSelectXP(event, player, object, sender, intid, code, menu_id)
    print(intid)
    local currentRate = XPCache[player:GetGUIDLow()] or 1
    if intid == 11 then
    
        player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/ABILITY_DRUID_MANATREE:32:32:-22:0|tTell me about Yggdrasil\n \nThe realms of Azeroth are connected in many ways, including through the Twisting Nether. However, in recent times, it has become apparent that an earthern force connects our realms as well. We've come to call this force Yggdrasil.\n \nThe roots of Yggdrasil have, since the dawn of time, come to grow new spurs, from which the world's Twiggies have risen.\n \nUs Twiggies have since taken it upon them to ease the burden of travelers in Azeroth. Every newcomer receives their own Branch of Yggdrasil, also known as Twiggy, to guide them.\n \nTwiggy can inform you of the features Yggdrasil brings, teleport you to the mall, and more.\n \n ", 0, 11)
        player:GossipMenuAddItem(0, "|TINTERFACE/ICONS/inv_misc_enggizmos_27:32:32:-22:0|tGo back", 0, 998)
        if not (object == player) then
            player:GossipSendMenu(12, object)
        else
            player:GossipSendMenu(12, player, 35355)
        end
        
    elseif intid == 12 then

        local cost6 = " (1x "..currencyNameSingular..")"
        local cost7 = " (2x "..currencyName..")"
        local cost8 = " (3x "..currencyName..")"
        local cost9 = " (4x "..currencyName..")"
        local cost10 = " (5x "..currencyName..")"
        
        if object == player or (player:GetData("VIPTime") and player:GetData("VIPTime") > os.time()) then
            cost6 = ""
            cost7 = ""
            cost8 = ""
            cost9 = ""
            cost10 = ""
        end
    
        player:GossipClearMenu()
        if player:GetLevel() == 80 and not (player:GetClass() == 3) then
            player:GossipMenuAddItem(0, "|TINTERFACE/ICONS/achievement_level_80:32:32:-22:0|tNo services available\n \nThere are no experience services available at level 80.\n \n ", 0, 12)
        else
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/spell_fire_burningspeed:32:32:-22:0|tYour experience rate is: x"..currentRate, 0, 2)
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x1", 0, 1, false, "Are you sure you want to change your experience rate to: x1?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x2", 0, 2, false, "Are you sure you want to change your experience rate to: x2?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x3", 0, 3, false, "Are you sure you want to change your experience rate to: x3?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x4", 0, 4, false, "Are you sure you want to change your experience rate to: x4?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x5", 0, 5, false, "Are you sure you want to change your experience rate to: x5?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x6"..cost6, 0, 6, false, "Are you sure you want to change your experience rate to: x6?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x7"..cost7, 0, 7, false, "Are you sure you want to change your experience rate to: x7?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x8"..cost8, 0, 8, false, "Are you sure you want to change your experience rate to: x8?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x9"..cost9, 0, 9, false, "Are you sure you want to change your experience rate to: x9?")
            player:GossipMenuAddItem(1, "|TINTERFACE/ICONS/Achievement_Quests_Completed_08:32:32:-22:0|tSet rates x10"..cost10, 0, 10, false, "Are you sure you want to change your experience rate to: x10?")
        end
        if not (object == player) then
            player:GossipMenuAddItem(0, "|TINTERFACE/ICONS/inv_misc_enggizmos_27:32:32:-22:0|tClose", 0, 997)
            player:GossipSendMenu(12, object)
        else
            player:GossipMenuAddItem(0, "|TINTERFACE/ICONS/inv_misc_enggizmos_27:32:32:-22:0|tClose", 0, 997)
            player:GossipSendMenu(12, player, 35353)
        end
    elseif intid == 997 then
        player:GossipComplete()
    elseif intid == 998 then
        OnXPRateChanger(event, player, object)
    elseif intid < 11 then
        if currentRate > intid then
            XPCache[player:GetGUIDLow()] = intid
            CharDBExecute("REPLACE INTO character_rate_xp (guid, rate) VALUES ('"..player:GetGUIDLow().."', '"..intid.."')")
            messagestring = "Congratulations, you changed your experience rate to: x"..intid
            if object == player then
                player:SendBroadcastMessage(messagestring)
            else
                object:SendUnitWhisper(messagestring, 0, player)
            end
            player:CastSpell(player, 47292, true)
            player:GossipComplete()
            return
        elseif intid > 5 and not (player:GetData("VIPTime") and (player:GetData("VIPTime") > os.time())) then -- Charge if higher tier XP and not VIP
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
        end
        XPCache[player:GetGUIDLow()] = intid
        CharDBExecute("REPLACE INTO character_rate_xp (guid, rate) VALUES ('"..player:GetGUIDLow().."', '"..intid.."')")
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
   CharDBQueryAsync("SELECT guid, rate FROM character_rate_xp", function(result)
       if result then
           repeat
               XPCache[result:GetUInt32(0)] = result:GetUInt8(1)
           until not result:NextRow()
       end
   end)
end

local function onXPCommand(event, player, command)
    if command:match("^%s*xpchangemenu%s+(%d+)%s*$") then
        local _, _, timestring = command:find("^%s*xpchangemenu%s+(%d+)%s*$")
        local verificationtime = tonumber(timestring)
        if verificationtime and verificationtime == os.time() then
            OnXPRateChanger(event, player, player)
        end
        return false
    end
end

------------------------------------------------------------------------------------------------
-- XP rate changer event registrations
------------------------------------------------------------------------------------------------

LoadXPCache() -- Loads XPCache on script load (server startup/reload ELUNA)
RegisterPlayerEvent(12, OnGiveXP)
RegisterCreatureGossipEvent(190023, 1, OnXPRateChanger)
RegisterCreatureGossipEvent(190023, 2, OnSelectXP)
RegisterPlayerEvent(42, onXPCommand)
RegisterPlayerGossipEvent(35353, 2, OnSelectXP)
RegisterPlayerGossipEvent(35354, 2, OnSelectXP)
RegisterPlayerGossipEvent(35355, 2, OnSelectXP)
RegisterCreatureGossipEvent(1900230, 1, OnXPRateChanger)
RegisterCreatureGossipEvent(1900230, 2, OnSelectXP)

------------------------------------------------------------------------------------------------
-- End XP rate changer event registrations
------------------------------------------------------------------------------------------------
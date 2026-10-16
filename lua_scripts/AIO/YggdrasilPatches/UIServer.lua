local AIO = require("AIO")

local UIFixLimit = {}
local NoAFKLogoutZones = {
    [3703] = 1, -- shattrath
    [4395] = 1, -- dalaran
    -- ally capitals
    [1519] = 1, -- stormwind
    [1537] = 1, -- ironforge
    [1657] = 1, -- darnassus
    [3557] = 1, -- exodar
    -- horde capitals
    [1637] = 1, -- orgrimmar
    [1638] = 1, -- thunder bluff
    [1497] = 1, -- undercity
    [3487] = 1, -- silvermoon
    -- mall
    [268] = 1, -- azshara crater
}

local function OnAddonMessageReceived(event, player, _type, header, data, target)
	if player and _type == 7 then
        if target and player:GetName() == target:GetName() then
            local name = player:GetName()
            if(header == "CAIO") then
                if string.find(data, "Init") then
                    if (UIFixLimit[name] and UIFixLimit[name] == os.time()) then
                        return
                    end
                    UIFixLimit[name] = os.time()
                    AIO.Handle(player, "UIFix", "Initialize")
				end
            end
        end
    end
end

local function AIO_UI_FIX(event, player, command)
	if not player then return end
	local guid = player:GetGUIDLow()
	
	if event == 28 then -- on login/map change, check reward state
		if player:Data():Get("LvlRewardsChecked") then return end
		CharDBQueryAsync("SELECT data FROM acore_eluna.character_custom_data WHERE guid = "..guid.." AND type = 99", function(result)
			local player
			if GetStateMapId() == -1 then player = GetPlayerByGUID(GetPlayerGUID(guid))
			else for _, p in ipairs(GetStateMap():GetPlayers()) do
				if p:GetGUIDLow() == guid then player = p break end
			end end
			if result then
				local data = result:GetString(0)
				if not player then return end
				if data == "DISABLED" then
					player:Data():Set("LvlRewardsDisabled", true)
				else
					player:Data():Set("LvlRewardsDisabled", false)
				end
				player:Data():Set("LvlRewardsChecked", true)
			end
		end)
	elseif event == 4 or event == 25 then
		if player:Data():Get("LvlRewardsChanged") then
			if player:Data():Get("LvlRewardsDisabled") then
				CharDBExecute("REPLACE INTO acore_eluna.character_custom_data (guid, type, time, data) VALUES ("..guid..", 99, "..os.time()..", 'DISABLED')")
			else
				CharDBExecute("REPLACE INTO acore_eluna.character_custom_data (guid, type, time, data) VALUES ("..guid..", 99, "..os.time()..", 'ENABLED')")
			end
		end
    elseif event == 42 then
		if command == "32819" then -- Extends worg form to 5 minutes, hack approach to spell script
			if player:HasAura(32819) then
				local aura = player:AddAura(32819, player)
				aura:SetDuration(5 * 60 * 1000)
			end
			return false
		elseif command == "afk" then
			--if player:IsAFK() 
			--and NoAFKLogoutZones[player:GetZoneId()]
			--then
			--    player:ToggleAFK()
			--end
			-- Doesn't work :(
			-- Just returning false until I can think of a better fix...
			return false
			
		-- LVL Reward Toggle in features tab
		elseif command == "lvlrewardsoff" then
			player:SendBroadcastMessage("Your level-up rewards have been disabled.")
			player:Data():Set("LvlRewardsDisabled", true)
			player:Data():Set("LvlRewardsChanged", true)
			return false
		elseif command == "lvlrewardson" then
			player:SendBroadcastMessage("Your level-up rewards have been enabled.")
			player:Data():Set("LvlRewardsDisabled", false)
			player:Data():Set("LvlRewardsChanged", true)
			return false
		elseif command == "lvlrewardsstatus" then
			local status = player:Data():Get("LvlRewardsDisabled")
			if status then
				player:SendAddonMessage("LvlRewardsDisabled", "DISABLED", 7, player)
			else
				player:SendAddonMessage("LvlRewardsDisabled", "ENABLED", 7, player)
			end	
			return false
		end
	end
end

local function CMSGAreaCodeTrigger(event, packet, player)
	if not player:GetAreaId() == 4564 then return end
	if not player:HasSpell(54197) then return end
	player:SendAddonMessage("CheckMounts", "ENABLED", 7, player)
end
local guidString = ""
local first = true

local players
if GetStateMapId() == -1 then
   players = GetPlayersInWorld()
else
   local map = GetStateMap()
   players = map and map:GetPlayers()
end
for _, player in ipairs(players or {}) do
   if first then
       guidString = tostring(player:GetGUIDLow())
       first = false
   else
       guidString = guidString .. "," .. player:GetGUIDLow()
   end
end

if not first then
   CharDBQueryAsync(
       string.format("SELECT guid, data FROM acore_eluna.character_custom_data WHERE guid IN (%s) AND type = 99", guidString),
       function(result)
           if result then
               repeat
                   local guid = result:GetUInt32(0)
                   local data = result:GetString(1)
                   if data == "DISABLED" then
					   local player
					   if GetStateMapId() == -1 then player = GetPlayerByGUID(GetPlayerGUID(guid))
					   else for _, p in ipairs(GetStateMap():GetPlayers()) do
						   if p:GetGUIDLow() == guid then player = p break end
					   end end
					   if player then player:Data():Set("LvlRewardsDisabled", true) end
				   end
               until not result:NextRow()
           end
       end
   )
end

CharDBExecute("CREATE TABLE IF NOT EXISTS acore_eluna.character_custom_data (guid int unsigned NOT NULL, type tinyint unsigned NOT NULL, time int unsigned NOT NULL, data blob NOT NULL, PRIMARY KEY (guid, type))")

RegisterPlayerEvent(4, AIO_UI_FIX)
RegisterPlayerEvent(25, AIO_UI_FIX)
RegisterPlayerEvent(28, AIO_UI_FIX)
RegisterPlayerEvent(42, AIO_UI_FIX)
RegisterServerEvent(30, OnAddonMessageReceived)
RegisterPacketEvent(0x0B4, 5, CMSGAreaCodeTrigger)

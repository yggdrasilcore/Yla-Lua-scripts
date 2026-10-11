-- Multistate: map-only script (all hooks fire in map states).
if GetStateMapId() == -1 then return end

local function SendBroadcastWithCheck(playerGUID, message, itemEntry, itemCount, acc)
	local player = require("Multistate").FindPlayerByGUID(playerGUID)
	local oldCount = player:GetItemCount(itemEntry)
	player:AddItem(itemEntry, itemCount)
	
	if not (player:GetItemCount(itemEntry) > oldCount) then
		print("Failed to award currency "..itemEntry.." to player "..player:GetGUIDLow().." acc "..acc)
		return -- Something went wrong - abort!
	end
	
	player:SendBroadcastMessage(message)
	print("Awarding currency "..itemEntry.." quantity "..itemCount.." to acc "..acc)
	if itemEntry == 20880 then
		CharDBExecute("UPDATE acore_eluna.account_currencies SET vp = 0 WHERE id = " .. acc)
		player:RegisterEvent(function(_, _, _, player)
			if not player:GetData("CurrSave") then
				player:SetData("CurrSave")
				player:SaveToDB()
			end
		end, 1000)
	else
		CharDBExecute("UPDATE acore_eluna.account_currencies SET dp = 0 WHERE id = " .. acc)
		player:RegisterEvent(function(_, _, _, player)
			if not player:GetData("CurrSave") then
				player:SetData("CurrSave")
				player:SaveToDB()
			end
		end, 1500)
	end
end

local function TokensOnLogin(event, player)
    if ShadowGetMaster(player:GetName()) then return end
    if player:GetData("LoginChecked") then return end
    local acc = player:GetAccountId()
    local playerGUID = player:GetGUID()
    local communitymessage = false
    local votemessage = false
   
    CharDBQueryAsync("SELECT dp, vp FROM acore_eluna.account_currencies WHERE id = " .. acc, function(query)
        local player = require("Multistate").FindPlayerByGUID(playerGUID)
 	    if not player then return end
 	    player:SetData("LoginChecked", true)
        if query then
            local dpValue = query:GetInt32(0)
            local vpValue = query:GetInt32(1)
            
            if dpValue and dpValue > 0 then
                CreateLuaEvent(function() 
                    SendBroadcastWithCheck(playerGUID, "You have been awarded " .. dpValue .. " Community Tokens. Thank you for supporting our community!", 19322, dpValue, acc)
                end, 3000, 1)
                communitymessage = true
            end
            
            if vpValue and vpValue > 0 then
                CreateLuaEvent(function() 
                    SendBroadcastWithCheck(playerGUID, "You have been awarded " .. vpValue .. " Vote Tokens, which can be redeemed for XP boosts, transmogs, and vanity items. Thank you for your vote!", 20880, vpValue, acc)
                end, 3000, 1)
                votemessage = true
            end
            
            if not (communitymessage or votemessage) then
                player:SendBroadcastMessage("Please remember to vote on Yggdrasilwow.com. Vote Tokens can be redeemed for XP boosts, transmogs, and vanity items.")
			end
		else
            player:SendBroadcastMessage("Please remember to vote on Yggdrasilwow.com. Vote Tokens can be redeemed for XP boosts, transmogs, and vanity items.")
        end
    end)
end

------------------------------------------------------------------------------------------------
-- Token on login awarder event registrations
------------------------------------------------------------------------------------------------

RegisterPlayerEvent(28, TokensOnLogin)

------------------------------------------------------------------------------------------------
-- End token on login awarder event registrations
------------------------------------------------------------------------------------------------
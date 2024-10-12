local function SendBroadcastWithCheck(playerGUID, message, itemEntry, itemCount)
    local player = GetPlayerByGUID(playerGUID)
    if player then
		local accountId = player:GetAccountId()
        if itemEntry and itemCount then
            player:AddItem(itemEntry, itemCount)
			player:SendBroadcastMessage(message)
			if itemEntry == 20880 then
				print("Awarding Vote Tokens to Account ID: " .. accountId)  -- Debugging line
				CharDBExecute("UPDATE account_currencies SET vp = 0 WHERE id = " .. accountId)
			else
				print("Awarding Community Tokens to Account ID: " .. accountId)  -- Debugging line
				CharDBExecute("UPDATE account_currencies SET dp = 0 WHERE id = " .. accountId)
			end
        end
    end
end

local function OnLogin(event, player)
    local accountId = player:GetAccountId()

    local playerGUID = player:GetGUID()
    local communitymessage = false
    local votemessage = false
    
	CharDBQueryAsync("SELECT dp FROM account_currencies WHERE id = " .. accountId, function(dpquery)
		if dpquery then
			local dpValue = dpquery:GetInt32(0)
			if dpValue and dpValue > 0 then
				local itemCount = dpValue
				CreateLuaEvent(function() 
					SendBroadcastWithCheck(playerGUID, "You have been awarded " .. itemCount .. " Community Tokens. Thank you for supporting our community!", 19322, itemCount)
				end, 10000, 1)
				communitymessage = true
			end
		end
	end)
    
	CharDBQueryAsync("SELECT vp FROM account_currencies WHERE id = " .. accountId, function(vpquery)
		if vpquery then
			local vpValue = vpquery:GetInt32(0)
			if vpValue and vpValue > 0 then
				local itemCount = vpValue
				CreateLuaEvent(function() 
					SendBroadcastWithCheck(playerGUID, "You have been awarded " .. itemCount .. " Vote Tokens, which can be redeemed for XP boosts, transmogs, and vanity items. Thank you for your vote!", 20880, itemCount)
				end, 10000, 1)
				votemessage = true
			end
		end
	end)
    
    if not (communitymessage or votemessage) then
		player:SendBroadcastMessage("Please remember to vote on Yggdrasilwow.com. Vote Tokens can be redeemed for XP boosts, transmogs, and vanity items.")
    end
end

RegisterPlayerEvent(3, OnLogin)
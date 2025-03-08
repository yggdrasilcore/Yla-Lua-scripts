
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

local function TokensOnLogin(event, player)
   if isPlayerBot[player:GetName()] then return end
   if player:GetData("LoginChecked") then return end
   local accountId = player:GetAccountId()
   local playerGUID = player:GetGUID()
   local GUIDLow = player:GetGUIDLow()
   local communitymessage = false
   local votemessage = false
   
   CharDBQueryAsync("SELECT dp, vp FROM account_currencies WHERE id = " .. accountId, function(query)
       local player = GetPlayerByGUID(playerGUID)
	   if not player then return end
	   player:SetData("LoginChecked", true)
       if query then
           local dpValue = query:GetInt32(0)
           local vpValue = query:GetInt32(1)
           
           if dpValue and dpValue > 0 then
               local itemCount = dpValue
               CreateLuaEvent(function() 
                   SendBroadcastWithCheck(playerGUID, "You have been awarded " .. itemCount .. " Community Tokens. Thank you for supporting our community!", 19322, itemCount)
               end, 3000, 1)
               communitymessage = true
           end
           
           if vpValue and vpValue > 0 then
               local itemCount = vpValue
               CreateLuaEvent(function() 
                   SendBroadcastWithCheck(playerGUID, "You have been awarded " .. itemCount .. " Vote Tokens, which can be redeemed for XP boosts, transmogs, and vanity items. Thank you for your vote!", 20880, itemCount)
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
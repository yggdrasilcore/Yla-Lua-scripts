-- Currencies covered
local currencies = {20880, 19322}

-- DB initiations
-- WorldDBExecute([[UPDATE item_template SET name = 'Vote Token', maxcount = 0, stackable = 9999999, Quality = 7, Flags = 32, Description = 'One vote can change everything. Thank you for your support!' WHERE entry = 20880;]])
-- WorldDBExecute([[UPDATE item_template SET name = 'Community Token', maxcount = 0, stackable = 9999999, Quality = 7, Flags = 32, Description = 'A shimmering token exchangable for exclusive services. Thank you for your support!' WHERE entry = 19322;]])

CharDBQuery([[CREATE TABLE IF NOT EXISTS account_currencies (
    id INT PRIMARY KEY,
    vp INT,
    dp INT,
    total_votes INT,
    location VARCHAR(255),
    nickname VARCHAR(255),
    language VARCHAR(50),
    avatar VARCHAR(255)
);]])

local function SendBroadcastWithCheck(playerGUID, message, itemEntry, itemCount)
    local player = GetPlayerByGUID(playerGUID)
    if player then
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

-- Function to handle player login event
local function OnLogin(event, player)
    local accountId = player:GetAccountId()
	local charguids = {}
	local accountCurrencies = {}
    
    -- Query to get character GUIDs for the account
    local query = CharDBQuery(string.format("SELECT guid FROM characters WHERE account = %d", accountId))
    if query then
        charguids[accountId] = {}
        repeat
            local guid = query:GetUInt32(0)
            table.insert(charguids[accountId], guid)
        until not query:NextRow()
    end
    
    -- Initialize currency counts for this account
    accountCurrencies[accountId] = {}
    for _, currencyId in ipairs(currencies) do
        accountCurrencies[accountId][currencyId] = 0
    end
    
-- Query and sum currency counts for all characters in the account, then reset to 0
	for _, guid in ipairs(charguids[accountId]) do
		for _, currencyId in ipairs(currencies) do
			local countQuery = CharDBQuery(string.format("SELECT SUM(count) FROM item_instance WHERE owner_guid = %d AND itemEntry = %d AND count > 0", guid, currencyId))
			if countQuery then
				local count = countQuery:GetUInt32(0) or 0
				accountCurrencies[accountId][currencyId] = accountCurrencies[accountId][currencyId] + count
				CharDBExecute(string.format("UPDATE item_instance SET count = 0 WHERE owner_guid = %d AND itemEntry = %d", guid, currencyId))

			end
		end
	end

    -- Print the total currency counts for the account
    for _, currencyId in ipairs(currencies) do
        print(string.format("Account ID %d has %d of currency %d", accountId, accountCurrencies[accountId][currencyId], currencyId))
		player:RemoveItem(currencyId,player:GetItemCount(currencyId))
		player:AddItem(currencyId,accountCurrencies[accountId][currencyId])
    end
	
    local playerGUID = player:GetGUID()
    local communitymessage = false
    local votemessage = false
    
    local vpquery = CharDBQuery("SELECT vp FROM account_currencies WHERE id = " .. accountId)
    local dpquery = CharDBQuery("SELECT dp FROM account_currencies WHERE id = " .. accountId)
    
    if dpquery then
        local dpValue = dpquery:GetInt32(0)
        if dpValue and dpValue > 0 then
            local itemCount = dpValue
            CreateLuaEvent(function() 
                SendBroadcastWithCheck(playerGUID, "You have been awarded " .. itemCount .. " Community Tokens. Thank you for supporting our community!", 19322, itemCount)
            end, 3000, 1)
            communitymessage = true
        end
    end
    
    if vpquery then
        local vpValue = vpquery:GetInt32(0)
        if vpValue and vpValue > 0 then
            local itemCount = vpValue
            CreateLuaEvent(function() 
                SendBroadcastWithCheck(playerGUID, "You have been awarded " .. itemCount .. " Vote Tokens, which can be redeemed for XP boosts, transmogs, and vanity items. Thank you for your support!", 20880, itemCount)
            end, 3000, 1)
            votemessage = true
        end
    end
    
    if not (communitymessage or votemessage) then
        CreateLuaEvent(function() 
            SendBroadcastWithCheck(playerGUID, "Please remember to vote on Yggdrasilwow.com. Vote Tokens can be redeemed for XP boosts, transmogs, and vanity items. Thank you for your support!")
        end, 3000, 1)
    end
end

RegisterPlayerEvent(3, OnLogin)
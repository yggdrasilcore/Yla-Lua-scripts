-- Currencies covered
currencies = {20880, 19322}

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
				
				print("Set count to 0 for char "..guid)
			end
		end
	end

    -- Print the total currency counts for the account
    for _, currencyId in ipairs(currencies) do
        print(string.format("Account ID %d has %d of currency %d", accountId, accountCurrencies[accountId][currencyId], currencyId))
		player:RemoveItem(currencyId,accountCurrencies[accountId][currencyId])
		player:AddItem(currencyId,accountCurrencies[accountId][currencyId])
    end
end

-- Register the login event
RegisterPlayerEvent(3, OnLogin)
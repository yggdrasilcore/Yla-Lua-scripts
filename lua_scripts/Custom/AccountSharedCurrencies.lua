
-- ----------------------------------------------------------------------------------------------
-- ACCOUNTWIDE CURRENCY CONFIG 
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
-- Adapted to Yggdrasil WoW by mostly nick :)
-- ----------------------------------------------------------------------------------------------

local currencyItemIDs = {
    37742,  -- Activity Token 
    20880,  -- Vote Token 
    19322,  -- Community Token 
}

-- End account-shared currencies tables

----------------------------------------------------------------------------------------------------
-- Account-shared currencies script start
----------------------------------------------------------------------------------------------------

local function UpdateAccountCurrency(accountId, currencyId, newCount)
    CharDBExecute("INSERT INTO accountwide_currency (accountId, currencyId, count) VALUES (" .. accountId .. ", " .. currencyId .. ", " .. newCount .. ") ON DUPLICATE KEY UPDATE count = " .. newCount)
end

local function InitializeAccountCurrencyOnEmptyTable(accountId)
	CharDBQueryAsync("SELECT 1 FROM accountwide_currency WHERE accountId = " .. accountId .. " LIMIT 1", function(result)
		if not result then
			for _, currencyId in ipairs(currencyItemIDs) do
				CharDBQueryAsync("SELECT SUM(count) FROM item_instance WHERE itemEntry = " .. currencyId .. " AND owner_guid IN (SELECT guid FROM characters WHERE account = " .. accountId .. ")", function(itemQuery)
					if itemQuery then
						local count = itemQuery:GetUInt32(0)
						UpdateAccountCurrency(accountId, currencyId, count)
					end
				end)
			end
		end
    end)
end

local function SyncCurrencyOnLogin(player, accountId)
	player:SetData("CurrencySynced", true)
	local name = player:GetName()
    for _, currencyId in ipairs(currencyItemIDs) do
		local playerCurrencyCount = player:GetItemCount(currencyId)
		CharDBQueryAsync("SELECT count FROM accountwide_currency WHERE accountId = " .. accountId .. " AND currencyId = " .. currencyId, function(query)
			local player = GetPlayerByName(name)
			if query then accountCurrencyCount = query:GetUInt32(0) else accountCurrencyCount = 0 end

			if playerCurrencyCount < accountCurrencyCount then
				player:AddItem(currencyId, accountCurrencyCount - playerCurrencyCount)
			elseif playerCurrencyCount > accountCurrencyCount then
				player:RemoveItem(currencyId, playerCurrencyCount - accountCurrencyCount)
			end
		end)
	end
end

local function AccountWideCurrency(event, player)
    if isPlayerBot[player:GetName()] then return end
    local accountId = player:GetAccountId()

    if event == 28 then
		if player:GetData("CurrencySynced") then return end
        InitializeAccountCurrencyOnEmptyTable(accountId)
        player:RegisterEvent(function(_, _, _, player)
            SyncCurrencyOnLogin(player, accountId)
        end, 1000, 1) -- Delay of 1000 milliseconds (1 second) to ensure that the InitializeAccountCurrencyOnEmptyTable() function finishes populating the empty table
    elseif event == 4 or event == 25 then
        for _, currencyId in ipairs(currencyItemIDs) do
			local playerCurrencyCount = player:GetItemCount(currencyId)
			CharDBQueryAsync("SELECT count FROM accountwide_currency WHERE accountId = " .. accountId .. " AND currencyId = " .. currencyId, function(query)
				if query then accountCurrencyCount = query:GetUInt32(0) else accountCurrencyCount = 0 end
				
				if playerCurrencyCount ~= accountCurrencyCount then
					UpdateAccountCurrency(accountId, currencyId, playerCurrencyCount)
				end
			end)
        end
    end
end

RegisterPlayerEvent(28, AccountWideCurrency) -- PLAYER_EVENT_ON_MAP_CHANGE
RegisterPlayerEvent(4, AccountWideCurrency) -- PLAYER_EVENT_ON_LOGOUT
RegisterPlayerEvent(25, AccountWideCurrency) -- EVENT_ON_SAVE

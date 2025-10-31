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
    print("[AccountCurrency] UpdateAccountCurrency: AccountID=" .. accountId .. ", CurrencyID=" .. currencyId .. ", NewCount=" .. newCount)
    CharDBExecute("INSERT INTO accountwide_currency (accountId, currencyId, count) VALUES (" .. accountId .. ", " .. currencyId .. ", " .. newCount .. ") ON DUPLICATE KEY UPDATE count = " .. newCount)
end

local function InitializeAccountCurrencyOnEmptyTable(accountId)
    print("[AccountCurrency] InitializeAccountCurrencyOnEmptyTable: Starting for AccountID=" .. accountId)
    CharDBQueryAsync("SELECT 1 FROM accountwide_currency WHERE accountId = " .. accountId .. " LIMIT 1", function(result)
        if not result then
            print("[AccountCurrency] InitializeAccountCurrencyOnEmptyTable: Empty table detected, initializing currencies for AccountID=" .. accountId)
            for _, currencyId in ipairs(currencyItemIDs) do
                CharDBQueryAsync("SELECT SUM(count) FROM item_instance WHERE itemEntry = " .. currencyId .. " AND owner_guid IN (SELECT guid FROM characters WHERE account = " .. accountId .. ")", function(itemQuery)
                    if itemQuery then
                        local count = itemQuery:GetUInt32(0)
                        print("[AccountCurrency] InitializeAccountCurrencyOnEmptyTable: Found " .. count .. " of currency " .. currencyId .. " across all characters for AccountID=" .. accountId)
                        UpdateAccountCurrency(accountId, currencyId, count)
                    else
                        print("[AccountCurrency] InitializeAccountCurrencyOnEmptyTable: No items found for currency " .. currencyId .. " for AccountID=" .. accountId)
                    end
                end)
            end
        end
    end)
end

local function SyncCurrencyOnLogin(player, accountId)
    local name = player:GetName()
    print("[AccountCurrency] SyncCurrencyOnLogin: Starting sync for player=" .. name .. ", AccountID=" .. accountId)
    
    for _, currencyId in ipairs(currencyItemIDs) do
        local playerCurrencyCount = player:GetItemCount(currencyId)
        print("[AccountCurrency] SyncCurrencyOnLogin: Player " .. name .. " has " .. playerCurrencyCount .. " of currency " .. currencyId)
        
        CharDBQueryAsync("SELECT count FROM accountwide_currency WHERE accountId = " .. accountId .. " AND currencyId = " .. currencyId, function(query)
            local player = GetPlayerByName(name)
            if not player then 
                print("[AccountCurrency] SyncCurrencyOnLogin: Player " .. name .. " no longer exists, aborting sync")
                return 
            end
            
            player:SetData("CurrencySynced", true)
            if player:GetData(currencyId) then 
                print("[AccountCurrency] SyncCurrencyOnLogin: Currency " .. currencyId .. " already synced for player " .. name)
                return 
            end
            player:SetData(currencyId, true)
            
            local accountCurrencyCount
            if query then 
                accountCurrencyCount = query:GetUInt32(0) 
            else 
                accountCurrencyCount = 0 
            end
            
            if playerCurrencyCount < accountCurrencyCount then
                local toAdd = accountCurrencyCount - playerCurrencyCount
                print("[AccountCurrency] SyncCurrencyOnLogin: Adding " .. toAdd .. " of currency " .. currencyId .. " to player " .. name)
                player:AddItem(currencyId, toAdd)
            elseif playerCurrencyCount > accountCurrencyCount then
                local toRemove = playerCurrencyCount - accountCurrencyCount
                print("[AccountCurrency] SyncCurrencyOnLogin: Removing " .. toRemove .. " of currency " .. currencyId .. " from player " .. name)
                player:RemoveItem(currencyId, toRemove)
            end
        end)
    end
end

local function AccountWideCurrency(event, player)
    if isPlayerBot[player:GetName()] then 
        return 
    end
    
    local accountId = player:GetAccountId()
    local playerName = player:GetName()
    
    print("[AccountCurrency] AccountWideCurrency: Event " .. event .. " triggered for player=" .. playerName .. ", AccountID=" .. accountId)
    
    if event == 28 then -- PLAYER_EVENT_ON_MAP_CHANGE
        print("[AccountCurrency] AccountWideCurrency: Map change event for player " .. playerName)
        if player:GetData("CurrencySynced") then 
            print("[AccountCurrency] AccountWideCurrency: Currency already synced for player " .. playerName .. ", skipping")
            return 
        end
        
        InitializeAccountCurrencyOnEmptyTable(accountId)
        player:RegisterEvent(function(_, _, _, player)
            SyncCurrencyOnLogin(player, accountId)
        end, 1000, 1) -- Delay of 1000 milliseconds (1 second)
        
    elseif event == 25 then -- PLAYER_EVENT_ON_SAVE        
        for _, currencyId in ipairs(currencyItemIDs) do
            local playerCurrencyCount = player:GetItemCount(currencyId)            
            CharDBQueryAsync("SELECT count FROM accountwide_currency WHERE accountId = " .. accountId .. " AND currencyId = " .. currencyId, function(query)
                local accountCurrencyCount
                if query then 
                    accountCurrencyCount = query:GetUInt32(0) 
                else 
                    accountCurrencyCount = 0 
                end
                
                if playerCurrencyCount ~= accountCurrencyCount then
                    print("[AccountCurrency] AccountWideCurrency: Updating account currency from " .. accountCurrencyCount .. " to " .. playerCurrencyCount .. " for currency " .. currencyId)
                    UpdateAccountCurrency(accountId, currencyId, playerCurrencyCount)
                else
                    print("[AccountCurrency] AccountWideCurrency: No update needed for currency " .. currencyId .. " (already " .. playerCurrencyCount .. ")")
                end
            end)
        end
    end
end

print("[AccountCurrency] Script loaded - registering events")
RegisterPlayerEvent(25, AccountWideCurrency) -- EVENT_ON_SAVE
RegisterPlayerEvent(28, AccountWideCurrency) -- PLAYER_EVENT_ON_MAP_CHANGE
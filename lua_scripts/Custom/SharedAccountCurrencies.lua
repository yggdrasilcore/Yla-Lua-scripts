-- ----------------------------------------------------------------------------------------------
-- ACCOUNTWIDE CURRENCY CONFIG 
--
-- Hosted by Aldori15 on Github: https://github.com/Aldori15/azerothcore-lua-accountwide
-- Adapted to Yggdrasil WoW by mostly nick :)
-- ----------------------------------------------------------------------------------------------
local ENABLE_ACCOUNTWIDE_CURRENCY = true 
-- -- -------------------------------------------------------------------------------------------
-- -- END CONFIG
-- -- -------------------------------------------------------------------------------------------

local currencyItemIDs = {
    37742,  -- Transmog Token 
    20880,  -- Vote Token 
    19322,  -- Community Token 
}

if not ENABLE_ACCOUNTWIDE_CURRENCY then return end

local function FetchAccountCurrency(accountId, currencyId)
    local query = CharDBQuery("SELECT count FROM accountwide_currency WHERE accountId = " .. accountId .. " AND currencyId = " .. currencyId)
    return query and query:GetUInt32(0) or 0
end

local function UpdateAccountCurrency(accountId, currencyId, newCount)
    CharDBExecute("INSERT INTO accountwide_currency (accountId, currencyId, count) VALUES (" .. accountId .. ", " .. currencyId .. ", " .. newCount .. ") ON DUPLICATE KEY UPDATE count = " .. newCount)
end

local function InitializeAccountCurrencyOnEmptyTable(accountId)
    local checkQuery = CharDBQuery("SELECT 1 FROM accountwide_currency WHERE account = " .. accountId .. " LIMIT 1")

    if not checkQuery then
        for _, currencyId in ipairs(currencyItemIDs) do
            local itemQuery = CharDBQuery("SELECT SUM(count) FROM item_instance WHERE itemEntry = " .. currencyId .. " AND owner_guid IN (SELECT guid FROM characters WHERE account = " .. accountId .. ")")
            if itemQuery then
                local count = itemQuery:GetUInt32(0)
                UpdateAccountCurrency(accountId, currencyId, count)
            end
        end
    end
end

local function SyncCurrencyOnLogin(player, accountId)
    for _, currencyId in ipairs(currencyItemIDs) do
        local accountCurrencyCount = FetchAccountCurrency(accountId, currencyId)
        local playerCurrencyCount = player:GetItemCount(currencyId)

        if playerCurrencyCount < accountCurrencyCount then
            player:AddItem(currencyId, accountCurrencyCount - playerCurrencyCount)
        elseif playerCurrencyCount > accountCurrencyCount then
            player:RemoveItem(currencyId, playerCurrencyCount - accountCurrencyCount)
        end
    end
end

local function AccountWideCurrency(event, player)
    local accountId = player:GetAccountId()

    if event == 3 then        
        InitializeAccountCurrencyOnEmptyTable(accountId)
        player:RegisterEvent(function(_, _, _, player)
            SyncCurrencyOnLogin(player, accountId)
        end, 1000, 1) -- Delay of 1000 milliseconds (1 second) to ensure that the InitializeAccountCurrencyOnEmptyTable() function finishes populating the empty table
    elseif event == 4 or event == 25 then
        for _, currencyId in ipairs(currencyItemIDs) do
            local playerCurrencyCount = player:GetItemCount(currencyId)
            local accountCurrencyCount = FetchAccountCurrency(accountId, currencyId)

            if playerCurrencyCount ~= accountCurrencyCount then
                UpdateAccountCurrency(accountId, currencyId, playerCurrencyCount)
            end
        end
    end
end

RegisterPlayerEvent(3, AccountWideCurrency) -- PLAYER_EVENT_ON_LOGIN
RegisterPlayerEvent(4, AccountWideCurrency) -- PLAYER_EVENT_ON_LOGOUT
RegisterPlayerEvent(25, AccountWideCurrency) -- EVENT_ON_SAVE


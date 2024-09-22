-- Currencies covered
local currencies = {20880, 19322}

-- DB initiations
-- WorldDBExecute([[UPDATE item_template SET name = 'Vote Token', maxcount = 0, stackable = 9999999, Quality = 7, Flags = 32, Description = 'One vote can change everything. Thank you for your support!' WHERE entry = 20880;]])
-- WorldDBExecute([[UPDATE item_template SET name = 'Community Token', maxcount = 0, stackable = 9999999, Quality = 7, Flags = 32, Description = 'A shimmering token exchangable for exclusive services. Thank you for your support!' WHERE entry = 19322;]])

--CharDBQuery([[CREATE TABLE IF NOT EXISTS account_currencies (id INT PRIMARY KEY, vp INT, dp INT, total_votes INT, location VARCHAR(255), nickname VARCHAR(255), language VARCHAR(50), avatar VARCHAR(255));]])

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

-- Function to handle player login event
local function OnLogin(event, player)
    local accountId = player:GetAccountId()
	local charguid = player:GetGUIDLow()
	local charguids = {}
	local itemcount
	local playername = player:GetName()
    local pendingQueries = 0
    local count20880 = 0
    local count19322 = 0
    
    if player:HasItem(20880, 1, true) then
        count20880 = player:GetItemCount(20880, true)
    end
    
    if player:HasItem(19322, 1, true) then
        count20880 = player:GetItemCount(20880, true)
    end
    
    print("Character with Yggdrasil currencies logged in. Currency amount before account syncing: Account ID "..accountId..",, Character GUID "..charguid..", Currency 20880, Count "..count20880..". Currency 19322, Count "..count19322)

    -- Query to get character GUIDs for the account
    CharDBQueryAsync(string.format("SELECT guid FROM characters WHERE account = %d", accountId), function(query)
        if query then
            charguids[accountId] = {}
            repeat
                local guid = query:GetUInt32(0)
                table.insert(charguids[accountId], guid)
            until not query:NextRow()
            
            -- Query and sum currency counts for all characters in the account, then reset to 0
            CharDBQueryAsync(string.format([[
                SELECT 
                    SUM(CASE WHEN itemEntry = 20880 THEN count ELSE 0 END) as count_20880,
                    SUM(CASE WHEN itemEntry = 19322 THEN count ELSE 0 END) as count_19322
                FROM item_instance 
                WHERE owner_guid IN (%s) AND itemEntry IN (20880, 19322) AND count > 0
            ]], table.concat(charguids[accountId], ",")), function(countQuery)
                if countQuery then
                    count20880 = countQuery:GetUInt32(0) or 0
                    count19322 = countQuery:GetUInt32(1) or 0
                    
                    if count20880 > 0 or count19322 > 0 then                       
                        player = GetPlayerByName(playername)
                        local guidString = table.concat(charguids[accountId], ",")
                        
                        if count20880 > 0 and count19322 == 0 then
                            print("Currencies after consolidating: Account ID "..accountId..", Character GUID "..charguid..", Currency 20880, Count "..count20880)
                            player:RemoveItem(20880, player:GetItemCount(20880, true))
                            player:AddItem(20880, count20880)
                            if player then -- Rapid dereferencing check
                                CharDBExecute("UPDATE item_instance SET count = CASE WHEN owner_guid IN (" .. guidString .. ") AND itemEntry = 20880 THEN 0 WHEN owner_guid = " .. charguid .. " AND itemEntry = 20880 THEN " .. count20880 .. " ELSE count END WHERE itemEntry = 20880")
                            end
                            print("Currencies after updating inactive characters: Account ID "..accountId..", Character GUID "..charguid..", Currency 20880, Count "..player:GetItemCount(20880, true))
                        elseif count20880 == 0 and count19322 > 0 then
                            print("Currencies after consolidating: Account ID "..accountId..", Character GUID "..charguid..", Currency 19322, Count "..count19322)
                            player:RemoveItem(19322, player:GetItemCount(19322, true))
                            player:AddItem(19322, count19322)
                            if player then -- Rapid dereferencing check
                                CharDBExecute("UPDATE item_instance SET count = CASE WHEN owner_guid IN (" .. guidString .. ") AND itemEntry = 19322 THEN 0 WHEN owner_guid = " .. charguid .. " AND itemEntry = 19322 THEN " .. count19322 .. " ELSE count END WHERE itemEntry = 19322")
                            end
                            print("Currencies after updating inactive characters: Account ID "..accountId..", Character GUID "..charguid..", Currency 19322, Count "..player:GetItemCount(19322, true))
                        else
                            print("Currencies after consolidating: Account ID "..accountId..", Character GUID "..charguid..", Currency 20880, Count "..count20880..", Currency 19322, Count "..count19322)
                            player:RemoveItem(19322, player:GetItemCount(19322, true))
                            player:RemoveItem(20880, player:GetItemCount(20880, true))
                            player:AddItem(19322, count19322)
                            player:AddItem(20880, count20880)
                            if player then --Rapid dereferencing check
                                CharDBExecute("UPDATE item_instance SET count = CASE WHEN owner_guid IN (" .. guidString .. ") AND itemEntry IN (19322, 20880) THEN 0 WHEN owner_guid = " .. charguid .. " AND itemEntry = 19322 THEN " .. count19322 .. " WHEN owner_guid = " .. charguid .. " AND itemEntry = 20880 THEN " .. count20880 .. " ELSE count END WHERE owner_guid = " .. charguid .. " OR owner_guid IN (" .. guidString .. ")")
                            end
                            print("Currencies after updating inactive characters: Account ID "..accountId..", Character GUID "..charguid..", Currency 20880, Count "..player:GetItemCount(20880, true)..", Currency 19322, Count "..player:GetItemCount(19322, true))                        
                        end
                    end
                end
            end)
        end
    end)
	
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
				end, 3000, 1)
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
				end, 3000, 1)
				votemessage = true
			end
		end
	end)
    
    if not (communitymessage or votemessage) then
		player:SendBroadcastMessage("Please remember to vote on Yggdrasilwow.com. Vote Tokens can be redeemed for XP boosts, transmogs, and vanity items.")
    end
end

RegisterPlayerEvent(3, OnLogin)
function IsVIP(player)
    return player:GetData("VIPTime") and player:GetData("VIPTime") > os.time()
end

local function CheckVIPOnLoad()
    local playerNames = {}
    local accountIdMap = {}
    local accountIds = {}
    
    for _, player in pairs(GetPlayersInWorld()) do
        local name = player:GetName()
        local accountId = player:GetAccountId()
        
        table.insert(playerNames, name)
        accountIdMap[name] = accountId
        table.insert(accountIds, accountId)
    end
    
    if #accountIds == 0 then return end
    
    local query = "SELECT account, viptime FROM accounts_vip WHERE account IN (" .. table.concat(accountIds, ",") .. ");"
    
    AuthDBQueryAsync(query, function(result)
        local vipTimeMap = {}
        
        if result then
            repeat
                local accountId = result:GetUInt32(0)
                local vipTime = result:GetUInt32(1)
                vipTimeMap[accountId] = vipTime
            until not result:NextRow()
        end
        
        for _, name in ipairs(playerNames) do
            local player = GetPlayerByName(name)
            if player and vipTimeMap[accountIdMap[name]] then
                player:SetData("VIPTime", vipTimeMap[accountIdMap[name]])
				print("VIP found: "..player:GetName()..", acc "..player:GetAccountId()..". VIPTime: "..player:GetData("VIPTime"))
            elseif player then
                player:SetData("VIPTime", 0)
            end
        end
    end)
end

local function CheckVIP(event, player)
	local name = player:GetName()
	local acc = player:GetAccountId()
    if isPlayerBot[name] then return end
	
	AuthDBQueryAsync("SELECT viptime FROM accounts_vip WHERE account = " .. player:GetAccountId() .. ";", function(result)
		local player = GetPlayerByName(name)
		if not player then return end
		if result then
			player:SetData("VIPTime", result:GetUInt32(0))
		else
			player:SetData("VIPTime", 0)
		end
	end)
end

local function VIPBotRepairOnResurrect(event, player)
    local name = player:GetName()
    if not isPlayerBot[name] then
        if IsVIP(player) then
            player:DurabilityRepairAll(false)
            player:SendBroadcastMessage("Your Yggdrasil VIP subscription has repaired your gear.")
            return
        end
    end
    
    local bot = player
    
	-- Find bot's master
    for botMasterName, bots in pairs(activeBots) do
        for i, botName in ipairs(bots) do
            if botName == name then
				local botMaster = GetPlayerByName(botMasterName)
				if not botMaster then return end
				if not IsVIP(botMaster) then
					bot:SendUnitWhisper('My equipment has taken a 10% durability hit. Please repair my gear by whispering "repair" to me next to a repair vendor.', 0, botMaster)
					return -- No valid VIP, do not repair
				end
				bot:DurabilityRepairAll(false)
				bot:SendUnitWhisper("Your Yggdrasil VIP subscription has repaired my gear.", 0, botMaster)
            end
        end
    end
end

local function VIPGMCommands(event, player, command)
	if not player then return end
    if player:GetGMRank() == 0 then return end
    
    local cmd = command:lower()
    
    if command == "vip" then
        player:SendBroadcastMessage("Welcome to Yggdrasil's VIP GM commands.")
        player:SendBroadcastMessage("These commands are only visible and available to GMs. Syntax:")
        player:SendBroadcastMessage("|-- .vip status")
        player:SendBroadcastMessage("|-- .vip add")
        player:SendBroadcastMessage("|-- .vip remove")
        return false
    end
    
    if cmd == "vip add" then
        player:SendBroadcastMessage("Usage:")
        player:SendBroadcastMessage("|-- .vip add <days>")
        player:SendBroadcastMessage("|-- .vip add <charactername> <days>")
        player:SendBroadcastMessage("|-- .vip add account <accountname> <days>")
        return false
    end
    
    local addAccountTarget, addAccountDays = cmd:match("^vip add account (%S+) (%d+)$")
    local addTarget, addDays = cmd:match("^vip add (%S+) (%d+)$")
    local addSingleMatch = cmd:match("^vip add (%d+)$")
    local removeTarget, removeDays = cmd:match("^vip remove (%S+) (%d+)$")
    local removeSingleMatch = cmd:match("^vip remove (%d+)$")
    local removeAllMatch = cmd:match("^vip remove (%S+) all$")
    local removeAllSingleMatch = cmd:match("^vip remove all$")
    
    if addAccountTarget and addAccountDays then
        local accountName = addAccountTarget
        local days = tonumber(addAccountDays)
        local gmName = player:GetName()
        
        if not days or days <= 0 then
            player:SendBroadcastMessage("Invalid number of days. Please use a positive number.")
            return false
        end
        
        AuthDBQueryAsync("SELECT id, username FROM account WHERE username = '" .. accountName .. "' COLLATE utf8mb4_general_ci;", function(result)
            local gm = GetPlayerByName(gmName)
            
            if not result then
                if gm then gm:SendBroadcastMessage("Account '" .. accountName .. "' does not exist.") end
                return
            end
            
            local targetAccountId = result:GetUInt32(0)
            local targetUsername = result:GetString(1)
            
            CharDBQueryAsync("SELECT name FROM characters WHERE account = " .. targetAccountId .. ";", function(charResult)
                local gm = GetPlayerByName(gmName)
                local charNames = {}
                local onlineCharName = nil
                
                if charResult then
                    repeat
                        local charName = charResult:GetString(0)
                        table.insert(charNames, charName)
                        
                        if not onlineCharName then
                            local p = GetPlayerByName(charName)
                            if p then
                                if isPlayerBot[charName] then
                                    local botMaster = nil
                                    for masterName, bots in pairs(activeBots) do
                                        for i, botName in ipairs(bots) do
                                            if botName == charName then
                                                botMaster = GetPlayerByName(masterName)
                                                break
                                            end
                                        end
                                        if botMaster then break end
                                    end
                                    if botMaster then
                                        onlineCharName = botMaster:GetName()
                                    end
                                else
                                    onlineCharName = charName
                                end
                            end
                        end
                    until not charResult:NextRow()
                end
                
                AuthDBQueryAsync("SELECT viptime FROM accounts_vip WHERE account = " .. targetAccountId .. ";", function(vipResult)
                    local gm = GetPlayerByName(gmName)
                    
                    local currentVIPTime = vipResult and vipResult:GetUInt32(0) or 0
                    local currentTime = os.time()
                    
                    local baseTime = math.max(currentVIPTime, currentTime)
                    local newVIPTime = baseTime + (days * 24 * 60 * 60)
                    
                    AuthDBExecute("INSERT INTO accounts_vip (account, viptime) VALUES (" .. targetAccountId .. ", " .. newVIPTime .. ") ON DUPLICATE KEY UPDATE VIPTIME = VALUES(VIPTIME);")
                    
                    local charListStr = #charNames > 0 and table.concat(charNames, ", ") or "no characters"
                    
                    local freshOnlinePlayer = onlineCharName and GetPlayerByName(onlineCharName) or nil
                    if freshOnlinePlayer then
                        freshOnlinePlayer:SetData("VIPTime", newVIPTime)
                        freshOnlinePlayer:SendBroadcastMessage("A GM has granted you " .. days .. " VIP days. Your VIP status has been updated!")
                    end
                    
                    if gm then gm:SendBroadcastMessage("Added " .. days .. " VIP days to " .. targetUsername .. " (" .. charListStr .. "). New VIP expires: " .. os.date("%Y-%m-%d %H:%M:%S", newVIPTime)) end
                end)
            end)
        end)
        
        return false

    elseif addTarget and addDays then
        local targetName = addTarget
        local days = tonumber(addDays)
        local gmName = player:GetName()
        
        if not days or days <= 0 then
            player:SendBroadcastMessage("Invalid number of days. Please use a positive number.")
            return false
        end
        
        CharDBQueryAsync("SELECT name, account FROM characters WHERE name = '" .. targetName .. "' COLLATE utf8mb4_general_ci;", function(result)
            local gm = GetPlayerByName(gmName)
            
            if not result then
                if gm then gm:SendBroadcastMessage("Player '" .. targetName .. "' does not exist.") end
                return
            end
            
            local charName = result:GetString(0)
            local targetAccountId = result:GetUInt32(1)
            local targetPlayer = GetPlayerByName(charName)
            
            -- Check if target is a bot, if so find its master
            if targetPlayer and isPlayerBot[charName] then
                local botMaster = nil
                for masterName, bots in pairs(activeBots) do
                    for i, botName in ipairs(bots) do
                        if botName == charName then
                            botMaster = GetPlayerByName(masterName)
                            break
                        end
                    end
                    if botMaster then break end
                end
                
                if botMaster then
                    targetPlayer = botMaster
                    charName = botMaster:GetName()
                    targetAccountId = botMaster:GetAccountId()
                    if gm then gm:SendBroadcastMessage("Adding VIP to " .. targetName .. "'s master: " .. botMaster:GetName()) end
                else
                    if gm then gm:SendBroadcastMessage("Could not find master for bot: " .. targetName) end
                    return
                end
            end
            
            AuthDBQueryAsync("SELECT username FROM account WHERE id = " .. targetAccountId .. ";", function(acctResult)
                local gm = GetPlayerByName(gmName)
                local username = acctResult and acctResult:GetString(0) or "unknown"
                
                AuthDBQueryAsync("SELECT viptime FROM accounts_vip WHERE account = " .. targetAccountId .. ";", function(vipResult)
                    local gm = GetPlayerByName(gmName)
                    local targetPlayer = GetPlayerByName(charName)
                    
                    local currentVIPTime = vipResult and vipResult:GetUInt32(0) or 0
                    local currentTime = os.time()
                    
                    local baseTime = math.max(currentVIPTime, currentTime)
                    local newVIPTime = baseTime + (days * 24 * 60 * 60)
                    
                    AuthDBExecute("INSERT INTO accounts_vip (account, viptime) VALUES (" .. targetAccountId .. ", " .. newVIPTime .. ") ON DUPLICATE KEY UPDATE VIPTIME = VALUES(VIPTIME);")
                    
                    if targetPlayer then
                        targetPlayer:SetData("VIPTime", newVIPTime)
                        targetPlayer:SendBroadcastMessage("A GM has granted you " .. days .. " VIP days. Your VIP status has been updated!")
                        if gm then gm:SendBroadcastMessage("Added " .. days .. " VIP days to " .. username .. " (" .. targetPlayer:GetName() .. "). New VIP expires: " .. os.date("%Y-%m-%d %H:%M:%S", newVIPTime)) end
                    else
                        if gm then gm:SendBroadcastMessage("Added " .. days .. " VIP days to " .. username .. " (" .. charName .. ", offline). New VIP expires: " .. os.date("%Y-%m-%d %H:%M:%S", newVIPTime)) end
                    end
                end)
            end)
        end)
        
        return false
    elseif addSingleMatch then
        local daysStr = addSingleMatch
        local days = tonumber(daysStr)
        
        if not days or days <= 0 then
            player:SendBroadcastMessage("Invalid number of days. Please use a positive number.")
            return false
        end
        
        -- Try to get target from selection first, then fall back to command user
        local targetPlayer = nil
        if player:GetSelection() and player:GetSelection():ToPlayer() then
            targetPlayer = player:GetSelection():ToPlayer()
            local selectedName = targetPlayer:GetName()
            
            -- Check if selected character is a bot
            if isPlayerBot[selectedName] then
                -- Find the bot's master
                local botMaster = nil
                for masterName, bots in pairs(activeBots) do
                    for i, botName in ipairs(bots) do
                        if botName == selectedName then
                            botMaster = GetPlayerByName(masterName)
                            break
                        end
                    end
                    if botMaster then break end
                end
                
                if botMaster then
                    targetPlayer = botMaster
                    player:SendBroadcastMessage("Adding VIP to " .. selectedName .. "'s master: " .. botMaster:GetName())
                else
                    player:SendBroadcastMessage("Could not find master for bot: " .. selectedName)
                    return false
                end
            end
        else
            targetPlayer = player
        end
        
        local targetAccountId = targetPlayer:GetAccountId()
        local currentVIPTime = targetPlayer:GetData("VIPTime") or 0
        local currentTime = os.time()
        
        local baseTime = math.max(currentVIPTime, currentTime)
        local newVIPTime = baseTime + (days * 24 * 60 * 60)
        
        AuthDBExecute("INSERT INTO accounts_vip (account, viptime) VALUES (" .. targetAccountId .. ", " .. newVIPTime .. ") ON DUPLICATE KEY UPDATE VIPTIME = VALUES(VIPTIME);")
        
        targetPlayer:SetData("VIPTime", newVIPTime)
        
        if targetPlayer == player then
            player:SendBroadcastMessage("Added " .. days .. " VIP days to yourself. New VIP expires: " .. os.date("%Y-%m-%d %H:%M:%S", newVIPTime))
        else
            player:SendBroadcastMessage("Added " .. days .. " VIP days to " .. targetPlayer:GetName() .. ". New VIP expires: " .. os.date("%Y-%m-%d %H:%M:%S", newVIPTime))
            targetPlayer:SendBroadcastMessage("A GM has granted you " .. days .. " VIP days. Your VIP status has been updated!")
        end
        
        return false
    elseif removeTarget and removeDays then
        local targetName = removeTarget
        local days = tonumber(removeDays)
        
        if not days or days <= 0 then
            player:SendBroadcastMessage("Invalid number of days. Please use a positive number.")
            return false
        end
        
        local targetPlayer = GetPlayerByName(targetName)
        if not targetPlayer then
            player:SendBroadcastMessage("Player '" .. targetName .. "' not found or not online.")
            return false
        end
        
        -- Check if target is a bot, if so find its master
        if isPlayerBot[targetName] then
            local botMaster = nil
            for masterName, bots in pairs(activeBots) do
                for i, botName in ipairs(bots) do
                    if botName == targetName then
                        botMaster = GetPlayerByName(masterName)
                        break
                    end
                end
                if botMaster then break end
            end
            
            if botMaster then
                targetPlayer = botMaster
                player:SendBroadcastMessage("Removing VIP from " .. targetName .. "'s master: " .. botMaster:GetName())
            else
                player:SendBroadcastMessage("Could not find master for bot: " .. targetName)
                return false
            end
        end
        
        local targetAccountId = targetPlayer:GetAccountId()
        local currentVIPTime = targetPlayer:GetData("VIPTime") or 0
        local currentTime = os.time()
        
        local newVIPTime = math.max(currentTime, currentVIPTime - (days * 24 * 60 * 60))
        
        AuthDBExecute("INSERT INTO accounts_vip (account, viptime) VALUES (" .. targetAccountId .. ", " .. newVIPTime .. ") ON DUPLICATE KEY UPDATE VIPTIME = VALUES(VIPTIME);")
        
        targetPlayer:SetData("VIPTime", newVIPTime)
        
        if newVIPTime <= currentTime then
            player:SendBroadcastMessage("Removed " .. days .. " VIP days from " .. targetPlayer:GetName() .. ". VIP is now INACTIVE.")
            targetPlayer:SendBroadcastMessage("A GM has removed " .. days .. " VIP days from your account. Your VIP status has been updated!")
        else
            player:SendBroadcastMessage("Removed " .. days .. " VIP days from " .. targetPlayer:GetName() .. ". New VIP expires: " .. os.date("%Y-%m-%d %H:%M:%S", newVIPTime))
            targetPlayer:SendBroadcastMessage("A GM has removed " .. days .. " VIP days from your account. Your VIP status has been updated!")
        end
        
        return false
    elseif removeSingleMatch then
        local daysStr = removeSingleMatch
        local days = tonumber(daysStr)
        
        if not days or days <= 0 then
            player:SendBroadcastMessage("Invalid number of days. Please use a positive number.")
            return false
        end
        
        -- Try to get target from selection first, then fall back to command user
        local targetPlayer = nil
        if player:GetSelection() and player:GetSelection():ToPlayer() then
            targetPlayer = player:GetSelection():ToPlayer()
            local selectedName = targetPlayer:GetName()
            
            -- Check if selected character is a bot
            if isPlayerBot[selectedName] then
                -- Find the bot's master
                local botMaster = nil
                for masterName, bots in pairs(activeBots) do
                    for i, botName in ipairs(bots) do
                        if botName == selectedName then
                            botMaster = GetPlayerByName(masterName)
                            break
                        end
                    end
                    if botMaster then break end
                end
                
                if botMaster then
                    targetPlayer = botMaster
                    player:SendBroadcastMessage("Removing VIP from " .. selectedName .. "'s master: " .. botMaster:GetName())
                else
                    player:SendBroadcastMessage("Could not find master for bot: " .. selectedName)
                    return false
                end
            end
        else
            targetPlayer = player
        end
        
        local targetAccountId = targetPlayer:GetAccountId()
        local currentVIPTime = targetPlayer:GetData("VIPTime") or 0
        local currentTime = os.time()
        
        local newVIPTime = math.max(currentTime, currentVIPTime - (days * 24 * 60 * 60))
        
        AuthDBExecute("INSERT INTO accounts_vip (account, viptime) VALUES (" .. targetAccountId .. ", " .. newVIPTime .. ") ON DUPLICATE KEY UPDATE VIPTIME = VALUES(VIPTIME);")
        
        targetPlayer:SetData("VIPTime", newVIPTime)
        
        if newVIPTime <= currentTime then
            if targetPlayer == player then
                player:SendBroadcastMessage("Removed " .. days .. " VIP days from yourself. VIP is now INACTIVE.")
            else
                player:SendBroadcastMessage("Removed " .. days .. " VIP days from " .. targetPlayer:GetName() .. ". VIP is now INACTIVE.")
                targetPlayer:SendBroadcastMessage("A GM has removed " .. days .. " VIP days from your account. Your VIP status has been updated!")
            end
        else
            if targetPlayer == player then
                player:SendBroadcastMessage("Removed " .. days .. " VIP days from yourself. New VIP expires: " .. os.date("%Y-%m-%d %H:%M:%S", newVIPTime))
            else
                player:SendBroadcastMessage("Removed " .. days .. " VIP days from " .. targetPlayer:GetName() .. ". New VIP expires: " .. os.date("%Y-%m-%d %H:%M:%S", newVIPTime))
                targetPlayer:SendBroadcastMessage("A GM has removed " .. days .. " VIP days from your account. Your VIP status has been updated!")
            end
        end
        
        return false
    elseif removeAllMatch then
        local targetName = removeAllMatch
        local targetPlayer = GetPlayerByName(targetName)
        
        if not targetPlayer then
            player:SendBroadcastMessage("Player '" .. targetName .. "' not found or not online.")
            return false
        end
        
        -- Check if target is a bot, if so find its master
        if isPlayerBot[targetName] then
            local botMaster = nil
            for masterName, bots in pairs(activeBots) do
                for i, botName in ipairs(bots) do
                    if botName == targetName then
                        botMaster = GetPlayerByName(masterName)
                        break
                    end
                end
                if botMaster then break end
            end
            
            if botMaster then
                targetPlayer = botMaster
                player:SendBroadcastMessage("Removing all VIP from " .. targetName .. "'s master: " .. botMaster:GetName())
            else
                player:SendBroadcastMessage("Could not find master for bot: " .. targetName)
                return false
            end
        end
        
        local targetAccountId = targetPlayer:GetAccountId()
        local currentTime = os.time()
        
        AuthDBExecute("INSERT INTO accounts_vip (account, viptime) VALUES (" .. targetAccountId .. ", " .. currentTime .. ") ON DUPLICATE KEY UPDATE VIPTIME = VALUES(VIPTIME);")
        
        targetPlayer:SetData("VIPTime", currentTime)
        
        player:SendBroadcastMessage("Removed all VIP time from " .. targetPlayer:GetName() .. ". VIP is now INACTIVE.")
        targetPlayer:SendBroadcastMessage("A GM has removed all VIP time from your account. Your VIP status has been updated!")
        
        return false
    elseif removeAllSingleMatch then
        -- Try to get target from selection first, then fall back to command user
        local targetPlayer = nil
        if player:GetSelection() and player:GetSelection():ToPlayer() then
            targetPlayer = player:GetSelection():ToPlayer()
            local selectedName = targetPlayer:GetName()
            
            -- Check if selected character is a bot
            if isPlayerBot[selectedName] then
                -- Find the bot's master
                local botMaster = nil
                for masterName, bots in pairs(activeBots) do
                    for i, botName in ipairs(bots) do
                        if botName == selectedName then
                            botMaster = GetPlayerByName(masterName)
                            break
                        end
                    end
                    if botMaster then break end
                end
                
                if botMaster then
                    targetPlayer = botMaster
                    player:SendBroadcastMessage("Removing all VIP from " .. selectedName .. "'s master: " .. botMaster:GetName())
                else
                    player:SendBroadcastMessage("Could not find master for bot: " .. selectedName)
                    return false
                end
            end
        else
            targetPlayer = player
        end
        
        local targetAccountId = targetPlayer:GetAccountId()
        local currentTime = os.time()
        
        AuthDBExecute("INSERT INTO accounts_vip (account, viptime) VALUES (" .. targetAccountId .. ", " .. currentTime .. ") ON DUPLICATE KEY UPDATE VIPTIME = VALUES(VIPTIME);")
        
        targetPlayer:SetData("VIPTime", currentTime)
        
        if targetPlayer == player then
            player:SendBroadcastMessage("Removed all VIP time from yourself. VIP is now INACTIVE.")
        else
            player:SendBroadcastMessage("Removed all VIP time from " .. targetPlayer:GetName() .. ". VIP is now INACTIVE.")
            targetPlayer:SendBroadcastMessage("A GM has removed all VIP time from your account. Your VIP status has been updated!")
        end
        
        return false
    elseif cmd:match("^vip remove") then
        -- Handle incorrect vip remove format
        player:SendBroadcastMessage('Incorrect format. Usage: ".vip remove <days>", ".vip remove <name> <days>", ".vip remove all", or ".vip remove <name> all"')
        return false
    end
    
    local statusMatch = cmd:match("^vip status (%S+)$")
    if statusMatch then
        local targetName = statusMatch
        local targetPlayer = GetPlayerByName(targetName)
        
        if not targetPlayer then
            player:SendBroadcastMessage("Player '" .. targetName .. "' not found or not online.")
            return false
        end
        
        local vipTime = targetPlayer:GetData("VIPTime") or 0
        local currentTime = os.time()
        
        if vipTime > currentTime then
            local remainingTime = vipTime - currentTime
            local days = math.floor(remainingTime / 86400)
            local hours = math.floor((remainingTime % 86400) / 3600)
            local minutes = math.floor((remainingTime % 3600) / 60)
            
            player:SendBroadcastMessage(targetName .. " VIP Status: ACTIVE")
            player:SendBroadcastMessage("Time remaining: " .. days .. " days, " .. hours .. " hours, " .. minutes .. " minutes")
            player:SendBroadcastMessage("Expires: " .. os.date("%Y-%m-%d %H:%M:%S", vipTime))
        else
            player:SendBroadcastMessage(targetName .. " VIP Status: INACTIVE")
            if vipTime > 0 then
                player:SendBroadcastMessage("Last expired: " .. os.date("%Y-%m-%d %H:%M:%S", vipTime))
            else
                player:SendBroadcastMessage("Never had VIP")
            end
        end
        
        return false
    end
    
    if cmd == "vip status" then
        local targetPlayer = player -- Default to command user
        
        -- Check if there's a selection
        if player:GetSelection() and player:GetSelection():ToPlayer() then
            local selectedChar = player:GetSelection():ToPlayer():GetName()
            
            -- Check if selected character is a bot
            if isPlayerBot[selectedChar] then
                -- Find the bot's master
                local botMaster = nil
                for masterName, bots in pairs(activeBots) do
                    for i, botName in ipairs(bots) do
                        if botName == selectedChar then
                            botMaster = GetPlayerByName(masterName)
                            break
                        end
                    end
                    if botMaster then break end
                end
                
                if botMaster then
                    targetPlayer = botMaster
                    player:SendBroadcastMessage("Checking VIP status of " .. selectedChar .. "'s master: " .. botMaster:GetName())
                else
                    player:SendBroadcastMessage("Could not find master for bot: " .. selectedChar)
                    return false
                end
            else
                targetPlayer = player:GetSelection():ToPlayer()
            end
        end
        
        local vipTime = targetPlayer:GetData("VIPTime") or 0
        local currentTime = os.time()
        
        if vipTime > currentTime then
            local remainingTime = vipTime - currentTime
            local days = math.floor(remainingTime / 86400)
            local hours = math.floor((remainingTime % 86400) / 3600)
            local minutes = math.floor((remainingTime % 3600) / 60)
            
            player:SendBroadcastMessage("VIP Status of "..targetPlayer:GetName()..": ACTIVE")
            player:SendBroadcastMessage("Time remaining: " .. days .. " days, " .. hours .. " hours, " .. minutes .. " minutes")
            player:SendBroadcastMessage("Expires: " .. os.date("%Y-%m-%d %H:%M:%S", vipTime))
        else
            player:SendBroadcastMessage("VIP Status of "..targetPlayer:GetName()..": INACTIVE")
            if vipTime > 0 then
                player:SendBroadcastMessage("Last expired: " .. os.date("%Y-%m-%d %H:%M:%S", vipTime))
            else
                player:SendBroadcastMessage("Never had VIP")
            end
        end
        
        return false
    end
    
    return
end

local function CheckVIPCmd(player)
    if not IsVIP(player) then
        player:SendBroadcastMessage("You don't have an active Yggdrasil VIP subscription. Talk to Twiggy to active VIP today.")
        return false
    end
    return true
end

local function VIPCommands(event, player, command)
    local cmd = command:lower()
    if cmd == "vip" and player:GetGMRank() == 0 then
        if not CheckVIPCmd(player) then return false end
        
        local vipTime = player:GetData("VIPTime") or 0
        local currentTime = os.time()
        
        if vipTime > currentTime then
            local remainingTime = vipTime - currentTime
            local days = math.floor(remainingTime / 86400)
            local hours = math.floor((remainingTime % 86400) / 3600)
            local minutes = math.floor((remainingTime % 3600) / 60)
            
            player:SendBroadcastMessage("Your Yggdrasil VIP is active.")
            player:SendBroadcastMessage("Time remaining: " .. days .. " days, " .. hours .. " hours, " .. minutes .. " minutes")
        end
        
        return false
    elseif (cmd == "vip repair" or cmd == "repair") then
        if not CheckVIPCmd(player) then return false end
        player:DurabilityRepairAll(false, 0, false)
        player:SendBroadcastMessage("All items have been repaired.")
        return false
        
    elseif cmd == "vip mail" then
        if not CheckVIPCmd(player) then return false end
        local guid = player:GetGUIDLow()
        local currentTime = os.time()
        if not mailboxtime[guid] then 
            mailboxtime[guid] = 0
        end
        
        if mailboxtime[guid] <= currentTime then
            player:CastSpell(player, 54710, true)
            mailboxtime[guid] = currentTime + 900
        else
            local remainingTime = mailboxtime[guid] - currentTime
            local minutes = math.floor(remainingTime / 60)
            local seconds = remainingTime % 60
            
            player:SendAreaTriggerMessage(string.format("Your VIP mailbox is on cooldown for %d minutes and %d seconds.", minutes, seconds))
        end
        return false
        
    elseif cmd == "vip bank" then
        if not CheckVIPCmd(player) then return false end
        player:SendShowBank(player)
        return false
        
    elseif cmd == "vip xp" then
        if not CheckVIPCmd(player) then return false end
        player:RunCommand("xpchangemenu "..os.time())
        return false
    end
end

CheckVIPOnLoad() -- Sets players with VIP as active VIP on load/reload ELUNA
RegisterPlayerEvent(28, CheckVIP)
RegisterPlayerEvent(36, VIPBotRepairOnResurrect)
RegisterPlayerEvent(42, VIPCommands)
RegisterPlayerEvent(42, VIPGMCommands)
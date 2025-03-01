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
            elseif player then
                player:SetData("VIPTime", 0)
            end
        end
    end)
end

local function CheckVIP(event, player)
    if isPlayerBot[name] then return end
	if not player:GetData("VIPTime") then
		local name = player:GetName()
		local GUIDLow = player:GetGUIDLow()
		AuthDBQueryAsync("SELECT viptime FROM accounts_vip WHERE account = " .. player:GetAccountId() .. ";", function(result)
			local player = GetPlayerByName(name)
			if result then
				player:SetData("VIPTime", result:GetUInt32(0))
				print("VIP found: "..player:GetName()..".")
			else
				player:SetData("VIPTime", 0)
			end
		end)
	end
end

local function HandleVIPCommands(event, player, command)
    if not command:lower():find("^vip") then
        return
    end
	
    if not (player:GetData("VIPTime") and player:GetData("VIPTime") > os.time()) then
        player:SendBroadcastMessage("You don't have an active Yggdrasil VIP subscription.")
        return false
    end

    local cmd = command:lower()
    
    if cmd == "vip repair" then
        player:DurabilityRepairAll(false, 0, false)
        player:SendBroadcastMessage("All items have been repaired.")
        return false
        
    elseif cmd == "vip mail" then

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
        player:SendShowBank(player)
        return false
        
    elseif cmd == "vip xp" then
		player:RunCommand("xpchangemenu "..os.time())
        return false
    end
end

CheckVIPOnLoad() -- Sets players with VIP as active VIP on load/reload ELUNA
RegisterPlayerEvent(28, CheckVIP)
RegisterPlayerEvent(42, HandleVIPCommands)
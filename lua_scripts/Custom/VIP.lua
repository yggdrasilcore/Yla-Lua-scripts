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
    if isPlayerBot[name] then print("Skipping VIP check on bot "..name) return end
	if player:GetData("VIPTime") then
		print("VIP Time - Map check for "..name.. ", VIP time is "..player:GetData("VIPTime"))
		return
	end
	
	print("Fetching VIP time for "..name..", acc ".. acc)
	AuthDBQueryAsync("SELECT viptime FROM accounts_vip WHERE account = " .. player:GetAccountId() .. ";", function(result)
		local player = GetPlayerByName(name)
		if not player then return end
		if result then
			player:SetData("VIPTime", result:GetUInt32(0))
		else
			player:SetData("VIPTime", 0)
		end
		print("VIP Time - Login check for "..name.. ", VIP time is "..player:GetData("VIPTime"))
	end)
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

local function VIPBotRepairOnResurrect(event, bot)
    local name = bot:GetName()
    if not isPlayerBot[name] then return end -- Not playerbot - do not check for free repairs on ress
    
	-- Find bot's master
    for botMasterName, bots in pairs(activeBots) do
        for i, botName in ipairs(bots) do
            if botName == name then
				local botMaster = GetPlayerByName(botMasterName)
				if not botMaster then return end
				if not (botMaster:GetData("VIPTime") and botMaster:GetData("VIPTime") > os.time()) then
					return -- No valid VIP, do not repair
				end
				bot:DurabilityRepairAll(false)
				bot:SendUnitWhisper("Your Yggdrasil VIP subscription has repaired my gear.", 0, botMaster)
            end
        end
    end
end

CheckVIPOnLoad() -- Sets players with VIP as active VIP on load/reload ELUNA
RegisterPlayerEvent(28, CheckVIP)
RegisterPlayerEvent(36, VIPBotRepairOnResurrect)
RegisterPlayerEvent(42, HandleVIPCommands)
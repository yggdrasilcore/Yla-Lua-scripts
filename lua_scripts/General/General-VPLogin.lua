WorldDBExecute([[UPDATE item_template SET name = 'Vote Token', maxcount = 0, stackable = 9999999, Quality = 7, Flags = 32, Description = 'One vote can change everything. Thank you for your support!' WHERE entry = 20880;]])
WorldDBExecute([[UPDATE item_template SET name = 'Community Token', maxcount = 0, stackable = 9999999, Quality = 7, Flags = 32, Description = 'A shimmering token exchangable for exclusive services. Thank you for your support!' WHERE entry = 19322;]])

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

local function SendBroadcastWithCheck(playerGUID, message)
    local player = GetPlayerByGUID(playerGUID)
    if player then
        player:SendBroadcastMessage(message)
    end
end

local function OnPlayerLogin(event, player)
    local accountId = player:GetAccountId()
    local playerGUID = player:GetGUID()
	local communitymessage
	local votemessage
	
    local vpquery = CharDBQuery("SELECT vp FROM account_currencies WHERE id = " .. accountId)
	local dpquery = CharDBQuery("SELECT dp FROM account_currencies WHERE id = " .. accountId)

    if dpquery then
        local dpValue = dpquery:GetInt32(0)
        if dpValue and dpValue > 0 then
            local itemCount = dpValue
            player:AddItem(19322, itemCount)
			print("Awarding Community Tokens to Account ID: " .. accountId)  -- Debugging line
            CharDBExecute("UPDATE account_currencies SET dp = 0 WHERE id = " .. accountId)
            CreateLuaEvent(function() SendBroadcastWithCheck(playerGUID, "You have been awarded " .. itemCount .. " Community Tokens. Thank you for supporting our community!") end, 3000, 1)
			communitymessage = true
        end
    end

    if vpquery then
        local vpValue = vpquery:GetInt32(0)
        if vpValue and vpValue > 0 then
            local itemCount = vpValue
            player:AddItem(20880, itemCount)
			print("Awarding Vote Tokens to Account ID: " .. accountId)  -- Debugging line
            CharDBExecute("UPDATE account_currencies SET vp = 0 WHERE id = " .. accountId)
            CreateLuaEvent(function() SendBroadcastWithCheck(playerGUID, "You have been awarded " .. itemCount .. " Vote Tokens, which can be redeemed for XP boosts, transmogs, and vanity items. Thank you for your support!") end, 3000, 1)
			votemessage = true
		end
	end
	
	if communitymessage or votemessage then
		return
	else
		CreateLuaEvent(function() SendBroadcastWithCheck(playerGUID, "Please remember to vote on Yggdrasilwow.com. Vote Tokens can be redeemed for XP boosts, transmogs, and vanity items. Thank you for your support!") end, 3000, 1)
    end
	
end

RegisterPlayerEvent(3, OnPlayerLogin)

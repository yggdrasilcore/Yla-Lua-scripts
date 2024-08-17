WorldDBExecute([[UPDATE item_template SET name = 'Vote Token', maxcount = 0, stackable = 9999, Quality = 7, Flags = 134217728, Description = 'A shimmering token of gratitude.' WHERE entry = 20880;]])
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
    local query = CharDBQuery("SELECT vp FROM account_currencies WHERE id = " .. accountId)

    if query then
        local vpValue = query:GetInt32(0)
        if vpValue and vpValue > 0 then
            local itemCount = vpValue
            player:AddItem(20880, itemCount)
			print("Awarding VP to Account ID: " .. accountId)  -- Debugging line
            CharDBExecute("UPDATE account_currencies SET vp = 0 WHERE id = " .. accountId)
            CreateLuaEvent(function() SendBroadcastWithCheck(playerGUID, "You have been awarded " .. itemCount .. " vote tokens, which can be redeemed for XP boosts, transmogs, and vanity items. Thank you for your support!") end, 3000, 1)
        else
            CreateLuaEvent(function() SendBroadcastWithCheck(playerGUID, "Please remember to vote on Yggdrasilwow.com. Vote tokens can be redeemed for XP boosts, transmogs, and vanity items. Thank you for your support!") end, 3000, 1)
        end
    end
end

RegisterPlayerEvent(3, OnPlayerLogin)

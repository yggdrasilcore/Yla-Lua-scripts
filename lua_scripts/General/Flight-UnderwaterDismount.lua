local BUFFIDS = {
    471, 3363, 8153, 8980, 10788, 10790, 10792, 24576, 25675, 25858, 28828, 32235, 32239, 32240,
    32242, 32243, 32244, 32245, 32246, 32289, 32290, 32292, 32295, 32296, 32297, 32345, 32420,
    33943, 34068, 37015, 39450, 39798, 39800, 39801, 39802, 39803, 39910, 39949, 40120, 40192,
    40212, 41513, 41514, 41515, 41516, 41517, 41518, 42667, 42668, 42673, 42679, 42929, 43810,
    43927, 44151, 44153, 44317, 44655, 44744, 44824, 44825, 44827, 45127, 45177, 46197, 46199,
    46980, 47037, 48023, 49193, 49908, 50281, 51617, 51960, 54726, 54727, 54729, 54903, 58615,
    59567, 59568, 59569, 59570, 59571, 59650, 59961, 59976, 59996, 60002, 60021, 60024, 60025,
    60099, 60120, 60136, 60140, 61229, 61230, 61289, 61294, 61309, 61442, 61444, 61446, 61451,
    61983, 61996, 61997, 62048, 63796, 63844, 63956, 63963, 64749, 64762, 64927, 65439, 66087,
    66088, 67336, 68767, 69395, 71346, 71347, 71810, 72283, 72284, 72807, 72808, 74854, 74855,
    75596, 75617, 75618, 76153
}

local ITEM_IDS = {39163, 28326, 20739, 208800} -- Items used to trigger initial cast

local playersToCheck = {}

local function IsBuffId(spellId)
    for _, id in ipairs(BUFFIDS) do
        if id == spellId then
            return true
        end
    end
    return false
end

local function IsTrackedItem(itemId)
    for _, id in ipairs(ITEM_IDS) do
        if id == itemId then
            return true
        end
    end
    return false
end

local function CheckUnderwater(eventId, delay, repeats, playerGUID, buffId)
    local players = GetPlayersInWorld()
    local foundPlayer = nil
    for _, player in ipairs(players) do
        if player and type(player) == "userdata" and player:GetGUID() == playerGUID then
            foundPlayer = player
            break
        end
    end

    if not foundPlayer then
        --print("Player not found. Stopping check.")
        playersToCheck[playerGUID] = nil
        return true  -- Cancel the event
    end

    if foundPlayer:IsUnderWater() then
        if foundPlayer:HasAura(buffId) then
            foundPlayer:RemoveAura(buffId)
            print("[Flight]: Removed flight " .. buffId .. " from player " .. foundPlayer:GetName().." as they were underwater.")
        end
    end
    
    if not foundPlayer:HasAura(buffId) then
        --print("Stopped checking player " .. foundPlayer:GetName())
        playersToCheck[playerGUID] = nil
        return true  -- Cancel the event
    end
end

local function StartCheckingPlayer(player, buffId)
    local playerGUID = player:GetGUID()
    if not playersToCheck[playerGUID] then
        playersToCheck[playerGUID] = true
        CreateLuaEvent(function(eventId, delay, repeats)
            if not playersToCheck[playerGUID] then
                return true  -- Cancel the event if player is no longer being checked
            end
            return CheckUnderwater(eventId, delay, repeats, playerGUID, buffId)
        end, 1000, 0)  -- Check every 1 second indefinitely
        --print("Started checking player " .. player:GetName() .. " for buff " .. buffId)
    end
end

local function OnSpellCast(event, player, spell, skipCheck)
    local spellId = spell:GetEntry()
    if IsBuffId(spellId) then
        StartCheckingPlayer(player, spellId)
    end
end

local function OnLogin(event, player)
    for _, buffId in ipairs(BUFFIDS) do
        if player:HasAura(buffId) then
            StartCheckingPlayer(player, buffId)
        end
    end
end

local function CheckAndStartMonitoring(player)
    if player:HasSpell(34091) or player:HasSpell(34093) then
        if player:HasAura(40120) then
            StartCheckingPlayer(player, 40120)
            return true
        end
    elseif player:HasSpell(34090) or player:HasSpell(34092) then
        if player:HasAura(33943) then
            StartCheckingPlayer(player, 33943)
            return true
        end
    end
    return false
end

local function OnItemUse(event, player, item, targets)
    local itemId = item:GetEntry()
    if IsTrackedItem(itemId) then
		--print("Item used!")
        local playerGUID = player:GetGUID()
        if not playersToCheck[playerGUID] then
            CreateLuaEvent(function(eventId, delay, repeats)
                local currentPlayer = GetPlayerByGUID(playerGUID)
                if not currentPlayer then
                    return true -- Cancel the event if player is not found
                end
                if CheckAndStartMonitoring(currentPlayer) then
                    return true -- Cancel the event if we've started monitoring
                end
            end, 500, 1) -- Check every 1 second indefinitely
        end
    end
end

RegisterPlayerEvent(3, OnLogin)  -- PLAYER_EVENT_ON_LOGIN
RegisterPlayerEvent(5, OnSpellCast)  -- PLAYER_EVENT_ON_CAST_SPELL
RegisterItemEvent(208800, 2, OnItemUse)  -- ITEM_EVENT_ON_USE
RegisterItemEvent(39163, 2, OnItemUse)  -- ITEM_EVENT_ON_USE
RegisterItemEvent(28326, 2, OnItemUse)  -- ITEM_EVENT_ON_USE
RegisterItemEvent(20739, 2, OnItemUse)  -- ITEM_EVENT_ON_USE
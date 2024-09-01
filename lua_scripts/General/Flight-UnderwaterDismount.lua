local BUFFIDS = {
    3363, 8153, 25675, 25858, 28828, 32235, 32239, 32240,
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

local playersToCheck = {}
local buffToCheck = {}
local flightcheckeventid

local function IsBuffId(spellId)
    for _, id in ipairs(BUFFIDS) do
        if id == spellId then
            return true
        end
    end
    return false
end

local function CheckUnderwater(eventId, delay, repeats)
	local checkcount = 0
	
    for playerName, _ in pairs(playersToCheck) do
		local player = GetPlayerByName(playerName)
		buffId = buffToCheck[playerName]
		
		if not player or (player and not player:HasAura(buffId)) then
			playersToCheck[playerName] = nil
			buffToCheck[playerName] = nil
		else
			checkcount = checkcount + 1
			
			if player:IsUnderWater() then
				if player:HasAura(buffId) then
					player:RemoveAura(buffId)
					
					playersToCheck[playerName] = nil
					buffToCheck[playerName] = nil
					
					print("[Flight]: Removed flight " .. buffId .. " from player " .. player:GetName().." as they were underwater.")
				end
			end
			
		end
	end
	
	if checkcount == 0 then
		RemoveEventById(eventId)
		flightcheckeventid = nil
	end
end

local function StartCheckingPlayer(player, buffId)
    local playerName = player:GetName()
    if not playersToCheck[playerName] then
        playersToCheck[playerName] = true
		buffToCheck[playerName] = buffId
		if not flightcheckeventid then
			flightcheckeventid = CreateLuaEvent(CheckUnderwater, 1500, 0)
		end
    end
end

local function OnSpellCast(event, player, spell, skipCheck)
    local buffId = spell:GetEntry()
    if IsBuffId(buffId) then
        StartCheckingPlayer(player, buffId)
    end
end

local function OnLogin(event, player)
    for _, buffId in ipairs(BUFFIDS) do
        if player:HasAura(buffId) then
            StartCheckingPlayer(player, buffId)
        end
    end
end

local function OnItemUse(event, player, item, targets)
    local itemId = item:GetEntry()
	local playerName = player:GetName()
	if not playersToCheck[playerName] then
		if player:HasSpell(34091) or player:HasSpell(34093) then
			if player:HasAura(40120) then
				StartCheckingPlayer(player, 40120)
			end
		elseif player:HasSpell(34090) or player:HasSpell(34092) then
			if player:HasAura(33943) then
				StartCheckingPlayer(player, 33943)
			end
		end
	end
end

RegisterPlayerEvent(3, OnLogin)  -- PLAYER_EVENT_ON_LOGIN
RegisterPlayerEvent(5, OnSpellCast)  -- PLAYER_EVENT_ON_CAST_SPELL
RegisterItemEvent(208800, 2, OnItemUse)  -- ITEM_EVENT_ON_USE
RegisterItemEvent(39163, 2, OnItemUse)  -- ITEM_EVENT_ON_USE
RegisterItemEvent(28326, 2, OnItemUse)  -- ITEM_EVENT_ON_USE
RegisterItemEvent(20739, 2, OnItemUse)  -- ITEM_EVENT_ON_USE
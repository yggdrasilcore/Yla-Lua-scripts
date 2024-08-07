local DALARAN_ZONE_ID = 4395
local BOREAN_ANIMAL_BLOOD = 46221
local MIN_Z_COORDINATE = 640
local CHECK_INTERVAL = 200 -- ms
local playersWithEvents2 = {}


local function CheckPlayerInWater(eventId, delay, repeats, playerGuid)
    local player = GetPlayerByGUID(playerGuid)
	--print("checkycheckceck")
    if player then
        if not player:HasAura(BOREAN_ANIMAL_BLOOD) then
            player:RemoveEventById(eventId)
			if not playersWithEvents2[playerGuid] == nil then
				playersWithEvents2[playerGuid] = nil
			end
            --print("Player no longer has the aura, event removed!")
            return
        end

        if player:IsInWater() then
            --print("Player is in water!")
            player:CastSpell(player, SPELL_TO_CAST, true)
            player:RemoveAura(BOREAN_ANIMAL_BLOOD)
            player:RemoveEventById(eventId)
			if not playersWithEvents2[playerGuid] == nil then
				playersWithEvents2[playerGuid] = nil
			end
            print("[Spell]: Borean Tundra animal blood - Water pool spawned!")
        end
    else
        -- If the player object can't be found, remove the event
        --print("Player not found, event removed!")
    end
end

function RemoveShapeshiftImmunity(eventId, delay, repeats, player)
    if not player:IsCasting() then
        player:RemoveAura(28237)
		print("[Spell]: Manabonk immunity - Player "..player:GetName().." is no longer immune to shapeshift!")
    end
end

local function OnSpellCast(event, player, spell, skipCheck)
	if not player:HasAura(46221) then
		--print("Spell cast detected!")
		if player:GetZoneId() == DALARAN_ZONE_ID and player:GetZ() >= MIN_Z_COORDINATE and player:HasAura(28237) and not player:HasAura(46221) then
			player:RegisterEvent(RemoveShapeshiftImmunity, 500, 1)
			print("[Spell]: Manabonk immunity - Registering immunity removal for "..player:GetName().."!")
		end
	elseif player:HasAura(46221) and player:GetZoneId() == DALARAN_ZONE_ID then 
			local playerGuid = player:GetGUIDLow()
            local eventId = player:RegisterEvent(function(eventId, delay, repeats)
                CheckPlayerInWater(eventId, delay, repeats, playerGuid)
            end, 1000, CHECK_DURATION)
            playersWithEvents2[player] = eventId
	end
end

local function OnLoginAndZoneChange(event, player)
    local function CheckPlayerStatus(eventId, delay, repeats, player)
        if player:GetZoneId() == DALARAN_ZONE_ID and player:GetZ() >= MIN_Z_COORDINATE and player:IsCasting() and not player:HasAura(28237) and not player:HasAura(46221) then
            player:AddAura(28237, player)
			print("[Spell]: Manabonk immunity - Player "..player:GetName().." was detected casting and is now immune to shapeshift!")
        end
    end
    player:RegisterEvent(CheckPlayerStatus, CHECK_INTERVAL, 0)
end


RegisterPlayerEvent(3, OnLoginAndZoneChange)
RegisterPlayerEvent(5, OnSpellCast)
RegisterPlayerEvent(27, OnLoginAndZoneChange)
print("[Spell]: Dalaran Manabonk Immunity when casting loaded")

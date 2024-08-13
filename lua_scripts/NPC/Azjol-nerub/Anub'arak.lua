local CREATURE_ID = 29120
local CHECK_INTERVAL = 200 -- 200 ms
local RANGE = 50 -- 50 yards
local AURA_ID = 29230
local AURA_DURATION = 45 -- 30 seconds

local playerTimers = {}
local creatureHPThresholds = {75, 50, 25}
local creatureHPFlags = {}

local function CheckCreatureHP(eventId, delay, repeats, player)
    if not player:IsInWorld() or player:GetMapId() ~= 601 then 
        player:RemoveEvents()
        playerTimers[player:GetGUID()] = nil
		print("[Instance]: Azjol-Nerub: Removing player event for Anub'arak!")
        return 
    end

    local creature = player:GetNearestCreature(RANGE, CREATURE_ID)
    if not creature then return end
	
    local guid = creature:GetGUIDLow()
    local hpPct = creature:GetHealthPct()

    for _, threshold in ipairs(creatureHPThresholds) do
        if hpPct <= threshold and not creatureHPFlags[guid .. threshold] then
            player:AddAura(AURA_ID, creature)
            creatureHPFlags[guid .. threshold] = true

            -- Schedule aura removal
            creature:RegisterEvent(function(eventId, delay, repeats, creature)
                creature:RemoveAura(AURA_ID)
				print("[Instance]: Azjol-Nerub: Aura removed!")
            end, AURA_DURATION * 1000, 1)

            --player:SendAreaTriggerMessage(string.format("Creature HP at or below %d%%. Aura applied.", threshold))
            print(string.format("[Instance]: Azjol-Nerub: Creature HP at or below %d%%. Aura applied.", threshold))
        end
    end
end

local function OnEnterArea(event, player, oldArea, newArea)
    local playerGuid = player:GetGUID()
	if newArea == 4405 then
		--print("[Instance]: Azjol-Nerub: Player changed location! New zone ID: "..player:GetZoneId())
		if not playerTimers[playerGuid] then
			playerTimers[playerGuid] = true
			player:RegisterEvent(CheckCreatureHP, CHECK_INTERVAL, 0)
			--print("[Instance]: Azjol-Nerub: Entered target area. Starting creature HP check.")
		end
	end
end

RegisterPlayerEvent(47, OnEnterArea) -- PLAYER_EVENT_ON_AREA_TRIGGER
print("[Instance]: Azjol-Nerub: Anub'Arak instance fix loaded!")

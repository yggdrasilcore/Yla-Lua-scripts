-- Multistate: map-only script (all hooks fire in map states).
if GetStateMapId() == -1 then return end

local AREA_CARRION_WASTES = 4188 -- Area to trigger script in
local PLAYER_BUFF_ID = 49078 -- Tank buff
local CHECK_INTERVAL = 14.7 -- Frequency to check for temporary gameobject, this triggers spawn of kill credit creature
local SPAWN_NPC_ID = 27625 -- Kill credit NPC re quest_template entry for Quest ID 12326
local CAST_SPELL_ID = 19901 -- High dmg ability
local OBJECT_ID = 189970 -- Temp gobject spawn by gnome engineers, last for about 15 seconds. Re check_interval
local invisibleDisplayID = 15435  -- Invisible NPC model
local CarrionWastesEvent = {}
-- local query = string.format("UPDATE creature_template_model SET CreatureDisplayID = %d WHERE CreatureID = %d", invisibleDisplayID, SPAWN_NPC_ID)

-- Make kill credit NPC invisible on server startup. Commented out as already in DB
-- WorldDBExecute(query)

local function SpawnAndCastOnNPC(player)
    local x, y, z, o = player:GetLocation()
    local spawnedNPC = player:SpawnCreature(SPAWN_NPC_ID, x, y, z, o, 1, 3) -- 3 ms despawn timer if cast doesn't kill NPC, to prevent invisible NPC from chasing players
	--print("Spawning kill credit NPC...")
    if spawnedNPC then
        player:CastSpell(spawnedNPC, CAST_SPELL_ID, true)
		--print("Sabotage credit awarded!")
	--else
	--print("ERROR Quest ID 12326 - Spawn credit NPC didn't spawn correctly!")
    end
end

local function ScheduleSpawnAndCastOnNPC(player, objectGUID)
    player:RegisterEvent(function(eventId, delay, repeats, p)
        SpawnAndCastOnNPC(p, objectGUID) -- Slight delay, I initially introduced this for a failsafe if player uses gnome engineer twice in 15 seconds (spell has 10-sec CD) but it doesn't really do anything now
    end, 100, 1)  
end

local function CheckNearbyObject(player)
    local nearbyObject = player:GetNearestGameObject(25, OBJECT_ID)
    if nearbyObject then
		--print("Quest ID 12326 - Temporary game object for sabotage detected.")
        local objectGUID = nearbyObject:GetGUID()
        local currentTime = os.time()
        ScheduleSpawnAndCastOnNPC(player, objectGUID) -- If gnome engineer object present, schedule spawn invisible kill credit NPC and kill it
    end
end

local function CheckPlayerBuff(eventId, delay, repeats, player)
    if player:HasAura(PLAYER_BUFF_ID) then
		--print("Quest ID 12326 - Tank buff detected.")
        CheckNearbyObject(player) -- If tank buff active, proceed to check for temporary gameobject from gnome engineers
    end
end

local function OnUpdateArea(event, player, oldArea, newArea)
    if newArea == AREA_CARRION_WASTES then
        --print("Quest ID 12326 - Player in Carrion Wastes detected. Starting event tracker for tank buff and sabotage credit event.")
		if CarrionWastesEvent[player:GetName()] then
			player:RemoveEventById(CarrionWastesEvent[player:GetName()]) -- If player leaves area, stop event
			CarrionWastesEvent[player:GetName()] = nil
		end
		
        CarrionWastesEvent[player:GetName()] = player:RegisterEvent(CheckPlayerBuff, CHECK_INTERVAL * 1000, 60) -- This triggers event 2, check for tank buff. Time-limited to 15 min (tank buff duration)
    elseif oldArea == AREA_CARRION_WASTES then
        player:RemoveEventById(CarrionWastesEvent[player:GetName()]) -- If player leaves area, stop event
		CarrionWastesEvent[player:GetName()] = nil
    end
end

RegisterPlayerEvent(47, OnUpdateArea)
--print("[Quest 12326 Fix]: Kill Credit on tank buff in carrion wastes loaded.")

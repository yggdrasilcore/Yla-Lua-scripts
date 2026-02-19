local lastPlayerHeartbeat = {}
local ULDUAR_MAP_ID = 603
local FREYA_AREA_ID = 4656
local FREYA_NPC_ID = 32906
local RESPAWN_COOLDOWN = 1800
local CHECK_FREYA = 1
local HERB_ENTRIES = {
    191019,
    190176,
    189973,
    190172,
    190171,
    190170,
    190169,
}

local function RespawnHerbs(player)
    for _, entry in ipairs(HERB_ENTRIES) do
        local objects = player:GetGameObjectsInRange(500, entry)
        for _, go in ipairs(objects) do
            go:Respawn()
        end
    end
end

local function OnHeartbeat(eventid, delay, repeats, player)
    if player:GetMapId() ~= ULDUAR_MAP_ID then
        player:RemoveEventById(eventid)
        return
    end

    local instanceId = player:GetInstanceId()
    local heartbeat = lastPlayerHeartbeat[instanceId]

    if heartbeat and (os.time() - heartbeat[2]) >= RESPAWN_COOLDOWN then
        if player:GetAreaId() == FREYA_AREA_ID then
            if CHECK_FREYA == 0 or player:GetNearestCreature(1000, FREYA_NPC_ID, 1) then
                RespawnHerbs(player)
            end
        end
    end

    lastPlayerHeartbeat[instanceId] = {instanceId, os.time()}
end

local function OnMapChange(event, player)
    if player:GetMapId() == ULDUAR_MAP_ID then
        player:RegisterEvent(OnHeartbeat, 60 * 1000, 0)
    end
end

RegisterPlayerEvent(28, OnMapChange)

local players = GetPlayersInWorld()
for _, player in ipairs(players) do
    if player:GetMapId() == ULDUAR_MAP_ID then
        player:RegisterEvent(OnHeartbeat, 60 * 1000, 0)
    end
end
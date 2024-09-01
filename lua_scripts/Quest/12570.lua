local AREA_ID = 4291
local QUEST_ID = 12570
local NPC_ID = 28217
local X, Y, Z = 5626, 4610, -137
local RANGE = 20
local CHECK_INTERVAL = 3000
local playerList = {}
local eventId = nil

local function CheckAndCompleteQuest()
    for playerName, _ in pairs(playerList) do
        local player = GetPlayerByName(playerName)
        if player and player:GetAreaId() ~= AREA_ID then
            playerList[playerName] = nil
        elseif player and player:IsWithinDist3d(X, Y, Z, RANGE) then
            local npc = player:GetNearestCreature(100, NPC_ID)
            if npc and npc:GetAreaId() == AREA_ID then
                if player:HasQuest(QUEST_ID) then
                    player:CompleteQuest(QUEST_ID)
                end
            end
        else
            playerList[playerName] = nil
        end
    end
    
    local playerCount = 0
    for _ in pairs(playerList) do
        playerCount = playerCount + 1
    end
    
    if playerCount == 0 then
        RemoveEventById(eventId)
        eventId = nil
    else
        eventId = CreateLuaEvent(CheckAndCompleteQuest, CHECK_INTERVAL, 1)
    end
end

local function OnAreaChange(event, player, oldArea, newArea)
    if newArea == AREA_ID then
        playerList[player:GetName()] = true
        if not eventId then
            eventId = CreateLuaEvent(CheckAndCompleteQuest, CHECK_INTERVAL, 1)
        end
    end
end

RegisterPlayerEvent(47, OnAreaChange)
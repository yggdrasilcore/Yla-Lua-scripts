-- Multistate: map-only script (all hooks fire in map states).
if not IsCompatibilityMode() and GetStateMapId() == -1 then return end

local AURA_ID = 42786
local QUEST_ID = 11343
local MAP_ID = 571
local AREA_ID = 3982
local AREA_X = 1071
local AREA_Y = -5032
local AREA_Z = 10
local CHECK_INTERVAL = 60 -- Check every 60 seconds
local AREA_RADIUS = 5 -- Radius around the area to check

local checkPlayers = {}
local eventId = nil

local function CheckPlayersForQuestCompletion()
    local playerCount = 0
    
    for playerName, _ in pairs(checkPlayers) do
        local player = require("Multistate").FindPlayerByName(playerName)
        if player and player:GetAreaId() == AREA_ID then
            playerCount = playerCount + 1
            if player:HasAura(AURA_ID) then
                local playerMapId = player:GetMapId()
                local distance = player:GetDistance(AREA_X, AREA_Y, AREA_Z)
                
                if playerMapId == MAP_ID and distance <= AREA_RADIUS then
                    if player:HasQuest(QUEST_ID) then
                        player:CompleteQuest(QUEST_ID)
                        player:SendAreaTriggerMessage("Secrets of Wyrmskull Uncovered (Complete)")
                    end
                end
            end
        else
            checkPlayers[playerName] = nil
        end
    end
    
    if playerCount == 0 then
        RemoveEventById(eventId)
        eventId = nil
    end
end

local function OnUpdateArea(event, player, oldArea, newArea)
    if newArea == AREA_ID then
        checkPlayers[player:GetName()] = true
        if not eventId then
            eventId = CreateLuaEvent(CheckPlayersForQuestCompletion, CHECK_INTERVAL * 1000, 0)
			print("Event ID "..eventId.." launched for "..player:GetName().."!")
        end
    end
end

RegisterPlayerEvent(47, OnUpdateArea)
local AREA_ID = 4291
local QUEST_ID = 12570
local NPC_ID = 28217
local X, Y, Z = 5626, 4610, -137
local RANGE = 20
local CHECK_INTERVAL = 3000 -- 2 seconds in milliseconds

local playerTimers = {}

local function CheckAndCompleteQuest()
    local map = GetMapById(571)  -- Northrend map ID
    if not map then return end

    local players = map:GetPlayers()
    for _, player in pairs(players) do
        if player:GetAreaId() == AREA_ID and player:IsWithinDist3d(X, Y, Z, RANGE) then
            local npc = player:GetNearestCreature(100, NPC_ID)
            if npc and npc:GetAreaId() == AREA_ID then
                if player:HasQuest(QUEST_ID) then
                    player:CompleteQuest(QUEST_ID)
                end
            end
        end
    end
    
    -- Schedule the next check
    CreateLuaEvent(CheckAndCompleteQuest, CHECK_INTERVAL, 1)
end

local function OnAreaChange(event, player, oldArea, newArea)
    if newArea == AREA_ID then
        -- Player entered the area, start the periodic check
        CreateLuaEvent(CheckAndCompleteQuest, CHECK_INTERVAL, 1)
		print("[FixQuest12570 Debug] Player entered Rainspeaker Canopy!")
	elseif oldArea == AREA_ID then
		print("[FixQuest12570 Debug] Player left Rainspeaker Canopy!")
    end
end

RegisterPlayerEvent(47, OnAreaChange)
print("[FixQuest12570 Debug] Completion check in Rainspeaker Canopy loaded.")
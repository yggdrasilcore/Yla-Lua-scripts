local AREA_ID = 4859
local CHECK_INTERVAL = 1 -- seconds
local Z_THRESHOLD = 840
local NPC_TELEPORT_Z = 840.8
local PLAYER_TELEPORT_Z = 834
local PLAYER_LOW_Z_THRESHOLD = 640
local PLAYER_LOW_Z_TELEPORT = 660
local SEARCH_RANGE = 8 -- yards
local LOW_Z_CHECK_INTERVAL = 15 -- seconds
local combatOnThrone = false
local nothingHappening = true
local IGNORED_NPC_PATTERNS = {
    "World Trigger",
    "Highlord Tirion Fordring",
    "Lich King"
}

local function ShouldIgnoreNPC(name)
    for _, pattern in ipairs(IGNORED_NPC_PATTERNS) do
        if name:find(pattern) then
            return true
        end
    end
    return false
end

local function CheckLowZPlayers(eventid, delay, repeats, player)
	if player:GetAreaId() == AREA_ID then
		local playerZ = player:GetZ()
		if playerZ < PLAYER_LOW_Z_THRESHOLD then
			print("ICC, Lich King - Player found below Z 700. Teleporting to Z 640 and stopping movement...")
			player:Teleport(player:GetMapId(), player:GetX(), player:GetY(), PLAYER_LOW_Z_TELEPORT, player:GetO())
			player:MoveStop()
		end
	end
end

local function CheckPlayersInArea(eventid, delay, repeats, player)
    local playersInArea = false
	if player:GetAreaId() == AREA_ID then
		playersInArea = true
		local playerZ = player:GetZ()
		
		if playerZ >= 835 and playerZ <= 836 then
			print("ICC, Lich King - Player found between Z 835 and 836. Teleporting to Z 834...")
			if player:IsAlive() then
				player:Teleport(player:GetMapId(), player:GetX(), player:GetY(), PLAYER_TELEPORT_Z, player:GetO())
			end
			if not player:IsAlive() then
				player:MoveTo(1, player:GetX(), player:GetY(), 640)
			end
		end
		
		if player:IsInCombat() and not combatOnThrone then
			nothingHappening = false
			--print("Combat on Frozen Throne detected! Checking for all NPCs...")
			combatOnThrone = true
		elseif player:IsInCombat() and combatOnThrone then
			local creatures = player:GetCreaturesInRange(SEARCH_RANGE)
			for _, creature in ipairs(creatures) do
				local name = creature:GetName()
				if not ShouldIgnoreNPC(name) then
					--print("NPC found: " .. name)
					local x, y, z, o = creature:GetX(), creature:GetY(), creature:GetZ(), creature:GetO()
					if z < Z_THRESHOLD then
						print("ICC, Lich King - NPC has fallen! Teleporting up: " .. name)
						creature:NearTeleport(x, y, NPC_TELEPORT_Z, o)
					end
				end
			end
		elseif nothingHappening == false then
			combatOnThrone = false
			print("Nothing happening on Frozen Throne yet.")
			nothingHappening = true
		end
	end
    
    if not playersInArea then
        print("ICC, Lich King - No players in Frozen Throne. Stopping the recurring events.")
		player:RemoveEvents()
    end
end

local eventIdMap = {}

local function OnEnterArea(event, player, newZone, newArea)
    if newArea == AREA_ID then
        local checkPlayersEventId = player:RegisterEvent(CheckPlayersInArea, CHECK_INTERVAL * 1000, 0)
        local checkLowZEventId = player:RegisterEvent(CheckLowZPlayers, LOW_Z_CHECK_INTERVAL * 1000, 0)
        eventIdMap[player:GetGUID()] = {checkPlayersEventId, checkLowZEventId}
        nothingHappening = false
        --print("Player entered the Frozen Throne! Starting periodical checks...")
    end
end

local function OnLeaveArea(event, player, oldZone, oldArea)
    if oldArea == AREA_ID then
        local eventIds = eventIdMap[player:GetGUID()]
        if eventIds then
            player:RemoveEventById(eventIds[1])
            player:RemoveEventById(eventIds[2])
            eventIdMap[player:GetGUID()] = nil
            --print("Player left the Frozen Throne. Stopping periodical checks for this player.")
        end
    end
end

RegisterPlayerEvent(27, OnEnterArea)
RegisterPlayerEvent(28, OnLeaveArea)

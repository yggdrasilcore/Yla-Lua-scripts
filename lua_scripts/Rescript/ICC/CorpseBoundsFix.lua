local eventIdMap = {}

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

local function AreaChange(event, player, oldArea, newArea)

    if newArea == 4859 then
        local checkLowZEventId = player:RegisterEvent(CheckLowZPlayers, LOW_Z_CHECK_INTERVAL * 5000, 0)
        eventIdMap[player:GetGUID()] = {checkPlayersEventId, checkLowZEventId}
        print("Player entered the Frozen Throne! Starting periodical checks...")
    end
	
    if oldArea == 4859 then
        local eventIds = eventIdMap[player:GetGUID()]
        if eventIds then
            player:RemoveEventById(eventIds[1])
            eventIdMap[player:GetGUID()] = nil
            print("Player left the Frozen Throne. Stopping periodical checks for this player.")
        end
    end

end

RegisterPlayerEvent(47, AreaChange)

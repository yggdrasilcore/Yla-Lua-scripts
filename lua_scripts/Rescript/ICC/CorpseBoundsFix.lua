local CorpseBoundsEvent = {}

local function CheckLowZPlayers(eventid, delay, repeats, player)
	if player then
        if player:GetAreaId() == 4859 then
            local playerZ = player:GetZ()
            if playerZ < 700 then
                print("ICC, Lich King - Player found below Z 700. Teleporting to Z 640 and stopping movement...")
                player:Teleport(player:GetMapId(), player:GetX(), player:GetY(), 640, player:GetO())
                player:RemoveEventById(eventid)
            end
        else
            player:RemoveEventById(eventid)
            CorpseBoundsEvent[player:GetGUIDLow()] = nil
        end
	else
        player:RemoveEventById(eventid)
        CorpseBoundsEvent[player:GetGUIDLow()] = nil
    end
end

local function AreaChange(event, player, oldArea, newArea)
    if newArea == 4859 then
        if not CorpseBoundsEvent[player:GetGUIDLow()] then
            CorpseBoundsEvent[player:GetGUIDLow()] = true
            player:RegisterEvent(CheckLowZPlayers, 2500, 0)
            print("Player entered the Frozen Throne! Starting periodical Z level checks...")
        end
    end
end

RegisterPlayerEvent(47, AreaChange)

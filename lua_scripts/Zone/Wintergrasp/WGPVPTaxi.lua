local function OnLeaveArea(event, player, oldArea, newArea)
    if oldArea == 4584
	or (oldArea == 4197 and newArea == 3711)
	or (oldArea == 4197 and newArea == 210)
	or (oldArea == 4197 and newArea == 65)
	or (oldArea == 4197 and newArea == 4163)
	or (oldArea == 4197 and newArea == 4034)
	or (oldArea == 4197 and newArea == 4125)
	or (oldArea == 4197 and newArea == 4034)
	or (oldArea == 4197 and newArea == 4124)
	or (oldArea == 4575 and newArea == 210)
	or (oldArea == 4585 and newArea == 210)
	or (oldArea == 4585 and newArea == 4172)
	then
		if player:IsPvPFlagged() then
			player:SaveToDB()
			player:RegisterEvent(function(eventId, delay, repeats, player)
				local query = CharDBQuery(string.format("SELECT taxi_path FROM characters WHERE guid = %d", player:GetGUIDLow()))
				if query then
					local taxiPath = query:GetString(0)
					if taxiPath and taxiPath ~= "" then
						player:SetPvP(false)
					end
				end
				player:RemoveEvents()
			end, 1000, 1)  -- 1000 milliseconds = 1 second
		end
	end
end

RegisterPlayerEvent(47, OnLeaveArea)  -- 28 is the event for PLAYER_EVENT_ON_LEAVE_AREA
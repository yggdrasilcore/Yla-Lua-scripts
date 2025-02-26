local function antiGMIslandCheat(event, player, newZone, newArea)
    if newZone == 876 and player:GetGMRank() == 0 then
		player:Teleport(13, 0, 0, 0, 0)
		player:SendAreaTriggerMessage("You have been detected in an area you're not supposed to be in!")
		local GMs = GetPlayersInWorld()
		for _, GM in pairs(GMs) do
			if player:GetGMRank() > 0 then
				GM:SendAreaTriggerMessage("[Anticheat] Player "..player:GetName().." has been detected on GM island with too low GM rank!")
			end
		end
    end
end

RegisterPlayerEvent(27, antiGMIslandCheat)
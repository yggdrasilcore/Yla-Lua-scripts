function OnEnterHOR(event, player, map)
	local LK = player:GetNearestCreature(2000, 36594, true)
	
	if LK then
		local group = player:GetGroup()
		
		if group then
			group:SetTargetIcon(2, LK:GetGUID(), player:GetGUID())
		end
	end
end

RegisterMapEvent(668, 2, OnEnterHOR)
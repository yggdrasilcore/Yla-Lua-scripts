local function OnMapChange(event, player)
	if not player then return end
	if not (player:GetInstanceId() > 0) then return end
	player:AddAura(43775, player)
	
	player:RegisterEvent(function(e, d, r, player)
		player:RemoveAura(43775)
	end, 200, 5)
end

RegisterPlayerEvent(28, OnMapChange)
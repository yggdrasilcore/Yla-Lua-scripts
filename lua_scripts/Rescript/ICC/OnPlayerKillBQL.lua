local function OnPlayerKillBQL(event, player, killed)
	if killed:GetEntry() == 37955 then
		
		if killed:GetZ() > 403 then killed:MoveTo(0, killed:GetX(), killed:GetY(), 400.14) end -- Prevent flying death
		
		local group = player:GetGroup()
		if group then
			local members = group:GetMembers()
			for _, member in pairs(members) do -- Clear residual vampire bite state
				if member:HasAura(70877) then member:RemoveAura(70877) end
				if member:HasAura(72151) then member:RemoveAura(72151) end
				if member:HasAura(72649) then member:RemoveAura(72649) end
			end
		end
	end
end

RegisterPlayerEvent(7, OnPlayerKillBQL)
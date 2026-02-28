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
				if member:HasAura(71949) then member:RemoveAura(71949) end
				if member:HasAura(70867) then member:RemoveAura(70867) end
				if member:HasAura(70879) then member:RemoveAura(70879) end
				if member:HasAura(70923) then member:RemoveAura(70923) end
			end
		end

        -- Fix buggy minchar quest completion
		local minchar = killed:GetNearestCreature(200, 38558, 0, 1)
		if not minchar then return end
        
        local difficulty = player:GetDifficulty()
        local questId = 24874 -- 10-man quest
        
        if difficulty == 1 or difficulty == 3 then
            questId = 24879 -- 25-man quest
        end
        
        if group then
            local members = group:GetMembers()
            for _, member in pairs(members) do
                if member:HasQuest(questId) then
                    member:CompleteQuest(questId)
                end
            end
        end
    end
end

RegisterPlayerEvent(7, OnPlayerKillBQL)
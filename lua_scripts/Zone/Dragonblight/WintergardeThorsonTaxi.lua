local playersToMove = {}
local function OnGossipHello(event, player, creature)
    if creature:GetEntry() == 27317 and player:HasQuest(12325) then
		if player:HasAura(71561) or player:HasAura(71484) -- Various shapeshifts, can't mount bird with these on
		or player:HasAura(71560) or player:HasAura(71556)
		or player:HasAura(71485) or player:HasAura(71492)
		or player:HasAura(2645) or player:HasAura(3025)
		or player:HasAura(9634) or player:HasAura(783)
		or player:HasAura(40120) or player:HasAura(33943)
		or player:HasAura(33891) or player:HasAura(24858)
		or player:HasAura(6405) or player:HasAura(16591)
		or player:HasAura(73320) or player:HasAura(59672)
		or player:HasAura(71487) or player:HasAura(71491)
		or player:HasAura(71486) or player:HasAura(71558)
		or player:HasAura(71557) or player:HasAura(71559)
		then player:SendAreaTriggerMessage("|cFFFF0000You are in shapeshift form.|r") return end
 
		if player:IsMounted() then player:Dismount() end
		
		local mount = player:SpawnCreature(27661, player:GetX(), player:GetY(), player:GetZ(), player:GetO(), 1, 40000)
		
		player:CastSpell(mount, 46598)
		
		mount:SetHover(false)
		mount:SetDisableGravity(true)
		mount:SetSpeed(0, 3)
		mount:SetSpeed(1, 3)
		mount:SetSpeed(6, 3)
        mount:MoveTo(1, 3607, -870, 238)
		
        local oldRider = player:GetNearestCreature(3, 27662)
		oldRider:SendUnitSay("Hang on to your hat, pal! We're in for a bumpy ride.",0)
        
        local moveTime = os.time() + 6
        playersToMove[player:GetName()] = moveTime
        
		--print("Player inserted into movement table: "..playersToMove[player:GetName()])
        
        -- Schedule the movement event
        CreateLuaEvent(function()
			for name, scheduledTime in pairs(playersToMove) do
				local player = GetPlayerByName(name)
				if player and os.time() >= scheduledTime then
                    local mount = player:GetNearestCreature(3, 27661)
					mount:SetHover(false)
					mount:SetDisableGravity(true)
					mount:SetSpeed(0, 4)
					mount:SetSpeed(1, 4)
					mount:SetSpeed(6, 4)
					mount:MoveTo(1, 3890, -1431, 170)
					--print("Moving player")
					playersToMove[name] = nil
				--else
					--print("player not ready or not found")
				end
			end
        end, 6200, 1)
    end
end

local function OnEnterArea(event, player, newZone, newArea)
	if newArea == 4177 or newArea == 4188 then
		local accidentalRider = player:GetNearestCreature(500, 27662)
		if accidentalRider and not accidentalRider:HasAura(48365) then
			accidentalRider:DespawnOrUnsummon()
		end
	end
    if newArea == 4190 then
		mount = player:GetNearestCreature(100, 27661)
		if mount and mount:GetAreaId() == 4190 then
			player:Dismount()
			player:AddAura(66657, player)
			local oldRider = player:GetNearestCreature(15, 27662)
			oldRider:SendUnitSay("This is your stop, pal. Safe landing!",0)
			--oldRider:AddAura(44312, oldRider)
			CreateLuaEvent(function()
				--print("Attempting to despawn mount and rider...")
				local players = GetPlayersInWorld()
					for _, player in pairs(players) do
					if player:GetAreaId() == 4190 then
						--print("Player on Thorson's farm found!")
						local oldRider = player:GetNearestCreature(300, 27662)
						local mount = player:GetNearestCreature(300, 27661)
						if mount:GetAreaId() == 4190 and oldRider:GetAreaId() == 4190 then
							--print("Mount and rider in correct area, despawning!")
							oldRider:DespawnOrUnsummon()
							mount:DespawnOrUnsummon()
						end
					end
				end
			end, 2500, 1)
		end
    end
end

RegisterCreatureGossipEvent(27317, 1, OnGossipHello)
RegisterPlayerEvent(27, OnEnterArea)

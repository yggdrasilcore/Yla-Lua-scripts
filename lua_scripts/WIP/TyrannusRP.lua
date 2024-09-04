local ALLIANCE_SLAVE_IDS = {37572, 37575, 37576}
local HORDE_SLAVE_IDS = {37579, 37578, 37577}
local spawnedSlaves = {}
local oldSlaves1 = {}
local oldSlaves2 = {}
local oldSlaves3 = {}
local oldSlaves4 = {}
local oldSlaves5 = {}
local oldSlaves6 = {}
local TyrannusRP = {}
local TyrannusSlaves = {}

--WorldDBExecute(string.format("UPDATE creature_template SET unit_flags = %d WHERE entry = %d;", 576, 36658))


local function TyrannusLeaveCombat(event, player)
	if player:GetMapId() == 658 then
        local slaveGroups = {
            player:GetCreaturesInRange(150, 37572),
            player:GetCreaturesInRange(150, 37575),
            player:GetCreaturesInRange(150, 37576),
            player:GetCreaturesInRange(150, 37579),
            player:GetCreaturesInRange(150, 37578),
            player:GetCreaturesInRange(150, 37577)
        }
		
		if TyrannusRP[player:GetInstanceId()] then
			TyrannusRP[player:GetInstanceId()] = nil
		end
		
		if TyrannusSlaves[player:GetInstanceId()] then
			TyrannusSlaves[player:GetInstanceId()] = nil
		end
		
		--player:RemoveEvents()
		
        for _, group in ipairs(slaveGroups) do
            for _, slave in ipairs(group) do
				if slave:GetFaction() == 1770 then
					slave:DespawnOrUnsummon()
				else
					slave:DeMorph()
				end
            end
        end

	end
end

local function AttackFallenWarriors(eventid, delay, repeats, creature)
	local slaveGroups = {
		creature:GetCreaturesInRange(500, 37572),
		creature:GetCreaturesInRange(500, 37575),
		creature:GetCreaturesInRange(500, 37576),
		creature:GetCreaturesInRange(500, 37579),
		creature:GetCreaturesInRange(500, 37578),
		creature:GetCreaturesInRange(500, 37577)
	}
	
	for _, group in ipairs(slaveGroups) do
		for _, slave in ipairs(group) do
			if slave:GetFaction() == 1770 then
				slave:EmoteState(333)
				slave:SetSheath(1)
			end
		end
	end
		
    FallenWarrior = creature:GetNearestCreature(100, 36841)
	if FallenWarrior then
		creature:AttackStart(FallenWarrior)
	else
		creature:MoveHome()
	end
end

local function TyrannusRoleplayArea(event, player, oldArea, newArea)
	if oldArea == 4905 then
		local Tyrannus = player:GetNearestCreature(200, 36658, 0, 1)
		
		if not Tyrannus or (Tyrannus and not Tyrannus:IsInCombat()) then
	
			local slaveGroups = {
				player:GetCreaturesInRange(500, 37572),
				player:GetCreaturesInRange(500, 37575),
				player:GetCreaturesInRange(500, 37576),
				player:GetCreaturesInRange(500, 37579),
				player:GetCreaturesInRange(500, 37578),
				player:GetCreaturesInRange(500, 37577)
			}
			
			if TyrannusRP[player:GetInstanceId()] then
				TyrannusRP[player:GetInstanceId()] = nil
			end
			
			for _, group in ipairs(slaveGroups) do
				for _, slave in ipairs(group) do
					slave:DespawnOrUnsummon()
					slave:RemoveEvents()
					print("POS area event - Slaves despawned")
				end
			end
			
			player:RemoveEvents()
		end
	end
	
	if newArea == 4905 then
		
		local Tyrannus = player:GetNearestCreature(200, 36658, 0, 1)
		local Rimefang = player:GetNearestCreature(200, 36661)
		
		if Rimefang and not Rimefang:HasAura(46598) and not Tyrannus:IsTargetableForAttack(false) then
			Tyrannus:CastSpell(Rimefang, 46598, true)
		elseif not Rimefang then
			print("POS area event - Rimefang not found!")
		end
		
		if Tyrannus and not Tyrannus:IsDead() and not TyrannusRP[player:GetInstanceId()] then
			
			local SlaveRPTime
		
			player:RegisterEvent(function(eventId, delay, repeats, player)
				if TyrannusRP[player:GetInstanceId()] then player:RemoveEventById(eventId) print("POS area event - Active event found, terminating duplicate event") return end
				
				print("POS area event - Looping Tyrannus RP event for "..player:GetName().."...")
				Tyrannus = player:GetNearestCreature(200, 36658)
				local targetable
				if Tyrannus then
					targetable = Tyrannus:IsTargetableForAttack(false)
				end
				if (Tyrannus and player:IsInCombat()) and not SlaveRPTime then
					SlaveRPTime = os.time() + 37
					print("POS area event - Tyrannus cb start detected, spawning slaves in 37 sec")
				elseif (Tyrannus and player:IsInCombat()) and SlaveRPTime <= os.time() and not TyrannusRP[player:GetInstanceId()] then

					TyrannusRP[player:GetInstanceId()] = true
					local slaveIds = ALLIANCE_SLAVE_IDS

					for _ = 1, 15 do
						print("POS area event - Spawning slaves")
						local minX = math.min(1045, 1040, 1051, 1057)
						local maxX = math.max(1045, 1040, 1051, 1057)
						local minY = math.min(113, 129, 131, 128)
						local maxY = math.max(113, 129, 131, 128)
						local randomX = math.random(minX, maxX)
						local randomY = math.random(minY, maxY)
						local randomSlaveId = slaveIds[math.random(#slaveIds)]
						local slave = player:SpawnCreature(randomSlaveId, randomX, randomY, 628.55, 5.12)
						slave:MoveIdle()
						slave:SetReactState(2)
						slave:SetSheath(0)
						slave:SetFaction(1770) -- Separate faction to identify combat-active slaves later
						slave:RegisterEvent(AttackFallenWarriors, 500, 0)
					end
				elseif not Tyrannus or (Tyrannus and Tyrannus:IsDead()) then
					if Tyrannus and Tyrannus:IsDead() then print("POS area event - Tyrannus dead, removing player event")
					elseif not Tyrannus then print("POS area event - Tyrannus not foud, removing player event")
					else  print("POS area event - No combat, removing player event") end
					player:RemoveEvents()
				end
			end, 1500, 0)
		end
	end
end

local function TrashCombat(event, player, enemy)
	if enemy:GetEntry() == 36877 then
		print("POS tunnel trash combat - wrathbone skeleton cb detected")
		local Tyrannus = player:GetNearestCreature(200, 36658, 0, 1)
		local Rimefang = player:GetNearestCreature(200, 36661)
		
		if Tyrannus and Rimefang and not Rimefang:HasAura(46598) then
			local distance = Tyrannus:GetDistance(Rimefang)
			
			if distance > 5 then
				print("POS tunnel trash combat - tyrannus NOT ok, resetting")
				NewTyrannus = player:SpawnCreature(36658, 1020, 160, 628.1562, 5.08)
				player:RegisterEvent(function(eventId, delay, repeats, player)
					local NewTyrannus = player:GetNearestCreature(200, 36658, 0, 1)
					local Rimefang = player:GetNearestCreature(200, 36661)
					NewTyrannus:CastSpell(Rimefang, 46598, true)
				end, 500, 1)
			else
				print("POS tunnel trash combat - tyrannus OK")
			end
		else
			print("POS tunnel trash combat - couldnt find tyrannus and/or rimefang")
		end
	end
end

RegisterPlayerEvent(33, TrashCombat)
RegisterPlayerEvent(34, TyrannusLeaveCombat)
RegisterPlayerEvent(47, TyrannusRoleplayArea)
print("[Instance]: POS - Tyrannus RP and double spawn fix loaded!")
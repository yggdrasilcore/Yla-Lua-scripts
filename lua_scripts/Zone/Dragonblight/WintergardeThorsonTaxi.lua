
local playersToMove = {}
local verifyMounting = {}
local opcodeCount = {}

local function OnPacket(event, packet, player)
	local opcode = packet:GetOpcode()
	local guid = player:GetGUIDLow()
	--print("Packet is hex: " .. string.format("0x%X", opcode))
    if player:HasQuest(12325) then
		--print("Player has quest OK")
		if player:GetNearestCreature(5, 27661) then
			if not opcodeCount[guid] or (opcodeCount[guid] and opcodeCount[guid] == 0) and player:GetNearestCreature(15, 26878) then
				opcodeCount[guid] = 1
				verifyMounting[player:GetName()] = player:GetName()
				CreateLuaEvent(function()
					--print("Checking for players mounting...")
					for name in pairs(verifyMounting) do
						local player = GetPlayerByName(name)
						if player then
							--print("Player found! Dismounting...")
							player:AddAura(46598, player)
							player:RemoveAura(46598)
							player:Dismount()
							verifyMounting[name] = nil
							local accidentalRider = player:GetNearestCreature(20, 27662)
							if accidentalRider and not accidentalRider:HasAura(48365) then
								accidentalRider:DespawnOrUnsummon()
							end
						end
					end
				end, 1000, 1)
			elseif opcodeCount[guid] then
				opcodeCount[guid] = opcodeCount[guid] + 1
			end
			if opcodeCount[guid] > 2 then
				opcodeCount[guid] = 0
			end
			if opcodeCount[guid] == 2 and player:GetNearestCreature(15, 26878) then
				--print(opcodeCount[guid])
		 
				if player:IsMounted() then player:Dismount() end
				
				local mount = player:SpawnCreature(27661, player:GetX(), player:GetY(), player:GetZ(), player:GetO(), 1, 35000)
				
				player:CastSpell(mount, 46598)
				
				mount:SetHover(false)
				mount:SetDisableGravity(true)
				mount:SetSpeed(0, 3)
				mount:SetSpeed(1, 3)
				mount:SetSpeed(6, 3)
				mount:MoveTo(1, 3558, -820, 263)
								
				local moveTime = os.time() + 6
				playersToMove[player:GetName()] = moveTime
				
				-- Get all creatures with the specified ID within the radius of the player
				local oldMounts = player:GetCreaturesInRange(50, 27661)

				-- Iterate through the list of oldMounts
				for _, oldMount in ipairs(oldMounts) do
					if not oldMount:HasAura(48365) then
						oldMount:SetRespawnDelay(30)
						oldMount:DespawnOrUnsummon()
					end
				end
				
				-- Schedule the movement event
				CreateLuaEvent(function()
					for name in pairs(playersToMove) do
						local player = GetPlayerByName(name)
						local oldRider = player:GetNearestCreature(3, 27662)
						oldRider:SendUnitSay("Hang on to your hat, pal! We're in for a bumpy ride.",0)
					end
				end, 2000, 1)
				
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
	end
	return false
end

local function OnEnterArea(event, player, newZone, newArea)
	if newArea == 4177 or newArea == 4188 then
		local accidentalRider = player:GetNearestCreature(500, 27662)
		local accidentalBird = player:GetNearestCreature(500, 27661)
		if accidentalRider and not accidentalRider:HasAura(48365) then
			accidentalRider:DespawnOrUnsummon()
		end
		if accidentalBird and not accidentalBird:HasAura(48365) then
			accidentalBird:DespawnOrUnsummon()
		end
	end
    if newArea == 4190 then
		local oldRider = player:GetNearestCreature(300, 27662)
		if oldRider and oldRider:GetAreaId() == 4190 and not oldRider:HasAura(48365) then
			oldRider:DespawnOrUnsummon()
		end
		
		mount = player:GetNearestCreature(100, 27661)
		
		if mount and mount:GetAreaId() == 4190 then
			player:AddAura(66657, player)
			player:Dismount()
			local oldRider = player:GetNearestCreature(80, 27662)
			if oldRider then oldRider:SendUnitSay("This is your stop, pal. Safe landing!",0) end
			--oldRider:AddAura(44312, oldRider)
			CreateLuaEvent(function()
				--print("Attempting to despawn mount and rider...")
				local players = GetPlayersInWorld()
					for _, player in pairs(players) do
					if player:GetAreaId() == 4190 then
						--print("Player on Thorson's farm found!")
						local oldRider = player:GetNearestCreature(300, 27662)
						local mount = player:GetNearestCreature(300, 27661)
						if (mount and mount:GetAreaId() == 4190) and (oldRider and oldRider:GetAreaId() == 4190) then
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

RegisterPacketEvent(0x38D, 5, OnPacket)
RegisterPlayerEvent(27, OnEnterArea)
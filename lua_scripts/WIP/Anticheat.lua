-- Welcome to Yggdrasil's ELUNA anti cheat by mostly nick :)

print("[Anticheat Module]: Yggdrasil anti cheats loaded!")

-- START CONFIGS

-- Module settings
local antiFlightHack		= 1 -- Set to 0 to disable
local antiGeneralSpeedHack 	= 1	-- Set to 0 to disable
local antiGargarinSpeedHack = 1 -- Set to 0 to disable
local antiAirJumpHack		= 1	-- Set to 0 to disable
local antiSuperWallJumpHack	= 1	-- Set to 0 to disable
local antiStuckHack			= 1	-- Set to 0 to disable
local antiTeleportHack		= 1	-- Set to 0 to disable
local antiWallClimbHack		= 1	-- Set to 0 to disable
local antiZorWaterWalkHack	= 1 -- Set to 0 to disable
local antiMapClipHack		= 1 -- Set to 0 to disable
local antiKnockBackHack		= 1 -- Set to 0 to disable
local antiGMIsland 			= 1 -- Set to 0 to permit normal players access to GM island
local cacheOnLoadEluna		= 1 -- Set to 0 ONLY for debugging! This initiates all cache, loads all live data required before functions break, and schedules periodic events
local GMRankDisable			= 4 -- Set to 0 to disable anti flight hack for GMs, 1 to enable for mods, 2 to enable for mods and GMs, 3 for all GMs

-- Warnings, hack logs, and punishment settings
local playerWarningEnabled 	= 0  -- Set 0 to not push SendAreaTriggerMessage to player
local GMwarningEnabled 		= 1  -- Set 0 to not push SendAreaTriggerMessage to GM
local punishmentEnabled 	= 0  -- Set to 0 to not apply punishmentId on player
local hackReportsLimit		= 10 -- Default 25. After X reports in 5 minutes, player will be kicked. Set to 0 to disable kick. This does not apply if punishmentEnabled = 0

-- General Anti Speed hack config
local strikesTimer 			= 5 	-- Reset speed hack counter every X seconds
local maxStrikes 			= 7 	-- How many strikes permissible during strikesTimer window
local veryFastSpeedLimit 	= 10	-- Can catch super quick speed hackers faster. 50 is about 10-25% above "normal" false positive values.
local speedCheckFrequency   = 200   -- How often to verify speed of moving players in miliseconds

-- Anti teleport settings
local teleportTimer 		= 2 	-- Lets clients process a zone change a given interval after server sends a teleport package 
local teleDistance			= 20	-- Coefficient threshold to trigger active anticheat. 15 is about 100 yards for walking targets, 500 for fast flying targets
local offsetTolerance 		= 1.20	-- 10% false positive offset 

-- Anti flight settings
local FlightVerificationFrequency = 2501 	-- How often the game carries out reality checks on flagged players

-- Anti water walking settings
local waterWalkingZCheck 		= 2.0 		-- Z to check for underneath player to run sanity check (if no obstacle under 2.0 and we are walking on straight Z we are probably fake water walking)

-- Anti wall climb hack settings
local wallHackCheckInterval   	= 80	 	-- Check every 500ms
local ZchangeThreshold		  	= 2 		-- Seems about sensitive enough to prevent false positives
local maxSteepness			  	= 1.1	 	-- 1 is about the point where players start sliding down if they try to climb farther. Upped a little for false positive tolerance
local wallClimbResetCount	  	= 10		-- How many times the hack check runs before it resets its hack counter. This is multiplied by the WallHackCheckInterval to form seconds (ie. if interval is 500 and this value is 10, it resets every 5 sec.)
local maxWallHackCount 		 	= 2			-- How many times the check is triggered before a punishment is called. Consider putting to above 1 if false positives

-- Anti no clip settings
local noClipCheckInterval		= 1 		-- Define the interval in seconds to check for No Clip hacks
local noClipDistanceCheck		= 15		-- How far away we should look for LOS blocks

-- Punishment settings
local punishmentId 				= 61204 	-- Which spell ID to punish player with (61204 is permanent invisible stuns)
local groundedDuration			= 5*60*1000 -- 5 minutes in miliseconds
local resetSpeedHackTimer		= 1500 		-- How often to reset anti cheat counts, in miliseconds
local resetJumpHackTimer		= 10000 	-- How often to reset anti cheat counts, in miliseconds

-- Linked configs
if punishmentEnabled == 0 then
	hackReportsLimit = 0
end

--END CONFIGS

-- Constants
local wallClimbCheckCount = 0

-- Tables, do not alter
local pendingFlightChecks = {}
local groundedPlayers = {}
local speedHackCount = {}
local wallClimbHackCount = {}
local playerCanFly = {}
local playerJumps = {}
local playerX = {}
local playerY = {}
local playerZ = {}
local movingPlayers = {}
local moveTypes = {}
local endTime = {}
local speedHackStrikes = {}
local speedHackTimer = {}
local lastMoveType = {}
local moveTypeChangeTime = {}
local moveTypeChangeFlag = {}
local lastSpeed = {} 
local imprisoned = {}
local canTeleportTime = {}
local teleportGraceTimer = {}
local speedHackGraceTimer = {}
local oldTeleMap = {}
local oldTeleX = {}
local oldTeleY = {}
local oldTeleZ = {}
local serverMap = {}
local serverX = {}
local serverY = {}
local serverZ = {}
local hackReports = {}
local playerZMovementTable = {}
local playerLastSteepness1X = {}
local playerLastSteepness1Y = {}
local playerLastSteepness1Z = {}
local playerLastSteepness2X = {}
local playerLastSteepness2Y = {}
local playerLastSteepness2Z = {}
local abortTeleCheck = {}
local superJumpers = {}
local superJumpersLow = {}
local jumpHistory = {}
local noClipPlayerPositions = {}
local losCache = {}
local knockedBackCheck = {}
local mountCache = {}
local notTeleporting = {}
local lastSpeed = {}
local playerLastSteepnessToggle = {}
local knockBackAck = {}
local knockBackAckTime = {}
local GMsingame = {}
local allClear = {}
local skipTeleportCheck = {}

local BUFFIDS = { 
    3363, 8153, 8980, 10788, 10790, 10792, 24576, 25675, 25858, 28828, 32235, 32239, 32240,
    32242, 32243, 32244, 32245, 32246, 32289, 32290, 32292, 32295, 32296, 32297, 32345, 32420,
    33943, 34068, 37015, 39450, 39798, 39800, 39801, 39802, 39803, 39910, 39949, 40120, 40192,
    40212, 41513, 41514, 41515, 41516, 41517, 41518, 42667, 42668, 42673, 42679, 42929, 43810,
    43927, 44151, 44153, 44317, 44655, 44744, 44824, 44825, 44827, 45127, 45177, 46197, 46199,
    46980, 47037, 48023, 49193, 49908, 50281, 51617, 51960, 54726, 54727, 54729, 54903, 58615,
    59567, 59568, 59569, 59570, 59571, 59650, 59961, 59976, 59996, 60002, 60021, 60024, 60025,
    60099, 60120, 60136, 60140, 61229, 61230, 61289, 61294, 61309, 61442, 61444, 61446, 61451,
    61983, 61996, 61997, 62048, 63796, 63844, 63956, 63963, 64681, 64749, 64762, 64927, 65439, 
    66088, 67336, 68767, 69395, 71346, 71347, 71810, 72283, 72284, 72807, 72808, 74854, 74855,
    75596, 75617, 75618, 76153, 66087, 31700
}

-- OPCODE TABLES, DO NOT EDIT

local clientOpcodes = {0x095, 0x097, 0x098, 0x12E, 0x136, 0x0C3, 0x0C2, 0x0B5, 0x0B6, 0x0B7, 0x0B8, 0x0B9, 0x0BA, 0x0BB, 0x0BC, 0x0BD, 0x0BE, 0x0BF} -- Teleport location tracker on move
local serverOpcodes = {0x495, 0x0C7, 0x4F7} -- Server packets to verify if new location is real


-- REFERENCE FUNCTIONS
local function HasBuff(player, buffIds) -- Flight buff IDs, used for general anti flight hack 
    for _, buffId in ipairs(buffIds) do
        if player:HasAura(buffId) then
            return true
        end
    end
    return false
end

local function ResetSpeedHackCount() -- Used in antiGeneralSpeedHack
    for guid in pairs(speedHackCount) do
        speedHackCount[guid] = nil
    end
end

local function ResetJumpHackCount() -- For anti air jump hack
    for guid in pairs(playerJumps) do
        playerJumps[guid] = nil
    end
end

local function CleanupGroundedPlayers()
    local currentTime = os.time() * 1000
    for guid, _ in pairs(groundedPlayers) do
        local player = GetPlayerByGUID(guid)
        if player and player:HasAura(punishmentId) then
            player:RemoveAura(punishmentId)
        end
        groundedPlayers[guid] = nil
    end
end

local function calculateSpeedHackDistance(x1, y1, z1, x2, y2, z2) -- Used in antiGeneralSpeedHack, Z is throwing error as it exaggerates the travelled distance so its effect is reduced
	if x1 then
		local dx = x2 - x1
		local dy = y2 - y1
		local dz = z2/10 - z1/10
		return math.sqrt(dx * dx + dy * dy + dz * dz)
	end
end

local function calculateTeleportDistance(x1, y1, z1, x2, y2, z2) -- Teleport distance must include Z, hence new function
    if x1 then
		return math.sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)
	else 
		return 0
	end
end

local function checkObstaclesForPlayer(player)
    local x, y, z = player:GetLocation()

    -- Check if the player is near the ground
    local success, ground = pcall(function() return player:GetMap():GetHeight(x, y, z >= 0 and z or 0.01) end)
    if not success then
        ground = 0
    end
    if not ground then return end

    local distanceToGround = z - ground
    local isNearGround = distanceToGround <= waterWalkingZCheck

    -- Check for obstacles using IsWithinLoS
    local allWithinLoS = true
    for i = 0, waterWalkingZCheck * 2, 0.5 do
        local testZ = z - i
        local success, isWithinLoS = pcall(function() return player:IsWithinLoS(x, y, testZ) end)

        if not (success and isWithinLoS) then
            allWithinLoS = false
            break
        end
    end

    local isNearBuilding = not allWithinLoS

    -- Combine the checks
    local isNearObstacle = isNearBuilding or isNearGround

    return isNearObstacle
end

-- ANTI CHEAT FUNCTIONS

local function mapNoClipHack()
    for _, player in pairs(GetPlayersInWorld()) do
        if not player then return end

        local mapId = player:GetMapId()
		if not mapId == 631 then -- Making ICC exempt to avoid issues on the Frozen Throne
			
			local x, y, z = player:GetLocation()

			if z < 0 then z = 0 end
			-- Get the map height at the player's location
			local groundLevel = player:GetMap():GetHeight(x, y, z)

			if groundLevel then
				-- Check if the player is at least 2 units below the ground level
				if z < groundLevel - 2 then
					-- Check for LOS hindrance within 50 yards under the player
					local losHindranceFound = false
					for dz = -50, 0 do
						if not player:IsWithinLoS(x, y, z + dz) then
							losHindranceFound = true
							break
						end
					end

					-- If no LOS hindrance is found and the player is not swimming, teleport them up
					if not losHindranceFound and not player:IsInWater() then
						print(string.format("[Anticheat Module]: Anti map clip - Player %s is below the ground level!", player:GetName()))
						player:Teleport(mapId, x, y, groundLevel+3, 0)
					end
				end
			end
        end
    end
end

local function antiStuckHackCheck(player)
    local guid = player:GetGUIDLow()

    if player:HasAura(punishmentId) and (not imprisoned[guid] or imprisoned[guid] == 0) and punishmentEnabled == 1 then
        imprisoned[guid] = 2
        player:Teleport(13, 0, 0, 0, 0)
		if playerWarningEnabled == 1 then
			if player:GetGMRank() == 0  then
				player:SendAreaTriggerMessage("You have been imprisoned for using cheats!")
			end
		end
		if GMwarningEnabled == 1 then
			local GMs = GetPlayersInWorld()
			for _, GM in pairs(GMs) do
				if GM:GetGMRank() >= 1 then		
					GM:SendAreaTriggerMessage("|cFFFF66FF[Nick's Anticheat] Player "..player:GetName().." has been imprisoned for using anti stuck hack!|r")
				end
			end
		end
        print("[Anticheat Module]: Anti stuck - Player "..player:GetName().." has been imprisoned for using anti stuck cheats!")
        if not hackReports[guid] then hackReports[guid] = 1 else hackReports[guid] = hackReports[guid] + 1 end
        if player:HasItem(6948) then
            player:RemoveItem(6948, 1)
        end
        if player:HasItem(37430) then
            player:RemoveItem(37430, 1)
        end
    end
end

local function periodicSpeedCheck(player)
    for playerGUID, _ in pairs(movingPlayers) do
		if not playerGUID then return end
		
        local player = GetPlayerByGUID(playerGUID)
		
		if not player or player == nil then return end
		
		local guid = player:GetGUIDLow()
		
		if knockedBackCheck[guid] and knockedBackCheck[guid] < os.time() then
			knockedBackCheck[guid] = nil
		end
		
		--if knockedBackCheck[guid] then
		--	print("speed check paused due to knockback")
		--end
		
		if player:IsMoving() and player:GetZoneId() ~= 2257
		and not player:IsFalling() and not knockedBackCheck[guid]
		and (speedHackGraceTimer[guid] and os.time() >= speedHackGraceTimer[guid]) then
		
			local startX = playerX[guid]
			local startY = playerY[guid]
			local startZ = playerZ[guid]

			local endX = player:GetX()
			local endY = player:GetY()
			local endZ = player:GetZ()
			
			local displacement
			
			if startX then	
				displacement = calculateSpeedHackDistance(startX, startY, startZ, endX, endY, endZ)
			else
				displacement = 0
			end
			
			if displacement == 0 then return end
			
			--print(displacement)

			local maxSpeed

			if player:IsFlying() then -- Minimum speed 16
				lastMoveType[guid] = 6
				maxSpeed = player:GetSpeed(lastMoveType[guid])
			elseif player:IsUnderWater() then -- Minimum speed 3.5
				lastMoveType[guid] = 3
				maxSpeed = player:GetSpeed(lastMoveType[guid])
			else -- Minimum speed 7
				lastMoveType[guid] = 1
				maxSpeed = player:GetSpeed(lastMoveType[guid])
			end
			
			if not lastSpeed[guid] then
				lastSpeed[guid] = maxSpeed 
			elseif lastSpeed[guid] > maxSpeed then
				lastSpeed[guid] = lastSpeed[guid]/10*9
				--print("Gradual speed reduction started")
				maxSpeed = lastSpeed[guid]
			end
			
			--print("Displacement: "..displacement)
			
			local maxDisplacement = maxSpeed / 2 * 1.07 -- For some reason displacement updates at half the speed rate. Added 7% inaccuracy room to avoid false positives
			--print("Max displacement: "..maxDisplacement)
			
			if speedHackStrikes[guid] and speedHackStrikes[guid] > 0 and speedHackStrikes[guid] < 2 then
				player:SaveToDB()
			local query = CharDBQuery(string.format("SELECT transguid FROM characters WHERE guid = %u", guid))
			if query then
				local transguid = query:GetInt32(0)  -- Get the value of the first column (transguid) in the result
				if transguid > 0 then
					speedHackStrikes[guid] = 0
					speedHackGraceTimer[guid] = os.time() + 300
					print("[Anticheat Module]: Speed hack - Aborting check, player " .. player:GetName() .. " is on transport!")
				end
			end
			elseif displacement > (maxDisplacement + veryFastSpeedLimit*20) then -- Probably not speed hacks. Teleport anti hack will catch these
				print("[Anticheat Module]: Speed hack - Unusually high value from player "..player:GetName().." (>"..(maxDisplacement + veryFastSpeedLimit*4)..")! Are they using teleport cheat?")
			elseif displacement > (maxDisplacement + veryFastSpeedLimit) then -- Very fast speed hacks
				print("[Anticheat Module]: Speed hack - Very fast speed detected on player "..player:GetName().."!")
				if not speedHackStrikes[guid] or speedHackStrikes[guid] == 0 then
					speedHackStrikes[guid] = 1
					speedHackTimer[guid] = os.time()
				elseif speedHackStrikes[guid] >= 1 then
					if playerWarningEnabled == 1 then
						if player:GetGMRank() == 0  then
							player:SendAreaTriggerMessage("You have been detected using speed hack!")
						end
					end
					if GMwarningEnabled == 1 then
						local GMs = GetPlayersInWorld()
						for _, GM in pairs(GMs) do
							if GM:GetGMRank() >= 1 then
								GM:SendAreaTriggerMessage("|cFFFF66FF[Nick's Anticheat] Player "..player:GetName().." has been detected using very fast speed hack!|r")
							end
						end
					end
					if punishmentEnabled == 1 then
						player:AddAura(punishmentId, player)
						if player:GetGMRank() > 0 then player:SendBroadcastMessage("Use command '.unaura "..punishmentId.."' to move again. Only GMs can see this message.") end
						if not hackReports[guid] then hackReports[guid] = 1 else hackReports[guid] = hackReports[guid] + 1 end
					end

					--print("[Anticheat Module]: Speed hack - Player " .. player:GetName() .. " is using speed hack! Speed: " .. string.format("%.2f", maxSpeed) .. ". Displacement: " .. string.format("%.2f", displacement) .. ", Max theoretical displacement: " .. string.format("%.2f", maxDisplacement) .. ", Time: " .. os.time())
					--print("[Anticheat Module]: Speed hack - Number of strikes: " .. speedHackStrikes[guid])

					speedHackStrikes[guid] = speedHackStrikes[guid] + 1
				end
				if os.time() - speedHackTimer[guid] > strikesTimer then
					speedHackTimer[guid] = os.time()
					speedHackStrikes[guid] = 1
				end

			elseif displacement > maxDisplacement then -- Moderate speed hacks
				print("[Anticheat Module]: Speed hack - Moderate speed discrepancy detected on player "..player:GetName().."! Displacement: "..displacement..". Max theortical displacement: "..maxDisplacement)
				if not speedHackStrikes[guid] or speedHackStrikes[guid] == 0 then
					speedHackStrikes[guid] = 1
					speedHackTimer[guid] = os.time()
				elseif speedHackStrikes[guid] >= maxStrikes-1 then
					if playerWarningEnabled == 1 then
						if player:GetGMRank() == 0  then
							player:SendAreaTriggerMessage("You have been detected using speed hack!")
						end
					end
					if GMwarningEnabled == 1 then
						local GMs = GetPlayersInWorld()
						for _, GM in pairs(GMs) do
							if GM:GetGMRank() >= 1 then
								GM:SendAreaTriggerMessage("|cFFFF66FF[Nick's Anticheat] Player "..player:GetName().." has been detected using general speed hack!|r")
							end
						end
					end
					if punishmentEnabled == 1 then
						player:AddAura(punishmentId, player)
						if player:GetGMRank() > 0 then player:SendBroadcastMessage("Use command '.unaura "..punishmentId.."' to move again. Only GMs can see this message.") end
						if not hackReports[guid] then hackReports[guid] = 1 else hackReports[guid] = hackReports[guid] + 1 end
					end
					speedHackStrikes[guid] = speedHackStrikes[guid] + 1
				elseif speedHackStrikes[guid] > 3 then
					speedHackStrikes[guid] = speedHackStrikes[guid] + 1
					print("[Anticheat Module]: Speed hack - Alert on "..player:GetName().."! Number of strikes: " .. speedHackStrikes[guid])
				else
					speedHackStrikes[guid] = speedHackStrikes[guid] + 1
				end

				if os.time() - speedHackTimer[guid] > strikesTimer then
					speedHackTimer[guid] = os.time()
					speedHackStrikes[guid] = 1
				end
				if speedHackStrikes[guid] >= maxStrikes then
					print("[Anticheat Module]: Speed hack - Player " .. player:GetName() .. " is using speed hack! Speed: " .. string.format("%.2f", maxSpeed) .. ". Displacement: " .. string.format("%.2f", displacement) .. ", Max theoretical displacement: " .. string.format("%.2f", maxDisplacement) .. ", Time: " .. os.time())
					print("[Anticheat Module]: Speed hack - Number of strikes: " .. speedHackStrikes[guid])
				end
			--else
				--print("[Anticheat Module]: No players are exceeding maximum theoretical displacement.")
			elseif displacement < maxDisplacement + 100 then
				notTeleporting[guid] = 1
			end
			playerX[guid] = endX
			playerY[guid] = endY
			playerZ[guid] = endZ
		else
			movingPlayers[guid] = nil
			notTeleporting[guid] = 0
			return
		end
	end
end

local function antiGeneralSpeedandStuck(event, packet, player)
    if not player then return end

    local guidLow = player:GetGUIDLow()
    local opcode = packet:GetOpcode()

    if antiStuckHack == 1 then
        antiStuckHackCheck(player)
    end

    if player:GetGMRank() >= GMRankDisable then return end
	
    if antiGeneralSpeedHack == 0 then return end

    if player:IsFalling() then return end
	
	if opcode == 0x0BB then -- Reducing speed hack count slightly if player triggers false positive from jumping
		if speedHackStrikes[guid] and speedHackStrikes[guid] > 1 then
			speedHackStrikes[guid] = speedHackStrikes[guid] - 0.5
		end
	end	

    if opcode == 0x0B5 or opcode == 0x0B6 or opcode == 0x0DA or opcode == 0x0DB or opcode == 0x0AB
	or opcode == 0x0B8 or opcode == 0x0B9 or opcode == 0x0EE or opcode == 0x12E then
        if not player:IsOnVehicle() and not player:HasAura(59656) then
            playerX[guidLow] = player:GetX()
            playerY[guidLow] = player:GetY()
            playerZ[guidLow] = player:GetZ()
			movingPlayers[guidLow] = player:GetGUID()
			player:RegisterEvent(periodicSpeedCheck, speedCheckFrequency, 0, playerGuid)
        end
    end
end

local function superJumpOrWallJumpCheck()
    for superJumpGUID, _ in pairs(superJumpers) do
        local player = GetPlayerByGUID(superJumpGUID)
        if not player then return end
        
        local guid = player:GetGUIDLow()
        if playerJumps[guid] and playerJumps[guid] > 0 then
            local currentZ = player:GetZ()
            
            if not jumpHistory[guid] then
                jumpHistory[guid] = {values = {currentZ}, startZ = currentZ, maxZ = currentZ, isFlying = false}
            else
                if player:IsFlying() then
                    playerJumps[guid] = 0
					--print("resetting jump check due to flight")
                else
                    table.insert(jumpHistory[guid].values, currentZ)
                    
                    if currentZ > jumpHistory[guid].maxZ then
                        jumpHistory[guid].maxZ = currentZ
                    end
                    
                    if #jumpHistory[guid].values > 30 then -- Keep up to 30 Z values
                        table.remove(jumpHistory[guid].values, 1)
                    end
                    
                    if currentZ < jumpHistory[guid].values[#jumpHistory[guid].values - 1] then
                        local totalZIncrease = jumpHistory[guid].maxZ - jumpHistory[guid].startZ
                        
                        if totalZIncrease > 10 then  -- Adjust this threshold as needed
                            print("[Anticheat Module]: Super jump or wall jump cheat detected on player "..player:GetName().."!")
                            if playerWarningEnabled == 1 then
								if player:GetGMRank() == 0  then
									player:SendAreaTriggerMessage("You have been detected using jump hack!")
								end
							end
                            if GMwarningEnabled == 1 then
                                local GMs = GetPlayersInWorld()
                                for _, GM in pairs(GMs) do
									if GM:GetGMRank() >= 1 then
										GM:SendAreaTriggerMessage("|cFFFF66FF[Nick's Anticheat] Player "..player:GetName().." has been detected using super jump or wall jump hack!|r")
									end
								end
                            end
                            if punishmentEnabled == 1 then
                                player:AddAura(punishmentId, player)
                                if player:GetGMRank() > 0 then 
                                    player:SendBroadcastMessage("Use command '.unaura "..punishmentId.."' to move again. Only GMs can see this message.") 
                                end
                                if not hackReports[guid] then 
                                    hackReports[guid] = 1 
                                else 
                                    hackReports[guid] = hackReports[guid] + 1 
                                end
                            end
                        end
                    end
                end
            end
        else
            -- Reset the jump history when the player is not jumping
            jumpHistory[guid] = nil
        end
    end
end
local function antiJump(event, packet, player)
    if not player then return end

	local opcode = packet:GetOpcode()
	local guid = player:GetGUIDLow()
	
	if speedHackStrikes[guid] and speedHackStrikes[guid] > 1 then
		speedHackStrikes[guid] = speedHackStrikes[guid] - 0.5
	end
	
	if opcode == 0x0BB and (playerJumps[guid] == 0 or not playerJumps[guid])
	and not player:IsOnVehicle() and not player:HasAura(59656) then
		playerJumps[guid] = 1
		
		if antiSuperWallJumpHack == 1 then
			local superJumpGUID = player:GetGUID()
			if superJumpersLow[guid] == 1 then
                jumpHistory[guid] = nil -- Reset jump history after processing
				CreateLuaEvent(superJumpOrWallJumpCheck, 100, 30)
			elseif not superJumpersLow[guid] or superJumpersLow[guid] == 0 then
                jumpHistory[guid] = nil -- Reset jump history after processing
				superJumpers[superJumpGUID] = 1
				superJumpersLow[guid] = 1
				CreateLuaEvent(superJumpOrWallJumpCheck, 100, 30)
			end
		end
		
	elseif opcode == 0x0BB and playerJumps[guid] == 1 then
		print("[Anticheat Module]: Jump cheat deteced on player "..player:GetName().."!")
		if playerWarningEnabled == 1 then
			if player:GetGMRank() == 0  then
				player:SendAreaTriggerMessage("You have been detected using air jump hack!")
			end
		end
		if GMwarningEnabled == 1 then
			local GMs = GetPlayersInWorld()
			for _, GM in pairs(GMs) do
				if GM:GetGMRank() >= 1 then
					GM:SendAreaTriggerMessage("|cFFFF66FF[Nick's Anticheat] Player "..player:GetName().." has been detected using air jump hack!|r")
				end
			end
		end
		if punishmentEnabled == 1 then
			player:AddAura(punishmentId, player)
			if player:GetGMRank() > 0 then player:SendBroadcastMessage("Use command '.unaura "..punishmentId.."' to move again. Only GMs can see this message.") end
			if not hackReports[guid] then hackReports[guid] = 1 else hackReports[guid] = hackReports[guid] + 1 end
		end
	elseif opcode == 0x0C9 or opcode == 0x0CA or
		player:HasAura(75333) or player:HasAura(1706) or player:HasAura(27986) or -- Various levitates
		player:HasAura(31704) or player:HasAura(50195) or player:HasAura(52970) or
		player:HasAura(59200) then
		playerJumps[guid] = nil
	end
end

local function antiGargarinSpeed(event, packet, player)
    if not player then return end

	local opcode = packet:GetOpcode()
	local guid = player:GetGUIDLow()
	
	if imprisoned[guid] and imprisoned[guid] > 0 then return end
	
	if opcode == 0x2CE and player:GetTotalPlayedTime() > 60 and not player:HasAura(punishmentId) then -- Total played time prevents false positives during start cinematics
			
		if not speedHackCount[guid] then
			speedHackCount[guid] = 1
			--print("[Anticheat Module]: Anti Gargarin speed hack - Run speed verification - Player "..player:GetName().." sent packet with opcode 0x2CE. Total Count: "..speedHackCount[guid])
		else
			speedHackCount[guid] = speedHackCount[guid] + 1
			--print("[Anticheat Module]: Anti Gargarin speed hack - Run speed verification - Player "..player:GetName().." sent packet with opcode 0x2CE. Total Count: "..speedHackCount[guid])
		end
		
		if speedHackCount[guid] >= 7 then
			print("[Anticheat Module]: Anti Gargarin - Speed hack detected on player "..player:GetName().."!")
			if playerWarningEnabled == 1 then
				if player:GetGMRank() == 0  then
					player:SendAreaTriggerMessage("You have been detected using Gargarin speed hack!")
				end
			end
			if GMwarningEnabled == 1 then
				local GMs = GetPlayersInWorld()
				for _, GM in pairs(GMs) do
					if GM:GetGMRank() >= 1 then
						GM:SendAreaTriggerMessage("|cFFFF66FF[Nick's Anticheat] Player "..player:GetName().." has been detected using Gargarin speed hack!|r")
					end
				end
			end
			
			if punishmentEnabled == 1 then
				player:AddAura(punishmentId, player)
				if player:GetGMRank() > 0 then player:SendBroadcastMessage("Use command '.unaura "..punishmentId.."' to move again. Only GMs can see this message.") end
				if not hackReports[guid] then hackReports[guid] = 1 else hackReports[guid] = hackReports[guid] + 1 end
			end

			speedHackCount[guid] = 0  -- Reset counter after applying aura
			groundedPlayers[guid] = true
		end
	end
end

local function antiFly(event, packet, player)
    if not player then return end
    
    local opcode = packet:GetOpcode()
    local guid = player:GetGUIDLow()
        
    if opcode == 0x345 then 
        playerCanFly[guid] = true
    end
    
    if opcode == 0x346 then
        if playerCanFly[guid] and (HasBuff(player, BUFFIDS) or player:IsOnVehicle() or player:HasAura(59656)) then return end
        
        if (not HasBuff(player, BUFFIDS)) and player:GetGMRank() <= GMRankDisable and not (playerCanFly[guid] or player:IsOnVehicle() or player:HasAura(59656)) then
            --print("[Anticheat Module]: Anti flight warning! Player "..player:GetName().." called opcode 0x346 without calling opcode 0x345 and not being able to fly!")
            
            if not pendingFlightChecks[guid] then
                pendingFlightChecks[guid] = os.time() + 5
            end
        elseif opcode == 0x346 and playerCanFly[guid] and (not HasBuff(player, BUFFIDS) or player:IsOnVehicle() or player:HasAura(59656)) then
            playerCanFly[guid] = false
        end
    end
end

local function processFlightVerification()
    local currentTime = os.time()
    for guid, checkTime in pairs(pendingFlightChecks) do
        if currentTime >= checkTime then
            local player = GetPlayerByGUID(guid)
            if player and not player:IsInWater() and player:IsFlying() then
				print("[Anticheat Module]: Anti flight hack - Player queued for check: "..player:GetName())
                local mapId = player:GetMapId()
                local zoneId = player:GetZoneId()
                local areaId = player:GetAreaId()
				
				if playerCanFly[guid] and (HasBuff(player, BUFFIDS) or player:IsOnVehicle() or player:HasAura(59656)) then -- There was a print here before but it's not needed anymore, now this is just a dead end for players that need no action
				
				elseif player:CanFly() and (not HasBuff(player, BUFFIDS)) and not (player:IsOnVehicle()) then
					if player:GetGMRank() <= GMRankDisable then
						print("[Anticheat Module]: Anti flight hack - Player "..player:GetName().." is flight hacking! Taking measures..")
						if (mapId == 0 or mapId == 1 or areaId == 3496 or zoneId == 3430 or zoneId == 3433 or zoneId == 3557 or zoneId == 3524 or zoneId == 4080 or zoneId == 3487 or zoneId == 3455 or zoneId == 3525 or zoneId == 3479) and player:HasItem(20739) then  -- Delete this for other servers, it's part of Yggdrasil's Azeroth flight module
							if player:IsMounted() then player:Dismount() end
							
							if player:HasSpell(34091) or player:HasSpell(34093) then
								player:AddAura(40120, player)
							end
							
							if player:HasSpell(34090) or player:HasSpell(34092) then
								player:AddAura(33943, player)
							end
						else
							if punishmentEnabled == 1 then
								player:AddAura(punishmentId,player)     
								if player:GetGMRank() > 0 then player:SendBroadcastMessage("Use command '.unaura "..punishmentId.."' to move again. Only GMs can see this message.") end       
								--player:SendAreaTriggerMessage("You have been locked in place for 5 minutes for unauthorized flight!")
								groundedPlayers[guid] = true
								if not hackReports[guid] then hackReports[guid] = 1 else hackReports[guid] = hackReports[guid] + 1 end
							end
							if playerWarningEnabled == 1 then
								if player:GetGMRank() == 0  then
									player:SendAreaTriggerMessage("You have been detected using flight hack!")
								end
							end
							if GMwarningEnabled == 1 then
								local GMs = GetPlayersInWorld()
								for _, GM in pairs(GMs) do
									if GM:GetGMRank() >= 1  then
										GM:SendAreaTriggerMessage("|cFFFF66FF[Nick's Anticheat] Player "..player:GetName().." has been detected using flight hack!|r")
									end
								end
							end
							
							--print("Player flight hacking: "..player:GetName())
						end
					else
						print("Error with GM rank!")
					end
				end
			end
			pendingFlightChecks[guid] = nil
        end
    end
end

local function clientSideTeleportCheck(event, packet, player)
    if not player then return end

    local guid = player:GetGUIDLow()
    local opcode = packet:GetOpcode()
	
	if skipTeleportCheck[guid] and skipTeleportCheck[guid] >= os.time() then
		--print("Skipping hack check for "..player:GetName().." due to taxiing.")
		return
	end

	if not moveTypeChangeFlag[guid] then
		moveTypeChangeFlag[guid] = 0
	end
	
	if not abortTeleCheck[guid] then abortTeleCheck[guid] = 0 end
	
	if player:IsAlive() and not player:IsOnVehicle() and not player:HasAura(59656)
	and not player:IsFalling() and abortTeleCheck[guid] > 0 then
		abortTeleCheck[guid] = abortTeleCheck[guid] - 1
	elseif player:IsAlive() and not player:IsFalling() and abortTeleCheck[guid] == 0 and not player:HasAura(59656) 
	and not player:HasAura(130) and not player:HasAura(12438) and not player:HasAura(50085) and not player:HasAura(50237) -- Slow fall spells
	and not player:HasAura(75333) and not player:HasAura(1706) and not player:HasAura(27986) and not player:HasAura(31704) -- Various levitates
	and not player:HasAura(50195) and not player:HasAura(52970) and not	player:HasAura(59200) and not player:HasAura(16593) -- Various levitates and noggenfogger slow fall
	and not player:HasAura(46598) -- Various vehicle/mount-related auras
	then

		-- Get the current speed
		if not lastMoveType[guid] then lastMoveType[guid] = 1 end
		
		if not player:GetSpeed(lastMoveType[guid]) then
			local currentSpeed = 0 
		else
			local currentSpeed = player:GetSpeed(lastMoveType[guid])
		end
	
		-- Check if the speed has changed
		if lastSpeed[guid] then
			if (currentSpeed and currentSpeed < lastSpeed[guid]) and (moveTypeChangeFlag[guid] and moveTypeChangeFlag[guid] == 0) then
				-- If the speed decreases and the flag is not set, set the timer for 5 seconds and set the flag
				moveTypeChangeTime[guid] = os.time() + 5
				moveTypeChangeFlag[guid] = 1
				--print("Speed decreased, setting timer for 5 seconds")
			elseif currentSpeed and lastSpeed[guid] and currentSpeed > lastSpeed[guid] then
				-- If the speed increases, update immediately and reset the timer and flag
				moveTypeChangeTime[guid] = 0
				moveTypeChangeFlag[guid] = 0
				--print("Speed increased, resetting timer and flag")
			end
		end

		if moveTypeChangeTime[guid] and moveTypeChangeTime[guid] > os.time() then
			currentSpeed = lastSpeed[guid]
			--print("Using last speed due to active timer")
		else
			moveTypeChangeTime[guid] = 0
			moveTypeChangeFlag[guid] = 0
			currentSpeed = player:GetSpeed(lastMoveType[guid])
			--print("Timer expired, updating to current speed and resetting flag")
		end

		lastSpeed[guid] = currentSpeed
		--print("Updated lastSpeed to:", currentSpeed)

		if canTeleportTime[guid] and type(canTeleportTime[guid]) == "number" then
			if canTeleportTime[guid] - os.time() > 0 then
				--print("Can teleport within " .. (canTeleportTime[guid] - os.time()) .. " seconds.")
			elseif canTeleportTime[guid] - os.time() < 0 then
				canTeleportTime[guid] = 0
			end
		end
		
		if canTeleportTime[guid] and canTeleportTime[guid] >= os.time() then
			--print ("Tele check called off because player is eligible to TP")
			return
		end 

		if opcode ~= 0x1F4 and opcode ~= 0x4F7 and opcode ~= 0x096 and opcode ~= 0x3B3 then -- Ignore passive packages, used to only to track movement packages to prevent most client-side teleports
			oldTeleMap[guid] = player:GetMapId()
			oldTeleX[guid] = player:GetX()
			oldTeleY[guid] = player:GetY()
			oldTeleZ[guid] = player:GetZ()
			--print(teleDistance*(player:GetSpeed(lastMoveType[guid])))
			if serverX[guid] and serverMap[guid] == oldTeleMap[guid] then
				local distance = calculateTeleportDistance(serverX[guid], serverY[guid], serverZ[guid], oldTeleX[guid], oldTeleY[guid], oldTeleZ[guid])
				if distance > ((teleDistance * (currentSpeed / 2))*offsetTolerance) then -- Check if distance is more than X yards	
					if playerWarningEnabled == 1 then
						if player:GetGMRank() == 0  then
							player:SendAreaTriggerMessage("You have been detected moving unusually!")
						end
					end
					if GMwarningEnabled == 1 then
						local GMs = GetPlayersInWorld()
						for _, GM in pairs(GMs) do
							if GM:GetGMRank() >= 1  then
								GM:SendAreaTriggerMessage("|cFFFF66FF[Nick's Anticheat] Player "..player:GetName().." has been detected using XYZ teleport hack!|r")
							end
						end
					end
					if punishmentEnabled == 1 then
						player:Teleport(serverMap[guid], serverX[guid], serverY[guid], serverZ[guid], 0)
						player:AddAura(punishmentId, player)
						if player:GetGMRank() > 0 then player:SendBroadcastMessage("Use command '.unaura "..punishmentId.."' to move again. Only GMs can see this message.") end
						if not hackReports[guid] then hackReports[guid] = 1 else hackReports[guid] = hackReports[guid] + 1 end
					end
					print("[Anticheat Module]: Player "..player:GetName().." has been detected using XYZ teleport hack!")
				end
			end
		end

		if opcode == 0x1F4 and player:GetGMRank() < GMRankDisable then -- Handle the teleport check for opcode 0x1F4, on client-side zone change
			local newTeleX = player:GetX()
			local newTeleY = player:GetY()
			local newTeleZ = player:GetZ()
			local distance = calculateTeleportDistance(oldTeleX[guid], oldTeleY[guid], oldTeleZ[guid], newTeleX, newTeleY, newTeleZ)

			if player:GetMapId() == oldTeleMap[guid] then
				if distance > ((teleDistance * (currentSpeed / 2))*offsetTolerance) then
					teleportGraceTimer[guid] = os.time() + teleportTimer
					print("[Anticheat Module]: Anti teleport zone hack - Player " .. player:GetName() .. " has been caught teleporting and returned to their original location!")
					if playerWarningEnabled == 1 then
						if player:GetGMRank() == 0  then
							player:SendAreaTriggerMessage("You have been detected using teleport hack!")
						end
					end
					if GMwarningEnabled == 1 then
						local GMs = GetPlayersInWorld()
						for _, GM in pairs(GMs) do
							if GM:GetGMRank() >= 1  then
								GM:SendAreaTriggerMessage("|cFFFF66FF[Nick's Anticheat] Player "..player:GetName().." has been detected using teleport hack!|r")
							end
						end
					end
					if punishmentEnabled == 1 then
						player:Teleport(oldTeleMap[guid], oldTeleX[guid], oldTeleY[guid], oldTeleZ[guid], 0)
						player:AddAura(punishmentId, player)
						if player:GetGMRank() > 0 then player:SendBroadcastMessage("Use command '.unaura "..punishmentId.."' to move again. Only GMs can see this message.") end
						if not hackReports[guid] then hackReports[guid] = 1 else hackReports[guid] = hackReports[guid] + 1 end
					end
				end
			else
				if distance > (teleDistance * (currentSpeed / 2)) then -- Check if distance is more than 50 yards
					if os.time() - (canTeleportTime[guid] or 0) >= teleportTimer then
						player:Teleport(oldTeleMap[guid], oldTeleX[guid], oldTeleY[guid], oldTeleZ[guid], 0)
						teleportGraceTimer[guid] = os.time() + teleportTimer
					end
				end
			end
		end
	end
end

local function serverSideTeleportCheck(event, packet, player)
    local guid = player:GetGUIDLow()
    local opcode = packet:GetOpcode()
	
    if opcode == 0x495 or opcode == 0x0C7 or opcode == 0x0A9 then
		--print(string.format("Packet debug: Server sent "..player:GetName().." packet with opcode 0x%03X", opcode))
		canTeleportTime[guid] = os.time() + teleportTimer
		--print("canteleporttime[guid] = "..canTeleportTime[guid]-os.time())
    end
	if opcode == 0x1AE then
		skipTeleportCheck[guid] = os.time() + 20 * 60
		print("Skip teleport check active for "..player:GetName())
	end
    if (opcode == 0x390 or opcode == 0x4F7 or opcode == 0x043 or opcode == 0x0AA) and not player:IsFalling() then
	    serverMap[guid] = player:GetMapId()
        serverX[guid] = player:GetX()
        serverY[guid] = player:GetY()
        serverZ[guid] = player:GetZ()
		abortTeleCheck[guid] = 0
		--print(string.format("Packets debug: Server sent "..player:GetName().." packet with opcode 0x%03X. Location - X: "..serverX[guid].." Y: "..serverY[guid].."Z: "..serverZ[guid]..".", opcode))
	elseif opcode == 0x390 and player:IsFalling() then
		abortTeleCheck[guid] = 3
    end
end

local function antiGMIslandCheat(event, player, newZone, newArea)
    if newZone == 876 and player:GetGMRank() == 0 then
		if punishmentEnabled == 1 then
			player:Teleport(13, 0, 0, 0, 0)
			if not hackReports[guid] then hackReports[guid] = 1 else hackReports[guid] = hackReports[guid] + 1 end
		end
		if playerWarningEnabled == 1 then
			if player:GetGMRank() == 0  then
				player:SendAreaTriggerMessage("You have been detected in an area you're not supposed to be in!")
			end
		end
		if GMwarningEnabled == 1 then
			local GMs = GetPlayersInWorld()
			for _, GM in pairs(GMs) do
				if GM:GetGMRank() >= 1  then
					GM:SendAreaTriggerMessage("|cFFFF66FF[Nick's Anticheat] Player "..player:GetName().." has been detected trespassing on GM island!|r")
				end
			end
		end
    end
end

local function checkPlayerZMovement(player)
    local guid = player:GetGUIDLow()
    local x, y, z = player:GetX(), player:GetY(), player:GetZ()
	
    if player:GetMap():GetHeight(x, y) and not player:IsOnVehicle()
	and not (HasBuff(player, BUFFIDS)) and player:IsMoving()
	and not player:HasAura(59656) and not player:IsFlying() then

        if not player:HasAura(546) and not player:HasAura(75341) -- Water walk and similar auras
		and not player:HasAura(74079) and not player:HasAura(61922)
		and not player:HasAura(3714) and not player:HasAura(11319)
		and not player:HasAura(10665) and not player:HasAura(8827)
		and not player:HasAura(3714) and not player:HasAura(1706)
		and not player:HasAura(30424) and not player:HasAura(51358)
		and not player:HasAura(61174) and not player:HasAura(58258)
		and not player:HasAura(punishmentId) and not player:IsInWater()
		and ((skipTeleportCheck[guid] and skipTeleportCheck[guid] < os.time()) or not skipTeleportCheck[guid]) then
		
			if not playerZMovementTable[guid] then
				playerZMovementTable[guid] = {
					lastZ = z,
					checkCount = 0,
					teleported = false
				}
			end

			local playerData = playerZMovementTable[guid]
				
				if math.abs(playerData.lastZ - z) <= 0.05 then
					playerData.checkCount = playerData.checkCount + 1
				else
					playerData.checkCount = 0
					playerData.lastZ = z
					playerData.teleported = false
				end

				if playerData.checkCount == 3 then
					local isNearObstacle = checkObstaclesForPlayer(player)
					if not isNearObstacle then
						--print("Checking "..player:GetName().." for water or Z-locked walking!")
						if playerWarningEnabled == 1 then
							if player:GetGMRank() == 0  then
								player:SendAreaTriggerMessage("You have been detected using water walk or Z lock hack!")
							end
						end
						if GMwarningEnabled == 1 then
							local GMs = GetPlayersInWorld()
							for _, GM in pairs(GMs) do
								if GM:GetGMRank() >= 1 then
									GM:SendAreaTriggerMessage("|cFFFF66FF[Nick's Anticheat] Player "..player:GetName().." has been detected using water walk or Z lock hack!|r")
								end
							end
						end
						if punishmentEnabled == 1 then
							player:AddAura(punishmentId, player)
							if player:GetGMRank() > 0 then
								player:SendBroadcastMessage("Use command '.unaura "..punishmentId.."' to move again. Only GMs can see this message.")
							end
							if not hackReports[guid] then
								hackReports[guid] = 1 else hackReports[guid] = hackReports[guid] + 1 end
							end
							print("[Anticheat Module]: Z and water walk anti cheat - Player " .. player:GetName() .. " might be water walk or Z lock hacking!")		
						end
                playerData.checkCount = 0
                playerData.teleported = false
            end
        end
    end
end

local function checkWallClimb(eventId, delay, repeats)
    for _, player in pairs(GetPlayersInWorld()) do
        local guid = player:GetGUIDLow()
        
		
        if player:IsInWorld() then
            -- Check if there's nothing within LOS for specified distances
            local checkDistances = {0.2, 0.5, 1, 2, 5}
            allClear[guid] = true
			
			
			if knockBackAckTime[guid] and knockBackAckTime[guid] > os.time() then
				--print("player immune to wall hack check")
				break
			elseif knockBackAckTime[guid] and knockBackAckTime[guid] <= os.time() then
				knockBackAckTime[guid] = nil
			end
            
            for _, distance in ipairs(checkDistances) do
                if player:IsWithinLoS(player:GetX(), player:GetY(), player:GetZ() + distance) then
                    allClear[guid] = false
                    break
                end
            end
            
            if allClear[guid] then
				--print("all clear")
                return -- Exit the function if all LOS checks are clear
            end
		
			if not player:IsMoving() then
				playerLastSteepness1X[guid] = nil
				playerLastSteepness1Y[guid] = nil
				playerLastSteepness1Z[guid] = nil
				playerLastSteepness2X[guid] = nil
				playerLastSteepness2Y[guid] = nil
				playerLastSteepness2Z[guid] = nil
			end
			
			if player:IsMounted() then
				mountCache[guid] = 1
			elseif not player:IsMounted() and mountCache[guid] == 1 then
				mountCache[guid] = os.time() + 5 
			elseif mountCache[guid] and mountCache[guid] < os.time() then
				mountCache[guid] = 0
			end
						
			if knockedBackCheck[guid] and knockedBackCheck[guid] < os.time() then
				knockedBackCheck[guid] = nil
			end
			
			if not player:IsFlying() and player:IsMoving()
			and not player:IsFalling() and not player:CanFly() and not player:IsInWater()
			and not player:HasItem(49278, 1) and not knockedBackCheck[guid]
			and ((mountCache[guid] and mountCache[guid] < os.time()) or not mountCache[guid])
			and ((knockBackAckTime[guid] and knockBackAckTime[guid] <= os.time())or not knockBackAckTime[guid]) then
			
				if (not playerJumps[guid] or playerJumps[guid] == 0) then
					
					if wallClimbCheckCount < wallClimbResetCount then
						wallClimbCheckCount = wallClimbCheckCount + 1
					elseif wallClimbCheckCount >= wallClimbResetCount then
						wallClimbCheckCount = 0
						wallClimbHackCount[guid] = 0
					end
					
					if not playerLastSteepness1Z[guid] or player:GetZ() < playerLastSteepness1Z[guid] then
						playerLastSteepness1X[guid] = player:GetX()
						playerLastSteepness1Y[guid] = player:GetY()
						playerLastSteepness1Z[guid] = player:GetZ()
						playerLastSteepness2X[guid] = player:GetX()
						playerLastSteepness2Y[guid] = player:GetY()
						playerLastSteepness2Z[guid] = player:GetZ()
						playerLastSteepnessToggle[guid] = false
					elseif player:GetZ() > playerLastSteepness1Z[guid] then
						if not playerLastSteepnessToggle[guid] then
							playerLastSteepness2X[guid] = player:GetX()
							playerLastSteepness2Y[guid] = player:GetY()
							playerLastSteepness2Z[guid] = player:GetZ()
							playerLastSteepnessToggle[guid] = true
						else
							playerLastSteepness1X[guid] = player:GetX()
							playerLastSteepness1Y[guid] = player:GetY()
							playerLastSteepness1Z[guid] = player:GetZ()
							playerLastSteepnessToggle[guid] = false
						end
					end
									
					if playerLastSteepness1Z[guid] and playerLastSteepness2Z[guid] then
					
						--print("Position 1. Z: "..playerLastSteepness1Z[guid])
						--print("Position 2. Z: "..playerLastSteepness2Z[guid])
						
						local zDiff
						if playerLastSteepness2Z[guid] - playerLastSteepness1Z[guid] > 0 then
							zDiff = playerLastSteepness2Z[guid] - playerLastSteepness1Z[guid]
						else
							zDiff = 0
						end
						
						--print(zDiff)
						
						if zDiff > ZchangeThreshold then
							local horizontalDist = math.sqrt((playerLastSteepness1X[guid] - playerLastSteepness2X[guid])^2 + (playerLastSteepness1Y[guid] - playerLastSteepness2Y[guid])^2)

							local gradient = zDiff / horizontalDist
							
							--print("Steepness for "..player:GetName()..": "..gradient)

							if gradient > maxSteepness*2 then -- Basically if players walk up 90-degree hills, this kicks in
								if playerWarningEnabled == 1 then
									if player:GetGMRank() == 0  then
										player:SendAreaTriggerMessage("You have been detected using wall climb/jump hack!")
									end
								end
								if GMwarningEnabled == 1 then
									local GMs = GetPlayersInWorld()
									for _, GM in pairs(GMs) do
										if GM:GetGMRank() >= 1  then
											GM:SendAreaTriggerMessage("|cFFFF66FF[Nick's Anticheat] Player "..player:GetName().." has been detected using wall climb/jump hack!|r")
										end
									end
								end
								if punishmentEnabled == 1 then
									player:AddAura(punishmentId, player)
									if player:GetGMRank() > 0 then player:SendBroadcastMessage("Use command '.unaura "..punishmentId.."' to move again. Only GMs can see this message.") end
									if not hackReports[guid] then hackReports[guid] = 1 else hackReports[guid] = hackReports[guid] + 1 end
								end
								print("[Anticheat Module]: Anti wall climb hack - Wall climb hack detected on "..player:GetName())
							elseif gradient > maxSteepness then
								--print("[Anticheat Module]: Anti wall climb hack - Possible hack detected on "..player:GetName())
								if not wallClimbHackCount[guid] then
									wallClimbHackCount[guid] = 1
								elseif wallClimbHackCount[guid] < maxWallHackCount-1 then
									wallClimbHackCount[guid] = wallClimbHackCount[guid] + 1
								elseif wallClimbHackCount[guid] >= maxWallHackCount-1 then
									if playerWarningEnabled == 1 then
										if player:GetGMRank() == 0  then
											player:SendAreaTriggerMessage("You have been detected using wall climb/jump hack!")
										end
									end
									if GMwarningEnabled == 1 then
										local GMs = GetPlayersInWorld()
										for _, GM in pairs(GMs) do
											if GM:GetGMRank() >= 1  then
												GM:SendAreaTriggerMessage("|cFFFF66FF[Nick's Anticheat] Player "..player:GetName().." has been detected using wall climb/jump hack!|r")
											end
										end
									end
									if punishmentEnabled == 1 then
										player:AddAura(punishmentId, player)
										if player:GetGMRank() > 0 then player:SendBroadcastMessage("Use command '.unaura "..punishmentId.."' to move again. Only GMs can see this message.") end
										if not hackReports[guid] then hackReports[guid] = 1 else hackReports[guid] = hackReports[guid] + 1 end
									end
									print("[Anticheat Module]: Anti wall climb hack - Wall hack detected on "..player:GetName())
								end
							end
						end
					end
				end
			end
		end
    end
end

local function knockBackCheck(event, packet, player)
	if not player then return end
	local guid = player:GetGUIDLow()
	knockedBackCheck[guid] = os.time() + 2 -- 2 sec immunity to wall climb check if player is knocked back
	--print("Player "..player:GetName().." got knocked back!")
end

local function onZUpdate()
    for _, player in ipairs(GetPlayersInWorld()) do
        checkPlayerZMovement(player)
    end
end

local function onPrison(event, player) -- Part of anti stuck
    local guid = player:GetGUIDLow()
	if imprisoned[guid] then
		if imprisoned[guid] >= 2 then
			imprisoned[guid] = imprisoned[guid] - 1
		elseif imprisoned[guid] == 1 then
			imprisoned[guid] = imprisoned[guid] - 1
			--print("Player "..player:GetName().." released from prison")
		end
	end
end

local function onLogin(event, player) -- Part of anti stuck and helps initiate anti teleport hack and anti speed hack
    local guid = player:GetGUIDLow()
	
	if player:IsFlying() then
		lastMoveType[guid] = 6
		maxSpeed = player:GetSpeed(lastMoveType[guid])
	elseif player:IsUnderWater() then
		lastMoveType[guid] = 3
		maxSpeed = player:GetSpeed(lastMoveType[guid])
	else
		lastMoveType[guid] = 1
		maxSpeed = player:GetSpeed(lastMoveType[guid])
	end
	
	speedHackGraceTimer[guid] = 0
	
	if antiTeleportHack == 1 then
		local query = CharDBQuery("SELECT LENGTH(taxi_path) FROM characters WHERE guid = " .. guid)
		
		if query then
			local length = query:GetUInt32(0)
			-- Check if the length of taxi_path is greater than 1 (indicating more than 1 byte of information)
			if length > 1 then
				skipTeleportCheck[guid] = os.time() + 20 * 60 -- Set skipTeleportCheck to current time + 15 minutes
				player:SendBroadcastMessage("Teleport check skipped for 20 minutes.")
			else
				player:SendBroadcastMessage("No active taxi path.")
			end
		else
			player:SendBroadcastMessage("Error: Could not retrieve taxi path information.")
		end
	end
	
	if player:GetMapId() == 13 then
		imprisoned[guid] = 1 
	end	
	
	if player:GetGMRank() > 0 then
		GMsingame[guid] = 1
	end
end

local function onLogout(event, player)
    local guid = player:GetGUIDLow()
    playerZMovementTable[guid] = nil -- Clears Z freeze / water walk check
	
	if player:GetGMRank() > 0 then
		GMsingame[guid] = nil
	end
end

local function ResetHackCount()
    for guid, _ in pairs(hackReports) do
        local player = GetPlayerByGUID(guid)
		hackReports[guid] = 0
    end
end

local function KickMaxHackers()
    for guid, _ in pairs(hackReports) do
		if not player then return end
        local player = GetPlayerByGUID(guid)
		
		local players = GetPlayersInWorld()
		for _, player in pairs(players) do
		
			if hackReportsLimit > 0 and hackReports[guid] > hackReportsLimit then
				if punishmentEnabled == 1 and player:GetGMRank() == 0 then
					player:LogoutPlayer()
				end
				if player:GetGMRank() >= 1 then
					GM:SendAreaTriggerMessage("|cFFFF66FF[Nick's Anticheat] Hacker "..player:GetName().." kicked for too many strikes!|r")
				end
				hackReports[guid] = 0
				print("[Anticheat Module]: Hacker "..player:GetName().." kicked for too many strikes!")
			elseif hackReports[guid] > 0 then
				print("[Anticheat Module]: Current hack report counts: "..player:GetName()..", number of hacks: "..hackReports[guid].." in the last 5 minutes.")
				if player:GetGMRank() >= 1 then
					GM:SendBroadcastMessage("[Anticheat Module]: Current hack report counts: "..player:GetName()..", number of hacks: "..hackReports[guid].." in the last 5 minutes.")
				end
			end
		end
	end
end

local function onLoadEluna()
	if antiFlightHack == 1 then
		CreateLuaEvent(processFlightVerification, FlightVerificationFrequency, 0)
	end
	
	if punishmentEnabled == 1 then
		CreateLuaEvent(CleanupGroundedPlayers, groundedDuration, 0)
	end
	
	if antiGargarinSpeedHack == 1 then
		CreateLuaEvent(ResetSpeedHackCount, resetSpeedHackTimer-1, 0)
		CreateLuaEvent(ResetJumpHackCount, resetJumpHackTimer-2, 0)
	end
	
	if hackReportsLimit > 0 then -- Runs once per minute
		CreateLuaEvent(KickMaxHackers, 60*1000, 0)
		CreateLuaEvent(ResetHackCount, 5*60*1000, 0)
	end
	
	if antiZorWaterWalkHack == 1 then
		CreateLuaEvent(onZUpdate, 1000, 0)
	end
	
	if antiMapClipHack == 1 then
		CreateLuaEvent(mapNoClipHack, noClipCheckInterval * 1000, 0)
	end
	
	if antiWallClimbHack == 1 then
		CreateLuaEvent(checkWallClimb, wallHackCheckInterval, 0)
	end
	
    local players = GetPlayersInWorld()
    for _, player in pairs(players) do
        local guid = player:GetGUIDLow()
		
        playerX[guid] = player:GetX()
        playerY[guid] = player:GetY()
        playerZ[guid] = player:GetZ()
		
		notTeleporting[guid] = 0
		speedHackGraceTimer[guid] = 0
		
		if player:IsOnVehicle() or player:HasAura(59656) then return end

		if player:IsFlying() then
			lastMoveType[guid] = 6
			maxSpeed = player:GetSpeed(lastMoveType[guid])
		elseif player:IsUnderWater() then
			lastMoveType[guid] = 3
			maxSpeed = player:GetSpeed(lastMoveType[guid])
		else
			lastMoveType[guid] = 1
			maxSpeed = player:GetSpeed(lastMoveType[guid])
		end
    end
end

-- Event initializations

RegisterPlayerEvent(4, onLogout)

if antiGMIsland == 1 then
	RegisterPlayerEvent(27, antiGMIslandCheat)
end

if antiFlightHack == 1 then
	RegisterPacketEvent(0x345, 5, antiFly)
	RegisterPacketEvent(0x346, 5, antiFly)
end

if antiGeneralSpeedHack == 1 or antiStuckHack == 1 then
	RegisterPacketEvent(0x0EE, 5, antiGeneralSpeedandStuck)
	RegisterPacketEvent(0x0B5, 5, antiGeneralSpeedandStuck)
	RegisterPacketEvent(0x0B6, 5, antiGeneralSpeedandStuck)
	RegisterPacketEvent(0x0B7, 5, antiGeneralSpeedandStuck)
	RegisterPacketEvent(0x0B8, 5, antiGeneralSpeedandStuck)
	RegisterPacketEvent(0x0AB, 5, antiGeneralSpeedandStuck) -- On use item
	RegisterPacketEvent(0x0BB, 5, antiGeneralSpeedandStuck) -- If player jumps, we reduce their speed hack count slightly as jumping is prone to false positives
	RegisterPacketEvent(0x0DA, 5, antiGeneralSpeedandStuck)
	RegisterPacketEvent(0x0DB, 5, antiGeneralSpeedandStuck)
	RegisterPacketEvent(0x0B9, 5, antiGeneralSpeedandStuck)
	RegisterPacketEvent(0x12E, 5, antiGeneralSpeedandStuck) -- Including spell cast to trigger speed check as some spells induce movement
	RegisterPacketEvent(0x0BA, 5, antiGeneralSpeedandStuck)
	RegisterPlayerEvent(3, onLogin)
end

if antiAirJumpHack == 1 then
	RegisterPacketEvent(0x0BB, 5, antiJump)
	RegisterPacketEvent(0x0C9, 5, antiJump)
	RegisterPacketEvent(0x0CA, 5, antiJump)
end

if antiAirJumpHack == 1 or antiGeneralSpeedHack == 1 or antiStuckHack == 1 or antiKnockBackHack == 1 then
	RegisterPacketEvent(0x0EF, 7, knockBackCheck)
end

if antiGargarinSpeedHack == 1 then
	RegisterPacketEvent(0x2CE, 5, antiGargarinSpeed)
end

if cacheOnLoadEluna == 1 then -- This initiates all cache, loads all live data required before functions break, and schedules periodic events
	RegisterServerEvent(33, onLoadEluna)
end

if antiStuckHack == 1 then
	RegisterPlayerEvent(28, onPrison)
	if not antiTeleportHack == 1 then
		RegisterPlayerEvent(3, onLogin)
	end
end

if antiKnockBackHack == 1 then
	local function antiKnockBackAck()
		for playerGUID, _ in pairs(knockBackAck) do
			local player = GetPlayerByGUID(playerGUID)
			--print("Checking for knocked back player")
			if player then
			--print("Knockbacked back player found: "..player:GetName())
				local guid = player:GetGUIDLow()
				if not knockBackAckTime[guid] or knockBackAckTime[guid] < os.time() then
					if playerWarningEnabled == 1 then
						if player:GetGMRank() == 0  then
							player:SendAreaTriggerMessage("You have been detected using anti knockback hack!")
						end
					end
					if GMwarningEnabled == 1 then
						local GMs = GetPlayersInWorld()
						for _, GM in pairs(GMs) do
							if GM:GetGMRank() >= 1 then
								GM:SendAreaTriggerMessage("|cFFFF66FF[Nick's Anticheat] Player "..player:GetName().." has been detected using anti knockback hack!|r")
							end
						end
					end
					if punishmentEnabled == 1 then
						player:AddAura(punishmentId, player)
						if player:GetGMRank() > 0 then player:SendBroadcastMessage("Use command '.unaura "..punishmentId.."' to move again. Only GMs can see this message.") end
						if not hackReports[guid] then hackReports[guid] = 1 else hackReports[guid] = hackReports[guid] + 1 end
					end
					print("[Anticheat Module]: Anti knockback hack - Hack detected on "..player:GetName())
				else
					knockBackAck[guid] = nil
				end
			end
		end
	end
	
	local function serverKnockBack(event, packet, player) 
		if not player then return end
		local guid = player:GetGUIDLow()
		knockBackAck[guid] = player:GetGUID()
		player:RegisterEvent(antiKnockBackAck, 1000, 1, knockBackAck[guid])
		--print("Knockback hack server side initialized")
	end
	
	local function clientKnockBackAck(event, packet, player) 
		if not player then return end
		local guid = player:GetGUIDLow()
		knockBackAckTime[guid] = os.time() + 10
		--print("Knockback hack client side registered")
	end

	RegisterPacketEvent(0x0EF, 7, serverKnockBack)
	RegisterPacketEvent(0x0F0, 5, clientKnockBackAck)
end

if antiTeleportHack == 1 then
	RegisterPacketEvent(0x095, 5, clientSideTeleportCheck)
	RegisterPacketEvent(0x097, 5, clientSideTeleportCheck)
	RegisterPacketEvent(0x098, 5, clientSideTeleportCheck)
	RegisterPacketEvent(0x12E, 5, clientSideTeleportCheck)
	RegisterPacketEvent(0x136, 5, clientSideTeleportCheck)
	RegisterPacketEvent(0x0C2, 5, clientSideTeleportCheck)
	RegisterPacketEvent(0x0C3, 5, clientSideTeleportCheck)
	RegisterPacketEvent(0x0B5, 5, clientSideTeleportCheck)
	RegisterPacketEvent(0x0B6, 5, clientSideTeleportCheck)
	RegisterPacketEvent(0x0B7, 5, clientSideTeleportCheck)
	RegisterPacketEvent(0x0B8, 5, clientSideTeleportCheck)
	RegisterPacketEvent(0x0B9, 5, clientSideTeleportCheck)
	RegisterPacketEvent(0x0BA, 5, clientSideTeleportCheck)
	RegisterPacketEvent(0x0BB, 5, clientSideTeleportCheck)
	RegisterPacketEvent(0x0BC, 5, clientSideTeleportCheck)
	RegisterPacketEvent(0x0BD, 5, clientSideTeleportCheck)
	RegisterPacketEvent(0x0BE, 5, clientSideTeleportCheck)
	RegisterPacketEvent(0x0BF, 5, clientSideTeleportCheck)
	RegisterPacketEvent(0x1F4, 5, clientSideTeleportCheck)
	RegisterPacketEvent(0x391, 5, clientSideTeleportCheck)
	RegisterPacketEvent(0x4F7, 5, clientSideTeleportCheck)
	RegisterPacketEvent(0x096, 5, clientSideTeleportCheck)
	RegisterPacketEvent(0x3B3, 5, clientSideTeleportCheck)
	RegisterPacketEvent(0x0A9, 7, serverSideTeleportCheck)
	RegisterPacketEvent(0x0AA, 7, serverSideTeleportCheck)
	RegisterPacketEvent(0x0C7, 7, serverSideTeleportCheck)
	RegisterPacketEvent(0x4F7, 7, serverSideTeleportCheck)
	RegisterPacketEvent(0x390, 7, serverSideTeleportCheck)
	RegisterPacketEvent(0x043, 7, serverSideTeleportCheck)
	RegisterPacketEvent(0x1AE, 7, serverSideTeleportCheck)
end

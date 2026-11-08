if GetStateMapId() ~= 724 then return end
-- NPCs
local HALION_ENTRY          = 39863
local COMBUSTION_ENTRY      = 40001
local CONSUMPTION_ENTRY     = 40135
local METEOR_STRIKES_ENTRY  = {40029, 40041, 40042, 40043, 40044, 40055}

local HALION_INSIDE_ENTRY   = 40142
local CONSUMPTION_ENTRY     = 40135
local SHADOW_ORBS			= {40083, 40100, 40468, 40469}

local TWILIGHT_PORTAL_OUTSIDE	= {202794, 202795}
local TWILIGHT_PORTAL_INSIDE 	= 202796

local COMBUSTION_AURA       = 74562
local CONSUMPTION_AURA      = 74792
local TWILIGHT_REALM        = 74807

local PULL_POS              = {3142.5, 534.3, 72.88}
local ORB_CENTER_POS        = {3153.75, 533.19, 72.88}

local AVERAGE_BOSS_DISTANCE        = 20
local AVERAGE_BOSS_DISTANCE_INSIDE = 20
local SPREAD_FACTOR                = 12
local SPREAD_FACTOR_INSIDE         = 5

local PORTAL_DISTANCE              = 8
local AOE_AVOIDANCE_DISTANCE       = 15

local TICK_FREQUENCY        = 200

local function HalionInsideLoop(eventId, delay, repeats, player)
    if not player:HasAura(TWILIGHT_REALM) or not player:IsInCombat() then
        StopLuaEvent(player)
        return
    end
    
    local halionInside = player:GetNearestCreature(100, HALION_INSIDE_ENTRY)
    
    if not halionInside then
        player:RegisterEvent(HalionInsideLoop, TICK_FREQUENCY, 1)
        return
    end
    
    local mainTank, offTank = IdentifyTanks(halionInside)
    local mainTankIsBot = mainTank and mainTank:IsBot() or false
    local offTankIsBot = offTank and offTank:IsBot() or false
    
    local insideTank = nil
    local insideTankIsBot = false
    
    if mainTank and mainTank:HasAura(TWILIGHT_REALM) then
        insideTank = mainTank
        insideTankIsBot = mainTankIsBot
    elseif offTank and offTank:HasAura(TWILIGHT_REALM) then
        insideTank = offTank
        insideTankIsBot = offTankIsBot
    end
	
	if IsTank(player) and (player:GetClass() == 11) and not player:HasAura(9634) then
		player:AddAura(9634, player) -- Foolproof druid tanks that sometimes shift out of form mid-fight
	end
    
    if insideTank and insideTankIsBot then
        if halionInside:IsCasting() and player == insideTank then
            UseDefensive(player)
        end
    end
    
    if not player:HasAura(CONSUMPTION_AURA) then
        player:Data():Set("ConsumptionPos", nil)
    end
    
    if player == insideTank and insideTankIsBot then
        local insideVictim = halionInside:GetVictim()
        if insideVictim and insideVictim ~= player then
            halionInside:AddThreat(player, 10000 + math.random(-500, 500))
            Taunt(player, halionInside, true)
        end

		local nextCutterTime = halionInside:Data():Get("NextCutterTime")
		local cutterEndPos = halionInside:Data():Get("CutterEndPos")
		local ocX, ocY, ocZ = ORB_CENTER_POS[1], ORB_CENTER_POS[2], ORB_CENTER_POS[3]		
		local shouldTrailOrb = false
		
		if not nextCutterTime then
			shouldTrailOrb = true
			halionInside:Data():Set("CutterActive", true)
		elseif (nextCutterTime - os.time()) < 2 or (nextCutterTime - os.time()) > 24 then
			halionInside:Data():Set("CutterEndPos", {x = player:GetX(), y = player:GetY()})
			shouldTrailOrb = true
			halionInside:Data():Set("CutterActive", true)
		else
			shouldTrailOrb = false
			halionInside:Data():Set("CutterActive", false)
		end
        
		if shouldTrailOrb then -- Trail cutter
			local ocX, ocY, ocZ = ORB_CENTER_POS[1], ORB_CENTER_POS[2], ORB_CENTER_POS[3]
			local shadowOrbs = {}
			
			for _, entry in ipairs(SHADOW_ORBS) do
				local orbs = player:GetCreaturesInRange(100, entry)
				for _, orb in ipairs(orbs) do
					table.insert(shadowOrbs, orb)
				end
			end

			if #shadowOrbs >= 1 then
				local px, py = player:GetLocation()
				local closestOrb = nil
				local closestDist = 999999
				
				for _, orb in ipairs(shadowOrbs) do
					local ox, oy = orb:GetLocation()
					local dist = math.sqrt((ox - px)^2 + (oy - py)^2)
					if dist < closestDist then
						closestDist = dist
						closestOrb = orb
					end
				end
				
				local orb1X, orb1Y = closestOrb:GetLocation()
				
				local angleToOrb = math.atan2(orb1Y - ocY, orb1X - ocX)
				local tankAngle = angleToOrb - math.rad(38)
				
				local targetX = ocX + (10 * math.cos(tankAngle))
				local targetY = ocY + (10 * math.sin(tankAngle))
				
				player:MoveTo(1, targetX, targetY, ocZ, true)
				
				if IsAtPos(player, targetX, targetY, 2) then
					local hix, hiy = halionInside:GetLocation()
					local distToCenter = math.sqrt((hix - ocX)^2 + (hiy - ocY)^2)
					if distToCenter > 3 then
						halionInside:MoveTo(1, ocX, ocY, ocZ, true)
					end
				end
			end
		elseif cutterEndPos then
		    local angleToEndPos = math.atan2(cutterEndPos.y - ocY, cutterEndPos.x - ocX)
			local targetAngle = angleToEndPos - math.rad(30) -- 30 degree trail in front of nearest shadow orb
			local targetX = ocX + (10 * math.cos(targetAngle))
			local targetY = ocY + (10 * math.sin(targetAngle))
			
			if not IsAtPos(player, targetX, targetY, 2) then
				player:MoveTo(1, targetX, targetY, ocZ, true)
			end
		else -- If no cutter spot found, just ensure we are close to center of circle
			local px, py = player:GetLocation()
			local distToCenter = math.sqrt((px - ocX)^2 + (py - ocY)^2)
			if distToCenter < 7 or distToCenter > 13 then
				local angle = halionInside:GetO()
				local targetX = ocX + (10 * math.cos(angle))
				local targetY = ocY + (10 * math.sin(angle))
				player:MoveTo(1, targetX, targetY, ocZ, true)
			end
		end

    elseif player:HasAura(CONSUMPTION_AURA) then
        local INSIDE_DANGER_NPCS = {CONSUMPTION_ENTRY}
        MoveForConsumption(player, halionInside, INSIDE_DANGER_NPCS)
        
        local targetPos = player:Data():Get("ConsumptionPos")
    elseif not player:Data():Get("OutsideGroup") then
		local INSIDE_DANGER_NPCS = {CONSUMPTION_ENTRY}
		
		local targetPos = player:Data():Get("HalionInsidePos")
		
		if targetPos then
			
			local px, py, pz = player:GetLocation()
			local currentPos = {x = px, y = py, z = pz}
			
			if halionInside and not IsPositionValidInSideArea(currentPos, halionInside, "left", AVERAGE_BOSS_DISTANCE_INSIDE, SPREAD_FACTOR_INSIDE, AOE_AVOIDANCE_DISTANCE, INSIDE_DANGER_NPCS) then
				if IsPositionValidInSideArea(targetPos, halionInside, "left", AVERAGE_BOSS_DISTANCE_INSIDE, SPREAD_FACTOR_INSIDE, AOE_AVOIDANCE_DISTANCE, INSIDE_DANGER_NPCS) then
					player:MoveTo(1, targetPos.x, targetPos.y, targetPos.z, true)
				else
					--print("Inside player " .. player:GetName() .. " saved position also invalid, finding new position")
					FindAndMoveToInsidePosition(player, halionInside, INSIDE_DANGER_NPCS)
				end
			end
		else
			FindAndMoveToInsidePosition(player, halionInside, INSIDE_DANGER_NPCS)
		end
	end
    
    player:RegisterEvent(HalionInsideLoop, TICK_FREQUENCY, 1)
end

local function HalionLoop(eventId, delay, repeats, halion)
    if halion:IsDead() or not halion:IsInCombat() then
        halion:Data():Set("PortalTransitionPrinted", nil)
        StopLuaEvent(halion)
        return
    end
    
    local bots = GetAllBotsInInstance(halion)
    
    if #bots == 0 then StopLuaEvent(halion) return end
    
    local mainTank, offTank = IdentifyTanks(halion)
    local mainTankIsBot = mainTank and mainTank:IsBot() or false
    local offTankIsBot = offTank and offTank:IsBot() or false
    
    local healers = {}
    for _, player in ipairs(bots) do
        if player:HasHealSpec() then
            table.insert(healers, player)
        end
    end
    table.sort(healers, function(a, b) return a:GetMaxPower(0) > b:GetMaxPower(0) end)
    
    halion:Data():Set("CombatTime", (halion:Data():Get("CombatTime") or 0) + TICK_FREQUENCY)
    
    local victim = halion:GetVictim()
    
    local DANGER_NPCS = {COMBUSTION_ENTRY}
    for _, id in ipairs(METEOR_STRIKES_ENTRY) do
        table.insert(DANGER_NPCS, id)
    end
    
    if halion:IsCasting() then 
        if mainTank and mainTankIsBot and not mainTank:HasAura(TWILIGHT_REALM) then
            UseDefensive(mainTank)
        end
        if offTank and offTankIsBot and not offTank:HasAura(TWILIGHT_REALM) then
            UseDefensive(offTank)
        end
    end

    if victim and victim:IsPlayer() then
        if IsAtPos(victim, ORB_CENTER_POS[1], ORB_CENTER_POS[2], 13) then
            if not IsAtPos(halion, ORB_CENTER_POS[1], ORB_CENTER_POS[2], 3) then
                halion:MoveTo(1, ORB_CENTER_POS[1], ORB_CENTER_POS[2], ORB_CENTER_POS[3], true)
            end
        end
	
		if IsTank(victim) and (victim:GetClass() == 11) and not victim:HasAura(9634) then
			victim:AddAura(9634, victim) -- Foolproof druid tanks that sometimes shift out of form mid-fight
		end
    end
    
	CheckIfPlayerNeedsDispel(halion)
	
    for _, player in ipairs(bots) do
        DisableManualSpells(player)
        
        if not player:HasAura(TWILIGHT_REALM) then
            if player:HasAura(COMBUSTION_AURA) then 
                MoveForCombustion(player, halion, DANGER_NPCS)
            else
                local isMainTankBot = (player == mainTank and mainTankIsBot)
                local isOffTankBot = (player == offTank and offTankIsBot)
                
				if isOffTankBot and not player:HasAura(TWILIGHT_REALM) then
					if victim and victim ~= player then
						halion:AddThreat(player, 10000 + math.random(-500, 500))
						Taunt(player, halion, false)
					end
					if halion:Data():Get("CombatTime") < 5000 then
						player:MoveTo(1, PULL_POS[1], PULL_POS[2], PULL_POS[3], true)
					else
						local dangerNpcs = {}
						for _, entry in ipairs(DANGER_NPCS) do
							local npcs = player:GetCreaturesInRange(100, entry)
							for _, npc in ipairs(npcs) do
								table.insert(dangerNpcs, npc)
							end
						end
						
						local meteorNearby = false
						local px, py = player:GetLocation()
						for _, npc in ipairs(dangerNpcs) do
							local nx, ny = npc:GetLocation()
							local dist = math.sqrt((px - nx)^2 + (py - ny)^2)
							if dist < 10 then
								meteorNearby = true
								break
							end
						end
						
						if meteorNearby then
							if not player:HasAura(71635) then
								player:AddAura(71635, player)
							end
							if not player:HasAura(71638) then
								player:AddAura(71638, player)
							end
						end
						
						if not IsAtPos(player, PULL_POS[1], PULL_POS[2], 3) then
							player:MoveTo(1, PULL_POS[1], PULL_POS[2], PULL_POS[3], true)
						end
					end
				end
			end
        end
    end

	if halion:GetHealthPct() >= 75 or halion:GetHealthPct() < 50 then
		local portalTransitionSafe = false
		
		if halion:GetHealthPct() < 50 then
			local halionInside = nil
			for _, p in ipairs(bots) do
				if p:HasAura(TWILIGHT_REALM) then
					halionInside = p:GetNearestCreature(100, HALION_INSIDE_ENTRY)
					break
				end
			end
			
			if halionInside then
				local cutterActive = halionInside:Data():Get("CutterActive") or false
				portalTransitionSafe = not cutterActive
			end
		end
		
		local METEOR_NPCS = {}
		for _, id in ipairs(METEOR_STRIKES_ENTRY) do
			table.insert(METEOR_NPCS, id)
		end
		
		local POSITION_DANGER_NPCS = {COMBUSTION_ENTRY}
		for _, id in ipairs(METEOR_STRIKES_ENTRY) do
			table.insert(POSITION_DANGER_NPCS, id)
		end
		
		local tanks = {}
		for _, player in ipairs(bots) do
			if IsTank(player) then
				table.insert(tanks, player)
			end
		end
		table.sort(tanks, function(a, b) return a:GetMaxHealth() > b:GetMaxHealth() end)
		
		local leftMeteors = 0
		local rightMeteors = 0
		
		local totalMeteors = 0
		for _, entry in ipairs(METEOR_STRIKES_ENTRY) do
			local meteors = halion:GetCreaturesInRange(100, entry)
			totalMeteors = totalMeteors + #meteors
			for _, meteor in ipairs(meteors) do
				local mx, my = meteor:GetLocation()
				local hx, hy = halion:GetLocation()
				local angle = math.atan2(my - hy, mx - hx)
				local facingAngle = halion:GetO()
				local relativeAngle = angle - facingAngle
				
				while relativeAngle > math.pi do relativeAngle = relativeAngle - 2 * math.pi end
				while relativeAngle < -math.pi do relativeAngle = relativeAngle + 2 * math.pi end
				
				if relativeAngle > math.pi / 4 and relativeAngle < 3 * math.pi / 4 then
					leftMeteors = leftMeteors + 1
				elseif relativeAngle < -math.pi / 4 and relativeAngle > -3 * math.pi / 4 then
					rightMeteors = rightMeteors + 1
				end
			end
		end
		
		local groupSide = leftMeteors <= rightMeteors and "left" or "right"
		
		local lastLeftMeteors = halion:Data():Get("LastLeftMeteors") or 0
		local lastRightMeteors = halion:Data():Get("LastRightMeteors") or 0
		
		if leftMeteors ~= lastLeftMeteors or rightMeteors ~= lastRightMeteors then
			--print("Left meteors: " .. leftMeteors .. ", Right meteors: " .. rightMeteors .. ", Assigned side: " .. groupSide)
			halion:Data():Set("LastLeftMeteors", leftMeteors)
			halion:Data():Set("LastRightMeteors", rightMeteors)
		end
		
		if totalMeteors == 0 then
			groupSide = halion:Data():Get("LastValidGroupSide") or "left"
		else
			halion:Data():Set("LastValidGroupSide", groupSide)
		end

		local currentMeteor40055 = {}
		for _, entry in ipairs({40055}) do
			local meteors = halion:GetCreaturesInRange(100, entry)
			for _, meteor in ipairs(meteors) do
				table.insert(currentMeteor40055, meteor:GetGUID())
			end
		end
		
		local lastMeteor40055 = halion:Data():Get("LastMeteor40055") or {}
		local newMeteor40055 = false
		
		for _, guid in ipairs(currentMeteor40055) do
			local found = false
			for _, oldGuid in ipairs(lastMeteor40055) do
				if guid == oldGuid then
					found = true
					break
				end
			end
			if not found then
				newMeteor40055 = true
				break
			end
		end
		
		if newMeteor40055 then
			--print("NEW 40055 DETECTED - locking side assignment for 30s")
			halion:Data():Set("SideAssignmentLocked", os.time() + 30)
		end
		
		halion:Data():Set("LastMeteor40055", currentMeteor40055)
		
		for _, player in ipairs(bots) do
			if not player:HasAura(TWILIGHT_REALM) then
				if player ~= victim and player ~= tanks[2]
				and not player:HasAura(COMBUSTION_AURA) and not player:HasAura(CONSUMPTION_AURA)
				and not (portalTransitionSafe and player:Data():Get("InsideGroup")) then
					
					local px, py, pz = player:GetLocation()
					local currentPos = {x = px, y = py, z = pz}
					local isCurrentValid = IsPositionValidInSideArea(currentPos, halion, groupSide, AVERAGE_BOSS_DISTANCE, SPREAD_FACTOR, AOE_AVOIDANCE_DISTANCE, POSITION_DANGER_NPCS)
					
					local lastValid = player:Data():Get("LastPosValid")
					if lastValid ~= isCurrentValid then
						print(player:GetName() .. " position status: " .. (isCurrentValid and "SAFE" or "UNSAFE"))
						player:Data():Set("LastPosValid", isCurrentValid)
					end
					
					if not isCurrentValid then
						local behindWaypoint = player:Data():Get("BehindWaypoint")
						
						if behindWaypoint then
							if not IsAtPos(player, behindWaypoint.x, behindWaypoint.y, 3) then
								DisableSpellCast(player, 0.2)
								player:MoveTo(1, behindWaypoint.x, behindWaypoint.y, behindWaypoint.z, true)
							else
								player:Data():Set("BehindWaypoint", nil)
								local targetPos = player:Data():Get("HalionPos")
								if targetPos then
									DisableSpellCast(player, 0.2)
									player:MoveTo(1, targetPos.x, targetPos.y, targetPos.z, true)
								end
							end
						else
							local targetPos = player:Data():Get("HalionPos")
							local needsReassign = false
							
							if targetPos then
								if not IsPositionValidInSideArea(targetPos, halion, groupSide, AVERAGE_BOSS_DISTANCE, SPREAD_FACTOR, AOE_AVOIDANCE_DISTANCE, POSITION_DANGER_NPCS) then
									needsReassign = true
								else
									local px, py, pz = player:GetLocation()
									local hx, hy = halion:GetLocation()
									local facing = halion:GetO()
									
									local pathCrossesDanger = false
									local numSamples = 10
									
									for i = 1, numSamples do
										local t = i / numSamples
										local sampleX = px + t * (targetPos.x - px)
										local sampleY = py + t * (targetPos.y - py)
										
										local angleToSample = math.atan2(sampleY - hy, sampleX - hx)
										local relativeSample = angleToSample - facing
										
										while relativeSample > math.pi do relativeSample = relativeSample - 2 * math.pi end
										while relativeSample < -math.pi do relativeSample = relativeSample + 2 * math.pi end
										
										if relativeSample >= -math.pi/4 and relativeSample <= math.pi/4 then
											pathCrossesDanger = true
											break
										end
										
										local samplePos = {x = sampleX, y = sampleY, z = pz}
										if not IsPositionValidInSideArea(samplePos, halion, groupSide, AVERAGE_BOSS_DISTANCE, SPREAD_FACTOR, AOE_AVOIDANCE_DISTANCE, POSITION_DANGER_NPCS) then
											pathCrossesDanger = true
											break
										end
									end
									
									if pathCrossesDanger then
										needsReassign = true
									else
										DisableSpellCast(player, 0.2)
										player:MoveTo(1, targetPos.x, targetPos.y, targetPos.z, true)
									end
								end
							else
								needsReassign = true
							end
							
							if needsReassign then
								HalionAssignPosition(player, halion, groupSide, METEOR_NPCS, POSITION_DANGER_NPCS)
							end
						end
					end
				end
			end
		end
	end

	if halion:GetHealthPct() < 75 and halion:GetHealthPct() >= 50 then
		if not halion:Data():Get("PortalTransitionPrinted") then
			--print("=== PORTAL TRANSITION (75%-50%) ===")
			--print("MainTank: " .. (mainTank and mainTank:GetName() or "none") .. " (Bot: " .. tostring(mainTankIsBot) .. ")")
			--print("OffTank: " .. (offTank and offTank:GetName() or "none") .. " (Bot: " .. tostring(offTankIsBot) .. ")")
			--print("Healer2: " .. (healers[2] and healers[2]:GetName() or "none"))
			halion:Data():Set("PortalTransitionPrinted", true)
			
			for _, player in ipairs(bots) do
				if player == offTank or player == healers[2] then
					player:Data():Set("HalionInsideCheckTime", os.time())
					StartLuaEvent(player, HalionCheckInsideCombat)
				end
			end
		end
		
		local allPlayers = GetPlayersInInstance(halion)
		local tankInside = false
		for _, player in ipairs(allPlayers) do
			if IsTank(player) and player:HasAura(TWILIGHT_REALM) then
				tankInside = true
				break
			end
		end
		
		local nearestPortal = GetNearestObject(halion, "GameObject", TWILIGHT_PORTAL_OUTSIDE, 100)
		
		if nearestPortal and not halion:IsCasting() then
			local portalX, portalY, portalZ = nearestPortal:GetLocation()
			local portalPos = {x = portalX, y = portalY, z = portalZ}
			
			for _, player in ipairs(bots) do
				if player ~= offTank and player ~= healers[2]
				and not player:HasAura(COMBUSTION_AURA) and not player:HasAura(CONSUMPTION_AURA) then
					if not player:HasAura(TWILIGHT_REALM) then                        
						if not IsAtPos(player, portalX, portalY, PORTAL_DISTANCE) or (not IsTank(player) and not tankInside) then
							player:MoveTo(1, portalX, portalY, portalZ, true)
						else
							StartLuaEvent(player, HalionInsideLoop)
							player:AddAura(TWILIGHT_REALM, player)
						end
					end
				end
			end
		end
	end
   
    if halion:GetHealthPct() < 50 then
        HandlePhase3Transition(halion, bots, mainTank, offTank, healers)
    end
	
    halion:RegisterEvent(HalionLoop, TICK_FREQUENCY, 1)
end

local function HalionOnEnterCombat(event, player, halion)
    if halion and halion:GetEntry() == HALION_ENTRY then
        player:Data():Set("HalionPos", nil)
        player:Data():Set("HalionSide", nil)
        player:Data():Set("HalionInsidePos", nil)
        player:Data():Set("HalionInsideSide", nil)
        player:Data():Set("CombustionPos", nil)
        player:Data():Set("ConsumptionPos", nil)
        player:Data():Set("TankSafePos", nil)
        player:Data():Set("OutsideGroup", nil)
        player:Data():Set("InsideGroup", nil)
        player:Data():Set("BehindWaypoint", nil)
        
        halion:Data():Set("CombatTime", 0)
		
		ApplyHiddenBuffsToShadows(player)
        StartLuaEvent(halion, HalionLoop)
    end
end

RegisterPlayerEvent(33, HalionOnEnterCombat)

function HalionCheckInsideCombat(eventId, delay, repeats, player)
    if not player:IsInCombat() then StopLuaEvent(player) return end
    
    local halion = player:GetNearestCreature(100, HALION_ENTRY)
    if not halion then StopLuaEvent(player) return end
    
    if halion:GetHealthPct() < 50 then StopLuaEvent(player) return end

    local instanceId = player:GetInstanceId()
    local map = player:GetMap()
    local allPlayers = map:GetPlayers()
    
    local playersInside = false
    local aliveCount = 0
    
    for _, p in ipairs(allPlayers) do
        if p:GetInstanceId() == instanceId and p:IsInCombat() and p:IsAlive() then
            aliveCount = aliveCount + 1
            if p:HasAura(TWILIGHT_REALM) then
                playersInside = true
            end
        end
    end
    
    local lastAliveCount = halion:Data():Get("LastAliveCount") or aliveCount
	
    halion:Data():Get("LastAliveCount", aliveCount)
    
    if not playersInside and (os.time() > player:Data():Get("HalionInsideCheckTime") + 20) then
        --print("WIPE: No players inside during portal phase")
        player:CastSpell(player, 7, true)
        StopLuaEvent(player)
        return
    end
    
    player:RegisterEvent(HalionCheckInsideCombat, TICK_FREQUENCY, 1)
end

function CheckIfPlayerNeedsDispel(halion)
	local allPlayers = GetPlayersInInstance(halion)
	for _, player in ipairs(allPlayers) do
		if not player:IsBot() then
			if player:HasAura(COMBUSTION_AURA) or player:HasAura(CONSUMPTION_AURA) and (player:GetDistance(ORB_CENTER_POS[1], ORB_CENTER_POS[2], ORB_CENTER_POS[3]) > 40) then
				local nearbyPlayers = player:GetPlayersInRange(40)
				
				for _, bot in ipairs(nearbyPlayers) do
					if bot:IsBot() then
						local class = bot:GetClass()
						if class == 2 or class == 8 or class == 11 or class == 7 or class == 5 then
							RemoveCurseOrMagic(bot, player)
							break
						end
					end
				end
			end
		end
	end
end

function HalionAssignPosition(player, halion, targetSide, sideSelectionDangerNpcs, positionDangerNpcs)
    local savedSide = player:Data():Get("HalionSide")
    local needsSideSwitch = savedSide and savedSide ~= targetSide
    
    if needsSideSwitch then
        local sideAssignmentLocked = halion:Data():Get("SideAssignmentLocked") or 0
		if os.time() < sideAssignmentLocked then
			--print("SIDE SWITCH BLOCKED: " .. player:GetName() .. " - side assignment locked for " .. (sideAssignmentLocked - os.time()) .. "s")
			local savedPos = player:Data():Get("HalionPos")
			local validPos = savedPos
			
			if not savedPos or not IsPositionValidInSideArea(savedPos, halion, savedSide, AVERAGE_BOSS_DISTANCE, SPREAD_FACTOR, AOE_AVOIDANCE_DISTANCE, positionDangerNpcs) then
				validPos = GetRandomValidPositionInSideArea(halion, savedSide, AVERAGE_BOSS_DISTANCE, SPREAD_FACTOR, AOE_AVOIDANCE_DISTANCE, positionDangerNpcs)
			end
			
			if validPos then
				player:Data():Set("HalionPos", validPos)
				local px, py = player:GetLocation()
				local dx = validPos.x - px
				local dy = validPos.y - py
				local distance = math.sqrt(dx*dx + dy*dy)
				if distance > 20 then UseSpeedBuff(player) end
				DisableSpellCast(player, 0.2)
				player:MoveTo(1, validPos.x, validPos.y, validPos.z, true)
			end
			return
		end
        
        local meteorUnderBoss = halion:Data():Get("MeteorUnderBoss") or 0
        if os.time() < meteorUnderBoss then
            --print("SIDE SWITCH BLOCKED: " .. player:GetName() .. " - meteor under boss (blocked for " .. (meteorUnderBoss - os.time()) .. "s)")
            local validPos = GetRandomValidPositionInSideArea(halion, savedSide, AVERAGE_BOSS_DISTANCE, SPREAD_FACTOR, AOE_AVOIDANCE_DISTANCE, positionDangerNpcs)
            if validPos then
                player:Data():Set("HalionPos", validPos)
                local px, py = player:GetLocation()
                local dx = validPos.x - px
                local dy = validPos.y - py
                local distance = math.sqrt(dx*dx + dy*dy)
                if distance > 20 then UseSpeedBuff(player) end
				DisableSpellCast(player, 0.2)
                player:MoveTo(1, validPos.x, validPos.y, validPos.z, true)
            end
            return
        end
        
        local meteorObjects = {}
        for _, entry in ipairs(sideSelectionDangerNpcs) do
            local npcs = halion:GetCreaturesInRange(200, entry)
            for _, npc in ipairs(npcs) do
                table.insert(meteorObjects, npc)
                
                if entry == 40029 then
                    local mx, my = npc:GetLocation()
                    local hx, hy = halion:GetLocation()
                    local distToHalion = math.sqrt((mx - hx)^2 + (my - hy)^2)
                    if distToHalion < 10 then
                        halion:Data():Set("MeteorUnderBoss", os.time() + 35)
                        --print("METEOR UNDER BOSS - blocking side switches for 35s")
                        local validPos = GetRandomValidPositionInSideArea(halion, savedSide, AVERAGE_BOSS_DISTANCE, SPREAD_FACTOR, AOE_AVOIDANCE_DISTANCE, positionDangerNpcs)
                        if validPos then
                            player:Data():Set("HalionPos", validPos)
                            local px, py = player:GetLocation()
                            local dx = validPos.x - px
                            local dy = validPos.y - py
                            local distance = math.sqrt(dx*dx + dy*dy)
                            if distance > 20 then UseSpeedBuff(player) end
							DisableSpellCast(player, 0.2)
                            player:MoveTo(1, validPos.x, validPos.y, validPos.z, true)
                        end
                        return
                    end
                end
            end
        end
        
        if #meteorObjects == 1 then
            local mx, my = meteorObjects[1]:GetLocation()
            local hx, hy = halion:GetLocation()
            local distToHalion = math.sqrt((mx - hx)^2 + (my - hy)^2)
            
            if distToHalion < 10 then
                --print("SIDE SWITCH BLOCKED: " .. player:GetName() .. " - only 1 meteor at " .. string.format("%.1f", distToHalion) .. " yds from boss (need 10+)")
                return
            end
        end
        
        --print("SIDE SWITCH: " .. player:GetName() .. " switching from " .. savedSide .. " to " .. targetSide)
        local hx, hy, hz = halion:GetLocation()
        local facing = halion:GetO()
        local behindAngle = facing + math.pi
        local behindDist = 5
        local behindX = hx + behindDist * math.cos(behindAngle)
        local behindY = hy + behindDist * math.sin(behindAngle)
        
        player:Data():Set("HalionSide", targetSide)
        player:Data():Set("HalionPos", nil)
        player:Data():Set("BehindWaypoint", {x = behindX, y = behindY, z = hz})
        
        UseSpeedBuff(player)
        DisableSpellCast(player, 0.2)
        player:MoveTo(1, behindX, behindY, hz, true)
        return
    end
    
    local validPos = GetRandomValidPositionInSideArea(halion, targetSide, AVERAGE_BOSS_DISTANCE, SPREAD_FACTOR, AOE_AVOIDANCE_DISTANCE, positionDangerNpcs)
    
    if validPos then
        local hx, hy, hz = halion:GetLocation()
        local facing = halion:GetO()
        local px, py, pz = player:GetLocation()
        
        local pathCrossesFront = false
        local numSamples = 10
        
        for i = 1, numSamples do
            local t = i / numSamples
            local sampleX = px + t * (validPos.x - px)
            local sampleY = py + t * (validPos.y - py)
            
            local angleToSample = math.atan2(sampleY - hy, sampleX - hx)
            local relativeSample = angleToSample - facing
            
            while relativeSample > math.pi do relativeSample = relativeSample - 2 * math.pi end
            while relativeSample < -math.pi do relativeSample = relativeSample + 2 * math.pi end
            
            if relativeSample >= -math.pi/4 and relativeSample <= math.pi/4 then
                pathCrossesFront = true
                break
            end
        end
        
        if pathCrossesFront then
            local behindAngle = facing + math.pi
            local behindDist = 5
            local behindX = hx + behindDist * math.cos(behindAngle)
            local behindY = hy + behindDist * math.sin(behindAngle)
            
            player:Data():Set("HalionSide", targetSide)
            player:Data():Set("HalionPos", validPos)
            player:Data():Set("BehindWaypoint", {x = behindX, y = behindY, z = hz})
            
            UseSpeedBuff(player)
			DisableSpellCast(player, 0.2)
            player:MoveTo(1, behindX, behindY, hz, true)
            return
        end
        
        player:Data():Set("HalionSide", targetSide)
        player:Data():Set("HalionPos", validPos)
        
        local dx = validPos.x - px
        local dy = validPos.y - py
        local distance = math.sqrt(dx*dx + dy*dy)
        
        if distance > 30 then
            UseSpeedBuff(player)
        end
        
        DisableSpellCast(player, 0.2)
        player:MoveTo(1, validPos.x, validPos.y, validPos.z, true)
    end
end

function MoveForCombustion(player, halion, dangerNpcEntries)
    local dangerNpcs = {}
    for _, entry in ipairs(dangerNpcEntries) do
        local npcs = player:GetCreaturesInRange(100, entry)
        for _, npc in ipairs(npcs) do
            table.insert(dangerNpcs, npc)
        end
    end
    
    local ocX, ocY, ocZ = ORB_CENTER_POS[1], ORB_CENTER_POS[2], ORB_CENTER_POS[3]
    
    local savedPos = player:Data():Get("CombustionPos")
    
    if savedPos then
        if IsAtPos(player, savedPos.x, savedPos.y, 2) then
            player:CastSpell(player, 4987, true)
            player:Data():Set("CombustionPos", nil)
        else
            UseSpeedBuff(player)
            DisableSpellCast(player, 0.2)
            player:MoveTo(1, savedPos.x, savedPos.y, savedPos.z, true)
        end
        return
    end
    
    local bestX, bestY, bestZ = nil, nil, nil
    local bestDist = 999999
    
    for angle = 0, 350, 10 do
        local rad = math.rad(angle)
        local testX = ocX + (45 * math.cos(rad))
        local testY = ocY + (45 * math.sin(rad))
        
        local valid = true
        for _, danger in ipairs(dangerNpcs) do
            local dx, dy = danger:GetLocation()
            local distToDanger = math.sqrt((testX - dx)^2 + (testY - dy)^2)
            if distToDanger < AOE_AVOIDANCE_DISTANCE then
                valid = false
                break
            end
        end
        
        if valid then
            local px, py = player:GetLocation()
            local dist = math.sqrt((testX - px)^2 + (testY - py)^2)
            if dist < bestDist then
                bestDist = dist
                bestX, bestY, bestZ = testX, testY, ocZ
            end
        end
    end
    
    if bestX then
        player:Data():Set("CombustionPos", {x = bestX, y = bestY, z = bestZ})
        UseSpeedBuff(player)
        DisableSpellCast(player, 0.2)
        player:MoveTo(1, bestX, bestY, bestZ, true)
    end
end

function MoveForConsumption(player, halionInside, dangerNpcEntries)
    local ocX, ocY, ocZ = ORB_CENTER_POS[1], ORB_CENTER_POS[2], ORB_CENTER_POS[3]
    
    local savedPos = player:Data():Get("ConsumptionPos")
    
    if savedPos then
        if IsAtPos(player, savedPos.x, savedPos.y, 2) then
            player:CastSpell(player, 4987, true)
            player:Data():Set("ConsumptionPos", nil)
            player:Data():Set("LastTargetPos", nil)
            player:Data():Set("StuckCheckPos", nil)
            player:Data():Set("StuckCheckTicks", nil)
            return
        end
        
        DisableSpellCast(player, 0.2)
        player:MoveTo(1, savedPos.x, savedPos.y, savedPos.z, true)
        return
    end
    
    local insideTank = nil
    local mainTank, offTank = IdentifyTanks(halionInside)
    
    if mainTank and mainTank:HasAura(TWILIGHT_REALM) then
        insideTank = mainTank
    elseif offTank and offTank:HasAura(TWILIGHT_REALM) then
        insideTank = offTank
    end
    
    if not insideTank then
        --print("No inside tank found for consumption movement")
        return
    end
    
    local hx, hy, hz = halionInside:GetLocation()
    local tx, ty = insideTank:GetLocation()
    local px, py, pz = player:GetLocation()
    
    local bestX, bestY, bestZ = nil, nil, nil
    local bestDist = 999999
    
    for angle = 0, 350, 10 do
        local rad = math.rad(angle)
        local testX = hx + (40 * math.cos(rad))
        local testY = hy + (40 * math.sin(rad))
        
        local distToTank = math.sqrt((testX - tx)^2 + (testY - ty)^2)
        
        if math.abs(distToTank - 40) < 2 then
            local dist = math.sqrt((testX - px)^2 + (testY - py)^2)
            if dist < bestDist then
                bestDist = dist
                bestX, bestY, bestZ = testX, testY, hz
            end
        end
    end
    
    if bestX then
        --print("Consumption triggered for " .. player:GetName() .. " - Moving to (" .. bestX .. ", " .. bestY .. ", " .. bestZ .. ")")
        player:Data():Set("ConsumptionPos", {x = bestX, y = bestY, z = bestZ})
        UseSpeedBuff(player)
        DisableSpellCast(player, 0.2)
        player:MoveTo(1, bestX, bestY, bestZ, true)
    else
        --print("No valid consumption position found for " .. player:GetName())
    end
end

function FindAndMoveToInsidePosition(player, halionInside, dangerNpcs)
    local validPos = GetRandomValidPositionInSideArea(halionInside, "left", AVERAGE_BOSS_DISTANCE_INSIDE, SPREAD_FACTOR_INSIDE, AOE_AVOIDANCE_DISTANCE, dangerNpcs)
    
    if validPos then
        player:Data():Set("HalionInsideSide", "left")
        player:Data():Set("HalionInsidePos", validPos)
        
        local px, py, pz = player:GetLocation()
        local dx = validPos.x - px
        local dy = validPos.y - py
        local distance = math.sqrt(dx*dx + dy*dy)
        
        if distance > 30 then
            UseSpeedBuff(player)
        end
        DisableSpellCast(player, 0.2)
        player:MoveTo(1, validPos.x, validPos.y, validPos.z, true)
    end
end

function HandlePhase3Transition(halion, bots, mainTank, offTank, healers)
    local mainTankIsBot = mainTank and mainTank:IsBot() or false
    local offTankIsBot = offTank and offTank:IsBot() or false
    
    local halionInside = nil
    local cutterActive = false
    for _, player in ipairs(bots) do
        if player:HasAura(TWILIGHT_REALM) then
            halionInside = player:GetNearestCreature(100, HALION_INSIDE_ENTRY)
            if halionInside then
                cutterActive = halionInside:Data():Get("CutterActive") or false
                break
            end
        end
    end
    
    if cutterActive then return end
    
    local nonTankHealers = {}
    for _, player in ipairs(bots) do
        if player:IsAlive() and player ~= mainTank and player ~= offTank
        and player ~= healers[1] and player ~= healers[2] then
            table.insert(nonTankHealers, player)
        end
    end
    
    table.sort(nonTankHealers, function(a, b)
        return a:GetMaxHealth() > b:GetMaxHealth()
    end)
    
    local outsideHP = 0
    local insideHP = 0
    
    if mainTank then
        if mainTank:HasAura(TWILIGHT_REALM) then
            insideHP = insideHP + mainTank:GetMaxHealth()
            mainTank:Data():Set("InsideGroup", true)
            mainTank:Data():Set("OutsideGroup", false)
            --print("MainTank " .. mainTank:GetName() .. " assigned to INSIDE group (Bot: " .. tostring(mainTankIsBot) .. ")")
        else
            outsideHP = outsideHP + mainTank:GetMaxHealth()
            mainTank:Data():Set("OutsideGroup", true)
            mainTank:Data():Set("InsideGroup", false)
            --print("MainTank " .. mainTank:GetName() .. " assigned to OUTSIDE group (Bot: " .. tostring(mainTankIsBot) .. ")")
        end
    end
    
    if offTank then
        if offTank:HasAura(TWILIGHT_REALM) then
            insideHP = insideHP + offTank:GetMaxHealth()
            offTank:Data():Set("InsideGroup", true)
            offTank:Data():Set("OutsideGroup", false)
            --print("OffTank " .. offTank:GetName() .. " assigned to INSIDE group (Bot: " .. tostring(offTankIsBot) .. ")")
        else
            outsideHP = outsideHP + offTank:GetMaxHealth()
            offTank:Data():Set("OutsideGroup", true)
            offTank:Data():Set("InsideGroup", false)
            --print("OffTank " .. offTank:GetName() .. " assigned to OUTSIDE group (Bot: " .. tostring(offTankIsBot) .. ")")
        end
    end
    
    for _, player in ipairs(nonTankHealers) do
        local hp = player:GetMaxHealth()
        if outsideHP <= insideHP then
            player:Data():Set("OutsideGroup", true)
            player:Data():Set("InsideGroup", false)
            outsideHP = outsideHP + hp
            print(player:GetName() .. " assigned to OUTSIDE group")
        else
            player:Data():Set("InsideGroup", true)
            player:Data():Set("OutsideGroup", false)
            insideHP = insideHP + hp
            print(player:GetName() .. " assigned to INSIDE group")
        end
    end
    
    if not halion:IsCasting() then
        for _, player in ipairs(bots) do
            if not player:HasAura(COMBUSTION_AURA) and not player:HasAura(CONSUMPTION_AURA) then
                local nearestPortal = nil
                
                if player:Data():Get("OutsideGroup") and player:HasAura(TWILIGHT_REALM) then
                    nearestPortal = GetNearestObject(player, "GameObject", {TWILIGHT_PORTAL_INSIDE}, 100)
                elseif player:Data():Get("InsideGroup") and not player:HasAura(TWILIGHT_REALM) then
                    local portals = {}
                    for _, entry in ipairs(TWILIGHT_PORTAL_OUTSIDE) do
                        local foundPortals = player:GetGameObjectsInRange(100, entry)
                        for _, p in ipairs(foundPortals) do
                            table.insert(portals, p)
                        end
                    end
                    
                    if #portals > 0 then
                        local hx, hy = halion:GetLocation()
                        local facing = halion:GetO()
                        local bestPortal = nil
                        local lowestDot = 999999
                        
                        for _, portal in ipairs(portals) do
                            local px, py = portal:GetLocation()
                            local dx, dy = px - hx, py - hy
                            local dist = math.sqrt(dx*dx + dy*dy)
                            local dotProduct = (dx * math.cos(facing) + dy * math.sin(facing)) / dist
                            
                            if dotProduct < lowestDot then
                                lowestDot = dotProduct
                                bestPortal = portal
                            end
                        end
                        
                        nearestPortal = bestPortal
                    end
                end
                
                if nearestPortal then
                    local portalX, portalY, portalZ = nearestPortal:GetLocation()
                    
                    if player:Data():Get("OutsideGroup") and player:HasAura(TWILIGHT_REALM) then
                        print(player:GetName() .. " needs to exit portal (assigned OUTSIDE, currently INSIDE)")
                        
                        if not IsAtPos(player, portalX, portalY, PORTAL_DISTANCE) then
                            local portalPos = {x = portalX, y = portalY, z = portalZ}
                            local INSIDE_DANGER_NPCS = {CONSUMPTION_ENTRY}
                            
							player:AddAura(71635, player)
							player:AddAura(71638, player)
							player:MoveTo(1, portalX, portalY, portalZ, true)
                        else
                            player:RemoveAura(TWILIGHT_REALM)
                            player:Data():Set("HalionInsideLoopStarted", false)
                            StopLuaEvent(player)
                        end
                    end
                    
					if player:Data():Get("InsideGroup") and not player:HasAura(TWILIGHT_REALM) then
						print(player:GetName() .. " needs to enter portal (assigned INSIDE, currently OUTSIDE)")
						
						if not IsAtPos(player, portalX, portalY, PORTAL_DISTANCE) then
							local portalPos = {x = portalX, y = portalY, z = portalZ}
							local INSIDE_DANGER_NPCS = {CONSUMPTION_ENTRY}
							
							player:AddAura(71635, player)
							player:AddAura(71638, player)
							player:MoveTo(1, portalX, portalY, portalZ, true)
						else
							player:AddAura(TWILIGHT_REALM, player)
							StartLuaEvent(player, HalionInsideLoop)
						end
					end
                end
            end
        end
    end
end

local function OnCutterCast(event, caster, spell)
    local halionInside = caster:GetNearestCreature(100, HALION_INSIDE_ENTRY)
    if halionInside then
        halionInside:Data():Set("NextCutterTime", os.time() + 29)
	end
end

RegisterSpellEvent(74768, 2, OnCutterCast)
-- NPCs
local HALION_ENTRY          = 39863
local COMBUSTION_ENTRY      = 40001
local CONSUMPTION_ENTRY     = 40135
local METEOR_STRIKES_ENTRY  = {40029, 40041, 40042, 40043, 40044, 40055}

local HALION_INSIDE_ENTRY   = 40142
local CONSUMPTION_ENTRY     = 40135
local SHADOW_ORBS			= {40083, 40100, 40468, 40469}

local TWILIGHT_PORTAL       = {202794, 202795, 202796}

local COMBUSTION_AURA       = 74562
local CONSUMPTION_AURA      = 74792
local TWILIGHT_REALM        = 74807

local PULL_POS              = {3142.5, 534.3, 72.88}
local ORB_CENTER_POS        = {3153.75, 533.19, 72.88}

local AVERAGE_BOSS_DISTANCE        = 25
local AVERAGE_BOSS_DISTANCE_INSIDE = 20
local SPREAD_FACTOR                = 12.5
local SPREAD_FACTOR_INSIDE         = 5

local PORTAL_DISTANCE              = 8
local AOE_AVOIDANCE_DISTANCE       = 15

local TICK_FREQUENCY        = 200

local function GetAllBotsInInstance(instanceId)
    local bots = {}
    local allPlayers = GetPlayersInWorld()
    for _, player in ipairs(allPlayers) do
        if isPlayerBot[player:GetName()] then
            local bot = GetPlayerByName(player:GetName())
            if bot and bot:GetInstanceId() == instanceId and bot:IsInCombat() and bot:IsAlive() then
                table.insert(bots, bot)
            end
        end
    end
    return bots
end

local function GetRoleArraysFromBots(bots)
    local tanks = {}
    local healers = {}
    local melee = {}
    local casters = {}
    
    for _, player in ipairs(bots) do
        if IsTank(player) then
            table.insert(tanks, player)
        end
        if player:HasHealSpec() then
            table.insert(healers, player)
        end
        if player:HasMeleeSpec() then
            table.insert(melee, player)
        end
        if player:HasCasterSpec() then
            table.insert(casters, player)
        end
    end
    
    table.sort(tanks, function(a, b) return a:GetMaxHealth() > b:GetMaxHealth() end)
    table.sort(healers, function(a, b) return a:GetMaxPower(0) > b:GetMaxPower(0) end)
    
    return tanks, healers, melee, casters
end

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
    local mainTankIsBot = mainTank and isPlayerBot[mainTank:GetName()] or false
    local offTankIsBot = offTank and isPlayerBot[offTank:GetName()] or false
    
    local insideTank = nil
    local insideTankIsBot = false
    
    if mainTank and mainTank:HasAura(TWILIGHT_REALM) then
        insideTank = mainTank
        insideTankIsBot = mainTankIsBot
    elseif offTank and offTank:HasAura(TWILIGHT_REALM) then
        insideTank = offTank
        insideTankIsBot = offTankIsBot
    end
    
    if insideTank and insideTankIsBot then
        if halionInside:IsCasting() and player == insideTank then
            UseDefensive(player)
        end
    end
    
    if not player:HasAura(CONSUMPTION_AURA) then
        player:SetData("ConsumptionPos", nil)
    end
    
    if player == insideTank and insideTankIsBot then
        local insideVictim = halionInside:GetVictim()
        if insideVictim and insideVictim ~= player then
            halionInside:AddThreat(player, 10000 + math.random(-500, 500))
            Taunt(player, halionInside, true)
        end
        
        local combatStart = halionInside:GetData("CombatStart")
        if not combatStart then
            combatStart = os.time()
            halionInside:SetData("CombatStart", combatStart)
        end
        
        local combatTime = os.time() - combatStart
        local shouldTrailOrb = false
        
        if combatTime >= 16 and combatTime < 26 then
            shouldTrailOrb = true
        elseif combatTime >= 26 then
            local timeSinceFirst = combatTime - 16
            local cycleTime = timeSinceFirst % 29
            if cycleTime < 10 then
                shouldTrailOrb = true
            end
        end
        
		if shouldTrailOrb then
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
		else
			local ocX, ocY, ocZ = ORB_CENTER_POS[1], ORB_CENTER_POS[2], ORB_CENTER_POS[3]
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
        
        local targetPos = player:GetData("ConsumptionPos")
    else
        if not player:HasAura(CONSUMPTION_AURA) then
            local INSIDE_DANGER_NPCS = {CONSUMPTION_ENTRY}
            
            local targetPos = player:GetData("HalionInsidePos")
            
            if targetPos then
                
                
                local px, py, pz = player:GetLocation()
                local currentPos = {x = px, y = py, z = pz}
                
                if halionInside and not IsPositionValidInSideArea(currentPos, halionInside, "left", AVERAGE_BOSS_DISTANCE_INSIDE, SPREAD_FACTOR_INSIDE, AOE_AVOIDANCE_DISTANCE, INSIDE_DANGER_NPCS) then
                    if IsPositionValidInSideArea(targetPos, halionInside, "left", AVERAGE_BOSS_DISTANCE_INSIDE, SPREAD_FACTOR_INSIDE, AOE_AVOIDANCE_DISTANCE, INSIDE_DANGER_NPCS) then
                        player:MoveTo(1, targetPos.x, targetPos.y, targetPos.z, true)
                    else
                        print("Inside player " .. player:GetName() .. " saved position also invalid, finding new position")
                        FindAndMoveToInsidePosition(player, halionInside, INSIDE_DANGER_NPCS)
                    end
                end
            else
                FindAndMoveToInsidePosition(player, halionInside, INSIDE_DANGER_NPCS)
            end
        end
    end
    
    player:RegisterEvent(HalionInsideLoop, TICK_FREQUENCY, 1)
end

local function HalionLoop(eventId, delay, repeats, halion)
    if halion:IsDead() or not halion:IsInCombat() then
        halion:SetData("PortalTransitionPrinted", nil)
        StopLuaEvent(halion)
        return
    end
    
    local instanceId = halion:GetInstanceId()
    local bots = GetAllBotsInInstance(instanceId)
    
    if #bots == 0 then StopLuaEvent(halion) return end
    
    local mainTank, offTank = IdentifyTanks(halion)
    local mainTankIsBot = mainTank and isPlayerBot[mainTank:GetName()] or false
    local offTankIsBot = offTank and isPlayerBot[offTank:GetName()] or false
    
    local healers = {}
    for _, player in ipairs(bots) do
        if player:HasHealSpec() then
            table.insert(healers, player)
        end
    end
    table.sort(healers, function(a, b) return a:GetMaxPower(0) > b:GetMaxPower(0) end)
    
    halion:SetData("CombatTime", (halion:GetData("CombatTime") or 0) + TICK_FREQUENCY)
    
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

    if victim then
        if IsAtPos(victim, ORB_CENTER_POS[1], ORB_CENTER_POS[2], 13) then
            if not IsAtPos(halion, ORB_CENTER_POS[1], ORB_CENTER_POS[2], 3) then
                halion:MoveTo(1, ORB_CENTER_POS[1], ORB_CENTER_POS[2], ORB_CENTER_POS[3], true)
            end
        end
    end
    
    for _, player in ipairs(bots) do
        DisableManualSpells(player)
        
        if not player:HasAura(TWILIGHT_REALM) then
            if player:HasAura(COMBUSTION_AURA) then
                MoveForCombustion(player, halion, DANGER_NPCS)
                
                local targetPos = player:GetData("CombustionPos")
                if targetPos then
                    
                end
            else
                local isMainTankBot = (player == mainTank and mainTankIsBot)
                local isOffTankBot = (player == offTank and offTankIsBot)
                
                if isOffTankBot and not player:HasAura(TWILIGHT_REALM) then
                    if victim and victim ~= player then
                        halion:AddThreat(player, 10000 + math.random(-500, 500))
                        Taunt(player, halion, false)
                    end
                    if halion:GetData("CombatTime") < 5000 then
                        local pullPos = {x = PULL_POS[1], y = PULL_POS[2], z = PULL_POS[3]}
                        player:MoveTo(1, PULL_POS[1], PULL_POS[2], PULL_POS[3], true)
                    
                    elseif halion:GetData("CombatTime") < 8000 then
                        local victim = halion:GetVictim()
                        if victim then
                            if IsAtPos(victim, ORB_CENTER_POS[1], ORB_CENTER_POS[2], 10) then
                                if not IsAtPos(halion, ORB_CENTER_POS[1], ORB_CENTER_POS[2], 3) then
                                    halion:MoveTo(1, ORB_CENTER_POS[1], ORB_CENTER_POS[2], ORB_CENTER_POS[3], true)
                                end
                            end
                        end
                    else
                        local cachedPos = player:GetData("TankSafePos")
                        local needsRecalc = false
                        
                        if cachedPos then
                            local dangerNpcs = {}
                            for _, entry in ipairs(DANGER_NPCS) do
                                local npcs = player:GetCreaturesInRange(100, entry)
                                for _, npc in ipairs(npcs) do
                                    table.insert(dangerNpcs, npc)
                                end
                            end
                            
                            for _, danger in ipairs(dangerNpcs) do
                                local dx, dy = danger:GetLocation()
                                local distToDanger = math.sqrt((cachedPos.x - dx)^2 + (cachedPos.y - dy)^2)
                                if distToDanger < AOE_AVOIDANCE_DISTANCE then
                                    needsRecalc = true
                                    break
                                end
                            end
                        else
                            needsRecalc = true
                        end
                        
                        if needsRecalc then
                            local dangerNpcs = {}
                            for _, entry in ipairs(DANGER_NPCS) do
                                local npcs = player:GetCreaturesInRange(100, entry)
                                for _, npc in ipairs(npcs) do
                                    table.insert(dangerNpcs, npc)
                                end
                            end
                            
                            local centerX, centerY, centerZ = ORB_CENTER_POS[1], ORB_CENTER_POS[2], ORB_CENTER_POS[3]
                            
                            local bestX, bestY, bestZ = PULL_POS[1], PULL_POS[2], PULL_POS[3]
                            local bestDist = 999999
                            
                            for angle = 0, 350, 10 do
                                local rad = math.rad(angle)
                                local testX = centerX + (10 * math.cos(rad))
                                local testY = centerY + (10 * math.sin(rad))
                                
                                local valid = true
                                for _, danger in ipairs(dangerNpcs) do
                                    local dx, dy = danger:GetLocation()
                                    if math.sqrt((testX - dx)^2 + (testY - dy)^2) < AOE_AVOIDANCE_DISTANCE then
                                        valid = false
                                        break
                                    end
                                end
                                
                                if valid then
                                    local dist = math.sqrt((testX - PULL_POS[1])^2 + (testY - PULL_POS[2])^2)
                                    if dist < bestDist then
                                        bestDist = dist
                                        bestX, bestY, bestZ = testX, testY, centerZ
                                    end
                                end
                            end
                            
                            player:SetData("TankSafePos", {x = bestX, y = bestY, z = bestZ})
                            cachedPos = {x = bestX, y = bestY, z = bestZ}
                        end
                        
                        if cachedPos then                            
                            if not IsAtPos(player, cachedPos.x, cachedPos.y, 3) then
                                player:MoveTo(1, cachedPos.x, cachedPos.y, cachedPos.z, true)
                            end
                        end
                    end
                end
            end
        end
    end

    if halion:GetHealthPct() >= 75 or halion:GetHealthPct() < 50 then
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
        
        local lastLeftMeteors = halion:GetData("LastLeftMeteors") or 0
        local lastRightMeteors = halion:GetData("LastRightMeteors") or 0
        
        if leftMeteors ~= lastLeftMeteors or rightMeteors ~= lastRightMeteors then
            print("Left meteors: " .. leftMeteors .. ", Right meteors: " .. rightMeteors .. ", Assigned side: " .. groupSide)
            halion:SetData("LastLeftMeteors", leftMeteors)
            halion:SetData("LastRightMeteors", rightMeteors)
        end
        
        local currentMeteor40055 = {}
        for _, entry in ipairs({40055}) do
            local meteors = halion:GetCreaturesInRange(100, entry)
            for _, meteor in ipairs(meteors) do
                table.insert(currentMeteor40055, meteor:GetGUID())
            end
        end
        
        local lastMeteor40055 = halion:GetData("LastMeteor40055") or {}
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
            print("NEW 40055 DETECTED - locking side assignment for 30s")
            halion:SetData("SideAssignmentLocked", os.time() + 30)
        end
        
        halion:SetData("LastMeteor40055", currentMeteor40055)
        
        for _, player in ipairs(bots) do
            if not player:HasAura(TWILIGHT_REALM) then
                if player ~= victim and player ~= tanks[2]
                and not player:HasAura(COMBUSTION_AURA) and not player:HasAura(CONSUMPTION_AURA) then
                    
                    local px, py, pz = player:GetLocation()
                    local currentPos = {x = px, y = py, z = pz}
                    local isCurrentValid = IsPositionValidInSideArea(currentPos, halion, groupSide, AVERAGE_BOSS_DISTANCE, SPREAD_FACTOR, AOE_AVOIDANCE_DISTANCE, POSITION_DANGER_NPCS)
                    
                    local lastValid = player:GetData("LastPosValid")
                    if lastValid ~= isCurrentValid then
                        print(player:GetName() .. " position status: " .. (isCurrentValid and "SAFE" or "UNSAFE"))
                        player:SetData("LastPosValid", isCurrentValid)
                    end
                    
                    if not isCurrentValid then
                        local behindWaypoint = player:GetData("BehindWaypoint")
                        
                        if behindWaypoint then
                            if not IsAtPos(player, behindWaypoint.x, behindWaypoint.y, 3) then
                                player:MoveTo(1, behindWaypoint.x, behindWaypoint.y, behindWaypoint.z, true)
                            else
                                player:SetData("BehindWaypoint", nil)
                                local targetPos = player:GetData("HalionPos")
                                if targetPos then
                                    player:MoveTo(1, targetPos.x, targetPos.y, targetPos.z, true)
                                end
                            end
                        else
                            local targetPos = player:GetData("HalionPos")
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
        if not halion:GetData("PortalTransitionPrinted") then
            print("=== PORTAL TRANSITION (75%-50%) ===")
            print("MainTank: " .. (mainTank and mainTank:GetName() or "none") .. " (Bot: " .. tostring(mainTankIsBot) .. ")")
            print("OffTank: " .. (offTank and offTank:GetName() or "none") .. " (Bot: " .. tostring(offTankIsBot) .. ")")
            print("Healer2: " .. (healers[2] and healers[2]:GetName() or "none"))
            halion:SetData("PortalTransitionPrinted", true)
            
            for _, player in ipairs(bots) do
                if player == offTank or player == healers[2] then
                    StartLuaEvent(player, HalionCheckInsideCombat)
                    print("Started HalionCheckInsideCombat on " .. player:GetName())
                end
            end
        end
        
        local nearestPortal = GetNearestObject(halion, "GameObject", TWILIGHT_PORTAL, 100)
        
        if nearestPortal then
            local portalX, portalY, portalZ = nearestPortal:GetLocation()
            local portalPos = {x = portalX, y = portalY, z = portalZ}
            
            for _, player in ipairs(bots) do
                if player ~= offTank and player ~= healers[2]
                and not player:HasAura(COMBUSTION_AURA) and not player:HasAura(CONSUMPTION_AURA) then
                    if not player:HasAura(TWILIGHT_REALM) then
                        print(player:GetName() .. " heading to portal")
                        
                        if not IsAtPos(player, portalX, portalY, PORTAL_DISTANCE) then
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
        player:SetData("HalionPos", nil)
        player:SetData("HalionSide", nil)
        player:SetData("HalionInsidePos", nil)
        player:SetData("HalionInsideSide", nil)
        player:SetData("CombustionPos", nil)
        player:SetData("ConsumptionPos", nil)
        player:SetData("TankSafePos", nil)
        player:SetData("OutsideGroup", nil)
        player:SetData("InsideGroup", nil)
        player:SetData("BehindWaypoint", nil)
        
        halion:SetData("CombatTime", 0)
        
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
    
    local lastAliveCount = halion:GetData("LastAliveCount") or aliveCount
    if aliveCount < lastAliveCount then
        print("DEATH DETECTED: " .. aliveCount .. " alive (was " .. lastAliveCount .. ")")
    end
    halion:GetData("LastAliveCount", aliveCount)
    
    if not playersInside then
        print("WIPE: No players inside during portal phase")
        player:CastSpell(player, 7, true)
        StopLuaEvent(player)
        return
    end
    
    player:RegisterEvent(HalionCheckInsideCombat, TICK_FREQUENCY, 1)
end

function HalionAssignPosition(player, halion, targetSide, sideSelectionDangerNpcs, positionDangerNpcs)
    local savedSide = player:GetData("HalionSide")
    local needsSideSwitch = savedSide and savedSide ~= targetSide
    
    if needsSideSwitch then
        local sideAssignmentLocked = halion:GetData("SideAssignmentLocked") or 0
        if os.time() < sideAssignmentLocked then
            print("SIDE SWITCH BLOCKED: " .. player:GetName() .. " - side assignment locked for " .. (sideAssignmentLocked - os.time()) .. "s")
            local validPos = GetRandomValidPositionInSideArea(halion, savedSide, AVERAGE_BOSS_DISTANCE, SPREAD_FACTOR, AOE_AVOIDANCE_DISTANCE, positionDangerNpcs)
            if validPos then
                player:SetData("HalionPos", validPos)
                local px, py = player:GetLocation()
                local dx = validPos.x - px
                local dy = validPos.y - py
                local distance = math.sqrt(dx*dx + dy*dy)
                if distance > 30 then
                    UseSpeedBuff(player)
                end
                player:MoveTo(1, validPos.x, validPos.y, validPos.z, true)
            end
            return
        end
        
        local meteorUnderBoss = halion:GetData("MeteorUnderBoss") or 0
        if os.time() < meteorUnderBoss then
            print("SIDE SWITCH BLOCKED: " .. player:GetName() .. " - meteor under boss (blocked for " .. (meteorUnderBoss - os.time()) .. "s)")
            local validPos = GetRandomValidPositionInSideArea(halion, savedSide, AVERAGE_BOSS_DISTANCE, SPREAD_FACTOR, AOE_AVOIDANCE_DISTANCE, positionDangerNpcs)
            if validPos then
                player:SetData("HalionPos", validPos)
                local px, py = player:GetLocation()
                local dx = validPos.x - px
                local dy = validPos.y - py
                local distance = math.sqrt(dx*dx + dy*dy)
                if distance > 30 then
                    UseSpeedBuff(player)
                end
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
                        halion:SetData("MeteorUnderBoss", os.time() + 35)
                        print("METEOR UNDER BOSS - blocking side switches for 35s")
                        local validPos = GetRandomValidPositionInSideArea(halion, savedSide, AVERAGE_BOSS_DISTANCE, SPREAD_FACTOR, AOE_AVOIDANCE_DISTANCE, positionDangerNpcs)
                        if validPos then
                            player:SetData("HalionPos", validPos)
                            local px, py = player:GetLocation()
                            local dx = validPos.x - px
                            local dy = validPos.y - py
                            local distance = math.sqrt(dx*dx + dy*dy)
                            if distance > 30 then
                                UseSpeedBuff(player)
                            end
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
                print("SIDE SWITCH BLOCKED: " .. player:GetName() .. " - only 1 meteor at " .. string.format("%.1f", distToHalion) .. " yds from boss (need 10+)")
                return
            end
        end
        
        print("SIDE SWITCH: " .. player:GetName() .. " switching from " .. savedSide .. " to " .. targetSide)
        local hx, hy, hz = halion:GetLocation()
        local facing = halion:GetO()
        local behindAngle = facing + math.pi
        local behindDist = 5
        local behindX = hx + behindDist * math.cos(behindAngle)
        local behindY = hy + behindDist * math.sin(behindAngle)
        
        player:SetData("HalionSide", targetSide)
        player:SetData("HalionPos", nil)
        player:SetData("BehindWaypoint", {x = behindX, y = behindY, z = hz})
        
        UseSpeedBuff(player)
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
            
            player:SetData("HalionSide", targetSide)
            player:SetData("HalionPos", validPos)
            player:SetData("BehindWaypoint", {x = behindX, y = behindY, z = hz})
            
            UseSpeedBuff(player)
            player:MoveTo(1, behindX, behindY, hz, true)
            return
        end
        
        player:SetData("HalionSide", targetSide)
        player:SetData("HalionPos", validPos)
        
        local dx = validPos.x - px
        local dy = validPos.y - py
        local distance = math.sqrt(dx*dx + dy*dy)
        
        if distance > 30 then
            UseSpeedBuff(player)
        end
        
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
    
    local savedPos = player:GetData("CombustionPos")
    
    if savedPos then
        local stillSafe = true
        for _, danger in ipairs(dangerNpcs) do
            local dx, dy = danger:GetLocation()
            local distToDanger = math.sqrt((savedPos.x - dx)^2 + (savedPos.y - dy)^2)
            if distToDanger < AOE_AVOIDANCE_DISTANCE then
                stillSafe = false
                break
            end
        end
        
        if stillSafe then
            if IsAtPos(player, savedPos.x, savedPos.y, 2) then
                player:CastSpell(player, 4987, true)
                player:SetData("CombustionPos", nil)
                player:SetData("LastTargetPos", nil)
                player:SetData("StuckCheckPos", nil)
                player:SetData("StuckCheckTicks", nil)
            else
                player:MoveTo(1, savedPos.x, savedPos.y, savedPos.z, true)
            end
            return
        end
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
        player:SetData("CombustionPos", {x = bestX, y = bestY, z = bestZ})
        UseSpeedBuff(player)
        DisableSpellCast(player, 2)
        player:MoveTo(1, bestX, bestY, bestZ, true)
    end
end

function MoveForConsumption(player, halionInside, dangerNpcEntries)
    local dangerNpcs = {}
    for _, entry in ipairs(dangerNpcEntries) do
        local npcs = player:GetCreaturesInRange(100, entry)
        for _, npc in ipairs(npcs) do
            table.insert(dangerNpcs, npc)
        end
    end
    
    local ocX, ocY, ocZ = ORB_CENTER_POS[1], ORB_CENTER_POS[2], ORB_CENTER_POS[3]
    
    local savedPos = player:GetData("ConsumptionPos")
    
    if savedPos then
        local stillSafe = true
        for _, danger in ipairs(dangerNpcs) do
            local dx, dy = danger:GetLocation()
            local distToDanger = math.sqrt((savedPos.x - dx)^2 + (savedPos.y - dy)^2)
            if distToDanger < AOE_AVOIDANCE_DISTANCE then
                stillSafe = false
                break
            end
        end
        
        if stillSafe then
            if IsAtPos(player, savedPos.x, savedPos.y, 2) then
                player:CastSpell(player, 4987, true)
                player:SetData("ConsumptionPos", nil)
                player:SetData("LastTargetPos", nil)
                player:SetData("StuckCheckPos", nil)
                player:SetData("StuckCheckTicks", nil)
            else
                DisableSpellCast(player, 2)
                player:MoveTo(1, savedPos.x, savedPos.y, savedPos.z, true)
            end
            return
        end
    end
    
    local bestX, bestY, bestZ = nil, nil, nil
    local bestDist = 999999

    local facingAngle = halionInside:GetO()
    local px, py, pz = player:GetLocation()

    for distance = 30, 50, 2 do
        local testX = px + (distance * math.cos(facingAngle))
        local testY = py + (distance * math.sin(facingAngle))
        
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
            local dist = math.sqrt((testX - px)^2 + (testY - py)^2)
            if dist < bestDist then
                bestDist = dist
                bestX, bestY, bestZ = testX, testY, pz
            end
        end
    end
    
    if bestX then
        print("Consumption triggered for " .. player:GetName() .. " - Boss facing: " .. facingAngle .. " - Player location: (" .. px .. ", " .. py .. ", " .. pz .. ") - New location: (" .. bestX .. ", " .. bestY .. ", " .. bestZ .. ")")
        player:SetData("ConsumptionPos", {x = bestX, y = bestY, z = bestZ})
        UseSpeedBuff(player)
        DisableSpellCast(player, 2)
        player:MoveTo(1, bestX, bestY, bestZ, true)
    else
        print("No valid consumption position found for " .. player:GetName())
    end
end

function FindAndMoveToInsidePosition(player, halionInside, dangerNpcs)
    local validPos = GetRandomValidPositionInSideArea(halionInside, "left", AVERAGE_BOSS_DISTANCE_INSIDE, SPREAD_FACTOR_INSIDE, AOE_AVOIDANCE_DISTANCE, dangerNpcs)
    
    if validPos then
        player:SetData("HalionInsideSide", "left")
        player:SetData("HalionInsidePos", validPos)
        
        local px, py, pz = player:GetLocation()
        local dx = validPos.x - px
        local dy = validPos.y - py
        local distance = math.sqrt(dx*dx + dy*dy)
        
        if distance > 30 then
            UseSpeedBuff(player)
        end
        
        print("Inside player " .. player:GetName() .. " moving to new position: (" .. validPos.x .. ", " .. validPos.y .. ", " .. validPos.z .. ")")
        player:MoveTo(1, validPos.x, validPos.y, validPos.z, true)
    end
end

function HandlePhase3Transition(halion, bots, mainTank, offTank, healers)
    local mainTankIsBot = mainTank and isPlayerBot[mainTank:GetName()] or false
    local offTankIsBot = offTank and isPlayerBot[offTank:GetName()] or false
    
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
            mainTank:SetData("InsideGroup", true)
            mainTank:SetData("OutsideGroup", false)
            print("MainTank " .. mainTank:GetName() .. " assigned to INSIDE group (Bot: " .. tostring(mainTankIsBot) .. ")")
        else
            outsideHP = outsideHP + mainTank:GetMaxHealth()
            mainTank:SetData("OutsideGroup", true)
            mainTank:SetData("InsideGroup", false)
            print("MainTank " .. mainTank:GetName() .. " assigned to OUTSIDE group (Bot: " .. tostring(mainTankIsBot) .. ")")
        end
    end
    
    if offTank then
        if offTank:HasAura(TWILIGHT_REALM) then
            insideHP = insideHP + offTank:GetMaxHealth()
            offTank:SetData("InsideGroup", true)
            offTank:SetData("OutsideGroup", false)
            print("OffTank " .. offTank:GetName() .. " assigned to INSIDE group (Bot: " .. tostring(offTankIsBot) .. ")")
        else
            outsideHP = outsideHP + offTank:GetMaxHealth()
            offTank:SetData("OutsideGroup", true)
            offTank:SetData("InsideGroup", false)
            print("OffTank " .. offTank:GetName() .. " assigned to OUTSIDE group (Bot: " .. tostring(offTankIsBot) .. ")")
        end
    end
    
    for _, player in ipairs(nonTankHealers) do
        local hp = player:GetMaxHealth()
        if outsideHP <= insideHP then
            player:SetData("OutsideGroup", true)
            player:SetData("InsideGroup", false)
            outsideHP = outsideHP + hp
            print(player:GetName() .. " assigned to OUTSIDE group")
        else
            player:SetData("InsideGroup", true)
            player:SetData("OutsideGroup", false)
            insideHP = insideHP + hp
            print(player:GetName() .. " assigned to INSIDE group")
        end
    end
    
    local nearestPortal = GetNearestObject(halion, "GameObject", TWILIGHT_PORTAL, 100)
    if nearestPortal then
        local portalX, portalY, portalZ = nearestPortal:GetLocation()
        local portalPos = {x = portalX, y = portalY, z = portalZ}
        
        for _, player in ipairs(bots) do
            if not player:HasAura(COMBUSTION_AURA) and not player:HasAura(CONSUMPTION_AURA) then
                if player:GetData("OutsideGroup") and player:HasAura(TWILIGHT_REALM) then
                    print(player:GetName() .. " needs to exit portal (assigned OUTSIDE, currently INSIDE)")
                    
                    if not IsAtPos(player, portalX, portalY, PORTAL_DISTANCE) then
                        player:AddAura(71638)
                        player:MoveTo(1, portalX, portalY, portalZ, true)
                    else
                        player:RemoveAura(TWILIGHT_REALM)
                        StopLuaEvent(player)
                        player:SetData("HalionInsideLoopStarted", false)
                    end
                end
                if player:GetData("InsideGroup") and not player:HasAura(TWILIGHT_REALM) then
                    print(player:GetName() .. " needs to enter portal (assigned INSIDE, currently OUTSIDE)")
                    
                    if not IsAtPos(player, portalX, portalY, PORTAL_DISTANCE) then
                        player:AddAura(71638)
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



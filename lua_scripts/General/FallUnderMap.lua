-- Multistate: map-only script (all hooks fire in map states).
if not IsCompatibilityMode() and GetStateMapId() == -1 then return end

local preFallZTolerance = 2

local function CheckPlayer(eventId, delay, repeats, player)
    if not player:IsFalling() or player:IsInWater() or player:IsOnVehicle() or player:IsFlying() then
        player:SetData("MapGlitchFailTicks", 0)
        player:SetData("MapGlitchWasFalling", false)
        local pz = player:GetZ()
        local minZ = player:GetMapId() == 530 and -499 or -100000
        local pfGroundZ = player:GetGroundZ()
        local pfFloorZ = player:GetFloorZ()
        local pfBest = nil
        if pfGroundZ and pfGroundZ > minZ and math.abs(pz - pfGroundZ) <= 1 then
            pfBest = pfGroundZ
        elseif pfFloorZ and pfFloorZ > minZ and math.abs(pz - pfFloorZ) <= 1 then
            pfBest = pfFloorZ
        end
        if pfBest then
            player:SetData("MapGlitchPreFallZ", pfBest)
            player:SetData("MapGlitchPreFallZTick", os.time())
        end
        return
    end

    local groundZ = player:GetGroundZ()
    local floorZ = player:GetFloorZ()
    if not groundZ and not floorZ then
        local wasFalling = player:GetData("MapGlitchWasFalling")
        player:SetData("MapGlitchWasFalling", true)
        if wasFalling then
            player:SetData("MapGlitchFailTicks", 0)
            return
        end
        player:SetData("MapGlitchFailTicks", 0)
        return
    end

    player:SetData("MapGlitchWasFalling", true)

    local minZ = player:GetMapId() == 530 and -499 or -100000
    local playerX = player:GetX()
    local playerY = player:GetY()
    local playerZ = player:GetZ()
    local preFallZ = player:GetData("MapGlitchPreFallZ")
    local preFallZTick = player:GetData("MapGlitchPreFallZTick")
    if preFallZTick and os.time() - preFallZTick > 2 then
        preFallZ = nil
    end
    local log = "[MapGlitch] " .. player:GetName() .. " map=" .. player:GetMapId() .. " pos=(" .. playerX .. "," .. playerY .. "," .. playerZ .. ") preFallZ=" .. tostring(preFallZ) .. " groundZ=" .. tostring(groundZ) .. " floorZ=" .. tostring(floorZ)

    if groundZ and groundZ <= minZ then groundZ = nil end
    if floorZ and floorZ <= minZ then floorZ = nil end
    log = log .. " | after minZ filter: groundZ=" .. tostring(groundZ) .. " floorZ=" .. tostring(floorZ)

    local targetZ = nil
    if groundZ and floorZ then
        targetZ = math.min(groundZ, floorZ)
    elseif groundZ then
        targetZ = groundZ
    elseif floorZ then
        targetZ = floorZ
    end
    log = log .. " targetZ=" .. tostring(targetZ)

    local bothInvalid = not groundZ and not floorZ
    local tooFarBelow = targetZ and playerZ < targetZ - 30
    log = log .. " bothInvalid=" .. tostring(bothInvalid) .. " tooFarBelow=" .. tostring(tooFarBelow)

    if bothInvalid or tooFarBelow then
        local ticks = (player:GetData("MapGlitchFailTicks") or 0) + 1
        player:SetData("MapGlitchFailTicks", ticks)
        log = log .. " | [probe] ticks=" .. ticks
        if ticks < 1 then print(log .. " SKIP(ticks)") return end
        local map = player:GetMap()
        local validZ = nil
        local probes = 0
        local successSpawnZ, successFloorZ, successMapZ
        for i = 1, 5 do
            local spawnZ = playerZ + (i * 5)
            local npc = player:SpawnCreature(22515, playerX, playerY, spawnZ, 0, 3, 5000)
            probes = probes + 1
            if npc then
                local npcFloorZ = npc:GetFloorZ()
                local npcMapZ = map:GetHeight(playerX, playerY)
                local validFloor = npcFloorZ and npcFloorZ > minZ and npcFloorZ > playerZ and npcFloorZ <= playerZ + 30
                local validMap = npcMapZ and npcMapZ > minZ and npcMapZ > playerZ and npcMapZ <= playerZ + 30
                local candidateZ = nil
                if validFloor and validMap then
                    candidateZ = math.abs(npcFloorZ - playerZ) < math.abs(npcMapZ - playerZ) and npcFloorZ or npcMapZ
                elseif validFloor then
                    candidateZ = npcFloorZ
                elseif validMap then
                    candidateZ = npcMapZ
                end
                if candidateZ then
                    validZ = candidateZ
                    successSpawnZ = spawnZ
                    successFloorZ = npcFloorZ
                    successMapZ = npcMapZ
                    break
                end
            end
        end
        log = log .. " probes=" .. probes .. " validZ=" .. tostring(validZ) .. " successSpawnZ=" .. tostring(successSpawnZ) .. " successFloorZ=" .. tostring(successFloorZ) .. " successMapZ=" .. tostring(successMapZ)
        if not validZ then
            print(log .. " OUTCOME=no_valid_z")
            player:SetData("MapGlitchFailTicks", 0)
            return
        end
        if preFallZ and validZ > preFallZ + preFallZTolerance then
            print(log .. " OUTCOME=rejected_too_far_above_preFallZ")
            player:SetData("MapGlitchFailTicks", 0)
            return
        end
        print(log .. " OUTCOME=teleport teleZ=" .. (validZ + 0.2))
        player:SetData("MapGlitchFailTicks", 0)
        player:Teleport(player:GetMapId(), playerX, playerY, validZ + 0.2, player:GetO())
        return
    end

    if playerZ < targetZ - 1 then
        local ticks = (player:GetData("MapGlitchFailTicks") or 0) + 1
        player:SetData("MapGlitchFailTicks", ticks)
        log = log .. " | [below] ticks=" .. ticks
        if ticks < 1 then print(log .. " SKIP(ticks)") return end
        local teleZ = targetZ + 0.2
        if preFallZ and teleZ > preFallZ + preFallZTolerance then
            print(log .. " OUTCOME=rejected_too_far_above_preFallZ teleZ=" .. teleZ)
            player:SetData("MapGlitchFailTicks", 0)
            return
        end
        print(log .. " OUTCOME=teleport teleZ=" .. teleZ)
        player:SetData("MapGlitchFailTicks", 0)
        player:Teleport(player:GetMapId(), playerX, playerY, teleZ, player:GetO())
    else
        player:SetData("MapGlitchFailTicks", 0)
    end
end

local function RegisterPlayerCheck(event, player)
    if ShadowGetMaster(player:GetName()) then return end
    local existingEvent = player:GetData("MapGlitchEvent")
    if existingEvent then player:RemoveEventById(existingEvent) end

    local eventId = player:RegisterEvent(CheckPlayer, 1000, 0)
    player:SetData("MapGlitchEvent", eventId)
end

RegisterPlayerEvent(28, RegisterPlayerCheck)
-- Multistate: state-aware catch-up for already-online players (server start or
-- reload). GetPlayersInWorld() only exists in the global state.
require("Multistate").ForEachPlayer(function(player) RegisterPlayerCheck(nil, player) end)
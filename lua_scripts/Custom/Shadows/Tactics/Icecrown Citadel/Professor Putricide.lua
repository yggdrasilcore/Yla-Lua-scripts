if GetStateMapId() ~= 631 then return end

local function GetNearestSafePoint(x, y)
    local safePoints = {
        {4356, 3265}, {4417, 3207}, {4356, 3157}, {4288, 3192}
    }
    
    local nearestPoint = safePoints[1]
    local minDist = math.huge
    
    for _, point in ipairs(safePoints) do
        local dx = x - point[1]
        local dy = y - point[2]
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist < minDist then
            minDist = dist
            nearestPoint = point
        end
    end
    
    return nearestPoint[1], nearestPoint[2], 389.3
end

local function ProfessorPutricideLoop(eventId, delay, repeats, putricide)
    if putricide:IsDead() or not putricide:IsInCombat() then
        StopLuaEvent(putricide)
        return
    end
    
    local players = putricide:GetPlayersInRange(200)
    
    for _, player in ipairs(players) do
        if player:IsBot() then
            local x, y, z = player:GetLocation()
            local shouldTeleport = false
            
            if z < 359 then
                local creature36627 = putricide:GetNearestCreature(300, 36627, 0)
                local creature36626 = putricide:GetNearestCreature(300, 36626, 0)
                
                if not creature36627 or not creature36626 then
                    shouldTeleport = true
                end
            elseif y > 3213 and z < 389 then
                shouldTeleport = true
            elseif y > 3273 then
                shouldTeleport = true
            end
            
            if shouldTeleport then
                local safeX, safeY, safeZ = GetNearestSafePoint(x, y)
                player:NearTeleport(safeX, safeY, safeZ, player:GetO())
            end
        end
    end
    
    putricide:RegisterEvent(ProfessorPutricideLoop, 500, 1)
end

local function OnProfessorPutricideCombat(event, player, enemy)
    if enemy and enemy:GetEntry() == 36678 then
        StartLuaEvent(enemy, ProfessorPutricideLoop)
    end
end

RegisterPlayerEvent(33, OnProfessorPutricideCombat)
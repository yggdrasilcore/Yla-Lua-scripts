local function CheckPlayer(eventId, delay, repeats, player)
    if not player:IsFalling() or player:IsInWater() or player:IsOnVehicle() then return end
    
    local groundZ = player:GetGroundZ()
    local floorZ = player:GetFloorZ()
    if not groundZ and not floorZ then return end

    local minZ = player:GetMapId() == 530 and -499 or -100000

    if groundZ and groundZ < minZ then groundZ = nil end
    if floorZ and floorZ < minZ then floorZ = nil end

    if not groundZ and not floorZ then return end

    local playerZ = player:GetZ()
    
    local targetZ = nil
    if groundZ and floorZ then
        targetZ = math.min(groundZ, floorZ)
    elseif groundZ then
        targetZ = groundZ
    else
        targetZ = floorZ
    end
    if playerZ < targetZ - 1 then
        print(string.format("[MapGlitch] %s is below ground at map %d (%.2f, %.2f, %.2f), teleporting to Z %.2f",
            player:GetName(), player:GetMapId(), player:GetX(), player:GetY(), playerZ, targetZ))
        player:Teleport(player:GetMapId(), player:GetX(), player:GetY(), targetZ + 0.2, player:GetO())
    end
end

local function RegisterPlayerCheck(event, player)
    if isPlayerBot[player:GetName()] then return end
    local existingEvent = player:GetData("MapGlitchEvent")
    if existingEvent then player:RemoveEventById(existingEvent) end
    
    local eventId = player:RegisterEvent(CheckPlayer, 1000, 0)
    player:SetData("MapGlitchEvent", eventId)
end

for _, player in ipairs(GetPlayersInWorld()) do
    RegisterPlayerCheck(_, player)
end

RegisterPlayerEvent(28, RegisterPlayerCheck)
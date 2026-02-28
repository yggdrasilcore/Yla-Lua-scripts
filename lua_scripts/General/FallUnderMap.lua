local function CheckPlayer(eventId, delay, repeats, player)
    if not player:IsFalling() or player:IsInWater() then return end

    local groundZ = player:GetGroundZ()
    local floorZ = player:GetFloorZ()

    if not groundZ and not floorZ then return end
    
    if not groundZ and not floorZ then return end
    
    if groundZ < -100000 then groundZ = nil end
    if floorZ < -100000 then floorZ = nil end

    local playerZ = player:GetZ()
    local targetZ = nil

    if groundZ and floorZ then
        targetZ = math.min(groundZ, floorZ)
    elseif groundZ then
        targetZ = groundZ
    else
        targetZ = floorZ
    end

    if playerZ < targetZ then
        print(string.format("[MapGlitch] %s is below ground, teleporting to %.2f", player:GetName(), targetZ))
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
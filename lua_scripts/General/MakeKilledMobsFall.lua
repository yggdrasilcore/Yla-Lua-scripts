local Z_TOLERANCE = 2 -- Proxy for object height

local function OnPlayerKillCreature(event, player, killed)
    if not player then return end
    if not killed then return end
    
    if killed:IsMounted() then return end
    if killed:IsInWater() then return end

    local killedZ = killed:GetZ()
    local floorZ = killed:GetFloorZ()
    local groundZ = killed:GetGroundZ()

    if floorZ <= -10000 and groundZ <= -10000 then return end

    if floorZ > -10000 and math.abs(killedZ - floorZ) <= Z_TOLERANCE then return end
    if groundZ > -10000 and math.abs(killedZ - groundZ) <= Z_TOLERANCE then return end

    local targetZ = nil
    if floorZ > -10000 and floorZ <= killedZ then
        targetZ = floorZ
    end
    if groundZ > -10000 and groundZ <= killedZ then
        if not targetZ or groundZ > targetZ then
            targetZ = groundZ
        end
    end

    if targetZ then
        killed:MoveTo(0, killed:GetX(), killed:GetY(), targetZ)
    end
end

RegisterPlayerEvent(7, OnPlayerKillCreature)
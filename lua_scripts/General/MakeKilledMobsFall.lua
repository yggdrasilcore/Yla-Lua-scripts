if GetStateMapId() == -1 then return end

local Z_TOLERANCE = 2 -- Proxy for object height

local function OnPlayerKillCreature(event, player, killed)
    if not player or not killed then return end
    if killed:IsMounted() or killed:IsInWater() then return end

    local z = killed:GetZ()
    local groundZ = math.max(killed:GetFloorZ(), killed:GetGroundZ())

    if groundZ <= -10000 then return end
    if z - groundZ <= Z_TOLERANCE then return end

    killed:MoveTo(0, killed:GetX(), killed:GetY(), groundZ)
end

RegisterPlayerEvent(7, OnPlayerKillCreature)
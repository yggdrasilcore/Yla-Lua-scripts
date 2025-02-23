local function EnterPlayerVehicle(event, packet, player)    
    if not player or not player:GetSelection() or not player:GetSelection():IsPlayer() then
        return
    end
    player:SetData("vehicleName", player:GetSelection():GetName())
end

local function HandlePlayerKill(event, killer, killed)
    if killed:IsOnVehicle() and killed:GetData("vehicleName") then
        local playerVehicle = GetPlayerByName(killed:GetData("vehicleName"))
        local vehicle = playerVehicle:GetVehicleKit()
        if vehicle and vehicle:IsOnBoard(killed) then
            killed:NearTeleport(killed:GetX(), killed:GetY(), killed:GetZ()+0.01, killed:GetO())
        end
    end
end

RegisterPlayerEvent(6, HandlePlayerKill)
RegisterPlayerEvent(8, HandlePlayerKill)
RegisterPacketEvent(0x4A8, 5, EnterPlayerVehicle)
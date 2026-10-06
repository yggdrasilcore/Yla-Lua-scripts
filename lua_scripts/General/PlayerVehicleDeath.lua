-- Multistate: the vehicle-target packet arrives globally while kill handlers
-- run in map states, so the stored vehicle name lives in shared Data().
local MS = require("Multistate")

local function EnterPlayerVehicle(event, packet, player)    
    if not player or not player:GetSelection() or not player:GetSelection():IsPlayer() then
        return
    end
    MS.SetShared(player, "vehicleName", player:GetSelection():GetName())
end

local function HandlePlayerKill(event, killer, killed)
    local vehicleName = MS.GetShared(killed, "vehicleName")
    if killed:IsOnVehicle() and vehicleName then
        local playerVehicle = MS.FindPlayerByName(vehicleName)
        if not playerVehicle then return end
        local vehicle = playerVehicle:GetVehicleKit()
        if vehicle and vehicle:IsOnBoard(killed) then
            killed:NearTeleport(killed:GetX(), killed:GetY(), killed:GetZ()+0.01, killed:GetO())
        end
    end
end

RegisterPlayerEvent(6, HandlePlayerKill)
RegisterPlayerEvent(8, HandlePlayerKill)
RegisterPacketEvent(0x4A8, 5, EnterPlayerVehicle)
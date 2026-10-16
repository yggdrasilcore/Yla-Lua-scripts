if GetStateMapId() ~= -1 then return end

local function LeaveVehiclePacket(event, packet, player) -- Adds parachute on vehicle change in certain Northrend areas
    if player:GetAreaId() == 4537 or player:GetAreaId() == 210 or player:GetAreaId() == 4509
    or player:GetAreaId() == 4510 or player:GetAreaId() == 4513 
    then
        player:RegisterEvent(function(eventId, delay, repeats, player)
            local map = player:GetMap()
            local x, y, z = player:GetLocation()
            local groundHeight = map:GetHeight(x, y)
            
            if not player:IsFalling() then
                return
            end
            
            if not groundHeight then
                return
            end
            
            if (z - groundHeight) >= 10 then
                player:AddAura(61243, player)
                return
            end
            
        end, 3000, 1)
    end
end

RegisterPacketEvent(0x38D, 5, LeaveVehiclePacket)
RegisterPacketEvent(0x46D, 5, LeaveVehiclePacket)
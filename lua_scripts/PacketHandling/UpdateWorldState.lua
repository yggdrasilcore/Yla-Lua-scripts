local function OnUpdateWorldStatePacket(event, packet, player)
    if player and player:GetMapId() == 571 and player:GetZoneId() == 4197 then
        local variableID = packet:ReadLong()
        local value = packet:ReadLong()
        if variableID == 3801 then -- Wintergrasp battle update
            ProcessWintergraspWorldstate(variableID, value)
            CompoundTenacity(value)
        elseif variableID == 3802 then
            if value == 0 then
                WG_Controller = "Alliance"
            else
                WG_Controller = "Horde"
            end
        end
    end
end 

RegisterPacketEvent(0x2C3, 7, OnUpdateWorldStatePacket)
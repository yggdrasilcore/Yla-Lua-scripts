local function OnInitWorldStatesPacket(event, packet, player)
    local mapID = packet:ReadLong()
    local zoneID = packet:ReadLong()
    local areaID = packet:ReadLong()
    local worldstateCount = packet:ReadUShort()
    
    if mapID == 571 and zoneID == 4197 then
        for i = 1, worldstateCount do
            local variableID = packet:ReadLong()
            local value = packet:ReadLong()
            if variableID == 3801 then
                WG_FightActive = (value == 0)
                CompoundTenacity(value)
                break
            end
        end
    end
end

RegisterPacketEvent(0x2C2, 7, OnInitWorldStatesPacket)

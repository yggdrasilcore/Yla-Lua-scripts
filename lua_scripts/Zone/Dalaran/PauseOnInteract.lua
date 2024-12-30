local function OnPacketReceive(event, packet, player)
    if not (player:GetZoneId() == 4395) then
        return
    end
    local target = player:GetSelection():ToCreature()
    if target then
        local aura = player:AddAura(35340, target)
        if aura then
            aura:SetDuration(15000)
        end
    end
end

RegisterPacketEvent(0x19E, 5, OnPacketReceive)
RegisterPacketEvent(0x17B, 5, OnPacketReceive)

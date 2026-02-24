local function OnSetSelection(event, packet, player)
    if not player then return end
    local guid = packet:ReadGUID()
    player:SetData("Target", guid)
end

RegisterPacketEvent(0x13D, 5, OnSetSelection)
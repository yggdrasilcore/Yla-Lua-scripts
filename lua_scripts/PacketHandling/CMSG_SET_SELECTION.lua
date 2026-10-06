-- Multistate: global-only script (all hooks fire in the world state).
if GetStateMapId() ~= -1 then return end

local function OnSetSelection(event, packet, player)
    if not player then return end
    local guid = packet:ReadGUID()
    player:SetData("Target", guid)
end

RegisterPacketEvent(0x13D, 5, OnSetSelection)
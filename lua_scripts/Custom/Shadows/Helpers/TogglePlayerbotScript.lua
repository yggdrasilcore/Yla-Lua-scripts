-- Multistate: map-only script (combat hooks fire in map states).
if GetStateMapId() == -1 then return end

function ToggleShadowsScript(player, script, state)
    local masterName = ShadowGetMaster(player:GetName())
    if not masterName then return end
    local master = require("Multistate").FindPlayerByName(masterName)
    if not master then return end
    local cmd = state and "co +" .. script or "co -" .. script
    master:Whisper(cmd, 0, player)
end


local function OnLeaveCombatICC(event, player)
    if player:GetMapId() ~= 631 then return end
    ToggleShadowsScript(player, "icc", true)
end

RegisterPlayerEvent(34, OnLeaveCombatICC)
function TogglePlayerbotScript(player, script, state)
    local masterName = isPlayerBot[player:GetName()]
    if not masterName then return end
    local master = GetPlayerByName(masterName)
    if not master then return end
    local cmd = state and "co +" .. script or "co -" .. script
    master:Whisper(cmd, 0, player)
end


local function OnLeaveCombatICC(event, player)
    if player:GetMapId() ~= 631 then return end
    TogglePlayerbotScript(player, "icc", true)
end

RegisterPlayerEvent(34, OnLeaveCombatICC)
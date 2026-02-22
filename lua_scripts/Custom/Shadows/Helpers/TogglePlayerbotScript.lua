function TogglePlayerbotScript(player, script, state)
    local masterName = isPlayerBot[player:GetName()]
    if not masterName then return end
    local master = GetPlayerByName(masterName)
    if not master then return end
    local cmd = state and "co +" .. script or "co -" .. script
    print("[TogglePlayerbotScript] " .. masterName .. " whispering " .. player:GetName() .. ": " .. cmd)
    master:Whisper(cmd, 0, player)
end
-- Multistate: Ruby Sanctum-only script (map 724).
if not IsCompatibilityMode() and GetStateMapId() ~= 724 then return end

RegisterPlayerEvent(28, function(event, player)
    if player:GetMapId() == 724 and player:IsBot() then
        local master = require("Multistate").FindPlayerByName(ShadowGetMaster(player:GetName()))
        if master then
            player:Whisper("Loaded Ruby Sanctum strategy.", 0, master)
        end
    end
end)
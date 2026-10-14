-- Multistate: Ruby Sanctum-only script (map 724).
if GetStateMapId() ~= 724 then return end

RegisterPlayerEvent(28, function(event, player)
    if player:GetMapId() == 724 and player:IsBot() then
        local shadow = player:ToShadow()
        local master = shadow and shadow:GetMaster()
        if master and (master:GetMapId() == player:GetMapId() and master:GetInstanceId() == player:GetInstanceId()) then
            player:Whisper("Loaded Ruby Sanctum strategy.", 0, master)
        end
    end
end)
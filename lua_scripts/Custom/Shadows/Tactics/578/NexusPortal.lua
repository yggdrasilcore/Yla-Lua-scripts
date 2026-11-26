if GetStateMapId() ~= 578 then return end

local function OnUseNexusPortal(event, go, player)
    player:RegisterEvent(function(eventId, delay, repeats, player)
        if player:GetDistance(983, 1054, 359) > 10 then return end

        for _, mapPlayer in ipairs(player:GetMap():GetPlayers()) do
            if mapPlayer:IsBot()
                and mapPlayer:GetInstanceId() == player:GetInstanceId()
                and mapPlayer:GetAccountId() == player:GetAccountId() then
                mapPlayer:NearTeleport(player:GetX(), player:GetY(), player:GetZ(), player:GetO())
            end
        end
    end, 1000, 1)
end

RegisterGameObjectEvent(189985, 14, OnUseNexusPortal)

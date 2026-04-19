local function OnMapChange(event, player)
    if not player then return end    
    if (player:GetInstanceId() > 0)  -- If in instance, remove flight
    or not player:IsOutdoors() -- If indoors, remove flight
    or player:GetMapId() == 37 -- If in Azshara Crater, remove flight
    then
        player:AddAura(43775, player)
        
        player:RegisterEvent(function(e, d, r, player)
            player:RemoveAura(43775)
        end, 200, 5)
    end
end

RegisterPlayerEvent(28, OnMapChange)
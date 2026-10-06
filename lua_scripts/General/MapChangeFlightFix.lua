-- Multistate: map-only script (all hooks fire in map states).
if not IsCompatibilityMode() and GetStateMapId() == -1 then return end

local function OnMapChange(event, player)
    if not player then return end    
    if (player:GetInstanceId() > 0)  -- If in instance, remove flight
    or not player:IsOutdoors() -- If indoors, remove flight
    or player:GetMapId() == 37 -- If in Azshara Crater, remove flight
    then
        if player:HasAura(40120) then
            player:RemoveAura(40120) -- Remove Swift Flight Form
        end
        if player:HasAura(33943) then
            player:RemoveAura(33943) -- Remove Flight Form
        end
        
        player:AddAura(43775, player) -- Hard set flight state
        
        player:RegisterEvent(function(e, d, r, player)
            player:RemoveAura(43775)
        end, 200, 25) -- Attempt to remove flight state periodically over 5 sec, assume client lag is less than this after entering world
    end
end

RegisterPlayerEvent(28, OnMapChange)
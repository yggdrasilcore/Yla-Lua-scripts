-- HOR TACTICS

function DoNotTargetLK(event, player)
    if not (player:GetMapId() == 668) then return end
    
    local LK = player:GetNearestCreature(4000, 36954)
    
    if LK then
        local group = player:GetGroup()
        
        if group then
            group:SetTargetIcon(4, LK:GetGUID(), player:GetGUID())
        end
    end
end

RegisterPlayerEvent(28, DoNotTargetLK)             -- On change map
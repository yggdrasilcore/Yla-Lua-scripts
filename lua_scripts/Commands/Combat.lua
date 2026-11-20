if GetStateMapId() ~= -1 then return end

local function CombatCheck(event, player, command)
    if command == "combat" then
        local target = player:GetSelection()
        local message = ""
        
        if target then
            local inCombat = target:IsInCombat()
            message = string.format("Unit %s is %s combat", target:GetName(), inCombat and "in" or "not in")
        else
            local playerInCombat = player:IsInCombat()
            message = string.format("You are %s combat", playerInCombat and "in" or "not in")
        end
        
        player:SendBroadcastMessage(message)
        return false
    end
end

RegisterPlayerEvent(42, CombatCheck)
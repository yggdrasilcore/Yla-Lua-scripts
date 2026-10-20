if GetStateMapId() ~= -1 then return end

local function OnRootCommand(event, player, command)
    if command == "root" then
        if player:GetGMRank() == 0 then return false end
        local target = player:GetSelection()
        if not target then target = player end
        if target:HasAura(38505) then
            target:RemoveAura(38505)
        else
            player:AddAura(38505, target)
        end
        return false
    elseif command == "unroot" then
        if player:GetGMRank() == 0 then return false end
        local target = player:GetSelection()
        if not target then target = player end
        target:RemoveAura(38505)
        return false
    end
end

RegisterPlayerEvent(42, OnRootCommand)

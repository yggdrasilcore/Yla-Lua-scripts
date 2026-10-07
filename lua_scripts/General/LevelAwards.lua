-- Multistate: map-only script (all hooks fire in map states).
if not IsCompatibilityMode() and GetStateMapId() == -1 then return end

function OnLevelUp(event, player, oldLevel)
	-- Multistate: the flag is maintained by UIServer in shared Data().
	if require("Multistate").GetData(player, "LvlRewardsDisabled") then return end
    local newLevel = player:GetLevel()
    local team = player:GetTeam()
    
    if newLevel >= 10 and oldLevel < 10 then
        player:LearnSpell(33388) --riding
        if team == 0 then
            player:LearnSpell(472)  --alliance mount
        elseif team == 1 then
            player:LearnSpell(578)  --horde mount
        end
        player:SendBroadcastMessage("Congratulations on reaching level 10! You have learned how to ride and summon a mount.")
    elseif newLevel >= 20 and oldLevel < 20 then
        player:ModifyMoney(250000) -- 25g
        player:SendBroadcastMessage("Congratulations on reaching level 20! You have earned 25 gold.")
    elseif newLevel >= 30 and oldLevel < 30 then
        player:ModifyMoney(500000) -- 50g
        player:SendBroadcastMessage("Congratulations on reaching level 30! You have earned 50 gold.")
    elseif newLevel >= 40 and oldLevel < 40 then
        player:ModifyMoney(1000000) -- 100g
        player:SendBroadcastMessage("Congratulations on reaching level 40! You have earned 100 gold.")
    elseif newLevel >= 50 and oldLevel < 50 then
        player:ModifyMoney(2000000) -- 200g
        player:SendBroadcastMessage("Congratulations on reaching level 50! You have earned 200 gold.")
    elseif newLevel >= 60 and oldLevel < 60 then
        player:ModifyMoney(3000000) -- 300g
        player:SendBroadcastMessage("Congratulations on reaching level 60! You have earned 300 gold.")
    elseif newLevel >= 70 and oldLevel < 70 then
        player:ModifyMoney(4000000) -- 400g
        player:SendBroadcastMessage("Congratulations on reaching level 70! You have earned 400 gold.")
    elseif newLevel >= 80 and oldLevel < 80 then
        player:AddItem(40753, 200) -- 200 EOV
        player:ModifyMoney(5000000) -- 500g
        player:SendBroadcastMessage("Congratulations on reaching level 80! You have been awarded 200 Emblems of Valor and 500 gold for your accomplishment.")
    end
end

-- Register the player level change event.
RegisterPlayerEvent(13, OnLevelUp)
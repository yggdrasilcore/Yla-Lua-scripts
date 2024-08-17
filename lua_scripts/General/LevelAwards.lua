local LEVEL_MOUNTS_AND_STONE = 10
local LEVEL80 = 80

function OnLevelUp(event, player, oldLevel)
    local newLevel = player:GetLevel()
    local team = player:GetTeam()

    if newLevel >= LEVEL_MOUNTS_AND_STONE and oldLevel < LEVEL_MOUNTS_AND_STONE then
        player:LearnSpell(33389) --riding
        if team == 0 then
            player:LearnSpell(472)  --alliance mount
        elseif team == 1 then
            player:LearnSpell(578)  --horde mount
        end
        player:SendBroadcastMessage("Congratulations on reaching level 10! You have received your mall stone and a mount.")
    elseif newLevel >= LEVEL80 and oldLevel < LEVEL80 then
        player:AddItem(40753, 200) --200 EOV
        player:SendBroadcastMessage("Congratulations on reaching level 80! You have been awarded 200 Emblems of Valor for your accomplishment.")
    end
end

-- Register the player level change event.
RegisterPlayerEvent(13, OnLevelUp)

-- Print statement to confirm script loading
print("Level-up awards script loaded!") --for console debugging
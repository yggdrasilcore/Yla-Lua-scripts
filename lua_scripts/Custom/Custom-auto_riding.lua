function MountSpeed(event, player, oldLevel)
    if oldLevel == 9 then  -- This means the player just reached level 10
        player:LearnSpell(33388)
        player:SetSkill(762, 75, 75, 75)
        --print("Player hit level 10!") --for console debugging
    end
end

RegisterPlayerEvent(13, MountSpeed)  -- 13 is PLAYER_LEVEL_CHANGED
print("Level 10 mount and riding loaded!") --for console debugging
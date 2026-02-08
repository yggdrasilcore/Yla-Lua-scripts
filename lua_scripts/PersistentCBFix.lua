local function OnKillCreature(event, killer, killed)
    if not (killer:GetMap():IsDungeon() or killer:GetMap():IsRaid()) then
        return
    end
    
    if not killer:IsInCombat() then
        return
    end
    
    -- print("Player "..killer:GetName().." just killed "..killed:GetName()..", checking if we need to clear combat!")
    
    -- Check all nearby creatures in combat within 500 yards
    local nearbyCreatures = killer:GetCreaturesInRange(500)
    local nearbyPlayers = killer:GetPlayersInRange(2000)
    local playerThreatFound = false
    
    if nearbyCreatures then
        for _, creature in pairs(nearbyCreatures) do
            if creature:IsInCombat() and (creature:IsAlive() or creature:GetHealth() > 0) then
                local threatList = creature:GetThreatList()
                
                if threatList then
                    for _, threatInfo in pairs(threatList) do
                        local threatStr = tostring(threatInfo)
                        if threatStr:find("Player:") then
                            playerThreatFound = true
                            break
                        end
                    end
                end
                
                if playerThreatFound then
                    break  -- Exit creature loop if we found any player threat
                end
            end
        end
    end
    
    -- If no player threats found, clear combat for all nearby players
    if not playerThreatFound then
        -- Clear killer's combat
        if killer:IsInCombat() then
            print("Killer "..killer:GetName().." has no valid threat entries! Clearing combat of player, group and pets...")
            killer:SetData("cbstoptime", os.time())
            killer:RunCommand("combatstop")
        end
        
        -- Clear nearby players' combat
        if nearbyPlayers then
            for _, player in pairs(nearbyPlayers) do
                if player:IsInCombat() then
                    player:SetData("cbstoptime", os.time())
                    player:RunCommand("combatstop")
                end
            end
        end
        
        -- Clear combat for player-owned creatures
        if nearbyCreatures then
            for _, creature in pairs(nearbyCreatures) do
                if creature:IsInCombat() and creature:GetOwner() and creature:GetOwner():ToPlayer() then
                    creature:ClearInCombat()
                end
            end
        end
    end
end

RegisterPlayerEvent(7, OnKillCreature)
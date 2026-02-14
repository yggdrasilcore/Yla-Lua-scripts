 
local function RemoveRaidIconsOnDeath(event, obj1, player)
    if event == 8 and not isPlayerBot[player:GetName()] then return end -- Ensures we don't process player death twice as this is in event 7 (packet) anyway
    
    local group = player:GetGroup()
    if not group then return end
    
    local members = group:GetMembers()
    for _, member in pairs(members) do
        if member:IsAlive() and member:IsInCombat() then
            local distance = player:GetDistance(member)
            if distance <= 100 then
                return
            end
        end
    end
    
    --[[
    local hasBots = false
    for _, member in pairs(members) do
        local memberName = member:GetName()
        if activeBots[memberName] then
            hasBots = true
            break
        end
    end
    
    if not hasBots then return end
    --]]
    
    group:SetTargetIcon(7, 0, player:GetGUID())
end

RegisterPacketEvent(0x269, 7, RemoveRaidIconsOnDeath) -- This captures all player deaths but packet events don't work on shadows, 
RegisterPlayerEvent(8, RemoveRaidIconsOnDeath) -- This works for all creature kills but not other death (shadows can only be killed by creatures, not gravity/drowning etc.)

-- END RAID ICONS SHADOW HANDLING

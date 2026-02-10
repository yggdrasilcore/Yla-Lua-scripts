function GetPlayersByRole(creature, range)
    local tanks = {}
    local healers = {}
    local melee = {}
    local casters = {}
    local bots = {}
    
    local players = creature:GetPlayersInRange(range or 100)
    
    for _, player in ipairs(players) do
        if player:IsAlive() and player:IsInCombat() and isPlayerBot[player:GetName()] then
            table.insert(bots, player)
            
            if IsTank(player) then
                table.insert(tanks, player)
            end
            if player:HasHealSpec() then
                table.insert(healers, player)
            end
            if player:HasMeleeSpec() then
                table.insert(melee, player)
            end
            if player:HasCasterSpec() then
                table.insert(casters, player)
            end
        end
    end
    
    table.sort(tanks, function(a, b) return a:GetMaxHealth() > b:GetMaxHealth() end)
    table.sort(healers, function(a, b) return a:GetMaxPower(0) > b:GetMaxPower(0) end)
    
    return tanks, healers, melee, casters, bots
end
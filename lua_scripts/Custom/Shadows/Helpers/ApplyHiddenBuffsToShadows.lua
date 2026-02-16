local tankBuffs = {39423}
local casterBuffs = {51040, 31750, 34772}
local healerBuffs = {51040, 51041}
local meleeBuffs = {40933, 42039, 42107, 47999, 48007, 48015, 48216, 48273, 48390, 48643, 49116, 53356, 53025, 52995, 52946}

function ApplyHiddenBuffsToShadows(player)
    if not isPlayerBot[player:GetName()] then return end
    
    local buffsToApply = {}
    
    if IsTank(player) then
        buffsToApply = tankBuffs
    elseif player:HasHealSpec() then
        buffsToApply = healerBuffs
    elseif player:HasMeleeSpec() or (player:GetClass() == 3) then
        buffsToApply = meleeBuffs
    elseif player:HasCasterSpec() then
        buffsToApply = casterBuffs
    end
    
    for _, spellId in ipairs(buffsToApply) do
        player:AddAura(spellId, player)
    end
end

local function RemoveHiddenBuffs(player)
    if not isPlayerBot[player:GetName()] then return end
    
    local allBuffs = {}
    for _, v in ipairs(tankBuffs) do table.insert(allBuffs, v) end
    for _, v in ipairs(casterBuffs) do table.insert(allBuffs, v) end
    for _, v in ipairs(healerBuffs) do table.insert(allBuffs, v) end
    for _, v in ipairs(meleeBuffs) do table.insert(allBuffs, v) end
    
    for _, spellId in ipairs(allBuffs) do
        player:RemoveAura(spellId)
    end
end

local function OnMapChange(event, player)
    if not player then return end
    if not isPlayerBot[player:GetName()] then return end
    
    RemoveHiddenBuffs(player)
end

local function OnLeaveCombat(event, player)
    if not player then return end
    if not isPlayerBot[player:GetName()] then return end
    
    RemoveHiddenBuffs(player)
end

RegisterPlayerEvent(28, OnMapChange)
RegisterPlayerEvent(34, OnLeaveCombat)
local RP_GG_ITEM = 42986
local RP_GG_SPELL = 49761
local RP_GG_MIN_RANGE = 12
local RP_GG_MAX_RANGE = 150

local RP_GG_TARGETS = {
    [28312] = true,
    [32627] = true,
    [27881] = true,
    [28094] = true,
}

local function OnUseRPGG(event, player, item, target)
    local creatures = player:GetCreaturesInRange(RP_GG_MAX_RANGE)
    if not creatures then  return true end
    
    local best = nil
    local bestDist = math.huge
    local pf = player:GetFaction()
    
    for _, creature in ipairs(creatures) do
        if RP_GG_TARGETS[creature:GetEntry()] then
            local cf = creature:GetFaction()
            if (pf == 1 or pf == 3 or pf == 4 or pf == 8 or pf == 927) ~= (cf == 1 or cf == 3 or cf == 4 or cf == 8 or cf == 927) then
                local dist = player:GetDistance(creature)
                
                if dist >= RP_GG_MIN_RANGE and dist < bestDist then
                    bestDist = dist
                    best = creature
                end
            end
        end
    end
    
    if not best then return true end
    
    player:CastSpell(best, RP_GG_SPELL, true)
    player:RegisterEvent(function(e,d,r,player) player:RemoveItem(RP_GG_ITEM, 1) end, 1)
    return false
end

RegisterItemEvent(RP_GG_ITEM, 2, OnUseRPGG)
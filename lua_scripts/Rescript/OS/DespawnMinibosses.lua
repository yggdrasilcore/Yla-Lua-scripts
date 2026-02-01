local function DespawnMinibosses(event, player, creature)
    if creature:GetEntry() ~= 28860 then return end
    
    local minibosses = creature:GetCreaturesInRange(1000)
    
    for _, miniboss in pairs(minibosses) do
        local entry = miniboss:GetEntry()
        if entry == 30451 or entry == 30452 or entry == 30449 then
            miniboss:DespawnOrUnsummon()
        end
    end
end

RegisterPlayerEvent(7, DespawnMinibosses)
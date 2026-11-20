if GetStateMapId() == -1 then return end

SpellsUsingSoulShards = {
    30146, 30842, 67514, 691, 8722, 712, 12746, 25112, 43896, 697, 11017, 45789,
    6366, 17951, 17952, 17953, 27250, 60219, 60220, 693, 20752, 20755, 20756,
    20757, 27238, 47884, 2362, 17727, 17728, 28172, 47886, 47888, 38376, 31797,
    38456, 42354, 30940, 28023, 6201, 6202, 5699, 11729, 11730, 27230, 47871,
    47878, 16633, 12890, 1098, 11725, 11726, 61191, 23058, 23062, 23061, 29134,
    29160, 29893, 58887, 32928, 46546, 32899, 61993, 698, 62735, 17877, 18867,
    18868, 18869, 18870, 18871, 27263, 30546, 47826, 47827, 6353, 17924, 27211,
    30545, 47824, 47825, 29858
}

local function OnSpellCast(event, player, spell, skipCheck)
    if player:GetClass() ~= 9 then return end
    if not player:IsBot() then return end
    player:AddItem(6265, 1)
end

for _, spellId in ipairs(SpellsUsingSoulShards) do
    RegisterSpellEvent(spellId, 2, OnSpellCast)
end

local function OnWarlockShadowEnterMap(event, player)
    if player:GetClass() ~= 9 then return end
    if not player:IsBot() then return end
    if not player:HasItem(6265) then player:AddItem(6265, 1) end
end

RegisterPlayerEvent(28, OnWarlockShadowEnterMap)
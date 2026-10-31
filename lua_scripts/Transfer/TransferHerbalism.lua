if GetStateMapId() ~= -1 then return end

local HERBALISM_SKILL = 182
local BASE_SPELLS = {
    2383,   -- Find Herbs
    2366,   -- Basic Herbalism spell
    32605   -- Basic Herbalism spell 2
}
local SKILL_SPELL_PAIRS = {
    {75, 2368},    -- Find Herbs (Apprentice)
    {150, 3570},   -- Find Herbs (Journeyman)
    {225, 11993},  -- Find Herbs (Expert)
    {300, 28695},  -- Find Herbs (Artisan)
    {375, 50300}   -- Find Herbs (Master)
}

local function OnPlayerLogin(event, player)
    -- Check if player has herbalism skill
    if player:HasSkill(HERBALISM_SKILL) then
        -- First check and learn base spells
        for _, spellId in ipairs(BASE_SPELLS) do
            if not player:HasSpell(spellId) then
                player:LearnSpell(spellId)
            end
        end
        
        -- Then check skill level and teach appropriate Find Herbs spells
        local skillLevel = player:GetSkillValue(HERBALISM_SKILL)
        for _, pair in ipairs(SKILL_SPELL_PAIRS) do
            local requiredSkill = pair[1]
            local spellId = pair[2]
            
            if skillLevel >= requiredSkill and not player:HasSpell(spellId) then
                player:LearnSpell(spellId)
            end
        end
    end
end

RegisterPlayerEvent(3, OnPlayerLogin) -- 3 is PLAYER_EVENT_ON_LOGIN
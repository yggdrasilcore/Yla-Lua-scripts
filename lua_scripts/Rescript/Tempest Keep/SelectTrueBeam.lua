-- Prevents "Select True Beam" aura for persisting forever

local SELECT_TRUE_BEAM = 33365

local function SetAuraDuration(caster)
    local players = caster:GetPlayersInRange(1000)
    for _, player in ipairs(players) do
        if player:HasAura(SELECT_TRUE_BEAM) then
            local aura = player:GetAura(SELECT_TRUE_BEAM)
            if aura then
                aura:SetDuration(500) -- I don't know if this aura actually does anythng, setting to a short duration just to be safe
            end
        end
    end
end

local function OnSpellCast(event, caster, spell)
	SetAuraDuration(caster)
end

RegisterSpellEvent(SELECT_TRUE_BEAM, 2, OnSpellCast)
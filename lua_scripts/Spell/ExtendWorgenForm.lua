local function ExtendWorgenForm(event, caster, spell)
    if not caster:ToPlayer() then return end
    caster:RegisterEvent(function(e,d,r,player)
        local aura = player:GetAura(32819)
        if not aura then return end
        aura:SetDuration(5 * 60 * 1000)
    end, 1)
end

RegisterSpellEvent(32819, 2, ExtendWorgenForm)
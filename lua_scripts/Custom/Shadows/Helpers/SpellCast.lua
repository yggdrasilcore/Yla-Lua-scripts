function DisableSpellCast(player, duration)
    if player:HasCasterSpec() then
        player:AddAura(302250, player) -- 4 Second silence 
        if duration then
            local aura = player:GetAura(302250)
            if aura then
                aura:SetDuration(duration * 1000)
            end
        end
    elseif player:GetClass() == 3 then -- Stop casting Steady Shot
        player:StopSpellCast(56641)
        player:StopSpellCast(34120)
        player:StopSpellCast(49051)
        player:StopSpellCast(49052)
    end
end

function AllowSpellCast(player)
    if player:HasAura(302250) then
        player:RemoveAura(302250) -- Remove silence
    end
end
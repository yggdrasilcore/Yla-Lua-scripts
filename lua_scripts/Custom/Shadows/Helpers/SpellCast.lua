function DisableSpellCast(player, duration)
    if player:HasCasterSpec() then
        player:AddAura(30225, player) -- 4 Second silence 
        if duration then
            local aura = player:GetAura(30225)
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
    if player:HasAura(30225) then
        player:RemoveAura(30225) -- Remove silence
    end
end
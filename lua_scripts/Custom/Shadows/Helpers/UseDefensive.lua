function UseDefensive(player)
    local class = player:GetClass()
    
    if class == 1 then
        if IsTank(player) then
            if not player:HasAura(871) then
                player:CastSpell(player, 871, true) -- Shield Wall
            end
        else
            if not player:HasAura(55694) then
                player:CastSpell(player, 55694, true) -- Frenzied Regeneration
            end
        end
    elseif class == 2 then
        if not player:HasAura(498) then
            player:AddAura(498, player) -- Divine Protection
        end
    elseif class == 3 then
        if not player:HasAura(19263) then
            player:CastSpell(player, 19263, true) -- Deterrence
        end
    elseif class == 4 then
        if not player:HasAura(26669) then
            player:CastSpell(player, 26669, true) -- Evasion
        end
        if not player:HasAura(48659) then
            player:CastSpell(player, 48659, true) -- Feint
        end
    elseif class == 5 then
        if player:HasSpell(47585) then
            if not player:HasAura(47585) then
                player:CastSpell(player, 47585, true) -- Disperse
            end
        else
            if not player:HasAura(48066) then
                player:AddAura(48066, player) -- Bubble
            end
            if not player:HasAura(48068) then
                player:AddAura(48068, player) -- Renew
            end
        end
    elseif class == 6 then
        if not player:HasAura(48792) then
            player:CastSpell(player, 48792, true) -- Icebound fortitude
        end
    elseif class == 7 then
        if player:HasSpell(30823) then
            if not player:HasAura(30823) then
                player:CastSpell(player, 30823, true) -- Shamanistic Rage
            end
        elseif player:HasSpell(61301) then
            if not player:HasAura(61301) then
                player:CastSpell(player, 61301, true) -- Riptide
            end
        else
            player:CastSpell(player, 58753, true) -- Stoneskin Totem
            player:CastSpell(player, 58739, true) -- Fire Resistance Totem
            player:CastSpell(player, 58745, true) -- Frost Resistance Totem
            player:CastSpell(player, 58749, true) -- Nature Resistance Totem
        end
    elseif class == 8 then
        if not player:HasAura(43020) then
            player:CastSpell(player, 43020, false) -- Mana Shield
        end
    elseif class == 9 then
        if player:HasSpell(19028) and not player:HasAura(19028) then
            player:CastSpell(player, 19028, true) -- Soul Link
        end
        player:CastSpell(player, 47875, true) -- Fel Healthstone
    elseif class == 11 then
        if not player:HasAura(22812) then
            player:CastSpell(player, 22812, true) -- Barkskin
        end
    end
end
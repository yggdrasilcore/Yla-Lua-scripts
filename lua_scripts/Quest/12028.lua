local WISP = 24465
local MORPH_DELAY_MS = 1550
local DEMORPH_DELAY_MS = 3*60*1000

local function OnWispForm(event, player, item, target)
    if not player:GetNearestGameObject(5, 188416) then -- Player is too farm from Brazier, don't do anything
        return
    end
    player:RegisterEvent(function(eventid, delay, repeats, player) -- Player should be done casting by now, 1.5 sec + a 50 ms safeguard
        if player and player:HasAura(47189) then -- If player finished casting, they have aura 47189 (Spiritual Insights)
            player:SetDisplayId(WISP)
        end
        player:RegisterEvent(function(eventid, delay, repeats, player)
            if player and (player:GetDisplayId() == WISP) then
                player:DeMorph()
            end
        end, DEMORPH_DELAY_MS) -- Aura 47189 lasts for 3 minutes, after which we remove the morph
    end, MORPH_DELAY_MS)
end

RegisterItemEvent(35907, 2, OnWispForm) -- 35907 is the incense item

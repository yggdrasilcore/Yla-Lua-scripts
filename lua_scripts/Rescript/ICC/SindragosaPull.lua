-- Multistate: Icecrown Citadel-only script (map 631).
if GetStateMapId() ~= 631 then return end

local function OnPullSindragosa(event, player, sindragosa)
    if sindragosa and sindragosa:GetEntry() == 36853 then
        if sindragosa:GetNearestCreature(300, 36789) then
            local players = sindragosa:GetPlayersInRange(130)
            for _, player in ipairs(players) do
                player:CastSpell(player, 70781, true)
            end
        end
    end
end

RegisterPlayerEvent(33, OnPullSindragosa)
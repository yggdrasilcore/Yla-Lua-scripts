if GetStateMapId() ~= -1 then return end

local function OnLootBatteredHilt(event, packet, player)
    if not player then return end
    player:RegisterEvent(function(e, d, r, player)
        if not player then return end
        if player:HasItem(50380) and player:IsAlliance() then
            player:RemoveItem(50380, 1)
            player:AddItem(50379, 1)
        elseif player:HasItem(50379) and not player:IsAlliance() then
            player:RemoveItem(50379, 1)
            player:AddItem(50380, 1)
        end
    end, 1)
end

RegisterPacketEvent(0x46A, 7, OnLootBatteredHilt)
local function OnLootBatteredHilt(event, packet, player)
	print("------- Logging overhead of OnLootBatteredHilt")
	player:RegisterEvent(function(e, d, r, player)
		if player:HasItem(50380) and player:IsAlliance() then
			player:RemoveItem(50380, 1)
			player:AddItem(50379, 1)
		elseif player:HasItem(50739) and not player:IsAlliance() then
			player:RemoveItem(50380, 1)
			player:AddItem(50379, 1)
		end
	end, 1)
end

RegisterPacketEvent(0x46A, 7, OnLootBatteredHilt)
local function OnPacketReceive(event, packet, player)
	local sel = player:GetSelection() -- Only proceed if player has a target
	if not sel then return end
	
	local target = sel:ToCreature() -- Only proceed if target is a creature
	
	if target then
		if target:GetEntry() == 26300 then return end  -- Do not process All-Buying Hobgoblin
		
		if not target:IsVendor() then return end -- Only proceed for vendors
		
		if target:GetOwner() then owner = target:GetOwner():ToPlayer() end
		if owner then return end -- Don't proceed for e.g., Twiggy or other owned creatures
		
		local aura = player:AddAura(35340, target)
		if aura then aura:SetDuration(20000) end -- Freeze vendors for 10 sec.
	
	end
end

RegisterPacketEvent(0x19E, 5, OnPacketReceive)
RegisterPacketEvent(0x17B, 5, OnPacketReceive)

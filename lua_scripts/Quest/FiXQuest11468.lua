local SPELL_ID = 44407
local NPC_ID = 24747
local ITEM_ID = 34120
local DELAY = 3000 -- 3 seconds in milliseconds

local function OnSpellCast(event, player, spell, skipCheck)
    if spell:GetEntry() == SPELL_ID then
	print("Fjord Hawk gathering cast!")
        local target = spell:GetTarget()
        if target and target:GetEntry() == NPC_ID then
            player:RemoveItem(34102, 1) --Removes fjord grub
			print("Fjord Hawk targeted!")
            player:RegisterEvent(function(eventId, delay, repeats, player)
                player:AddItem(ITEM_ID, 1)
				print("Awarding Fjord Hawk item!")
            end, DELAY, 1)
        end
    end
end

RegisterPlayerEvent(5, OnSpellCast)
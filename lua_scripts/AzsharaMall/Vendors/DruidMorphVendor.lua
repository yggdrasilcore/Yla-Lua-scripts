if GetStateMapId() ~= 37 then return end

local NPC_ID = 190098

local function OnGossipHello(event, player, object)
	if player:GetClass() == 11 then
		player:GossipClearMenu()
		player:GossipMenuAddItem(0, "I hear you're interested in the secrets of Kaldorei shapeshift morphing...", 0, 1)
		player:GossipSendMenu(1, object)
    else
        object:SendUnitWhisper("I only cater to Druids.", 0, player)
	end
end

local function OnGossipSelect(event, player, object, sender, intid, code)
    if intid == 1 then

        player:GossipClearMenu()

        player:GossipMenuAddItem(1, "Do you want to open the store to buy a Kaldorei Medallion?", 0, 2)
        player:GossipMenuAddItem(0, "We have nothing to discuss.", 0, 3)

        player:GossipSendMenu(1, object)
    elseif intid == 2 then
        player:SendAddonMessage("StoreOpenSearch", "Medallion", 7, player)
        player:GossipComplete()
    elseif intid == 3 then
        player:GossipComplete()
    end
end

RegisterCreatureGossipEvent(NPC_ID, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ID, 2, OnGossipSelect)
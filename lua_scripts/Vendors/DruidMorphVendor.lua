local NPC_ID = 190098
local VOTE_TOKEN_ID = 20880
local MORPH_ITEM = 17890
local PRICE = 50

local function OnGossipHello(event, player, object)
	if player:GetClass() == 11 then
		player:GossipClearMenu()
		player:GossipMenuAddItem(0, "I hear you're interested in the secrets of Kaldorei shapeshift morphing...", 0, 1)
		player:GossipSendMenu(1, object)
	else
		player:SendBroadcastMessage("I only cater to druids.")
	end
end

local function OnGossipSelect(event, player, object, sender, intid, code)
    if intid == 1 then

        player:GossipClearMenu()

        player:GossipMenuAddItem(1, "Do you want to buy a Kaldorei Medallion for " .. PRICE .. " Vote Tokens?", 0, 2)
        player:GossipMenuAddItem(0, "We have nothing to discuss.", 0, 3)

        player:GossipSendMenu(1, object)
    elseif intid == 2 then
        local hasEnoughVT = player:GetItemCount(VOTE_TOKEN_ID) >= 50
        local hasMorphItem = player:GetItemCount(MORPH_ITEM) > 0
        if hasEnoughVT and not hasMorphItem then
            player:RemoveItem(VOTE_TOKEN_ID, PRICE)

            player:AddItem(MORPH_ITEM, 1)

        elseif hasEnoughVT and hasMorphItem then
            player:SendBroadcastMessage("You already have a Kaldorei Medallion.")
		elseif not hasEnoughVT and hasMorphItem then
            player:SendBroadcastMessage("You already have a Kaldorei Medallion.")
		elseif not hasEnoughVT and not hasMorphItem then
            player:SendBroadcastMessage("You do not have enough Vote Tokens.")
        end
		if hasMorphItem then
		end
        player:GossipComplete()
    elseif intid == 3 then
        player:GossipComplete()
    end
end

RegisterCreatureGossipEvent(NPC_ID, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ID, 2, OnGossipSelect)

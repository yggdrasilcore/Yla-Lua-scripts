if GetStateMapId() == -1 then return end

local SMSG_CREATURE_QUERY_RESPONSE = 0x061

local function SendCreatureQueryResponse(player, entry, name, subname, iconName, typeFlags, creatureType, family, rank, killCredit1, killCredit2, modelId1, modelId2, modelId3, modelId4, modHealth, modMana, racialLeader, questItems, movementId)
    local packet = CreatePacket(SMSG_CREATURE_QUERY_RESPONSE, 100)
    packet:WriteULong(entry)
    packet:WriteString(name)
    packet:WriteString("")
    packet:WriteString("")
    packet:WriteString("")
    packet:WriteString(subname)
    packet:WriteString(iconName)
    packet:WriteULong(typeFlags)
    packet:WriteULong(creatureType)
    packet:WriteULong(family)
    packet:WriteULong(rank)
    packet:WriteULong(killCredit1)
    packet:WriteULong(killCredit2)
    packet:WriteULong(modelId1)
    packet:WriteULong(modelId2)
    packet:WriteULong(modelId3)
    packet:WriteULong(modelId4)
    packet:WriteFloat(modHealth)
    packet:WriteFloat(modMana)
    packet:WriteUByte(racialLeader)
    for i = 1, 6 do
        packet:WriteULong(questItems[i] or 0)
    end
    packet:WriteULong(movementId)
    player:SendPacket(packet)
end

local mapCreatures = {
    [409] = function(player)
        SendCreatureQueryResponse(player, 11502, "Ragnaros", "", "", 108, 4, 0, 3, 0, 0, 11121, 0, 0, 0, 330.0, 1.0, 0, {19017, 20951}, 0)
    end,
    [469] = function(player)
        SendCreatureQueryResponse(player, 11583, "Nefarian", "", "", 108, 2, 0, 3, 0, 0, 11380, 0, 0, 0, 650.0, 20.0, 0, {21138}, 188)
    end,
    [249] = function(player)
        SendCreatureQueryResponse(player, 36561, "Onyxian Lair Guard", "", "", 8, 2, 0, 1, 0, 0, 12891, 0, 0, 0, 15.0, 1.0, 0, {}, 0)
    end,
    [543] = function(player)
        SendCreatureQueryResponse(player, 17517, "Hellfire Sentry", "Herald's Sentry", "", 0, 7, 0, 1, 0, 0, 16577, 0, 0, 0, 3.5, 1.0, 0, {}, 0)
    end,
    [547] = function(player)
        SendCreatureQueryResponse(player, 25740, "Ahune", "The Frost Lord", "", 72, 4, 0, 1, 0, 0, 23344, 0, 0, 0, 40.0, 1.0, 0, {}, 0)
        SendCreatureQueryResponse(player, 25865, "Frozen Core", "", "", 0, 4, 0, 1, 0, 0, 23447, 0, 0, 0, 40.0, 1.0, 0, {}, 0)
    end,
    [560] = function(player)
        SendCreatureQueryResponse(player, 17848, "Lieutenant Drake", "", "", 0, 7, 0, 1, 0, 0, 17386, 0, 0, 0, 12.0, 1.0, 0, {}, 144)
    end,
    [571] = function(player)
        SendCreatureQueryResponse(player, 28498, "The Lich King", "", "", 4, 6, 0, 3, 0, 0, 28122, 0, 0, 0, 2000.0, 500.0, 0, {}, 53)
        SendCreatureQueryResponse(player, 23795, "Dark Iron Antagonist", "", "", 0, 7, 0, 0, 0, 0, 21826, 21827, 21828, 21829, 1.0, 1.0, 0, {}, 0)
        SendCreatureQueryResponse(player, 29183, "The Lich King", "", "", 44, 6, 0, 3, 0, 0, 24191, 0, 0, 0, 2000.0, 500.0, 0, {}, 169)
    end,
    [595] = function(player)
        SendCreatureQueryResponse(player, 27915, "Chromie", "", "", 0, 2, 0, 0, 0, 0, 10008, 0, 0, 0, 1.35, 1.0, 0, {}, 0)
        SendCreatureQueryResponse(player, 26533, "Mal'Ganis", "", "", 72, 3, 0, 1, 0, 0, 26582, 0, 0, 0, 30.0, 10.0, 0, {}, 0)
     end,
    [603] = function(player)
        SendCreatureQueryResponse(player, 34099, "Worm Hole", "", "", 0, 4, 0, 1, 0, 0, 28460, 0, 0, 0, 1.0, 1.0, 0, {}, 0)
        SendCreatureQueryResponse(player, 34129, "Nature Bomb", "", "", 0, 10, 0, 0, 0, 0, 23258, 0, 0, 0, 2.0, 1.0, 0, {}, 0)
        SendCreatureQueryResponse(player, 33288, "Yogg-Saron", "", "", 108, 10, 0, 3, 0, 0, 28817, 0, 0, 0, 788.813, 1.0, 0, {}, 0)
    end,
    [608] = function(player)
        SendCreatureQueryResponse(player, 29365, "Void Sentry", "", "", 72, 3, 0, 0, 0, 0, 23767, 0, 0, 0, 1.0, 1.0, 0, {}, 0)
    end,
    [615] = function(player)
        SendCreatureQueryResponse(player, 30882, "Twilight Egg", "", "", 1088, 10, 0, 1, 0, 0, 28014, 0, 0, 0, 2.0, 1.0, 0, {}, 0)
    end,
    [616] = function(player)
        SendCreatureQueryResponse(player, 30161, "Wyrmrest Skytalon", "", "", 0, 2, 0, 0, 0, 0, 25835, 0, 0, 0, 7.93651, 1.0, 0, {}, 231)
        SendCreatureQueryResponse(player, 32295, "Alexstrasza the Life-Binder", "Queen of the Dragons", "", 0, 2, 0, 3, 0, 0, 27569, 0, 0, 0, 10000.0, 1000.0, 0, {}, 0)
    end,
    [631] = function(player)
        SendCreatureQueryResponse(player, 37501, "Nerub'ar Champion", "", "", 0, 6, 0, 1, 0, 0, 26194, 0, 0, 0, 25.0, 1.0, 0, {}, 0)
        SendCreatureQueryResponse(player, 37502, "Nerub'ar Webweaver", "", "", 0, 6, 0, 1, 0, 0, 31050, 0, 0, 0, 25.0, 12.0, 0, {}, 0)
    end,
    [649] = function(player)
        SendCreatureQueryResponse(player, 35877, "The Lich King", "", "", 36, 6, 0, 3, 0, 0, 25337, 0, 0, 0, 2000.0, 500.0, 0, {}, 169)
    end,
    [724] = function(player)
        SendCreatureQueryResponse(player, 40142, "Halion", "The Twilight Destroyer", "", 1132, 2, 0, 3, 0, 0, 31952, 0, 0, 0, 800.0, 1.0, 0, {}, 150)
    end,
}

local function OnMapChange(event, player)
    if player:IsBot() then return end
    local mapId = player:GetMapId()
    if mapCreatures[mapId] then
        mapCreatures[mapId](player)
    end
end

RegisterPlayerEvent(28, OnMapChange)
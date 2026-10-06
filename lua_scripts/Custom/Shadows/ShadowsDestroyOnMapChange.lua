local function SMSG_DESTROY_OBJECT(target, object, onDeath)
    local packet = CreatePacket(0x0AA, 9)
    packet:WriteGUID(object:GetGUID())
    packet:WriteUByte(onDeath and 1 or 0)
    target:SendPacket(packet)
end

local function sendDestroy(player, storedMap)
    local players = {}
    require("Multistate").ForEachPlayer(function(p) table.insert(players, p) end)
    for _, p in ipairs(players) do
        if p:GetMapId() == storedMap then
            SMSG_DESTROY_OBJECT(p, player, false)
        end
    end
end

local function checkMap(eventId, delay, repeats, player)
    if not player:IsBot() then return end

    local storedMap = player:GetData("BotMap")
    local currentMap = player:GetMapId()

    if storedMap and storedMap ~= currentMap then
        sendDestroy(player, storedMap)
    end

    player:SetData("BotMap", currentMap)
end

local function onMapChanged(event, player)
    if not player then return end

    local storedMap = player:GetData("BotMap")

    if storedMap then
        checkMap(nil, nil, nil, player)
    else
        player:RegisterEvent(checkMap, 2000, 1, player)
    end
end

local function onLogout(event, player)
    if not player then return end
    if not player:IsBot() then return end

    local storedMap = player:GetData("BotMap")
    if not storedMap then return end

    sendDestroy(player, storedMap)
end

RegisterPlayerEvent(28, onMapChanged)
RegisterPlayerEvent(4, onLogout)

require("Multistate").ForEachPlayer(function(player)
    onMapChanged(nil, player)
end)
local AIO = require("AIO")

local function OnPlayerLogin(event, player)
    AIO.Handle(player, "TwiggyFix", "Initialize")
end

local function OnReloadPacket(event, packet, player)
    AIO.Handle(player, "TwiggyFix", "Initialize")
end

RegisterPlayerEvent(3, OnPlayerLogin)
RegisterPacketEvent(0x0EB, 5, OnReloadPacket)
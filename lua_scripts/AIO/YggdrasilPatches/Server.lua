local AIO = require("AIO")

local UIFixLimit = {}
local NoAFKLogoutZones = {
    [3703] = 1, -- shattrath
    [4395] = 1, -- dalaran
    -- ally capitals
    [1519] = 1, -- stormwind
    [1537] = 1, -- ironforge
    [1657] = 1, -- darnassus
    [3557] = 1, -- exodar
    -- horde capitals
    [1637] = 1, -- orgrimmar
    [1638] = 1, -- thunder bluff
    [1497] = 1, -- undercity
    [3487] = 1, -- silvermoon
    -- mall
    [268] = 1, -- azshara crater
}

local function OnAddonMessageReceived(event, player, _type, header, data, target)
	if player and _type == 7 then
        if target and player:GetName() == target:GetName() then
            local name = player:GetName()
            if(header == "CAIO") then
                if string.find(data, "Init") then
                    if (UIFixLimit[name] and UIFixLimit[name] == os.time()) then
                        return
                    end
                    UIFixLimit[name] = os.time()
                    AIO.Handle(player, "UIFix", "Initialize")
                end
            end
        end
    end
end

local function AIOUIFIXCMD(event, player, command)
    if command == "32819" then
        if player:HasAura(32819) then
            local aura = player:AddAura(32819, player)
            aura:SetDuration(5 * 60 * 1000)
        end
        return false
    end

    if command == "afk" then
        if player:IsAFK() 
		and NoAFKLogoutZones[player:GetZoneId()]
		then
            player:ToggleAFK()
        end
        return false
    end
	
end

RegisterServerEvent(30, OnAddonMessageReceived)
RegisterPlayerEvent(42, AIOUIFIXCMD)
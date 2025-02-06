local AIO = require("AIO")

local UIFixLimit = {}

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

RegisterServerEvent(30, OnAddonMessageReceived)

local function WorgenForm(event, player, command)
    if command == "32819" then
        if player:HasAura(32819) then
            local aura = player:AddAura(32819, player)
            aura:SetDuration(5 * 60 * 1000)
        end
        return false
    end
end

RegisterPlayerEvent(42, WorgenForm)
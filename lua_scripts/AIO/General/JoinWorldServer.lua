local function onLoginEvent(event, player)
    if event == 30 or (event == 3 and player:GetClass() == 6 and player:GetLevel() == 55) then
        player:RegisterEvent(function(event, delay, repeats, player)
            player:SendAddonMessage("NewCharacterJoinWorld", "join", 7, player)
        end, 5000, 1)
    end
end

RegisterPlayerEvent(30, onLoginEvent)
RegisterPlayerEvent(3, onLoginEvent)
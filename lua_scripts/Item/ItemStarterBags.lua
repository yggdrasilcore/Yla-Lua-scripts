function FirstLogin(event, player)
    if player:GetLevel() == 1 then
        --SendWorldMessage("Hello "..player:GetName()..", welcome to Yggdrasil!");
        player:EquipItem(4497, 19)
        player:EquipItem(4497, 20)
        player:EquipItem(4497, 21)
        player:EquipItem(4497, 22)
        player:EquipItem(4497, 23)
        player:ModifyMoney(100000)
    end
end

RegisterPlayerEvent(30, FirstLogin)
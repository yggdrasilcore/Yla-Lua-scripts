local FoodObjects = {
    -- gameObjectId
    193061, -- Refreshment Table (level 80)
    186812, -- Refreshment Table (level 70)
    192152, -- Big Berry Pie Cake
    192783, -- Dalaran Apple Bowl
    193965, -- Dalaran Swiss Wheel
    192151, -- Lovely Cake
    193964, -- Aged Dalaran Sharp Wheel
    192150, -- Chocolate Celebration Cake
    195303, -- Bountiful Feast
    193056, -- Small Feast
    193055, -- Gigantic Feast
    192675, -- Fish Feast
    192625, -- Great Feast
}

local function OnFoodUse(event, go, player)
    local bots = go:GetPlayersInRange(10, 0, 1)

    if bots then
        for _, bot in pairs(bots) do
            local shadow = bot:ToShadow()
            local botMaster = shadow and shadow:GetMaster()
            if botMaster and botMaster:GetGUID() == player:GetGUID() then
                if go:GetEntry() == 192675 then -- Fish
                    bot:CastSpell(bot, 57397, true)
                    bot:RegisterEvent(function(e, d, p, bot)
                        bot:AddAura(57399, bot)
                    end, 10000)
                elseif go:GetEntry() == 192625 then -- Great
                    bot:CastSpell(bot, 57337, true)
                    bot:RegisterEvent(function(e, d, p, bot)
                        bot:AddAura(57294, bot)
                    end, 10000)
                elseif go:GetEntry() == 193056 then -- Small
                    bot:CastSpell(bot, 58475, true)
                    bot:RegisterEvent(function(e, d, p, bot)
                        bot:AddAura(58479, bot)
                    end, 10000)
                elseif go:GetEntry() == 195303 then -- Bountiful
                    bot:CastSpell(bot, 66477, true)
                    bot:RegisterEvent(function(e, d, p, bot)
                        bot:AddAura(66623, bot)
                    end, 10000)
                elseif go:GetEntry() == 193055 then -- Gigantic
                    bot:CastSpell(bot, 58466, true)
                    bot:RegisterEvent(function(e, d, p, bot)
                        bot:AddAura(58468, bot)
                    end, 10000)
                else -- Other food
                    bot:CastSpell(bot, 61829, true)
                end
            end
        end
    end
end

for _, gameObjectId in pairs(FoodObjects) do
    RegisterGameObjectEvent(gameObjectId, 14, OnFoodUse)
end

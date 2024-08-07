local spellRanks = {
    ["Mining"] = {2575, 2576, 3564, 10248, 29354, 50310},
    ["Herbalism"] = {2366, 2368, 3570, 11993, 28695, 50300},
    ["Blacksmithing"] = {2018, 3100, 3538, 9785, 29844, 51300},
    ["Engineering"] = {4036, 4037, 4038, 12656, 30350, 51306},
    ["Tailoring"] = {3908, 3909, 3910, 12180, 26790, 51309},
    ["Enchanting"] = {7411, 7412, 7413, 13920, 28029, 51313},
    ["Alchemy"] = {2259, 3101, 3464, 11611, 28596, 51304},
    ["Skinning"] = {8613, 8617, 8618, 10768, 32678, 50305},
    ["Leatherworking"] = {2108, 3104, 3811, 10662, 32549, 51302},
    ["Inscription"] = {45357, 45358, 45359, 45360, 45361, 45363},
    ["Cooking"] = {2550, 3102, 3413, 18260, 33359, 51296},
    ["Fishing"] = {7620, 7731, 7732, 18248, 33095, 51294},
    ["First Aid"] = {3273, 3274, 7924, 10846, 27028, 45542},
    ["Riding"] = {33388, 33391, 34090, 34091}
}

local function OnPlayerLogin(event, player)
    for profession, spells in pairs(spellRanks) do
        for i = #spells, 1, -1 do
            if player:HasSpell(spells[i]) then
                for j = 1, i-1 do
                    player:LearnSpell(spells[j])
                end
                break
            end
        end
    end
end

RegisterPlayerEvent(3, OnPlayerLogin)
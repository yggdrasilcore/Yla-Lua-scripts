local AIO = require("AIO")

local CustomShop = AIO.AddHandlers("CustomShop", {})

local TOKEN_ITEMS = {
    ["Community Tokens"] = 19322,
    ["Vote Tokens"] = 20880,
    ["Activity Tokens"] = 37742,
}

local itemsInfo = {
    [0] = {
        -- Home tab
        { id = 1072, name = "Sap of Yggdrasil", itemType = "item", quantity = "1", costType = "Community Tokens",    cost = 25 },
        { id = 44728, name = "Potion of Yggdrasil Rejuvenation", itemType = "item", quantity = "1", costType = "Community Tokens",    cost = 25 },
        { id = 23578, name = "Twiggy's Tonic", itemType = "item", quantity = "1", costType = "Community Tokens",    cost = 25 },
        { id = 41415, name = "Twiggy's Wisdom", itemType = "item", quantity = "1", costType = "Community Tokens",    cost = 25 },
        { id = 20739, name = "Feathers of Azeroth", itemType = "item", quantity = "1", costType = "Vote Tokens",    cost = 150 },
        { id = 20739, name = "Feathers of Azeroth", itemType = "item", quantity = "1", costType = "Community Tokens",    cost = 15 },
        { id = 17890, name = "Druid Medallion", itemType = "item", quantity = "1", costType = "Vote Tokens",    cost = 50 },
        { id = 17890, name = "Druid Medallion", itemType = "item", quantity = "1", costType = "Community Tokens",    cost = 10 },
        { id = 23162, name = "Trunk of Yggdrasil", itemType = "item", quantity = "1", costType = "Vote Tokens",    cost = 100 },
        { id = 23162, name = "Trunk of Yggdrasil", itemType = "item", quantity = "1", costType = "Community Tokens",    cost = 15 },
        { id = 5041, name = "Demonic Scroll", itemType = "item", quantity = "1", costType = "Vote Tokens",    cost = 25 },
        { id = 5041, name = "Demonic Scroll", itemType = "item", quantity = "1", costType = "Community Tokens",    cost = 5 },
        { id = 4427, name = "Enchant Scroll", itemType = "item", quantity = "1", costType = "Community Tokens",    cost = 2 },
    },
    [1] = {
        --  Spells tab
        { id = 7, name = "Suicide",  itemType = "spell", quantity = "1", costType = "Community Tokens", cost = 10 },
        { id = 427, name = "Tele Monastery",  itemType = "spell", quantity = "1", costType = "Community Tokens", cost = 10 },
        { id = 32819, name = "Worgen Form",  itemType = "spell", quantity = "1", costType = "Community Tokens", cost = 25 },
        { id = 8041, name = "Serpent Form",  itemType = "spell", quantity = "1", costType = "Community Tokens", cost = 25 },
        { id = 3329, name = "Frog Form",  itemType = "spell", quantity = "1", costType = "Community Tokens", cost = 25 },
        { id = 24717, name = "Costume",  itemType = "spell", quantity = "1", costType = "Community Tokens", cost = 25 },
        { id = 24737, name = "Costume",  itemType = "spell", quantity = "1", costType = "Community Tokens", cost = 25 },
        { id = 24718, name = "Costume",  itemType = "spell", quantity = "1", costType = "Community Tokens", cost = 25 },
        { id = 24719, name = "Costume",  itemType = "spell", quantity = "1", costType = "Community Tokens", cost = 25 },
        { id = 24724, name = "Costume",  itemType = "spell", quantity = "1", costType = "Community Tokens", cost = 25 },
    },
    [2] = {
        --  Raid tab
        { id = 49634, name = "Yggdrasil Drums of the Wild", itemType = "item", quantity = "1", costType = "Activity Tokens",    cost = 50 },
        { id = 49633, name = "Yggdrasil Drums of Kings", itemType = "item", quantity = "1", costType = "Activity Tokens",    cost = 50 },
        { id = 29530, name = "Yggdrasil Drums of Speed", itemType = "item", quantity = "1", costType = "Activity Tokens",    cost = 50 },
        { id = 49632, name = "Yggdrasil Runescroll of Fortitude", itemType = "item", quantity = "20", costType = "Activity Tokens",    cost = 50 },
        { id = 25886, name = "Raid Flare", itemType = "item", quantity = "20", costType = "Activity Tokens", cost = 100 },
        { id = 23771, name = "Raid Flare", itemType = "item", quantity = "20", costType = "Activity Tokens", cost = 100 },
        { id = 23770, name = "Raid Flare", itemType = "item", quantity = "20", costType = "Activity Tokens", cost = 100},
        { id = 23769, name = "Raid Flare", itemType = "item", quantity = "20", costType = "Activity Tokens", cost = 100},
        { id = 23768, name = "Raid Flare", itemType = "item", quantity = "20", costType = "Activity Tokens", cost = 100},
        { id = 49634, name = "Yggdrasil Drums of the Wild", itemType = "item", quantity = "1", costType = "Community Tokens",    cost = 2 },
        { id = 49633, name = "Yggdrasil Drums of Kings", itemType = "item", quantity = "1", costType = "Community Tokens",    cost = 2 },
        { id = 29530, name = "Yggdrasil Drums of Speed", itemType = "item", quantity = "1", costType = "Community Tokens",    cost = 2 },
        { id = 49632, name = "Yggdrasil Runescroll of Fortitude", itemType = "item", quantity = "20", costType = "Community Tokens",    cost = 2 },
        { id = 25886, name = "Raid Flare", itemType = "item", quantity = "20", costType = "Community Tokens",    cost = 5 },
        { id = 23771, name = "Raid Flare", itemType = "item", quantity = "20", costType = "Community Tokens",    cost = 5 },
        { id = 23770, name = "Raid Flare", itemType = "item", quantity = "20", costType = "Community Tokens",    cost = 5 },
        { id = 23769, name = "Raid Flare", itemType = "item", quantity = "20", costType = "Community Tokens",    cost = 5 },
        { id = 23768, name = "Raid Flare", itemType = "item", quantity = "20", costType = "Community Tokens",    cost = 5 },
    },
    [3] = {
        -- Toys tab
        { id = 52253, name = "Lamenters",  itemType = "item", quantity = "1", costType = "Community Tokens", cost = 100 },
        { id = 54452, name = "Ethereal Portal",  itemType = "item", quantity = "1", costType = "Community Tokens", cost = 50 },
        { id = 33223, name = "Fishing Chair",  itemType = "item", quantity = "1", costType = "Community Tokens", cost = 50 },
        { id = 37710, name = "Crashin' Thrashin'",  itemType = "item", quantity = "1", costType = "Activity Tokens", cost = 25 },
        { id = 54343, name = "Crashin' Thrashin'",  itemType = "item", quantity = "1", costType = "Activity Tokens", cost = 25 },
        { id = 46709, name = "Crashin' Thrashin'",  itemType = "item", quantity = "1", costType = "Activity Tokens", cost = 25 },
        { id = 22728, name = "Crashin' Thrashin'",  itemType = "item", quantity = "1", costType = "Activity Tokens", cost = 25 },
    },
    [4] = {
        -- Mounts tab
        { id = 54860, name = "X-53", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 100 },
        { id = 51960, name = "Frost Wyrm Mount", itemType = "spell", quantity = "1", costType = "Community Tokens", cost = 50 },
        { id = 3363, name = "Nether Drake", itemType = "spell", quantity = "1", costType = "Community Tokens", cost = 50 },
        { id = 54811, name = "Celestial Steed", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 50 },
        { id = 35226, name = "X-51 X-TREME", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 50 },
        { id = 35225, name = "X-51", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 25 },
        { id = 33225, name = "Swift Spectral Tiger", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 25 },
        { id = 43599, name = "Big Blizzard Bear", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 25 },
        { id = 38576, name = "Big Battle Bear", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 25 },
        { id = 24576, name = "Chromatic Taxi", itemType = "spell", quantity = "1", costType = "Community Tokens", cost = 25 },
        { id = 33224, name = "Spectral Tiger", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 10 },
        { id = 32420, name = "Old Crappy McWeaksauce", itemType = "spell", quantity = "1", costType = "Community Tokens", cost = 10 },
        { id = 10790, name = "Tiger", itemType = "spell", quantity = "1", costType = "Community Tokens", cost = 10 },
        { id = 10788, name = "Leopard", itemType = "spell", quantity = "1", costType = "Community Tokens", cost = 10 },
    },
    [5] = {
        -- Pets tab
        { id = 38050, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 100 },
        { id = 49693, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 13582, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 13583, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 13584, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 25535, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 33816, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 48527, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 20371, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 20651, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 22114, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 46802, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 32233, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 32616, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 32617, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 32622, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 33816, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 33818, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 35349, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 35350, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 33993, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 34955, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 39656, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 41133, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 43517, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 43698, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 49662, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 49663, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 45180, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 46767, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 49646, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 49693, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 54847, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 54857, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 56806, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 49665, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 21168, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 19055, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 19054, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 18964, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 45942, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 32588, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 34493, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 34492, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 34518, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 34519, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 37297, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 37298, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 49343, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 54810, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 38658, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 19450, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 11903, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        { id = 49362, name = "pet", itemType = "item", quantity = "1", costType = "Vote Tokens", cost = 50 },
        -- Community Token pets
        { id = 38050, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 10 },
        { id = 49693, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 13582, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 13583, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 13584, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 25535, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 33816, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 48527, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 20371, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 20651, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 22114, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 46802, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 32233, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 32616, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 32617, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 32622, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 33816, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 33818, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 35349, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 35350, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 33993, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 34955, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 39656, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 41133, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 43517, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 43698, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 49662, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 49663, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 45180, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 46767, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 49646, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 49693, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 54847, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 54857, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 56806, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 49665, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 21168, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 19055, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 19054, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 18964, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 45942, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 32588, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 34493, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 34492, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 34518, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 34519, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 37297, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 37298, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 49343, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 54810, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 38658, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 19450, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 11903, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        { id = 49362, name = "pet", itemType = "item", quantity = "1", costType = "Community Tokens", cost = 5 },
        -- Activity Token pets (common rarity)
        { id = 11903, name = "pet", itemType = "item", quantity = "1", costType = "Activity Tokens", cost = 250 },
        { id = 18964, name = "pet", itemType = "item", quantity = "1", costType = "Activity Tokens", cost = 250 },
        { id = 19054, name = "pet", itemType = "item", quantity = "1", costType = "Activity Tokens", cost = 250 },
        { id = 19055, name = "pet", itemType = "item", quantity = "1", costType = "Activity Tokens", cost = 250 },
        { id = 19450, name = "pet", itemType = "item", quantity = "1", costType = "Activity Tokens", cost = 250 },
        { id = 21168, name = "pet", itemType = "item", quantity = "1", costType = "Activity Tokens", cost = 250 },
        { id = 45942, name = "pet", itemType = "item", quantity = "1", costType = "Activity Tokens", cost = 250 },
        { id = 49362, name = "pet", itemType = "item", quantity = "1", costType = "Activity Tokens", cost = 250 },
    },
    [6] = { -- example
        { id = 33447,   name = "Super Healing Potion", itemType = "item", quantity = "20", costType = "Activity Tokens", cost = 150 },
        { id = 33448,   name = "Super Mana Potion", itemType = "item", quantity = "20", costType = "Activity Tokens", cost = 150 },
        { id = 22849,   name = "Armor Potion", itemType = "item", quantity = "20", costType = "Activity Tokens", cost = 100 },
        { id = 22839,   name = "China Flame Cap", itemType = "item", quantity = "20", costType = "Activity Tokens", cost = 100 },
        { id = 22838,   name = "Haste Potion", itemType = "item", quantity = "20", costType = "Activity Tokens", cost = 100 },
        { id = 22837,   name = "Heroic Potion", itemType = "item", quantity = "20", costType = "Activity Tokens", cost = 100 },
        { id = 5631,   name = "Rage Potion", itemType = "item", quantity = "20", costType = "Activity Tokens", cost = 100 },
        { id = 9036,   name = "Magic Resistance Potion", itemType = "item", quantity = "20", costType = "Activity Tokens", cost = 100 },
        { id = 9030,   name = "Restorative Potion", itemType = "item", quantity = "20", costType = "Activity Tokens", cost = 100 },
        { id = 2459,   name = "Swiftness Potion", itemType = "item", quantity = "20", costType = "Activity Tokens", cost = 100 },
        { id = 3823,   name = "Invis Potion", itemType = "item", quantity = "20", costType = "Activity Tokens", cost = 100 },
        { id = 5634,   name = "Free Action Potion", itemType = "item", quantity = "20", costType = "Activity Tokens", cost = 100 },
        { id = 5632,   name = "Flee Potion", itemType = "item", quantity = "20", costType = "Activity Tokens", cost = 100 },
        { id = 22829,   name = "Super Healing Potion", itemType = "item", quantity = "20", costType = "Activity Tokens", cost = 50 },
        { id = 22832,   name = "Super Mana Potion", itemType = "item", quantity = "20", costType = "Activity Tokens", cost = 50 },
        { id = 33447,   name = "Super Healing Potion", itemType = "item", quantity = "20", costType = "Community Tokens", cost = 15 },
        { id = 33448,   name = "Super Mana Potion", itemType = "item", quantity = "20", costType = "Community Tokens", cost = 15 },
        { id = 22849,   name = "Armor Potion", itemType = "item", quantity = "20", costType = "Community Tokens", cost = 10 },
        { id = 22839,   name = "China Flame Cap", itemType = "item", quantity = "20", costType = "Community Tokens", cost = 10 },
        { id = 22838,   name = "Haste Potion", itemType = "item", quantity = "20", costType = "Community Tokens", cost = 10 },
        { id = 22837,   name = "Heroic Potion", itemType = "item", quantity = "20", costType = "Community Tokens", cost = 10 },
        { id = 5631,   name = "Rage Potion", itemType = "item", quantity = "20", costType = "Community Tokens", cost = 10 },
        { id = 9036,   name = "Magic Resistance Potion", itemType = "item", quantity = "20", costType = "Community Tokens", cost = 10 },
        { id = 9030,   name = "Restorative Potion", itemType = "item", quantity = "20", costType = "Community Tokens", cost = 10 },
        { id = 2459,   name = "Swiftness Potion", itemType = "item", quantity = "20", costType = "Community Tokens", cost = 10 },
        { id = 3823,   name = "Invis Potion", itemType = "item", quantity = "20", costType = "Community Tokens", cost = 10 },
        { id = 5634,   name = "Free Action Potion", itemType = "item", quantity = "20", costType = "Community Tokens", cost = 10 },
        { id = 5632,   name = "Flee Potion", itemType = "item", quantity = "20", costType = "Community Tokens", cost = 10 },
        { id = 22829,   name = "Super Healing Potion", itemType = "item", quantity = "20", costType = "Community Tokens", cost = 5 },
        { id = 22832,   name = "Super Mana Potion", itemType = "item", quantity = "20", costType = "Community Tokens", cost = 5 },
    },

}

local PURCHASE_COOLDOWN = 2

local purchaseVerification = {}
local purchaseCooldown = {}

local function GetStoreEntry(serviceID)
    local tab, index = tostring(serviceID):match("^(%-?%d+):(%d+)$")
    if not tab then
        return nil
    end

    tab = tonumber(tab)
    index = tonumber(index)

    local tabItems = itemsInfo[tab]
    if not tabItems then
        return nil
    end

    return tabItems[index]
end

local function GetPlayerCurrency(player, costType)
    if costType == "Gold" then
        return player:GetCoinage()
    elseif costType == "Honor Tokens" then
        return player:GetHonorPoints()
    elseif costType == "Arena Tokens" then
        return player:GetArenaPoints()
    end

    local itemID = TOKEN_ITEMS[costType]
    if itemID then
        return player:GetItemCount(itemID)
    end

    return nil
end

local function DeductPlayerCurrency(player, costType, totalCost)
    if costType == "Gold" then
        player:ModifyMoney(-totalCost)
    elseif costType == "Honor Tokens" then
        player:SetHonorPoints(player:GetHonorPoints() - totalCost)
    elseif costType == "Arena Tokens" then
        player:SetArenaPoints(player:GetArenaPoints() - totalCost)
    else
        local itemID = TOKEN_ITEMS[costType]
        if itemID then
            player:RemoveItem(itemID, totalCost)
        end
    end
end

local function FormatGold(totalCost)
    local gold = math.floor(totalCost / 10000)
    local silver = math.floor((totalCost - gold * 10000) / 100)
    local copper = totalCost - gold * 10000 - silver * 100
    return gold .. "g " .. silver .. "s " .. copper .. "c"
end

local function PurchaseItem(player, itemID, quantity, totalCost, costType)
    local guid = player:GetGUIDLow()
    local initialCount = player:GetItemCount(itemID) or 0

    local added = player:AddItem(itemID, quantity)
    if not added then
        player:SendBroadcastMessage("Unable to add this item to your inventory.")
        return
    end

    purchaseVerification[guid] = {
        itemID = itemID,
        initialCount = initialCount,
        expectedCount = initialCount + quantity,
        quantity = quantity,
        totalCost = totalCost,
        costType = costType,
    }

    player:RegisterEvent(function(eventId, delay, repeats, player)
        local data = purchaseVerification[guid]
        purchaseVerification[guid] = nil

        if not data then
            return
        end

        local currentCount = player:GetItemCount(data.itemID) or 0
        if currentCount >= data.expectedCount then
            DeductPlayerCurrency(player, data.costType, data.totalCost)

            local itemLink = GetItemLink(data.itemID) or ("item " .. data.itemID)
            if data.costType == "Gold" then
                player:SendBroadcastMessage(
                    "You have purchased " .. data.quantity .. "x " .. itemLink .. " for " .. FormatGold(data.totalCost)
                )
            else
                player:SendBroadcastMessage(
                    "You have purchased "
                    .. data.quantity
                    .. "x "
                    .. itemLink
                    .. " for "
                    .. data.totalCost
                    .. " "
                    .. data.costType
                    .. "."
                )
            end
        else
            player:SendBroadcastMessage("You can't purchase more of this item.")
        end
    end, 500, 1)
end

local function PurchaseSpell(player, spellID, totalCost, costType)
    if player:HasSpell(spellID) then
        player:SendBroadcastMessage("You already have this spell.")
        return
    end

    DeductPlayerCurrency(player, costType, totalCost)
    player:LearnSpell(spellID)

    if costType == "Gold" then
        player:SendBroadcastMessage("You have purchased a spell for " .. FormatGold(totalCost) .. ".")
    else
        player:SendBroadcastMessage("You have purchased a spell for " .. totalCost .. " " .. costType .. ".")
    end
end

function CustomShop.addItemOrSpell(player, serviceID)
    local guid = player:GetGUIDLow()
    local now = os.time()

    if purchaseCooldown[guid] and purchaseCooldown[guid] > now then
        return
    end
    purchaseCooldown[guid] = now + PURCHASE_COOLDOWN

    local entry = GetStoreEntry(serviceID)
    if not entry then
        return player:SendBroadcastMessage("Invalid purchase request.")
    end

    local itemID = tonumber(entry.id)
    local itemType = entry.itemType
    local quantity = tonumber(entry.quantity)
    local costType = entry.costType
    local totalCost = tonumber(entry.cost)

    if not itemID or not quantity or not totalCost or quantity < 1 or totalCost < 1 then
        return player:SendBroadcastMessage("Invalid purchase request.")
    end

    if itemType ~= "item" and itemType ~= "spell" then
        return player:SendBroadcastMessage("Invalid purchase request.")
    end

    local playerCurrency = GetPlayerCurrency(player, costType)
    if not playerCurrency or playerCurrency < totalCost then
        return player:SendBroadcastMessage("You don't have enough currency to purchase this item.")
    end

    if itemType == "item" then
        PurchaseItem(player, itemID, quantity, totalCost, costType)
    else
        PurchaseSpell(player, itemID, totalCost, costType)
    end
end

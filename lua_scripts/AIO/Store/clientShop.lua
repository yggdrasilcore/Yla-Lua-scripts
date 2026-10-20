local AIO = AIO or require("AIO")
if AIO.AddAddon() then
    return
end

local createdButtons = {} -- this is a table that will hold all the buttons that are created to update prices and such

local tabsInfo = {
    { id = 0, name = "Featured", icon = "Interface\\Icons\\inv_feather_13" },
    { id = 1, name = "Spells", icon = "Interface\\Icons\\spell_arcane_mindmastery"  },
    { id = 2, name = "Raid", icon = "Interface\\Icons\\achievement_zone_icecrown_01"  },
    { id = 3, name = "Toys", icon = "Interface\\Icons\\inv_misc_toy_03"  },
    { id = 4, name = "Mounts", icon = "Interface\\Icons\\ability_mount_ridingelekkelite_purple"  },
    { id = 5, name = "Pets", icon = "Interface\\Icons\\inv_pet_babyblizzardbear"  },
    { id = 6, name = "Potions", icon = "Interface\\Icons\\inv_potion_105"  },
    --{ id = 7, name = "Currencies", icon = "Interface\\Icons\\inv_misc_frostemblem_01"  },
    --{ id = 8, name = "Heirlooms", icon = "Interface\\Icons\\spell_fire_burningspeed"  },
    --{ id = 9, name = "Class", icon = "Interface\\Icons\\spell_magic_greaterblessingofkings"  },
}

-- the "name" can be ingored it's not being used really atm u can just use the id of the item and it will display the name of the item
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
----------------------------------------------------------------------------------------------

local FALLBACK_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local CURRENCY_ITEMS = {
    ["Community Tokens"] = 19322,
    ["Vote Tokens"] = 20880,
    ["Activity Tokens"] = 37742,
}

local CURRENCY_ORDER = { "Community Tokens", "Vote Tokens", "Activity Tokens" }

local currentTab = tabsInfo[1] and tabsInfo[1].id or 0
local currentPage = 1
local currentFilter = "All Currencies"

local UpdateCurrencyBalances
local UpdateServiceCards
local SelectTab
local ShowPurchaseConfirm

local function GetEntryDisplay(entry)
    if entry.itemType == "spell" then
        local name, _, icon = GetSpellInfo(entry.id)
        return name or entry.name or ("Spell " .. tostring(entry.id)), icon or FALLBACK_ICON
    end

    local name, _, _, _, _, _, _, _, _, icon = GetItemInfo(entry.id)
    if not icon then
        icon = GetItemIcon(entry.id)
    end

    return name or entry.name or ("Item " .. tostring(entry.id)), icon or FALLBACK_ICON
end

local function FormatCost(cost, costType)
    if costType == "Gold" then
        local gold = math.floor(cost / 10000)
        local silver = math.floor((cost - gold * 10000) / 100)
        local copper = cost - gold * 10000 - silver * 100
        return gold .. "g " .. silver .. "s " .. copper .. "c"
    end

    return tostring(cost)
end

local function GetCostIcon(costType)
    if costType == "Gold" then
        return "Interface\\MoneyFrame\\UI-GoldIcon"
    end

    local itemID = CURRENCY_ITEMS[costType]
    if itemID then
        return GetItemIcon(itemID) or FALLBACK_ICON
    end

    return FALLBACK_ICON
end

local function GetFilteredEntries()
    local entries = {}
    local tabItems = itemsInfo[currentTab] or {}

    for index, entry in ipairs(tabItems) do
        if currentFilter == "All Currencies" or entry.costType == currentFilter then
            table.insert(entries, { entry = entry, index = index })
        end
    end

    return entries
end

----------------------------------------------------------------------------------------------

local mainFrame = CreateFrame("Frame", "YggdrasilStoreMainFrame", UIParent)
mainFrame:SetSize(900, 560)
mainFrame:SetPoint("CENTER")
mainFrame:SetFrameStrata("DIALOG")
mainFrame:SetMovable(true)
mainFrame:EnableMouse(true)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
mainFrame:SetClampedToScreen(true)
mainFrame:SetBackdrop(
    {
        bgFile = "Interface\\FrameGeneral\\UI-Background-Marble",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 256,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    }
)
mainFrame:SetBackdropColor(0.20, 0.16, 0.12, 1)
mainFrame:SetBackdropBorderColor(0.65, 0.52, 0.20, 1)
mainFrame:Hide()

local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", mainFrame, "TOP", 0, -10)
title:SetFont("Fonts\\FRIZQT__.TTF", 18)
title:SetText("Shop")
title:SetTextColor(0.95, 0.82, 0.3)

local titleDivider = mainFrame:CreateTexture(nil, "ARTWORK")
titleDivider:SetTexture("Interface\\Buttons\\WHITE8X8")
titleDivider:SetVertexColor(0.55, 0.45, 0.15, 1)
titleDivider:SetSize(600, 2)
titleDivider:SetPoint("TOP", mainFrame, "TOP", 0, -34)

local closeButton = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -5, -5)

local loadingFrame = CreateFrame("Frame", "YggdrasilStoreLoadingFrame", UIParent)
loadingFrame:SetSize(280, 90)
loadingFrame:SetPoint("CENTER")
loadingFrame:SetFrameStrata("DIALOG")
loadingFrame:SetBackdrop(
    {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    }
)
loadingFrame:SetBackdropColor(0.20, 0.16, 0.12, 1)
loadingFrame:SetBackdropBorderColor(0.65, 0.52, 0.20, 1)
loadingFrame:Hide()

local loadingTitle = loadingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
loadingTitle:SetPoint("TOP", loadingFrame, "TOP", 0, -18)
loadingTitle:SetText("Loading store...")
loadingTitle:SetTextColor(0.95, 0.82, 0.3)

local loadingSubtitle = loadingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
loadingSubtitle:SetPoint("TOP", loadingTitle, "BOTTOM", 0, -8)
loadingSubtitle:SetText("Querying item data")

----------------------------------------------------------------------------------------------

local navPanel = CreateFrame("Frame", nil, mainFrame)
navPanel:SetSize(190, 417)
navPanel:SetPoint("TOPLEFT", 15, -48)
navPanel:SetBackdrop(
    {
        bgFile = "Interface\\FrameGeneral\\UI-Background-Rock",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 256,
        edgeSize = 12,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    }
)
navPanel:SetBackdropColor(0.25, 0.20, 0.14, 1)
navPanel:SetBackdropBorderColor(0.55, 0.45, 0.15, 1)

local navHeader = navPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
navHeader:SetPoint("TOPLEFT", navPanel, "TOPLEFT", 10, -8)
navHeader:SetText("Categories")
navHeader:SetTextColor(0.8, 0.7, 0.35)

local navButtons = {}

for i, tab in ipairs(tabsInfo) do
    local button = CreateFrame("Button", "YggdrasilStoreNavButton" .. i, navPanel)
    button:SetSize(170, 34)
    button:SetPoint("TOPLEFT", navPanel, "TOPLEFT", 10, -30 - (i - 1) * 38)
    button:SetBackdrop(
        {
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false,
            edgeSize = 12,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        }
    )
    button:SetBackdropColor(0.30, 0.22, 0.10, 1)
    button:SetBackdropBorderColor(0.55, 0.45, 0.15, 1)

    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.text:SetPoint("LEFT", button, "LEFT", 32, 0)
    button.text:SetJustifyH("LEFT")
    button.text:SetWidth(130)
    button.text:SetText(tab.name)

    button.icon = button:CreateTexture(nil, "OVERLAY")
    button.icon:SetSize(22, 22)
    button.icon:SetPoint("LEFT", button, "LEFT", 7, 0)
    button.icon:SetTexture(tab.icon or FALLBACK_ICON)
    button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    button.tabID = tab.id
    button.selected = false

    button:SetScript(
        "OnEnter",
        function(self)
            self:SetBackdropBorderColor(0.95, 0.80, 0.30, 1)
        end
    )

    button:SetScript(
        "OnLeave",
        function(self)
            if self.selected then
                self:SetBackdropBorderColor(0.95, 0.80, 0.30, 1)
            else
                self:SetBackdropBorderColor(0.55, 0.45, 0.15, 1)
            end
        end
    )

    button:SetScript(
        "OnClick",
        function()
            if SelectTab then
                SelectTab(tab)
            end
        end
    )

    navButtons[i] = button
end

----------------------------------------------------------------------------------------------

local contentPanel = CreateFrame("Frame", nil, mainFrame)
contentPanel:SetSize(665, 477)
contentPanel:SetPoint("TOPLEFT", 220, -48)
contentPanel:SetBackdrop(
    {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 12,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    }
)
contentPanel:SetBackdropColor(0.40, 0.32, 0.22, 1)
contentPanel:SetBackdropBorderColor(0.55, 0.45, 0.15, 1)

local categoryHeader = contentPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
categoryHeader:SetPoint("TOPLEFT", contentPanel, "TOPLEFT", 12, -10)
categoryHeader:SetTextColor(0.95, 0.82, 0.3)

local nextButton = CreateFrame("Button", nil, contentPanel, "UIPanelButtonTemplate")
nextButton:SetSize(24, 22)
nextButton:SetText(">")
nextButton:SetPoint("TOPRIGHT", contentPanel, "TOPRIGHT", -10, -8)

local pageText = contentPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
pageText:SetPoint("RIGHT", nextButton, "LEFT", -8, 0)

local prevButton = CreateFrame("Button", nil, contentPanel, "UIPanelButtonTemplate")
prevButton:SetSize(24, 22)
prevButton:SetText("<")
prevButton:SetPoint("RIGHT", pageText, "LEFT", -8, 0)

prevButton:SetScript(
    "OnClick",
    function()
        if currentPage > 1 then
            currentPage = currentPage - 1
            UpdateServiceCards()
        end
    end
)

nextButton:SetScript(
    "OnClick",
    function()
        local total = #GetFilteredEntries()
        local maxPages = math.max(1, math.ceil(total / 8))
        if currentPage < maxPages then
            currentPage = currentPage + 1
            UpdateServiceCards()
        end
    end
)

----------------------------------------------------------------------------------------------

local serviceCards = {}
local CARD_WIDTH = 152
local CARD_HEIGHT = 200
local CARD_SPACING_X = 10
local CARD_SPACING_Y = 12
local GRID_LEFT = 8
local GRID_TOP = -38

for i = 1, 8 do
    local card = CreateFrame("Button", nil, contentPanel)
    card:SetSize(CARD_WIDTH, CARD_HEIGHT)

    local col = (i - 1) % 4
    local row = math.floor((i - 1) / 4)
    card:SetPoint(
        "TOPLEFT",
        contentPanel,
        "TOPLEFT",
        GRID_LEFT + col * (CARD_WIDTH + CARD_SPACING_X),
        GRID_TOP - row * (CARD_HEIGHT + CARD_SPACING_Y)
    )

    card:SetBackdrop(
        {
            bgFile = "Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false,
            edgeSize = 12,
            insets = { left = 6, right = 6, top = 6, bottom = 6 }
        }
    )
    card:SetBackdropColor(0.50, 0.38, 0.22, 1)
    card:SetBackdropBorderColor(0.55, 0.42, 0.20, 1)
    card:EnableMouse(true)
    card.entry = nil

    card.IconPlate = card:CreateTexture(nil, "BACKGROUND")
    card.IconPlate:SetSize(54, 54)
    card.IconPlate:SetPoint("TOP", card, "TOP", 0, -7)
    card.IconPlate:SetTexture("Interface\\Buttons\\WHITE8X8")
    card.IconPlate:SetVertexColor(0, 0, 0, 0.35)

    card.Icon = card:CreateTexture(nil, "ARTWORK")
    card.Icon:SetSize(44, 44)
    card.Icon:SetPoint("TOP", card, "TOP", 0, -12)
    card.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    card.NameText = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    card.NameText:SetPoint("TOP", card, "TOP", 0, -64)
    card.NameText:SetWidth(CARD_WIDTH - 16)
    card.NameText:SetHeight(34)
    card.NameText:SetJustifyH("CENTER")
    card.NameText:SetWordWrap(true)

    card.QuantityText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    card.QuantityText:SetPoint("TOP", card.NameText, "BOTTOM", 0, -2)
    card.QuantityText:SetTextColor(0.75, 0.70, 0.60)

    card.PriceText = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    card.PriceText:SetPoint("CENTER", card, "CENTER", -10, -31)
    card.PriceText:SetTextColor(0.95, 0.82, 0.30)

    card.PriceIcon = card:CreateTexture(nil, "OVERLAY")
    card.PriceIcon:SetSize(16, 16)
    card.PriceIcon:SetPoint("LEFT", card.PriceText, "RIGHT", 4, 0)
    card.PriceIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    card.BuyButton = CreateFrame("Button", nil, card)
    card.BuyButton:SetSize(104, 22)
    card.BuyButton:SetPoint("BOTTOM", card, "BOTTOM", 0, 10)
    card.BuyButton:SetBackdrop(
        {
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false,
            edgeSize = 10,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        }
    )
    card.BuyButton:SetBackdropColor(0.30, 0.04, 0.04, 1)
    card.BuyButton:SetBackdropBorderColor(0.55, 0.18, 0.18, 1)

    card.BuyButton.Text = card.BuyButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    card.BuyButton.Text:SetPoint("CENTER")
    card.BuyButton.Text:SetText("Buy now!")

    local function OnCardEnter(self)
        self:SetBackdropBorderColor(0.95, 0.80, 0.30, 1)
        if self.entry then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(self.entry.itemType .. ":" .. self.entry.id)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(
                "Price: " .. FormatCost(self.entry.cost, self.entry.costType) .. " " .. self.entry.costType,
                1,
                1,
                1
            )
            GameTooltip:Show()
        end
    end

    local function OnCardLeave(self)
        self:SetBackdropBorderColor(0.55, 0.42, 0.20, 1)
        GameTooltip:Hide()
    end

    local function OnBuyEnter(self)
        self:SetBackdropBorderColor(0.95, 0.35, 0.35, 1)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(card.entry.itemType .. ":" .. card.entry.id)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(
            "Price: " .. FormatCost(card.entry.cost, card.entry.costType) .. " " .. card.entry.costType,
            1,
            1,
            1
        )
        GameTooltip:Show()
    end

    local function OnBuyLeave(self)
        self:SetBackdropBorderColor(0.55, 0.18, 0.18, 1)
        GameTooltip:Hide()
    end

    card:SetScript("OnEnter", OnCardEnter)
    card:SetScript("OnLeave", OnCardLeave)
    card.BuyButton:SetScript("OnEnter", OnBuyEnter)
    card.BuyButton:SetScript("OnLeave", OnBuyLeave)

    card:SetScript(
        "OnClick",
        function(self)
            if self.entry and ShowPurchaseConfirm then
                ShowPurchaseConfirm(self.entry, self.serviceKey)
            end
        end
    )

    card.BuyButton:SetScript(
        "OnClick",
        function()
            if card.entry and ShowPurchaseConfirm then
                PlaySound("uChatScrollButton", "Master")
                ShowPurchaseConfirm(card.entry, card.serviceKey)
            end
        end
    )

    serviceCards[i] = card
end

----------------------------------------------------------------------------------------------

local currencyBar = CreateFrame("Frame", nil, mainFrame)
currencyBar:SetSize(300, 26)
currencyBar:SetPoint("BOTTOMLEFT", 15, 15)
currencyBar:SetBackdrop(
    {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 10,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    }
)
currencyBar:SetBackdropColor(0.25, 0.20, 0.14, 1)
currencyBar:SetBackdropBorderColor(0.55, 0.45, 0.15, 1)

local currencyBadges = {}

for i, costType in ipairs(CURRENCY_ORDER) do
    local itemID = CURRENCY_ITEMS[costType]

    local badge = CreateFrame("Frame", nil, currencyBar)
    badge:SetSize(85, 20)
    badge:SetPoint("LEFT", currencyBar, "LEFT", 10 + (i - 1) * 95, 0)
    badge:EnableMouse(true)
    badge.itemID = itemID
    badge.costType = costType

    badge.Icon = badge:CreateTexture(nil, "ARTWORK")
    badge.Icon:SetSize(18, 18)
    badge.Icon:SetPoint("LEFT", badge, "LEFT", 0, 0)
    badge.Icon:SetTexture(GetItemIcon(itemID) or FALLBACK_ICON)
    badge.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    badge.Amount = badge:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    badge.Amount:SetPoint("LEFT", badge.Icon, "RIGHT", 6, 0)

    badge:SetScript(
        "OnEnter",
        function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink("item:" .. self.itemID)
            GameTooltip:AddLine("Your balance: " .. GetItemCount(self.itemID), 1, 1, 1)
            GameTooltip:Show()
        end
    )

    badge:SetScript(
        "OnLeave",
        function()
            GameTooltip:Hide()
        end
    )

    currencyBadges[i] = badge
end

----------------------------------------------------------------------------------------------

local pendingPurchase

StaticPopupDialogs["YGGDRASIL_STORE_CONFIRM"] = {
    text = "Purchase %s for %s %s?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        local purchase = pendingPurchase
        pendingPurchase = nil

        if not purchase then
            return
        end

        AIO.Handle("CustomShop", "addItemOrSpell", purchase.serviceKey)

        local frame = CreateFrame("Frame")
        frame:SetScript(
            "OnUpdate",
            function(self, elapsed)
                self.elapsed = (self.elapsed or 0) + elapsed
                if self.elapsed >= 1 then
                    UpdateCurrencyBalances()
                    UpdateServiceCards()
                    self:SetScript("OnUpdate", nil)
                end
            end
        )
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

ShowPurchaseConfirm = function(entry, serviceKey)
    pendingPurchase = { entry = entry, serviceKey = serviceKey }
    local name = GetEntryDisplay(entry)
    StaticPopup_Show("YGGDRASIL_STORE_CONFIRM", name, FormatCost(entry.cost, entry.costType), entry.costType)
end

----------------------------------------------------------------------------------------------

UpdateCurrencyBalances = function()
    for _, badge in ipairs(currencyBadges) do
        badge.Icon:SetTexture(GetItemIcon(badge.itemID) or FALLBACK_ICON)
        badge.Amount:SetText(tostring(GetItemCount(badge.itemID)))
    end
end

local function UpdatePageButtons()
    local total = #GetFilteredEntries()
    local maxPages = math.max(1, math.ceil(total / 8))

    if currentPage > maxPages then
        currentPage = maxPages
    end

    if maxPages <= 1 then
        prevButton:Hide()
        nextButton:Hide()
        pageText:Hide()
        return
    end

    prevButton:Show()
    nextButton:Show()
    pageText:Show()
    pageText:SetText(currentPage .. " / " .. maxPages)

    if currentPage == 1 then
        prevButton:Disable()
    else
        prevButton:Enable()
    end

    if currentPage == maxPages then
        nextButton:Disable()
    else
        nextButton:Enable()
    end
end

UpdateServiceCards = function()
    local entries = GetFilteredEntries()
    local startIndex = (currentPage - 1) * 8

    for i = 1, 8 do
        local card = serviceCards[i]
        local item = entries[startIndex + i]

        if item then
            local entry = item.entry
            local name, icon = GetEntryDisplay(entry)

            card.entry = entry
            card.serviceKey = currentTab .. ":" .. tostring(item.index)
            card.Icon:SetTexture(icon)
            card.NameText:SetText(name)
            card.QuantityText:SetText("x" .. tostring(entry.quantity or "1"))
            card.PriceText:SetText(FormatCost(entry.cost, entry.costType))
            card.PriceIcon:SetTexture(GetCostIcon(entry.costType))
            card:Show()
        else
            card.entry = nil
            card.serviceKey = nil
            card:Hide()
        end
    end

    UpdatePageButtons()
end

SelectTab = function(tab)
    currentTab = tab.id
    currentPage = 1

    for _, button in ipairs(navButtons) do
        if button.tabID == tab.id then
            button.selected = true
            button:SetBackdropBorderColor(0.95, 0.80, 0.30, 1)
            button:SetBackdropColor(0.45, 0.32, 0.14, 1)
            button.text:SetTextColor(1, 0.82, 0.10)
        else
            button.selected = false
            button:SetBackdropBorderColor(0.55, 0.45, 0.15, 1)
            button:SetBackdropColor(0.30, 0.22, 0.10, 1)
            button.text:SetTextColor(1, 1, 1)
        end
    end

    PlaySound("uChatScrollButton", "Master")
    categoryHeader:SetText(tab.name)
    UpdateServiceCards()
end

----------------------------------------------------------------------------------------------

local filterDropdown = CreateFrame("Frame", "YggdrasilStoreFilterDropdown", navPanel, "UIDropDownMenuTemplate")
filterDropdown:SetPoint("BOTTOMLEFT", navPanel, "BOTTOMLEFT", 2, 8)

local filterLabel = navPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
filterLabel:SetPoint("BOTTOMLEFT", navPanel, "BOTTOMLEFT", 14, 42)
filterLabel:SetText("Filter by currency")
filterLabel:SetTextColor(0.80, 0.70, 0.35)

local function FilterDropdown_OnClick(self)
    currentFilter = self.value
    currentPage = 1
    UIDropDownMenu_SetText(filterDropdown, currentFilter)
    UpdateServiceCards()
end

local function InitializeFilterDropdown(self, level)
    local info = UIDropDownMenu_CreateInfo()
    local options = { "All Currencies", "Community Tokens", "Vote Tokens", "Activity Tokens" }

    for _, option in ipairs(options) do
        info.text = option
        info.value = option
        info.func = FilterDropdown_OnClick
        UIDropDownMenu_AddButton(info)
    end
end

UIDropDownMenu_Initialize(filterDropdown, InitializeFilterDropdown)
UIDropDownMenu_SetWidth(filterDropdown, 160)
UIDropDownMenu_SetText(filterDropdown, currentFilter)

----------------------------------------------------------------------------------------------

local itemQueries = {}
local spellQueries = {}
local allQueriesReady = false
local prefetchStarted = false
local pendingStoreOpen = false

local function CollectStoreQueryIds()
    for _, tabItems in pairs(itemsInfo) do
        for _, entry in ipairs(tabItems) do
            if entry.itemType == "spell" then
                spellQueries[entry.id] = true
            else
                itemQueries[entry.id] = true
            end
        end
    end

    for _, itemID in pairs(CURRENCY_ITEMS) do
        itemQueries[itemID] = true
    end
end

local function QueryMissingStoreData()
    for itemID in pairs(itemQueries) do
        if not GetItemInfo(itemID) then
            GetItemInfo(itemID)
        end
    end

    for spellID in pairs(spellQueries) do
        if not GetSpellInfo(spellID) then
            GetSpellInfo(spellID)
        end
    end
end

local function AreStoreQueriesReady()
    for itemID in pairs(itemQueries) do
        if not GetItemInfo(itemID) then
            return false
        end
    end

    for spellID in pairs(spellQueries) do
        if not GetSpellInfo(spellID) then
            return false
        end
    end

    return true
end

local function StartStorePrefetch()
    if prefetchStarted then
        return
    end

    prefetchStarted = true
    CollectStoreQueryIds()
    QueryMissingStoreData()

    local startTime = GetTime()
    local elapsedSinceQuery = 0
    local queryDelay = 1
    local prefetchFrame = CreateFrame("Frame")

    prefetchFrame:SetScript(
        "OnUpdate",
        function(self, elapsed)
            elapsedSinceQuery = elapsedSinceQuery + elapsed
            if elapsedSinceQuery < queryDelay then
                return
            end

            elapsedSinceQuery = 0

            if AreStoreQueriesReady() or (GetTime() - startTime > 12) then
                allQueriesReady = true
                self:SetScript("OnUpdate", nil)
                self:Hide()

                if pendingStoreOpen then
                    pendingStoreOpen = false
                    loadingFrame:Hide()
                    mainFrame:Show()
                end

                return
            end

            queryDelay = math.min(queryDelay * 2, 4)
            QueryMissingStoreData()
        end
    )

    prefetchFrame:Show()
end

local function OpenStore()
    if allQueriesReady then
        loadingFrame:Hide()
        mainFrame:Show()
    else
        pendingStoreOpen = true
        loadingFrame:Show()
        StartStorePrefetch()
    end
end

----------------------------------------------------------------------------------------------

mainFrame:SetScript(
    "OnShow",
    function()
        UpdateCurrencyBalances()
        UpdateServiceCards()
        PlaySound("AuctionWindowOpen", "Master")
    end
)

mainFrame:SetScript(
    "OnHide",
    function()
        PlaySound("AuctionWindowClose", "Master")
    end
)

tinsert(UISpecialFrames, mainFrame:GetName())

----------------------------------------------------------------------------------------------

SLASH_YGGDRASILSTORE1 = "/store"
SlashCmdList["YGGDRASILSTORE"] = function()
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        OpenStore()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:SetScript(
    "OnEvent",
    function(_, event, prefix, message)
        if event == "CHAT_MSG_ADDON" and prefix == "CustomShop" and message == "openstore" then
            OpenStore()
        end
    end
)

----------------------------------------------------------------------------------------------

local reToggleMenu

if GameMenuFrame and GameMenuFrame:IsShown() then
    reToggleMenu = true
    GameMenuFrame:Hide()
end

local storeButton = CreateFrame("Button", "GameMenuButtonStore", GameMenuFrame, "GameMenuButtonTemplate")
storeButton:SetText("Yggdrasil Store")
storeButton:SetSize(144, 21)
storeButton:ClearAllPoints()
storeButton:SetPoint("TOP", GameMenuButtonContinue, "BOTTOM", 0, -15)
storeButton:SetScript(
    "OnClick",
    function()
        HideUIPanel(GameMenuFrame)
        OpenStore()
    end
)

GameMenuFrame:HookScript(
    "OnShow",
    function()
        local moveAnythingButton = _G["GameMenuButtonMoveAnything"]
        if moveAnythingButton then
            moveAnythingButton:ClearAllPoints()
            moveAnythingButton:SetPoint("TOP", storeButton, "BOTTOM", 0, -15)
        end
    end
)

if _G["GameMenuButtonMoveAnything"] then
    GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + 60)
else
    GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + 30)
end

if tabsInfo[1] then
    SelectTab(tabsInfo[1])
end

StartStorePrefetch()

if reToggleMenu == true then
    GameMenuFrame:Show()
end

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
        { id = 20739, name = "Feathers of Azeroth", itemType = "item", quantity = "1", costType = "Gold",    cost = 500000 },
        { id = 17890, name = "Druid Medallion", itemType = "item", quantity = "1", costType = "Vote Tokens",    cost = 50 },
        { id = 17890, name = "Druid Medallion", itemType = "item", quantity = "1", costType = "Community Tokens",    cost = 10 },
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

-----------------------------------------------------------------------------------------------

local itemTooltip = CreateFrame("GameTooltip", "CustomStoreTooltip", UIParent, "GameTooltipTemplate")
itemTooltip:SetScale(1)
itemTooltip:SetClampedToScreen(true)

-----------------------------------------------------------------------------------------------

local mainFrame = CreateFrame("Frame", "CustomStoreMainFrame", UIParent, "UIPanelDialogTemplate")
mainFrame:SetSize(800, 500)
mainFrame:SetPoint("CENTER")
-- mainFrame:SetBackdrop(
--     {
--         bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
--         edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
--         tile = true,
--         tileSize = 32,
--         edgeSize = 32,
--         insets = { left = 11, right = 12, top = 12, bottom = 11 }
--     }
-- )
mainFrame:SetMovable(true)
mainFrame:EnableMouse(true)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
mainFrame:SetClampedToScreen(true)
-- mainFrame:Show()
mainFrame:Hide()
-- Create the currency balance display
local currencyFrame = CreateFrame("Frame", nil, mainFrame)
currencyFrame:SetSize(250, 100)
currencyFrame:SetPoint("BOTTOM", mainFrame, "BOTTOM", -40, 10)

-- Add border
currencyFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
currencyFrame:SetBackdropColor(0, 0, 0, 0.8)
currencyFrame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

-- Create header
local headerText = currencyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
headerText:SetPoint("TOPLEFT", currencyFrame, "TOPLEFT", 10, -10)
headerText:SetText("Currency Balances:")

-- Create labels (left side)
local goldLabel = currencyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
goldLabel:SetPoint("TOPLEFT", currencyFrame, "TOPLEFT", 10, -25)
goldLabel:SetText("Gold:")

local communityTokensLabel = currencyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
communityTokensLabel:SetPoint("TOPLEFT", goldLabel, "BOTTOMLEFT", 0, -5)
communityTokensLabel:SetText("Community Tokens:")

local voteTokensLabel = currencyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
voteTokensLabel:SetPoint("TOPLEFT", communityTokensLabel, "BOTTOMLEFT", 0, -5)
voteTokensLabel:SetText("Vote Tokens:")

local activityTokensLabel = currencyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
activityTokensLabel:SetPoint("TOPLEFT", voteTokensLabel, "BOTTOMLEFT", 0, -5)
activityTokensLabel:SetText("Activity Tokens:")

-- Create values (right side)
local goldValue = currencyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
goldValue:SetPoint("TOPRIGHT", currencyFrame, "TOPRIGHT", -10, -25)

local communityTokensValue = currencyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
communityTokensValue:SetPoint("TOPRIGHT", goldValue, "BOTTOMRIGHT", 0, -5)

local voteTokensValue = currencyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
voteTokensValue:SetPoint("TOPRIGHT", communityTokensValue, "BOTTOMRIGHT", 0, -5)

local activityTokensValue = currencyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
activityTokensValue:SetPoint("TOPRIGHT", voteTokensValue, "BOTTOMRIGHT", 0, -5)

-- Function to update currency balances
local function UpdateCurrencyBalances()
    local totalGold = GetMoney()
    local Gold = math.floor(totalGold / 10000)
    local silver = math.floor((totalGold - (Gold * 10000)) / 100)
    local copper = totalGold - (Gold * 10000) - (silver * 100)
    local costText = Gold .. "g " .. silver .. "s " .. copper .. "c"
    local communityTokens = GetItemCount(19322)
    local voteTokens = GetItemCount(20880)
    local activityTokens = GetItemCount(37742)

    goldValue:SetText(costText)
    communityTokensValue:SetText(communityTokens)
    voteTokensValue:SetText(voteTokens)
    activityTokensValue:SetText(activityTokens)
end

-- Call the function to update currency balances when the frame is shown
mainFrame:HookScript("OnShow", UpdateCurrencyBalances)

local quantityInput = CreateFrame("EditBox", "CustomStore_QuantityInput", mainFrame, "InputBoxTemplate")
quantityInput:SetAutoFocus(false)
quantityInput:SetWidth(50)
quantityInput:SetHeight(20)
quantityInput:SetPoint("BOTTOMRIGHT", -30, 30)
quantityInput:SetNumeric(true)
quantityInput:SetMaxLetters(3)
quantityInput:SetNumber(1) -- Set default quantity to 1
quantityInput:SetCursorPosition(0)
--set name left side saying quantity
local quantityLabel = quantityInput:CreateFontString(nil, "OVERLAY", "GameFontNormal")
quantityLabel:SetText("Quantity:")
quantityLabel:SetPoint("RIGHT", quantityInput, "LEFT", -5, 0)
-- quantityLabel:SetPoint("BOTTOMLEFT", quantityInput, "TOPLEFT", 0, 0)
-- get quantity and set a attribute
quantityInput:Hide()

local titleBar = mainFrame:CreateTexture(nil, "ARTWORK")
titleBar:SetTexture("Interface/DialogFrame/UI-DialogBox-Header")
titleBar:SetWidth(300)
titleBar:SetHeight(64)
titleBar:SetPoint("TOP", 0, 30)

local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOP", titleBar, "TOP", 0, -14)
title:SetText("Yggdrasil Store")

local categoryList = CreateFrame("Frame", "categoryList", mainFrame)
categoryList:SetSize(mainFrame:GetWidth() - 650, mainFrame:GetHeight() - 150)
categoryList:SetPoint("TOPLEFT", 15, -35)
categoryList:SetBackdrop(
    {
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    }
)
categoryList:SetBackdropColor(0, 0, 0, 0.8)

local itemList = CreateFrame("Frame", nil, mainFrame)
itemList:SetSize(mainFrame:GetWidth() - 250, mainFrame:GetHeight() - 150)
itemList:SetPoint("TOPRIGHT", -15, -35)
itemList:SetBackdrop(
    {
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    }
)
itemList:SetBackdropColor(0, 0, 0, 0.8)

local scrollFrame = CreateFrame("ScrollFrame", "CustomStore_ScrollFrame", itemList, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", itemList, "TOPLEFT", 10, -30) -- Adjusted to start below the headers
scrollFrame:SetPoint("BOTTOMRIGHT", itemList, "BOTTOMRIGHT", -30, 10)
itemList.scrollFrame = scrollFrame

-- Create the header font strings
local categoryHeader = itemList:CreateFontString(nil, "OVERLAY", "GameFontNormal")
categoryHeader:SetPoint("TOPLEFT", itemList, "TOPLEFT", -220, 27)

local itemHeader = itemList:CreateFontString(nil, "OVERLAY", "GameFontNormal")
itemHeader:SetPoint("TOPLEFT", itemList, "TOPLEFT", 15, -15)
itemHeader:SetText("Item")

local quantityHeader = itemList:CreateFontString(nil, "OVERLAY", "GameFontNormal")
quantityHeader:SetPoint("TOP", itemList, "TOP", 10, -15)
quantityHeader:SetText("Quantity")

local priceHeader = itemList:CreateFontString(nil, "OVERLAY", "GameFontNormal")
priceHeader:SetPoint("TOPRIGHT", itemList, "TOPRIGHT", -100, -15)
priceHeader:SetText("Price")

local contentFrame = CreateFrame("Frame", nil, scrollFrame)
contentFrame:SetSize(scrollFrame:GetSize())
scrollFrame:SetScrollChild(contentFrame)
itemList.contentFrame = contentFrame

local tabButtonsScrollFrame = CreateFrame("ScrollFrame", "CustomStore_TabButtonsScrollFrame", categoryList)
tabButtonsScrollFrame:SetSize(150, categoryList:GetHeight() - 10)
tabButtonsScrollFrame:SetPoint("TOPLEFT", categoryList, "TOPLEFT", 5, -5)

local tabButtonsContentFrame = CreateFrame("Frame", nil, tabButtonsScrollFrame)
tabButtonsScrollFrame:SetScrollChild(tabButtonsContentFrame)

local tabButtonsScrollBar =
    CreateFrame("Slider", "CustomStore_TabButtonsScrollBar", tabButtonsScrollFrame, "UIPanelScrollBarTemplate")
tabButtonsScrollBar:SetPoint("TOPLEFT", categoryList, "TOPRIGHT", -20, -20)
tabButtonsScrollBar:SetPoint("BOTTOMLEFT", categoryList, "BOTTOMRIGHT", -20, 20)
tabButtonsScrollBar:SetMinMaxValues(0, 1)
tabButtonsScrollBar:SetValueStep(1)
tabButtonsScrollBar.scrollStep = 1
tabButtonsScrollBar:SetValue(0)
tabButtonsScrollBar:SetWidth(16)
-- tabButtonsScrollBar:SetAlpha(1)
tabButtonsScrollFrame:EnableMouseWheel(true)
tabButtonsScrollFrame:SetScript(
    "OnMouseWheel",
    function(self, delta)
        local currentValue = tabButtonsScrollBar:GetValue()
        local newValue = currentValue - (delta * 30) -- Change '30' to adjust the scroll speed
        tabButtonsScrollBar:SetValue(
            math.min(
                math.max(newValue, 0),
                -- TODO - Replace 10000 with the height of the content frames
                math.max(0, 10000 - tabButtonsScrollFrame:GetHeight())
            )
        )
    end
)

tabButtonsScrollBar:SetScript(
    "OnValueChanged",
    function(self, value)
        tabButtonsScrollFrame:SetVerticalScroll(value)
    end
)
local contentHeight = #tabsInfo * 30 -- Assuming each tab button has a height of 30 units (including spacing)
tabButtonsContentFrame:SetSize(tabButtonsScrollFrame:GetWidth(), contentHeight)
tabButtonsScrollBar:SetMinMaxValues(0, math.max(0, contentHeight - tabButtonsScrollFrame:GetHeight()))
local function UpdateTabButtonsScrollBarVisibility()
    if contentHeight > tabButtonsScrollFrame:GetHeight() then
        tabButtonsScrollBar:Show()
    else
        tabButtonsScrollBar:Hide()
    end
end

UpdateTabButtonsScrollBarVisibility()

local function CreateTabButton(id, text, onClick)
    local button = CreateFrame("Button", nil, tabButtonsContentFrame, "UIPanelButtonTemplate")
    button:SetSize(139, 25)
    button:SetText(text)
    button:SetPoint("TOPLEFT", 0, -35 - (id - 1) * 30)
    button:SetScript("OnClick", onClick)
    return button
end

local function CreateItemButton(parent, index, id, text, icon, onClick, itemType, costType, cost, quantity)
    local button = CreateFrame("Button", nil, parent)

    button:SetSize(350, 40)
    -- button:SetSize(32, 32)

    local iconTexture = button:CreateTexture(nil, "ARTWORK")
    iconTexture:SetTexture(icon)
    iconTexture:SetSize(32, 32)
    iconTexture:SetPoint("LEFT", 5, 0)

    local textLabel = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    -- "RIGHT", quantityInput, "LEFT", -5, 0
    -- textLabel:SetPoint("LEFT", iconTexture, "RIGHT", 1, -10)
    textLabel:SetPoint("LEFT", iconTexture, "RIGHT", 10, 0)
    -- set text white
    textLabel:SetTextColor(1, 1, 1, 1)
    -- if text is too long, cut it off
    textLabel:SetWidth(200)
    textLabel:SetHeight(40)
    textLabel:SetWordWrap(true)
    textLabel:SetJustifyH("LEFT")

    textLabel:SetText(text)
    -- textLabel:SetText(text)

    -- textLabel:SetJustifyV("TOP")

    -- textLabel:SetPoint("LEFT", iconTexture, "RIGHT", 10, 0)

    -- button:SetPoint("TOPLEFT", 15, -35 - (index - 1) * 45)
    button:SetPoint("TOPLEFT", 0, -((index - 1) * 45 + 22))

    -----------------------------------------------------------------------------------------------

    local costLabel = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    costLabel:SetPoint("LEFT", textLabel, "RIGHT", textLabel:GetWidth() - 85, 0)
    costLabel:SetTextColor(1, 1, 1)

    local quantityLabel1 = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    quantityLabel1:SetPoint("LEFT", textLabel, "RIGHT", 20, 0)
    quantityLabel1:SetTextColor(1, 1, 1, 1)

    button:SetScript("OnClick", onClick)
    button:SetScript(
        "OnEnter",
        function(self)
            itemTooltip:SetOwner(self, "ANCHOR_CURSOR")
            itemTooltip:SetHyperlink(itemType..":" .. id)
            itemTooltip:Show()
        end
    )

    button:SetScript(
        "OnLeave",
        function()
            itemTooltip:Hide()
        end
    )

    button:SetAttribute("itemType", itemType)
    button:SetAttribute("itemCost", cost)
    button:SetAttribute("costType ", costType)
    button:SetAttribute("cost", cost)
    table.insert(createdButtons, button)

    button.costLabel = costLabel
    button.quantityLabel1 = quantityLabel1
    return button, costLabel, quantityLabel1
end
-------------------------------
-- [refreshButton]

-- add button to refresh list of items
-- local refreshButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
-- refreshButton:SetSize(120, 25)
-- refreshButton:SetText("Refresh")
-- set right side above quantity input box
-- refreshButton:SetPoint("TOP", quantityInput, "TOP", -15, 30)

-- refreshButton:SetScript("OnClick", function()
--    print("Refresh button clicked")
-- end)
--------------------------------- 
--Create dropdown menu
local filterDropdown = CreateFrame("Frame", "CustomStoreFilterDropdown", mainFrame, "UIDropDownMenuTemplate")
filterDropdown:SetSize(250, 40)
filterDropdown:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -5, 80)

-- Set larger text size for the dropdown button
local text = _G[filterDropdown:GetName().."Text"]
if text then
    text:SetFont(text:GetFont(), 13)
end

local function FilterDropdown_OnClick(self, arg1, arg2, checked)
    local costType = self.value
    UIDropDownMenu_SetText(filterDropdown, costType)
    -- Filter the buttons
    local contentHeight = 0
    local buttonIndex = 1
    for _, button in ipairs(createdButtons) do
        local buttonCostType = button:GetAttribute("costType")
        if costType == "All Currencies" or buttonCostType == costType then
            button:SetPoint("TOPLEFT", 0, -(buttonIndex - 1) * 22)
            buttonIndex = buttonIndex + 1
            contentHeight = contentHeight + 10
            button:Show()
        else
            button:Hide()
        end
    end
    itemList.contentFrame:SetHeight(contentHeight)
end

local function InitializeFilterDropdown(self, level)
    local info = UIDropDownMenu_CreateInfo()
    
    -- Create custom font for size 13
    local dropdownFont = CreateFont("CustomDropdownFont")
    dropdownFont:SetFont("Fonts\\FRIZQT__.TTF", 13)
    
    -- Set properties for menu items
    info.height = 25
    info.fontObject = dropdownFont
    info.justifyH = "RIGHT"
    
    -- Add "All" option
    info.text = "All Currencies"
    info.value = "All Currencies"
    info.func = FilterDropdown_OnClick
    UIDropDownMenu_AddButton(info)
    
    local costTypes = {
        "Gold",
        "Community Tokens",
        "Vote Tokens",
        "Activity Tokens"
    }
    
    -- Add other options
    for _, costType in ipairs(costTypes) do
        info.text = costType
        info.value = costType
        info.func = FilterDropdown_OnClick
        UIDropDownMenu_AddButton(info)
    end
end

UIDropDownMenu_Initialize(filterDropdown, InitializeFilterDropdown)
UIDropDownMenu_SetWidth(filterDropdown, 250)  -- Increased from 200
UIDropDownMenu_SetText(filterDropdown, "Filter by Currency")

-------------------------------
-- [ShowConfirmPurchasePopup]
-- sets up the popup window handle when you click on the buy button
local function ShowConfirmPurchasePopup(itemID, itemType, quantity, costType, totalCost)
    local costText
    if costType == "Gold" then
        local Gold = math.floor(totalCost / 10000)
        local silver = math.floor((totalCost - (Gold * 10000)) / 100)
        local copper = totalCost - (Gold * 10000) - (silver * 100)
        costText = Gold .. "g " .. silver .. "s " .. copper .. "c"
    elseif costType == "Honor Tokens" then
        costText = totalCost .. " Honor Tokens"
    elseif costType == "Arena Tokens" then
        costText = totalCost .. " Arena Tokens"
    elseif costType == "Community Tokens" then
        costText = totalCost .. " Community Tokens"
    elseif costType == "Vote Tokens" then
        costText = totalCost .. " Vote Tokens"
    elseif costType == "Activity Tokens" then
        costText = totalCost .. " Activity Tokens"
    end

    StaticPopupDialogs["CONFIRM_PURCHASE"] = {
        text = "Are you sure you want to purchase x%d %s for " .. costText .. "?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            AIO.Handle("CustomShop", "addItemOrSpell", itemID, itemType, quantity, costType, totalCost)
            local frame = CreateFrame("Frame")
            frame:SetScript("OnUpdate", function(self, elapsed)
                self.elapsed = (self.elapsed or 0) + elapsed
                if self.elapsed >= 1 then
                    UpdateCurrencyBalances()
                    self:SetScript("OnUpdate", nil)
                end
            end)
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3
    }

    StaticPopupDialogs["CONFIRM_SPELL_PURCHASE"] = {
        text = "Are you sure you want to purchase %s for " .. costText .. "?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            AIO.Handle("CustomShop", "addItemOrSpell", itemID, itemType, quantity, costType, totalCost)
            local frame = CreateFrame("Frame")
            frame:SetScript("OnUpdate", function(self, elapsed)
                self.elapsed = (self.elapsed or 0) + elapsed
                if self.elapsed >= 1.2 then
                    UpdateCurrencyBalances()
                    self:SetScript("OnUpdate", nil)
                end
            end)
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3
    }

    if itemType == "item" then
        local itemName = GetItemInfo(itemID)
        StaticPopup_Show("CONFIRM_PURCHASE", quantity, itemName, itemID, totalCost)
    elseif itemType == "spell" then
        local spellName = GetSpellInfo(itemID)
        StaticPopup_Show("CONFIRM_SPELL_PURCHASE", spellName, itemID, totalCost)
    end
end

-------------------------------

local function UpdateAllCostLabels()
    local quantity = quantityInput:GetNumber()

    for _, button in ipairs(createdButtons) do
        -- update button cost label

        local costType = button:GetAttribute("costType")
        local itemCost = button:GetAttribute("itemCost")
        local quantity = button:GetAttribute("quantity")
        local totalCost = itemCost

        -- setup quantity label
        if quantity then
            button.quantityLabel1:SetText(quantity .. " x ")
        else
            button.quantityLabel1:SetText("1 x")
        end

        if costType == "Gold" then
            local Gold = math.floor(totalCost / 10000)
            local silver = math.floor((totalCost - (Gold * 10000)) / 100)
            local copper = totalCost - (Gold * 10000) - (silver * 100)

            button.costLabel:SetText(Gold .. "g " .. silver .. "s " .. copper .. "c")
        elseif costType == "Honor Tokens" then
            button.costLabel:SetText(totalCost .. " " .. costType)
        elseif costType == "Arena Tokens" then
            button.costLabel:SetText(totalCost .. " " .. costType)
        elseif costType == "Community Tokens" then
            button.costLabel:SetText(totalCost .. " " .. costType)
        elseif costType == "Vote Tokens" then
            button.costLabel:SetText(totalCost .. " " .. costType)
        elseif costType == "Activity Tokens" then
            button.costLabel:SetText(totalCost .. " " .. costType)
        end
    end
end

quantityInput:SetScript("OnTextChanged", UpdateAllCostLabels)  -- for live updates
quantityInput:SetScript("OnEnterPressed", UpdateAllCostLabels) -- for when user presses enter
-- quantityInput:SetScript("OnUpdate", UpdateAllCostLabels)       -- for when user clicks on the input box
-----------------------------------------------------------------------------------------------
-- local Gold = math.floor(cost / 10000)
-- local silver = math.floor((cost - (Gold * 10000)) / 100)
-- local copper = cost - (Gold * 10000) - (silver * 100)
local function ItemButton_OnClick(self, button)
    -- Handle item click, e.g., display item details or initiate purchase
    local itemID = self:GetID()
    local itemType = self:GetAttribute("itemType")
    local itemCost = self:GetAttribute("itemCost")
    local costType = self:GetAttribute("costType")
    local quantity = self:GetAttribute("quantity")

    local totalCost = itemCost
    ShowConfirmPurchasePopup(itemID, itemType, quantity, costType, totalCost)
end

local function PopulateItemList(tabID)
    if not itemsInfo[tabID] then
        return print("No items found for tabID: " .. tabID)
    end

    -- Update category header
    for _, tab in ipairs(tabsInfo) do
        if tab.id == tabID then
            categoryHeader:SetText("Browsing category: " .. tab.name)
            break
        end
    end
    
    -- Reset the scrollbar position
    itemList.scrollFrame:SetVerticalScroll(0)

    -- Calculate the required height of the contentFrame based on the number of items
    local items = itemsInfo[tabID]
    local contentHeight = #items * 45

    -- Update the contentFrame's height
    itemList.contentFrame:SetHeight(contentHeight)

    -- Update the scrollbar's values based on the content frame's height
    local slider = _G[itemList.scrollFrame:GetName() .. "ScrollBar"]
    slider:SetMinMaxValues(0, math.max(0, contentHeight - itemList.scrollFrame:GetHeight()))
    slider:SetValue(0)

    -- Show the scrollbar only if the contentHeight is greater than the scrollFrame's height
    if contentHeight > itemList.scrollFrame:GetHeight() then
        slider:Show()
    else
        slider:Hide()
    end

    -- Remove existing item buttons
    for _, child in ipairs({ itemList.contentFrame:GetChildren() }) do
        child:Hide()
    end

    wipe(createdButtons) -- Clear previous buttons array

    for i, item in ipairs(items) do
        local id, itemType, quantity, costType, cost = item.id, item.itemType, item.quantity, item.CostType, item.cost
        local icon, fakeName
        if item.itemType == "item" then
            icon = GetItemIcon(id)
            fakeName = GetItemInfo(id) or "Hover to show item"
        elseif item.itemType == "spell" then
            local spellTexture = select(3, GetSpellInfo(id))
            icon = spellTexture
            fakeName = GetSpellInfo(id) or "Hover to show spell"
        end

        local button = CreateItemButton(
            itemList.contentFrame,
            i,
            id,
            fakeName,
            icon,
            ItemButton_OnClick,
            item.itemType,
            item.CostType,
            item.cost,
            item.quantity
        )
        button:SetID(id)

        button:SetAttribute("costType", item.costType)
        button:SetAttribute("itemCost", item.cost)
        button:SetAttribute("quantity", item.quantity)

        table.insert(createdButtons, button)
    end

    UpdateAllCostLabels()
end

local function TabButton_OnClick(self)
    local tabID = self:GetID()
    PopulateItemList(tabID)
    UIDropDownMenu_SetText(filterDropdown, "Filter by Currency")
    PopulateItemList(tabID)
end


for i, tab in ipairs(tabsInfo) do
    local button = CreateTabButton(tab.id, tab.name, TabButton_OnClick)
    button:SetID(tab.id)
    button:SetBackdrop(
        {
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        }
    )
    button:SetBackdropBorderColor(1, 1, 1, 1) -- Default border color
end

local f = CreateFrame("Frame")
f:SetScript("OnEvent", OnEvent)
f:RegisterEvent("CHAT_MSG_ADDON")

SLASH_CUSTOMSTORE1 = "/store"  -- The prefix should match the SlashCmdList key
SlashCmdList["CUSTOMSTORE"] = function()  -- Keys in SlashCmdList should be uppercase
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        mainFrame:Show()
        categoryHeader:Hide()
        AIO.Msg():Add("CustomShop", "GetCategories"):Send()
        -- Highlight the first tab button when the frame is shown
        if tabsInfo[1] then
            local firstButton = _G["categoryListButton" .. tabsInfo[1].id]
        end
    end
end

tinsert(UISpecialFrames, mainFrame:GetName()) -- allows frame to be closed with escape key

-- Add icon on worldframe for easy access
local icon = CreateFrame("Button", nil, WorldFrame)
icon:SetSize(32, 32)
icon:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, -50) -- Anchor to the bottom center of the minimap, 50 pixels below (30 pixels lower than before)

icon:SetNormalTexture("Interface\\Icons\\wowtoken")
local tex = icon:CreateFontString(nil, "OVERLAY")
tex:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
tex:SetPoint("CENTER", icon, "BOTTOM", 0, 20)
tex:SetText("Yggdrasil Store")

-- Create a texture behind the text
local backgroundTexture = icon:CreateTexture(nil, "BACKGROUND")
backgroundTexture:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up") -- You can change this to any texture you prefer
backgroundTexture:SetWidth(200) -- Adjust the width as needed
backgroundTexture:SetHeight(40) -- Adjust the height as needed
backgroundTexture:SetPoint("CENTER", icon, "BOTTOM", 35, 15)

icon:SetFrameStrata("LOW")
icon:SetClampedToScreen(true)
icon:SetScript(
    "OnClick",
    function(self, button, down)
        if mainFrame:IsShown() then
            mainFrame:Hide()
        else
            mainFrame:Show()
            categoryHeader:Hide()
            AIO.Msg():Add("CustomStore", "GetCategories"):Send()
            -- Highlight the first tab button when the frame is shown
            if tabsInfo[1] then
                local firstButton = _G["categoryListButton" .. tabsInfo[1].id]
            end
        end
    end
)

icon:SetScript(
    "OnEnter",
    function(self)
        icon:SetAlpha(1)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Click to open the Yggdrasil Store")
        GameTooltip:Show()
    end
)
icon:SetScript(
    "OnLeave",
    function(self)
        icon:SetAlpha(0.5)
        GameTooltip:Hide()
    end
)
-- drag able
icon:SetMovable(true)
icon:EnableMouse(true)
icon:RegisterForDrag("LeftButton")
icon:SetScript(
    "OnDragStart",
    function(self)
        self:StartMoving()
    end
)
icon:SetScript(
    "OnDragStop",
    function(self)
        self:StopMovingOrSizing()
    end
)

-- Create the toggle button
local toggleButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
toggleButton:SetSize(137, 50)
toggleButton:SetText("Show/Hide\nStore Button")
toggleButton:SetPoint("BOTTOMLEFT", 20, 10)

-- Get the text object of the button
local buttonText = toggleButton:GetFontString()

-- Adjust the text position
buttonText:SetPoint("CENTER", 0, -1)

toggleButton:SetScript("OnClick", function()
    if icon:IsVisible() then
        icon:Hide()
        print("You can show/hide the Yggdrasil Store by using the '/store' command.")
    else
        icon:Show()
    end
end)

-- Create the help button
local helpButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
helpButton:SetSize(137, 50)
helpButton:SetText("Help")
helpButton:SetPoint("BOTTOMLEFT", toggleButton, "TOPLEFT", 0, 3)
helpButton:SetScript("OnClick", function()
    HelpMicroButton:Click()
    KnowledgeBaseFrameGMTalk:Click()
    HelpFrameGMTalkOpenTicket:Click()
end)

-- Modify the welcome frame creation code:
local welcomeFrame = CreateFrame("Frame", "CustomStoreWelcomeFrame", mainFrame)
welcomeFrame:SetSize(mainFrame:GetWidth() - 0, mainFrame:GetHeight() - 0)
welcomeFrame:SetPoint("CENTER")
welcomeFrame:SetFrameStrata("DIALOG")

-- Create a blocking panel that will catch all mouse events
local blockingPanel = CreateFrame("Frame", nil, welcomeFrame)
blockingPanel:SetAllPoints()
blockingPanel:EnableMouse(true) -- This makes it catch all mouse events
blockingPanel:SetFrameLevel(welcomeFrame:GetFrameLevel() + 10) -- Set it above other elements

-- Move the existing background panel setup after the blocking panel
local bgPanel = CreateFrame("Frame", nil, welcomeFrame)
bgPanel:SetFrameLevel(welcomeFrame:GetFrameLevel() - 1)
bgPanel:SetAllPoints()
bgPanel:SetBackdrop({
    bgFile = "Interface/Buttons/WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
bgPanel:SetBackdropColor(0, 0, 0, 1)

-- Ensure the welcome content is above the blocking panel
local welcomeTitle = welcomeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
welcomeTitle:SetPoint("TOP", 0, -20)
welcomeTitle:SetText("Welcome to the Yggdrasil Store!")

local welcomeSubtitle = welcomeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
welcomeSubtitle:SetPoint("TOP", welcomeTitle, "BOTTOM", 0, -20)
welcomeSubtitle:SetText("What category would you like to browse?")

-- Create a scroll frame for the welcome screen categories
local welcomeScrollFrame = CreateFrame("ScrollFrame", "CustomStoreWelcomeScrollFrame", welcomeFrame, "UIPanelScrollFrameTemplate")
welcomeScrollFrame:SetPoint("TOPLEFT", welcomeFrame, "TOPLEFT", 10, -80)
welcomeScrollFrame:SetPoint("BOTTOMRIGHT", welcomeFrame, "BOTTOMRIGHT", -30, 10)

local welcomeContentFrame = CreateFrame("Frame", nil, welcomeScrollFrame)
welcomeScrollFrame:SetScrollChild(welcomeContentFrame)
welcomeContentFrame:SetSize(welcomeScrollFrame:GetSize())
welcomeContentFrame:SetFrameLevel(blockingPanel:GetFrameLevel() + 1)

-- Set the frame level of the scroll bar to be above the blocking panel
local slider = _G[welcomeScrollFrame:GetName() .. "ScrollBar"]
slider:SetFrameLevel(blockingPanel:GetFrameLevel() + 2)

-- Calculate grid layout
local BUTTONS_PER_ROW = 3
local BUTTON_SIZE = 100
local SPACING = 20
local START_X = -((BUTTONS_PER_ROW * (BUTTON_SIZE + SPACING)) / 2) + (BUTTON_SIZE / 2) + 335 -- Move 200 pixels to the right
local START_Y = -10

local function CreateCategoryButton(parent, index, name, icon)
    local row = math.floor((index - 1) / BUTTONS_PER_ROW)
    local col = (index - 1) % BUTTONS_PER_ROW
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    button:SetPoint("TOPLEFT", START_X + (col * (BUTTON_SIZE + SPACING)), START_Y + (row * -(BUTTON_SIZE + SPACING)))

    local iconTexture = button:CreateTexture(nil, "ARTWORK")
    iconTexture:SetTexture(icon)
    iconTexture:SetSize(32, 32)
    iconTexture:SetPoint("TOP", button, "TOP", 0, -10)

    local nameText = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("TOP", iconTexture, "BOTTOM", 0, -5)
    nameText:SetText(name)

    button:SetScript("OnClick", function()
        welcomeFrame:Hide()
        categoryHeader:Show()
        for _, child in pairs({tabButtonsContentFrame:GetChildren()}) do
            if child:GetID() == index - 1 then
                PopulateItemList(index - 1)
                break
            end
        end
    end)
    return button
end

-- Create category buttons within the content frame
for i, tab in ipairs(tabsInfo) do
    CreateCategoryButton(welcomeContentFrame, i, tab.name, tab.icon)
end

-- Update the content frame height based on the number of category buttons
local contentHeight = math.ceil(#tabsInfo / BUTTONS_PER_ROW) * (BUTTON_SIZE + SPACING)
welcomeContentFrame:SetHeight(contentHeight)

-- Update the scrollbar's values based on the content frame's height
slider:SetMinMaxValues(0, math.max(0, contentHeight - welcomeScrollFrame:GetHeight()))
slider:SetValue(0)

-- Show the scrollbar only if the contentHeight is greater than the scrollFrame's height
if contentHeight > welcomeScrollFrame:GetHeight() then
    slider:Show()
else
    slider:Hide()
end

-- Show welcome frame on initial Store opening
mainFrame:HookScript("OnShow", function()
    welcomeFrame:Show()
end)

if not icon:IsVisible() then
    icon:ClearAllPoints()
    icon:SetPoint("TOP", WorldFrame, "TOP", 0, -125)
end

-- Make the bgPanel and blockingPanel draggable
bgPanel:SetMovable(true)
bgPanel:EnableMouse(true)
bgPanel:RegisterForDrag("LeftButton")
bgPanel:SetScript("OnDragStart", function(self)
    mainFrame:StartMoving()
end)
bgPanel:SetScript("OnDragStop", function(self)
    mainFrame:StopMovingOrSizing()
end)

blockingPanel:SetMovable(true)
blockingPanel:EnableMouse(true)
blockingPanel:RegisterForDrag("LeftButton")
blockingPanel:SetScript("OnDragStart", function(self)
    mainFrame:StartMoving()
end)
blockingPanel:SetScript("OnDragStop", function(self)
    mainFrame:StopMovingOrSizing()
end)

icon:Hide() -- Start hidden for live test
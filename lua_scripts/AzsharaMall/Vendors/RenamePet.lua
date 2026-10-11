if GetStateMapId() ~= 37 then return end

local cost = 30
local communityCost = cost/10
local currencyName = "Vote Tokens"
local communityCurrencyName = "Community Tokens"
-- Static pet-name index, dumped from world.pet_name_generation.
-- Each entry: {id = ..., word = ..., entry = ..., half = ...}
local STATIC_PET_NAMES = {
{id=1,word="Aba",entry=416,half=0},
{id=2,word="Az",entry=416,half=0},
{id=3,word="Bel",entry=416,half=0},
{id=4,word="Biz",entry=416,half=0},
{id=5,word="Cho",entry=416,half=0},
{id=6,word="Dag",entry=416,half=0},
{id=7,word="Gak",entry=416,half=0},
{id=8,word="Gar",entry=416,half=0},
{id=9,word="Gel",entry=416,half=0},
{id=10,word="Gho",entry=416,half=0},
{id=11,word="Gob",entry=416,half=0},
{id=12,word="Gra",entry=416,half=0},
{id=13,word="Jak",entry=416,half=0},
{id=14,word="Jub",entry=416,half=0},
{id=15,word="Kar",entry=416,half=0},
{id=16,word="Kup",entry=416,half=0},
{id=17,word="Laz",entry=416,half=0},
{id=18,word="Nal",entry=416,half=0},
{id=19,word="Nok",entry=416,half=0},
{id=20,word="Pag",entry=416,half=0},
{id=21,word="Pig",entry=416,half=0},
{id=22,word="Pip",entry=416,half=0},
{id=23,word="Piz",entry=416,half=0},
{id=24,word="Quz",entry=416,half=0},
{id=25,word="Rui",entry=416,half=0},
{id=26,word="Rul",entry=416,half=0},
{id=27,word="Rup",entry=416,half=0},
{id=28,word="Tar",entry=416,half=0},
{id=29,word="Vol",entry=416,half=0},
{id=30,word="Yaz",entry=416,half=0},
{id=31,word="Zep",entry=416,half=0},
{id=32,word="Zig",entry=416,half=0},
{id=33,word="Zil",entry=416,half=0},
{id=34,word="Zor",entry=416,half=0},
{id=35,word="bis",entry=416,half=1},
{id=36,word="fip",entry=416,half=1},
{id=37,word="gup",entry=416,half=1},
{id=38,word="ham",entry=416,half=1},
{id=39,word="jub",entry=416,half=1},
{id=40,word="kin",entry=416,half=1},
{id=41,word="kol",entry=416,half=1},
{id=42,word="lop",entry=416,half=1},
{id=43,word="loz",entry=416,half=1},
{id=44,word="mat",entry=416,half=1},
{id=45,word="mir",entry=416,half=1},
{id=46,word="nam",entry=416,half=1},
{id=47,word="nar",entry=416,half=1},
{id=48,word="nik",entry=416,half=1},
{id=49,word="nip",entry=416,half=1},
{id=50,word="pad",entry=416,half=1},
{id=51,word="pep",entry=416,half=1},
{id=52,word="pit",entry=416,half=1},
{id=53,word="qua",entry=416,half=1},
{id=54,word="rai",entry=416,half=1},
{id=55,word="rin",entry=416,half=1},
{id=56,word="rot",entry=416,half=1},
{id=57,word="tai",entry=416,half=1},
{id=58,word="tal",entry=416,half=1},
{id=59,word="tik",entry=416,half=1},
{id=60,word="tip",entry=416,half=1},
{id=61,word="tog",entry=416,half=1},
{id=62,word="tuk",entry=416,half=1},
{id=63,word="uri",entry=416,half=1},
{id=64,word="yal",entry=416,half=1},
{id=65,word="yap",entry=416,half=1},
{id=66,word="Bhee",entry=417,half=0},
{id=67,word="Bruu",entry=417,half=0},
{id=68,word="Czaa",entry=417,half=0},
{id=69,word="Droo",entry=417,half=0},
{id=70,word="Flaa",entry=417,half=0},
{id=71,word="Fzuu",entry=417,half=0},
{id=72,word="Ghaa",entry=417,half=0},
{id=73,word="Gree",entry=417,half=0},
{id=74,word="Gzaa",entry=417,half=0},
{id=75,word="Haa",entry=417,half=0},
{id=76,word="Haad",entry=417,half=0},
{id=77,word="Haag",entry=417,half=0},
{id=78,word="Haap",entry=417,half=0},
{id=79,word="Jhaa",entry=417,half=0},
{id=80,word="Jhuu",entry=417,half=0},
{id=81,word="Khaa",entry=417,half=0},
{id=82,word="Khii",entry=417,half=0},
{id=83,word="Khuu",entry=417,half=0},
{id=84,word="Kree",entry=417,half=0},
{id=85,word="Luu",entry=417,half=0},
{id=86,word="Maa",entry=417,half=0},
{id=87,word="Nhee",entry=417,half=0},
{id=88,word="Phuu",entry=417,half=0},
{id=89,word="Pryy",entry=417,half=0},
{id=90,word="Rhuu",entry=417,half=0},
{id=91,word="Shaa",entry=417,half=0},
{id=92,word="Sloo",entry=417,half=0},
{id=93,word="Sruu",entry=417,half=0},
{id=94,word="Thoo",entry=417,half=0},
{id=95,word="Traa",entry=417,half=0},
{id=96,word="Wraa",entry=417,half=0},
{id=97,word="Zhaa",entry=417,half=0},
{id=98,word="dhon",entry=417,half=1},
{id=99,word="dhum",entry=417,half=1},
{id=100,word="dhun",entry=417,half=1},
{id=101,word="dom",entry=417,half=1},
{id=102,word="don",entry=417,half=1},
{id=103,word="drom",entry=417,half=1},
{id=104,word="dym",entry=417,half=1},
{id=105,word="fenn",entry=417,half=1},
{id=106,word="fum",entry=417,half=1},
{id=107,word="fun",entry=417,half=1},
{id=108,word="ghon",entry=417,half=1},
{id=109,word="ghun",entry=417,half=1},
{id=110,word="grom",entry=417,half=1},
{id=111,word="grym",entry=417,half=1},
{id=112,word="hom",entry=417,half=1},
{id=113,word="hon",entry=417,half=1},
{id=114,word="hun",entry=417,half=1},
{id=115,word="jhom",entry=417,half=1},
{id=116,word="kun",entry=417,half=1},
{id=117,word="lum",entry=417,half=1},
{id=118,word="mmon",entry=417,half=1},
{id=119,word="mon",entry=417,half=1},
{id=120,word="myn",entry=417,half=1},
{id=121,word="nam",entry=417,half=1},
{id=122,word="nem",entry=417,half=1},
{id=123,word="nhym",entry=417,half=1},
{id=124,word="nom",entry=417,half=1},
{id=125,word="num",entry=417,half=1},
{id=126,word="phom",entry=417,half=1},
{id=127,word="roon",entry=417,half=1},
{id=128,word="rym",entry=417,half=1},
{id=129,word="shon",entry=417,half=1},
{id=130,word="thun",entry=417,half=1},
{id=131,word="tom",entry=417,half=1},
{id=132,word="zhem",entry=417,half=1},
{id=133,word="zhum",entry=417,half=1},
{id=134,word="zun",entry=417,half=1},
{id=135,word="Bar",entry=1860,half=0},
{id=136,word="Bel",entry=1860,half=0},
{id=137,word="Char",entry=1860,half=0},
{id=138,word="Grak'",entry=1860,half=0},
{id=139,word="Graz'",entry=1860,half=0},
{id=140,word="Grim",entry=1860,half=0},
{id=141,word="Hath",entry=1860,half=0},
{id=142,word="Hel",entry=1860,half=0},
{id=143,word="Hok",entry=1860,half=0},
{id=144,word="Huk",entry=1860,half=0},
{id=145,word="Jhaz",entry=1860,half=0},
{id=146,word="Jhom",entry=1860,half=0},
{id=147,word="Juk'",entry=1860,half=0},
{id=148,word="Kal'",entry=1860,half=0},
{id=149,word="Klath",entry=1860,half=0},
{id=150,word="Kon",entry=1860,half=0},
{id=151,word="Krag",entry=1860,half=0},
{id=152,word="Krak",entry=1860,half=0},
{id=153,word="Mak",entry=1860,half=0},
{id=154,word="Mezz",entry=1860,half=0},
{id=155,word="Orm",entry=1860,half=0},
{id=156,word="Phan",entry=1860,half=0},
{id=157,word="Sar",entry=1860,half=0},
{id=158,word="Tang",entry=1860,half=0},
{id=159,word="Than",entry=1860,half=0},
{id=160,word="Thog",entry=1860,half=0},
{id=161,word="Thok",entry=1860,half=0},
{id=162,word="Thul",entry=1860,half=0},
{id=163,word="Zag'",entry=1860,half=0},
{id=164,word="Zang",entry=1860,half=0},
{id=165,word="Zhar'",entry=1860,half=0},
{id=166,word="kath",entry=1860,half=1},
{id=167,word="doc",entry=1860,half=1},
{id=168,word="dok",entry=1860,half=1},
{id=169,word="gak",entry=1860,half=1},
{id=170,word="garth",entry=1860,half=1},
{id=171,word="gore",entry=1860,half=1},
{id=172,word="gorg",entry=1860,half=1},
{id=173,word="grave",entry=1860,half=1},
{id=174,word="gron",entry=1860,half=1},
{id=175,word="juk",entry=1860,half=1},
{id=176,word="krast",entry=1860,half=1},
{id=177,word="kresh",entry=1860,half=1},
{id=178,word="krit",entry=1860,half=1},
{id=179,word="los",entry=1860,half=1},
{id=180,word="mon",entry=1860,half=1},
{id=181,word="mos",entry=1860,half=1},
{id=182,word="moth",entry=1860,half=1},
{id=183,word="nagma",entry=1860,half=1},
{id=184,word="nak",entry=1860,half=1},
{id=185,word="nar",entry=1860,half=1},
{id=186,word="nos",entry=1860,half=1},
{id=187,word="nuz",entry=1860,half=1},
{id=188,word="phog",entry=1860,half=1},
{id=189,word="rath",entry=1860,half=1},
{id=190,word="tast",entry=1860,half=1},
{id=191,word="taz",entry=1860,half=1},
{id=192,word="thak",entry=1860,half=1},
{id=193,word="thang",entry=1860,half=1},
{id=194,word="thyk",entry=1860,half=1},
{id=195,word="vhug",entry=1860,half=1},
{id=196,word="zazt",entry=1860,half=1},
{id=197,word="Ael",entry=1863,half=0},
{id=198,word="Aez",entry=1863,half=0},
{id=199,word="Ang",entry=1863,half=0},
{id=200,word="Ban",entry=1863,half=0},
{id=201,word="Bet",entry=1863,half=0},
{id=202,word="Bro",entry=1863,half=0},
{id=203,word="Bry",entry=1863,half=0},
{id=204,word="Cat",entry=1863,half=0},
{id=205,word="Dir",entry=1863,half=0},
{id=206,word="Dis",entry=1863,half=0},
{id=207,word="Dom",entry=1863,half=0},
{id=208,word="Drus",entry=1863,half=0},
{id=209,word="Fie",entry=1863,half=0},
{id=210,word="Fier",entry=1863,half=0},
{id=211,word="Gly",entry=1863,half=0},
{id=212,word="Hel",entry=1863,half=0},
{id=213,word="Hes",entry=1863,half=0},
{id=214,word="Kal",entry=1863,half=0},
{id=215,word="Lyn",entry=1863,half=0},
{id=216,word="Mir",entry=1863,half=0},
{id=217,word="Nim",entry=1863,half=0},
{id=218,word="Sar",entry=1863,half=0},
{id=219,word="Sel",entry=1863,half=0},
{id=220,word="Vil",entry=1863,half=0},
{id=221,word="Zah",entry=1863,half=0},
{id=222,word="aith",entry=1863,half=1},
{id=223,word="anda",entry=1863,half=1},
{id=224,word="antia",entry=1863,half=1},
{id=225,word="evere",entry=1863,half=1},
{id=226,word="lia",entry=1863,half=1},
{id=227,word="lissa",entry=1863,half=1},
{id=228,word="neri",entry=1863,half=1},
{id=229,word="neth",entry=1863,half=1},
{id=230,word="nia",entry=1863,half=1},
{id=231,word="nlissa",entry=1863,half=1},
{id=232,word="nora",entry=1863,half=1},
{id=233,word="nva",entry=1863,half=1},
{id=234,word="nys",entry=1863,half=1},
{id=235,word="ola",entry=1863,half=1},
{id=236,word="ona",entry=1863,half=1},
{id=237,word="ora",entry=1863,half=1},
{id=238,word="rah",entry=1863,half=1},
{id=239,word="riana",entry=1863,half=1},
{id=240,word="riel",entry=1863,half=1},
{id=241,word="rona",entry=1863,half=1},
{id=242,word="tai",entry=1863,half=1},
{id=243,word="tevere",entry=1863,half=1},
{id=244,word="thea",entry=1863,half=1},
{id=245,word="vina",entry=1863,half=1},
{id=246,word="wena",entry=1863,half=1},
{id=247,word="wyn",entry=1863,half=1},
{id=248,word="xia",entry=1863,half=1},
{id=249,word="yla",entry=1863,half=1},
{id=250,word="yssa",entry=1863,half=1},
{id=251,word="Flaa",entry=17252,half=0},
{id=252,word="Haa",entry=17252,half=0},
{id=253,word="Jhuu",entry=17252,half=0},
{id=254,word="Shaa",entry=17252,half=0},
{id=255,word="Thoo",entry=17252,half=0},
{id=256,word="dhun",entry=17252,half=1},
{id=257,word="ghun",entry=17252,half=1},
{id=258,word="roon",entry=17252,half=1},
{id=259,word="thun",entry=17252,half=1},
{id=260,word="tom",entry=17252,half=1},
{id=261,word="Stone",entry=26125,half=0},
{id=262,word="Stone",entry=26125,half=0},
{id=263,word="Eye",entry=26125,half=0},
{id=264,word="Dirt",entry=26125,half=0},
{id=265,word="Blight",entry=26125,half=0},
{id=266,word="Bat",entry=26125,half=0},
{id=267,word="Rat",entry=26125,half=0},
{id=268,word="Corpse",entry=26125,half=0},
{id=269,word="Grave",entry=26125,half=0},
{id=270,word="Carrion",entry=26125,half=0},
{id=271,word="Skull",entry=26125,half=0},
{id=272,word="Bone",entry=26125,half=0},
{id=273,word="Crypt",entry=26125,half=0},
{id=274,word="Rib",entry=26125,half=0},
{id=275,word="Brain",entry=26125,half=0},
{id=276,word="Tomb",entry=26125,half=0},
{id=277,word="Rot",entry=26125,half=0},
{id=278,word="Gravel",entry=26125,half=0},
{id=279,word="Plague",entry=26125,half=0},
{id=280,word="Casket",entry=26125,half=0},
{id=281,word="Limb",entry=26125,half=0},
{id=282,word="Worm",entry=26125,half=0},
{id=283,word="Earth",entry=26125,half=0},
{id=284,word="Spine",entry=26125,half=0},
{id=285,word="Pebble",entry=26125,half=0},
{id=286,word="Root",entry=26125,half=0},
{id=287,word="Marrow",entry=26125,half=0},
{id=288,word="Hammer",entry=26125,half=0},
{id=289,word="ravager",entry=26125,half=1},
{id=290,word="muncher",entry=26125,half=1},
{id=291,word="cruncher",entry=26125,half=1},
{id=292,word="masher",entry=26125,half=1},
{id=293,word="leaper",entry=26125,half=1},
{id=294,word="grinder",entry=26125,half=1},
{id=295,word="stalker",entry=26125,half=1},
{id=296,word="gobbler",entry=26125,half=1},
{id=297,word="feeder",entry=26125,half=1},
{id=298,word="basher",entry=26125,half=1},
{id=299,word="chewer",entry=26125,half=1},
{id=300,word="ripper",entry=26125,half=1},
{id=301,word="slicer",entry=26125,half=1},
{id=302,word="gnaw",entry=26125,half=1},
{id=303,word="flayer",entry=26125,half=1},
{id=304,word="rumbler",entry=26125,half=1},
{id=305,word="chomp",entry=26125,half=1},
{id=306,word="breaker",entry=26125,half=1},
{id=307,word="keeper",entry=26125,half=1},
{id=308,word="rawler",entry=26125,half=1},
{id=309,word="stealer",entry=26125,half=1},
{id=310,word="thief",entry=26125,half=1},
{id=311,word="catcher",entry=26125,half=1},
{id=312,word="drinker",entry=26125,half=1},
{id=313,word="slicer",entry=26125,half=1},
}
local petNameCache = {}
local sortedPetNameCache = {}
local PAGE_SIZE = 13
local currentEntry = 0
local currentHalf = 0
local currentPage = 1
local firstHalfSelection = ""
local secondHalfSelection = ""
local pendingRenames = {}
local petTypes = {
    [416] = "Imp",
    [417] = "Felhunter",
    [1860] = "Voidwalker",
    [1863] = "Succubus",
    [17252] = "Felguard",
    [26125] = "Raise Dead pet"  -- For Death Knight
}

-- New constants for INTID ranges
local MENU_OFFSET = 100000
local PET_TYPE_OFFSET = MENU_OFFSET + 100
local PAGE_CONTROL_OFFSET = MENU_OFFSET + 200

-- Build pet-name index from the static table
local function LoadPetNames()
    for _, r in ipairs(STATIC_PET_NAMES) do
        petNameCache[r.id] = { word = r.word, entry = r.entry, half = r.half }
        table.insert(sortedPetNameCache, { id = r.id, word = r.word, entry = r.entry, half = r.half })
    end
    table.sort(sortedPetNameCache, function(a, b) return a.word < b.word end)
end

-- Load pet names into cache on script load
LoadPetNames()

local function OnGossipHello(event, player, creature)
    if player:GetClass() == 9 then -- DK support removed as pet's name is dynamic (or player:GetClass() == 6)
        player:GossipClearMenu()
        player:GossipMenuAddItem(4, "How does this work?", 0, MENU_OFFSET + 1)
        
        if player:GetClass() == 9 then -- Warlock
            player:GossipMenuAddItem(0, "Imp", 0, PET_TYPE_OFFSET + 416)
            player:GossipMenuAddItem(0, "Felhunter", 0, PET_TYPE_OFFSET + 417)
            player:GossipMenuAddItem(0, "Voidwalker", 0, PET_TYPE_OFFSET + 1860)
            player:GossipMenuAddItem(0, "Succubus", 0, PET_TYPE_OFFSET + 1863)
            player:GossipMenuAddItem(0, "Felguard", 0, PET_TYPE_OFFSET + 17252)
        elseif player:GetClass() == 6 then -- Death Knight
            player:GossipMenuAddItem(0, "What do you want to rename your undead pet to?", 0, PET_TYPE_OFFSET + 26125)
        end
        
        player:GossipMenuAddItem(4, "Nevermind", 0, MENU_OFFSET + 2)
        player:GossipSendMenu(1, player, 60)
    else
        creature:SendUnitWhisper("I only cater to Warlocks.", 0, player)
    end
end

local function ShowPage(player, entry, half, page)
    currentEntry = entry
    currentHalf = half
    currentPage = page

    local startIdx = (page - 1) * PAGE_SIZE + 1
    local endIdx = page * PAGE_SIZE
    local totalItems = 0

    -- Count total items
    for _, data in pairs(sortedPetNameCache) do
        if data.entry == entry and data.half == half then
            totalItems = totalItems + 1
        end
    end

    player:GossipClearMenu()

    -- Add the indicator for which half of the name is being selected
    local petType = petTypes[currentEntry] or "Pet"
    player:GossipMenuAddItem(4, half == 0 and "Selecting first half of "..petType.." name" or "Selecting second half of "..petType.." name", 0, PAGE_CONTROL_OFFSET)

    -- Show items for the current page
    local itemsShown = 0
    for _, data in pairs(sortedPetNameCache) do
        if data.entry == entry and data.half == half then
            if itemsShown >= startIdx - 1 and itemsShown < endIdx then
                player:GossipMenuAddItem(0, data.word, 0, data.id)
            end
            itemsShown = itemsShown + 1
        end
    end

    -- Add previous page button if not on the first page
    if page > 1 then
        player:GossipMenuAddItem(4, "Previous Page", 0, PAGE_CONTROL_OFFSET + 1)
    end

    -- Add next page button if there are more items
    if totalItems > endIdx then
        player:GossipMenuAddItem(4, "Next Page", 0, PAGE_CONTROL_OFFSET + 2)
    end

    -- Add a "Back" button
    player:GossipMenuAddItem(4, "Back", 0, MENU_OFFSET + 3)

    player:GossipSendMenu(1, player, 60)
end

local function UpdatePetName(playerGUID)
    local renameInfo = pendingRenames[playerGUID]
    if renameInfo then
        local query = string.format("UPDATE character_pet SET name = '%s' WHERE owner = %d AND entry = %d",
            renameInfo.petName, playerGUID, renameInfo.petEntry)
        CharDBExecute(query)
        print(string.format("Pet Renamer]: Updated pet name in database for player GUID %d to %s", playerGUID, renameInfo.petName))
        pendingRenames[playerGUID] = nil
    end
end

local function OnGossipSelect(event, player, object, sender, intid, code)
    if intid == PAGE_CONTROL_OFFSET + 1 then
        player:GossipClearMenu()
        ShowPage(player, currentEntry, currentHalf, currentPage - 1)
    elseif intid == PAGE_CONTROL_OFFSET + 2 then
        player:GossipClearMenu()
        ShowPage(player, currentEntry, currentHalf, currentPage + 1)
    elseif intid >= PET_TYPE_OFFSET and intid < PET_TYPE_OFFSET + 30000 then
        local petEntry = intid - PET_TYPE_OFFSET
        firstHalfSelection = ""
        secondHalfSelection = ""
        currentEntry = petEntry
        currentHalf = 0
        player:GossipClearMenu()
        ShowPage(player, petEntry, 0, 1)
    elseif intid == MENU_OFFSET + 1 then
        player:GossipClearMenu()
        player:GossipMenuAddItem(0, "I possess the ability to permanently rename your pets through manipulating the threads in the Twisting Nether. Simply choose what kind of pet you want to rename and select the name. I charge "..cost.." "..currencyName.." for my services. To complete the process, I will log you out. When you return, your pet will be renamed.", 0, intid)
        player:GossipMenuAddItem(4, "Back", 0, MENU_OFFSET + 3)
        player:GossipSendMenu(1, player, 60)
    elseif intid == MENU_OFFSET + 2 then
        player:GossipComplete()
    elseif petNameCache[intid] then
        local selectedName = petNameCache[intid]
        if selectedName then
            if currentHalf == 0 then
                firstHalfSelection = selectedName.word
                currentHalf = 1
                player:GossipClearMenu()
                ShowPage(player, selectedName.entry, 1, 1)
            else
                secondHalfSelection = selectedName.word
                local fullPetName = firstHalfSelection .. secondHalfSelection
                local petType = petTypes[currentEntry] or "Pet"
                
                player:GossipClearMenu()
                player:GossipMenuAddItem(4, string.format("How do you want to pay to rename your %s to %s?", petType, fullPetName), 0, MENU_OFFSET, false)
                player:GossipMenuAddItem(1, cost.." "..currencyName, 0, MENU_OFFSET + 4, false, string.format("Are you sure you want to rename your %s to '%s'? This process costs "..cost.." "..currencyName.." and will log you out to save the change.", petType, fullPetName))
                player:GossipMenuAddItem(1, communityCost.." "..communityCurrencyName, 0, MENU_OFFSET + 5, false, string.format("Are you sure you want to rename your %s to '%s'? This process costs "..communityCost.." "..communityCurrencyName.." and will log you out to save the change.", petType, fullPetName))
                player:GossipMenuAddItem(4, "Cancel", 0, MENU_OFFSET + 3)
                player:GossipSendMenu(1, player, 60)
            end
        end
	elseif intid == MENU_OFFSET + 5 then
        local petType = petTypes[currentEntry] or "Pet"
        local fullPetName = firstHalfSelection .. secondHalfSelection
        local playerGUID = player:GetGUIDLow()
        
        -- Check if the player has enough vote tokens
        if player:GetItemCount(19322) >= communityCost then
            player:RemoveItem(19322, communityCost)
            player:SaveToDB()
            
            pendingRenames[playerGUID] = {
                petName = fullPetName,
                petEntry = currentEntry
            }
            
            --print(string.format("Player %s will rename their %s to: %s", player:GetName(), petType, fullPetName))
            player:GossipComplete()
            
            -- Schedule the database update
            CreateLuaEvent(function() UpdatePetName(playerGUID) end, 1000, 1)
            
            -- Log out the player
            player:LogoutPlayer(false)
			print("[Pet Renamer]: Player "..player:GetName().." has paid "..communityCost.." "..communityCurrencyName.." to rename pet to.")
        else
            player:SendBroadcastMessage("You don't have enough "..communityCurrencyName..". "..communityCost.." "..communityCurrencyName.." are required to rename your pet.")
            player:GossipComplete()
        end
    elseif intid == MENU_OFFSET + 4 then
        local petType = petTypes[currentEntry] or "Pet"
        local fullPetName = firstHalfSelection .. secondHalfSelection
        local playerGUID = player:GetGUIDLow()
        
        -- Check if the player has enough vote tokens
        if player:GetItemCount(20880) >= cost then
            player:RemoveItem(20880, cost)
            player:SaveToDB()
            
            pendingRenames[playerGUID] = {
                petName = fullPetName,
                petEntry = currentEntry
            }
            
            --print(string.format("Player %s will rename their %s to: %s", player:GetName(), petType, fullPetName))
            player:GossipComplete()
            
            -- Schedule the database update
            CreateLuaEvent(function() UpdatePetName(playerGUID) end, 1000, 1)
            
            -- Log out the player
            player:LogoutPlayer(false)
			print("Pet Renamer]: Player "..player:GetName().." has paid "..cost.." "..currencyName.." to rename pet.")
        else
            player:SendBroadcastMessage("You don't have enough "..currencyName..". "..cost.." "..currencyName.." are required to rename your pet.")
            player:GossipComplete()
        end
    elseif intid == MENU_OFFSET + 3 then
        firstHalfSelection = ""
        secondHalfSelection = ""
        currentHalf = 0
        player:GossipClearMenu()
        player:GossipMenuAddItem(4, "How does this work?", 0, MENU_OFFSET + 1)
        
        if player:GetClass() == 9 then -- Warlock
            player:GossipMenuAddItem(0, "Imp", 0, PET_TYPE_OFFSET + 416)
            player:GossipMenuAddItem(0, "Felhunter", 0, PET_TYPE_OFFSET + 417)
            player:GossipMenuAddItem(0, "Voidwalker", 0, PET_TYPE_OFFSET + 1860)
            player:GossipMenuAddItem(0, "Succubus", 0, PET_TYPE_OFFSET + 1863)
            player:GossipMenuAddItem(0, "Felguard", 0, PET_TYPE_OFFSET + 17252)
        elseif player:GetClass() == 6 then -- Death Knight
            player:GossipMenuAddItem(0, "What do you want to rename your undead pet to?", 0, PET_TYPE_OFFSET + 26125)
        end
        player:GossipMenuAddItem(4, "Nevermind", 0, MENU_OFFSET + 2)
        
        player:GossipSendMenu(1, player, 60)
    end
end

-- Register gossip event for player interactions (ID 60) and NPC (ID 190086)
RegisterPlayerGossipEvent(60, 2, OnGossipSelect)
RegisterCreatureGossipEvent(190086, 1, OnGossipHello)
RegisterCreatureGossipEvent(190086, 2, OnGossipSelect)

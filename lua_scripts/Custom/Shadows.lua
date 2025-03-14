
-- Shdows Configs Start
local BOT_TELE_VISUAL   = 64446
local BotSummonCD       = 30 * 60 -- 30 minutes
minShadowsLevel          = 15 -- Global var also referenced by Twiggy

isPlayerBot		        =   {} -- Global table referenced in VIP script as well
local addCmdTimer       =   {}
local logoutEvent       =   {}
local botsAvailable     =   {}
local activeBots        =   {}
local botCount          =   {}
local botTeleTime       =   {}
local botMasters        =   {}
local botSummonTime     =   {}
local dontKickTime	    =   {}
local removalInProgress =   {}
local lastTeleTime      =   {}
local disallowedZones   =   {4298, 4197, 3628, 3666} -- Scarlet Enclave (DK start area), Wintergrasp, Halaa

-- Shadows Configs End

-- Shadows Script Start

function GetClassName(classId)
    local classNames = {
        [1] = "Warrior",
        [2] = "Paladin",
        [3] = "Hunter",
        [4] = "Rogue",
        [5] = "Priest",
        [6] = "Death Knight",
        [7] = "Shaman",
        [8] = "Mage",
        [9] = "Warlock",
        [11] = "Druid"
    }
    return classNames[classId] or "Unknown"
end

function GetRaceName(raceId)
    local raceNames = {
        [1] = "Human",
        [2] = "Orc",
        [3] = "Dwarf",
        [4] = "Night Elf",
        [5] = "Undead",
        [6] = "Tauren",
        [7] = "Gnome",
        [8] = "Troll",
        [10] = "Blood Elf",
        [11] = "Draenei"
    }
    return raceNames[raceId] or "Unknown"
end

function GetClassIconPath(classId)
    local classIcons = {
        [1] = "Ability_Warrior_SavageBlow",      -- Warrior
        [2] = "Spell_Holy_HolyBolt",             -- Paladin
        [3] = "INV_Weapon_Bow_07",               -- Hunter
        [4] = "Ability_Stealth",                 -- Rogue
        [5] = "Spell_Holy_PowerWordShield",      -- Priest
        [6] = "Spell_Deathknight_ClassIcon",     -- Death Knight
        [7] = "Spell_Nature_BloodLust",          -- Shaman
        [8] = "Spell_Holy_MagicalSentry",        -- Mage
        [9] = "Spell_Shadow_CurseOfTounges",     -- Warlock
        [11] = "Spell_Nature_Regeneration"       -- Druid
    }
    return classIcons[classId] or "INV_Misc_QuestionMark"
end

function GetRaceIconPath(raceId, gender)
    local raceIcons = {
        [1] = {
            [0] = "achievement_character_human_male",
            [1] = "achievement_character_human_female"
        },
        [2] = {
            [0] = "achievement_character_orc_male",
            [1] = "achievement_character_orc_female"
        },
        [3] = {
            [0] = "achievement_character_dwarf_male",
            [1] = "inv_misc_head_dwarf_02"
        },
        [4] = {
            [0] = "achievement_character_nightelf_male",
            [1] = "achievement_character_nightelf_female"
        },
        [5] = {
            [0] = "inv_misc_head_undead_01",
            [1] = "inv_misc_head_undead_02"
        },
        [6] = {
            [0] = "achievement_character_tauren_male",
            [1] = "achievement_character_tauren_female"
        },
        [7] = {
            [0] = "inv_misc_head_gnome_01",
            [1] = "inv_misc_head_gnome_02"
        },
        [8] = {
            [0] = "achievement_character_troll_male",
            [1] = "achievement_character_troll_female"
        },
        [10] = {
            [0] = "achievement_character_bloodelf_male",
            [1] = "achievement_character_bloodelf_female"
        },
        [11] = {
            [0] = "achievement_character_draenei_male",
            [1] = "achievement_character_draenei_female"
        }
    }
    
    if raceIcons[raceId] and raceIcons[raceId][gender] then
        return raceIcons[raceId][gender]
    end
    return "INV_Misc_QuestionMark"
end

local commandCategories = {
   movement = {
       name = "Movement",
       intid = 20,
       commands = {
           {cmd = "follow", name = "Follow", desc = "Your shadows will follow the player. Say 'follow' in group chat or whisper to instruct shadow."},
           {cmd = "flee", name = "Flee", desc = "Your shadows will try to move away from their target while in combat. Say 'flee' in group chat or whisper to instruct shadow."},
           {cmd = "runaway", name = "Run Away", desc = "Your shadows will try to kite their currently aggroed mobs by whispering or saying 'runaway' in group chat."},
           {cmd = "@tank flee", name = "Tank Flee", desc = "Your shadows will command the tank to flee from combat. Say '@tank flee' in group chat or whisper to instruct shadow."},
           {cmd = "@dps flee", name = "DPS Flee", desc = "Your shadows will command the DPS to flee from combat. Say '@dps flee' in group chat or whisper to instruct shadow."},
           {cmd = "@heal flee", name = "Healer Flee", desc = "Your shadows will command the healer to flee from combat. Say '@heal flee' in group chat or whisper to instruct shadow."},
           {cmd = "@melee flee", name = "Melee Flee", desc = "Your shadows will command melee players to flee from combat. Say '@melee flee' in group chat or whisper to instruct shadow."},
           {cmd = "@ranged flee", name = "Ranged Flee", desc = "Your shadows will command ranged players to flee from combat. Say '@ranged flee' in group chat or whisper to instruct shadow."},
           {cmd = "stay", name = "Stay", desc = "Your shadows will stay in its current position. Say 'stay' in group chat or whisper to instruct shadow."},
           {cmd = "reset botAI", name = "Reset botAI", desc = "Say 'reset botAI' (case sensitive) in group chat or whispers to a shadow to reset its current settings."},
       }
   },
   combat = {
       name = "Combat",
       intid = 21,
       commands = {
           {cmd = "attack", name = "Attack", desc = "Your shadows will engage and attack the target. Say 'attack' in group chat or whisper to instruct shadow."},
           {cmd = "@tank attack", name = "Tank Attack", desc = "Your shadows will command the tank to attack the target. Say '@tank attack' in group chat or whisper to instruct shadow."},
           {cmd = "@dps attack", name = "DPS Attack", desc = "Your shadows will command the DPS to attack the target. Say '@dps attack' in group chat or whisper to instruct shadow."},
           {cmd = "@heal attack", name = "Healer Attack", desc = "Your shadows will command the healer to attack the target. Say '@heal attack' in group chat or whisper to instruct shadow."},
           {cmd = "@melee attack", name = "Melee Attack", desc = "Your shadows will command melee players to attack the target. Say '@melee attack' in group chat or whisper to instruct shadow."},
           {cmd = "@ranged attack", name = "Ranged Attack", desc = "Your shadows will command ranged players to attack the target. Say '@ranged attack' in group chat or whisper to instruct shadow."},
           {cmd = "grind", name = "Grind", desc = "Make all shadows automatically attack nearby creatures that yield experience points. Say 'grind' in group chat to activate grind mode."},
           {cmd = "reset botAI", name = "Reset botAI", desc = "Say 'reset botAI' (case sensitive) in group chat or whispers to a shadow to reset its current settings."},
       }
   },
   formation = {
       name = "Formation",
       intid = 22,
       commands = {
           {cmd = "formation arrow", name = "Arrow Formation", desc = "Your shadows will arrange itself in an arrow formation. Say 'formation arrow' in group chat or whisper to instruct shadow."},
           {cmd = "formation queue", name = "Queue Formation", desc = "Your shadows will arrange itself in a queue formation. Say 'formation queue' in group chat or whisper to instruct shadow."},
           {cmd = "formation near", name = "Near Formation", desc = "Your shadows will arrange itself in a close formation. Say 'formation near' in group chat or whisper to instruct shadow."},
           {cmd = "formation melee", name = "Melee Formation", desc = "Your shadows will arrange itself in a melee formation. Say 'formation melee' in group chat or whisper to instruct shadow."},
           {cmd = "formation line", name = "Line Formation", desc = "Your shadows will arrange itself in a line formation. Say 'formation line' in group chat or whisper to instruct shadow."},
           {cmd = "formation circle", name = "Circle Formation", desc = "Your shadows will arrange itself in a circular formation. Say 'formation circle' in group chat or whisper to instruct shadow."},
           {cmd = "formation chaos", name = "Chaos Formation", desc = "Your shadows will arrange itself in a chaotic formation. Say 'formation chaos' in group chat or whisper to instruct shadow."},
           {cmd = "formation shield", name = "Shield Formation", desc = "Your shadows will arrange itself in a shield formation. Say 'formation shield' in group chat or whisper to instruct shadow."},
           {cmd = "formation", name = "Default Formation", desc = "Your shadows will revert to its default formation. Say 'formation' in group chat or whisper to instruct shadow."},
           {cmd = "reset botAI", name = "Reset botAI", desc = "Say 'reset botAI' (case sensitive) in group chat or whispers to a shadow to reset its settings."},
       }
   },
   worldinteraction = {
       name = "World Interaction", 
       intid = 23,
       commands = {
           {cmd = "repair", name = "Repair", desc = "Your shadows will repair at a nearby eligible vendor if you say 'repair' in group chat or whispers."},
           {cmd = "talk", name = "Talk", desc = "By saying 'talk' in group chat or whispers to a shadow, your shadows will talk to your current target. This can be used to hand in quests or learn flight paths, for example."},
           {cmd = "trainer learn", name = "Learn Skills", desc = "Your shadows will learn applicable skills from the trainer you are currently talking to. Say 'trainer learn' in group chat or whisper to instruct shadow."},
           {cmd = "release", name = "Release Spirit", desc = "Your shadows will release its spirit upon death. Say 'release' in group chat or whisper to instruct shadow."},
           {cmd = "quests", name = "View Quests", desc = "Your shadows will display available quests. Say 'quests' in group chat or whisper to instruct shadow."},
           {cmd = "stats", name = "View Stats", desc = "Your shadows will display current stats. Say 'stats' in group chat or whisper to instruct shadow."},
           {cmd = "reset botAI", name = "Reset botAI", desc = "Say 'reset botAI' (case sensitive) in group chat or whispers to a shadow to reset its settings."},
        }
   },
   spell = {
       name = "Spells", 
       intid = 24,
       commands = {
           {cmd = "cast <spell>", name = "cast <spell name>", desc = "You may instruct your shadows to cast specific spells in their spell book by saying 'cast <spell name>'.\n \nFor example, if you want your Death Knight shadow to change presence, say 'cast Blood Presence' in group chat or whisper.\n \nThis is also how one can assign paladin and other class buffs.\n \n"},
       }
   },
   playerinteraction = {
       name = "Player Interaction", 
       intid = 26,
       commands = {
           {cmd = "stats", name = "Stats", desc = "By saying 'stats' in group chat or whispers, your shadows will display their experience percentage, number of free bag slots, and money."},
           {cmd = "inv", name = "Inventory", desc = "By whispering 'inv' to a shadow, the shadow will whisper back its full inventory."},
           {cmd = "c", name = "Inventory", desc = "'c' can also be used to make a shadow show its inventory."},
           {cmd = "e", name = "Equip Inventory", desc = "By whispering 'e <item>' to a shadow, the shadow will equip a named or linked from its inventory."},
           {cmd = "s", name = "Sell Inventory", desc = "By whispering 's' to a shadow, a shadow can vendor specific items. Specify further with grey, vendor, item link, and more."},
           {cmd = "u", name = "Use Inventory", desc = "Whisper 'u' to a shadow to make it use any available item specified in the message. If no item specified, your shadow will say which items can be used."},
           {cmd = "destroy", name = "Destroy Inventory", desc = "By whispering 'destroy' to a shadow, you can select items to destroy from its inventory."},
           {cmd = "rep", name = "Reputation", desc = "By whispering 'rep' or 'reputation' to a shadow, the shadow will tell you its current reputation standing of the faction of whichever NPC you are currently targetting."},
           {cmd = "t", name = "Trade", desc = "You may trade your shadows to distribute loot, free up inventory, pass mats around, and so on. Whisper them 't' or trade them directly to get started. They will whisper you their inventory. To select items to trade, whisper them which item from their inventory you want traded. \n \nNote: Shadows cannot trade you soulbound items even if they have a valid trade timer."},
       }
   },
   talents = {
       name = "Talents", 
       intid = 27,
       commands = {
           {cmd = "talents", name = "Talents", desc = "Your shadows are capable of flexibly utilizing their talents. Whisper your shadow 'talents' to get started."},
           {cmd = "talents spec list", name = "Talents Spec List", desc = "Your shadows come with preset talents you can assign them. They can list applicable talent presets by whispering them 'talents spec list'."},
           {cmd = "talents switch", name = "Talents Switch", desc = "By whispering 'talents switch 1' or 'talents switch 2' to a shadow, the shadow will switch to its main specialization (1) or its secondary specialization (2)."},
           {cmd = "talents spec <specName>", name = "Talents Spec <specName>", desc = "By whispering 'talents spec' with a specialization as listed by 'talents spec list', your shadow will swap out its current set of talents for the chosen preset."},
           {cmd = "talents autopick", name = "Talents Autopick", desc = "Your shadows can automatically select their preferred talents by whispering them 'talents autopick', assuming they have free talent points."},
           {cmd = "note", name = "Note", desc = "Using flexible shadow talents will not influence your glyphs. The talents your shadows apply will remain after the shadow session ends. It is free for shadows to respec."},
       }
   },
   talents = {
       name = "Loot", 
       intid = 28,
       commands = {
		   {cmd = "ll", name = "Loot List Settings", desc = "Control how your shadows loot items with the following commands."},
		   {cmd = "ll normal", name = "Loot Normal Items", desc = "Instruct your shadows to roll greed on all items up to rare quality and loot items not claimed by other players by whispering 'll normal'."},
		   {cmd = "ll all", name = "Loot All Items", desc = "Instruct your shadows to loot all quality items by whispering 'll all'."},
		   {cmd = "ll quest", name = "Loot Quest Items", desc = "Instruct your shadows to loot quest-related items by whispering 'll quest'."},
		   {cmd = "ll disenchant", name = "Loot Disenchantable Items", desc = "Instruct your shadows to loot items suitable for disenchanting by whispering them 'll disenchant'."},
		   {cmd = "ll none", name = "Stop Looting", desc = "Instruct your shadows to stop looting by whispering 'll none'."}
         }
   },
}

local function ShadowsHello(player)
    local accountId = player:GetAccountId()
    local guidlow = player:GetGUIDLow()
    local name = player:GetName()
    local maxBotCount       = 2
    local maxVIPCount       = 4
    
    player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_gizmo_02:40:40:-24:0|tHow to use shadows", 0, 2)
    
    if not botCount[name] or botCount[name] < 0 then
        botCount[name] = 0
    end
        
    if not botsAvailable[accountId] then
        print("Querying for bots available for "..player:GetName())
        botsAvailable[accountId] = {}
        CharDBQueryAsync("SELECT name, race, class, gender, level FROM characters WHERE account = " .. accountId, function(query)
            if query then
                repeat
                    local name = query:GetString(0)
                    local race = query:GetUInt8(1)
                    local class = query:GetUInt8(2)
                    local gender = query:GetUInt8(3)
                    local level = query:GetUInt8(4)
                    
                    table.insert(botsAvailable[accountId], {
                        name = name,
                        race = race,
                        class = class,
                        gender = gender,
                        level = level
                    })
                    
                until not query:NextRow()

                table.sort(botsAvailable[accountId], function(a, b)
                    return a.level > b.level
                end)
            end
        end)
    end

    if player:GetData("VIPTime") and player:GetData("VIPTime") > os.time() then -- Increased bot limit for VIP
        maxBotCount = maxVIPCount
    end
    
    player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_groupneedmore:40:40:-24:0|tAdd shadow (" .. botCount[name] .. "/"..maxBotCount..")", 0, 10)
    if botCount[name] > 0 then
        --player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_hunter_improvedtracking:40:40:-24:0|tCommand follow", 0, 3)
        --player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_ghoulfrenzy:40:40:-24:0|tCommand attack", 0, 4)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_unused2:40:40:-24:0|tSummon shadows", 0, 5, false, "Are you sure you want to summon your shadow(s) here?\n \nThis will induce a 30-minute summon cooldown.")
        player:GossipMenuAddItem(4, "|TInterface/PaperDollInfoFrame/UI-GearManager-Undo:40:40:-24:0|tRemove shadow", 0, 6)
    end
    player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:40:40:-24:0|tExit", 0, 1000)
    player:GossipSendMenu(12, player, 200)
end

local function ListActiveShadows(player)
    local name = player:GetName()
    player:GossipClearMenu()

    player:GossipMenuAddItem(0, "|TInterface/PaperDollInfoFrame/UI-GearManager-Undo:40:40:-24:0|tActive shadows:\n \n ", 0, 6)

    if activeBots[name] then
       for index, botName in ipairs(activeBots[name]) do
           local menuText = string.format(
               "|TInterface/ICONS/ability_vehicle_loadselfcatapult:40:40:-24:0|t%s\n \n ", 
               botName
           )
           
           player:GossipMenuAddItem(0, menuText, 0, 200 + index)
       end
    end

    player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:40:40:-24:0|tBack", 0, 999)
    player:GossipSendMenu(12, player, 200)
end

local function ShadowsGossipSelect(event, player, object, sender, intid, code, menu_id)
    local accountId = player:GetAccountId()
    local guid = player:GetGUIDLow()
    local name = player:GetName()
    local maxBotCount       = 2
    local maxVIPCount       = 4
    
    if player:GetData("VIPTime") and player:GetData("VIPTime") > os.time() then -- Increased bot limit for VIP
        maxBotCount = maxVIPCount
    end
    
    if intid == 2 then -- Settings main menu
       player:GossipClearMenu()
       player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_gizmo_02:40:40:-24:0|tHow to use shadows\n \nBy reaching through the Twisting Nether, you are able to summon shadows of the other characters on your account.\n \nTo control and summon a shadow, it must be within ten levels of you.\n \nYour active shadows adjust to your faction.\n \nYou may control up to 2 shadows at a time, or 4 shadows at a time if you have VIP.\n \nSee below for how to control your shadows.\n \n", 0, 2)
       
       -- Add main category options
       for _, category in pairs(commandCategories) do
           player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_gizmo_02:40:40:-24:0|t"..category.name, 0, category.intid)
       end
       
       player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:40:40:-24:0|tBack", 0, 999)
       player:GossipSendMenu(12, player, 200)
       
   elseif intid >= 20 and intid <= 29 then -- Category submenus
       player:GossipClearMenu()
       
       -- Find the selected category
       local selectedCategory
       for _, category in pairs(commandCategories) do
           if category.intid == intid then
               selectedCategory = category
               break
           end
       end
       
        function GetCategoryIcon(categoryName)
           local icons = {
               ["Movement"] = "ability_hunter_improvedtracking",
               ["Combat"] = "ability_warrior_battleshout",
               ["Formation"] = "achievement_arena_5v5_3",
               ["World Interaction"] = "achievement_zone_northrend_01",
               ["Spells"] = "ability_mage_frostfirebolt",
               ["Trade"] = "inv_misc_coin_06",
               ["Player Interaction"] = "inv_misc_bag_07_red",
               ["Talents"] = "ability_dualwieldspecialization",
               ["Loot"] = "inv_box_03",
           }
           return icons[categoryName] or "inv_misc_questionmark"
        end

        if selectedCategory then
           -- Header with gizmo icon
           player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_gizmo_02:40:40:-24:0|t"..selectedCategory.name.." Commands:\n \n ", 0, selectedCategory.intid)
           
           -- Get the appropriate icon for this category
           local categoryIcon = GetCategoryIcon(selectedCategory.name)
           
           for _, command in ipairs(selectedCategory.commands) do
               local menuText = string.format(
                   "|TInterface/ICONS/%s:40:40:-24:0|t%s\n \n%s\n \n ",
                   categoryIcon,
                   command.name,
                   command.desc
               )
               player:GossipMenuAddItem(0, menuText, 0, selectedCategory.intid)
           end
        end
       
       player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:40:40:-24:0|tBack", 0, 2)
       player:GossipSendMenu(12, player, 200)
	   
    elseif intid == 3 then -- Follow
        for _, name in pairs(activeBots[name]) do 
            if name ~= player:GetName() then
                bot = GetPlayerByName(name)
                if bot then
                    bot:MoveFollow(player, math.random(-6, 6), math.random(-6, 6))
                    if bot:IsInCombat() and bot:GetSelection() then
                        bot:GetSelection():ClearInCombat()
                    end
                    bot:ClearInCombat()
                end
            end
        end
        player:SendAreaTriggerMessage("Your shadows are now following you.")
        ShadowsHello(player)
    elseif intid == 4 then -- Attack
        for _, name in pairs(activeBots[name]) do 
            if name ~= player:GetName() then
                bot = GetPlayerByName(name)
                if bot then
                    player:Say("/p attack", 0)
                end
            end
        end
        ShadowsHello(player)
    elseif intid == 5 then -- Summon
        if not botTeleTime[accountId] then botTeleTime[accountId] = 0 end
        
        if botTeleTime[accountId] < os.time() then
            for _, name in pairs(activeBots[name]) do 
                if name ~= player:GetName() then
                    bot = GetPlayerByName(name)
                    if bot then
                        if bot:GetMapId() == player:GetMapId() then
                            bot:Teleport(player:GetMapId(), player:GetX() + math.random(-3, 3), player:GetY() + math.random(-3, 3), player:GetZ() + math.random(0, 0.1), player:GetO() + math.random(-6, 6))
                            player:CastSpell(bot, BOT_TELE_VISUAL, true)
                            bot:CastSpell(bot, BOT_TELE_VISUAL, true)
                        else
                            bot:Teleport(player:GetMapId(), player:GetX() + math.random(-3, 3), player:GetY() + math.random(-3, 3), player:GetZ() + math.random(0, 0.1), player:GetO() + math.random(-6, 6))
                            player:CastSpell(bot, BOT_TELE_VISUAL, true)
                            local name = player:GetName()
                            bot:RegisterEvent(function(eventId, delay, repeats, bot) 
                                bot:CastSpell(bot, BOT_TELE_VISUAL, true)
                            end, 500, 1)
                        end
                    end
                end
            end
            botTeleTime[accountId] = os.time() + (BotSummonCD)
        else
            player:SendAreaTriggerMessage("Your shadows summon is on cooldown for " .. math.floor((botTeleTime[accountId] - os.time()) / 60) .." minutes.")
        end
        ShadowsHello(player)
    elseif intid == 6 then  -- Show list of active shadows to remove
        ListActiveShadows(player)
    elseif intid >= 200 and intid < 299 then  -- Bot removal selection
        local selectedIndex = intid - 200

        if activeBots[name] and activeBots[name][selectedIndex] then
           local selectedBot = activeBots[name][selectedIndex]
           player:RunCommand(".playerbots bot remove " .. selectedBot)
           print("Removing bot "..selectedBot.." from gossip menu")
           ListActiveShadows(player)
        end
    elseif intid == 10 then  -- "Add bot" option
        local group = player:GetGroup()
        local groupMembers = {}
        local groupNames = {}
        
        player:GossipClearMenu()
        player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_groupneedmore:40:40:-24:0|tAvailable shadows:\n \n ", 0, 10)
        
        if group then
            groupMembers = group:GetMembers()
            for _, member in pairs(groupMembers) do
                if member then
                    groupNames[member:GetName()] = true
                end
            end
        end
        
        if botsAvailable[accountId] then
            local found = false
            for index, charInfo in ipairs(botsAvailable[accountId]) do
                if charInfo.name ~= player:GetName() then
                    local className = GetClassName(charInfo.class)
                    local raceName = GetRaceName(charInfo.race)
                    
                    local raceIcon = GetRaceIconPath(charInfo.race, charInfo.gender)
                    local classIcon = GetClassIconPath(charInfo.class)
                    
                    if charInfo.name and not groupNames[charInfo.name] then
                        if charInfo.level >= minShadowsLevel and charInfo.level > 9 and math.abs(player:GetLevel() - charInfo.level) <= 10 then
                            player:GossipMenuAddItem(4, "|TInterface/ICONS/" .. raceIcon .. ":40:40:-24:0|t |TInterface/ICONS/" .. classIcon .. ":40:40:-24:0|t |TInterface/ICONS/achievement_level_" .. (math.floor(charInfo.level / 10) * 10) .. ":40:40:-24:0|t \n \n \n \nName:  " .. charInfo.name .. "\n \nLevel:  " .. charInfo.level .. "\n \nRace:  " .. raceName .. "\n \nClass:  " .. className .. "\n ", 0, 100 + index)
                            found = true
                        elseif charInfo.level >= minShadowsLevel and math.abs(player:GetLevel() - charInfo.level) <= 10 then
                            player:GossipMenuAddItem(4, "|TInterface/ICONS/" .. raceIcon .. ":40:40:-24:0|t |TInterface/ICONS/" .. classIcon .. ":40:40:-24:0|t |TInterface/ICONS/inv_misc_desecrated_clothchest:40:40:-24:0|t\n \n \n \nName:  " .. charInfo.name .. "\n \nLevel:  " .. charInfo.level .. "\n \nRace:  " .. raceName .. "\n \nClass:  " .. className .. "\n ", 0, 100 + index)
                            found = true
                        end
                    end
                end
            end
            if not found then
                player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_rogue_shadowstep:40:40:-24:0|tNo available shadows \n \nThere are no shadows available in the range you can mind control. Your shadows must be within ten levels of you and at least level 15.\n \n", 0, 10)
            end
        end
                
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:40:40:-24:0|tBack", 0, 999)
        
        player:GossipSendMenu(12, player, 200)
    elseif intid >= 100 and intid < 199 then  -- Bot selection
        player:GossipClearMenu()
        for _, zone in pairs(disallowedZones) do
            if player:GetZoneId() == zone or player:GetAreaId() == zone then
                player:GossipComplete()
                player:SendAreaTriggerMessage("You cannot use shadows in "..GetAreaName(player:GetAreaId())..".")
                return
            end
        end
        if player:GetLevel() < minShadowsLevel then
            player:SendAreaTriggerMessage("You need to be at least level ".. minShadowsLevel .. " to use shadows!")
            ShadowsHello(player)
            return
        end
        if botCount[name] < maxBotCount then
            local selectedIndex = intid - 100
            
            if addCmdTimer[guid] and not (os.time() - addCmdTimer[guid] > 1) then
                player:SendAreaTriggerMessage("You can't add shadows that fast!")
                ShadowsHello(player)
                return
            end
            
            if botsAvailable[accountId] and botsAvailable[accountId][selectedIndex] then
                local selectedChar = botsAvailable[accountId][selectedIndex]
                botCount[name] = (botCount[name] or 0) + 1

                -- Initialize activeBots[name] as a table if it is nil
                if not activeBots[name] then 
                    activeBots[name] = {} 
                end

                table.insert(activeBots[name], selectedChar.name)

                if not botMasters[guid] then 
                    botMasters[guid] = {} 
                end

                table.insert(botMasters[guid], player:GetName())
                botSummonTime[guid] = os.time()
                player:RunCommand(".playerbots bot add " .. selectedChar.name) -- Add bot
				dontKickTime[selectedChar.name] = os.time() + 1
                if not isPlayerBot[selectedChar.name] then
                    isPlayerBot[selectedChar.name] = name
                elseif not (isPlayerBot[selectedChar.name] == name) then
                    isPlayerBot[selectedChar.name] = name
                end
                ShadowsHello(player)
            end
        else
            player:SendAreaTriggerMessage("You can't summon more shadows until you remove one.")
            ShadowsHello(player)
        end
    elseif intid == 999 then  -- "Back" option
        player:GossipClearMenu()
        ShadowsHello(player)
    elseif intid == 1000 then  -- "Exit" option
        player:GossipComplete()
    end
end

function SetActiveBots()
    activeBots = {}
    botCount = {}
    local playersByAccount = {}
    local allGuids = {}
    
    -- Group players by their account ID and collect all GUIDs
    for _, player in pairs(GetPlayersInWorld()) do
        if player then
            local accountId = player:GetAccountId()
            if not playersByAccount[accountId] then
                playersByAccount[accountId] = {}
            end
            local playerData = {
                name = player:GetName(),
                guid = player:GetGUIDLow()
            }
            table.insert(playersByAccount[accountId], playerData)
            table.insert(allGuids, playerData.guid)
        end
    end

    if #allGuids > 0 then
        local guidString = table.concat(allGuids, ",")
        
        CharDBQueryAsync(string.format(
            "SELECT guid, cooldown_end FROM character_cooldowns WHERE guid IN (%s) AND item_id = 0",
            guidString
        ),
        function(query)
            local cooldowns = {}
            
            if query then
                repeat
                    local guid = query:GetUInt32(0)
                    local cooldownEnd = query:GetUInt32(1)
                    cooldowns[guid] = cooldownEnd
                until not query:NextRow()
            end

            -- Process each account
            for accountId, players in pairs(playersByAccount) do
                if #players > 1 then
                    local lowestCooldown = nil
                    local mainPlayer = nil

                    -- Find player with lowest cooldown in this account
                    for _, playerData in pairs(players) do
                        local cooldown = cooldowns[playerData.guid] or 0
                        if not lowestCooldown or cooldown < lowestCooldown then
                            lowestCooldown = cooldown
                            mainPlayer = playerData
                        end
                    end

                    -- Set up activeBots for the main player
                    if mainPlayer then
                        activeBots[mainPlayer.name] = {}
                        botCount[mainPlayer.name] = 0
                        
                        -- Add other characters as bots
                        for _, playerData in pairs(players) do
                            if playerData.guid ~= mainPlayer.guid then
                                table.insert(activeBots[mainPlayer.name], playerData.name)
                                botCount[mainPlayer.name] = (botCount[mainPlayer.name] or 0) + 1
                                isPlayerBot[playerData.name] = mainPlayer.name
                                print("Player "..playerData.name.." is a bot, setting var on script load!")
                            end
                        end
                    end
                end
            end
        end)
    end
end

local function ShadowsLoginHook(event, player) -- Lazy persistent storage solution. Could probably just use characters table directly. Initially wanted cache-persistent value attached to world but not possible in standard AC ELUNA
    CharDBExecute("REPLACE INTO character_cooldowns (guid, item_id, cooldown_end) VALUES (" .. player:GetGUIDLow() .. ", 0, " .. os.time() .. ")"); 
end

local function Logout(event, player)
    local accountId = player:GetAccountId()
    local guidlow = player:GetGUIDLow()
    local name = player:GetName()
	
    isPlayerBot[name]           = nil
    botsAvailable[accountId]    = nil
    activeBots[name]            = nil
    botCount[name]              = nil
    botMasters[guidlow]         = nil
    
    -- Check if player is set as active anywhere in the table
    for botMaster, bots in pairs(activeBots) do
        for i, botName in ipairs(bots) do
            if botName == name then
                -- Found the player as a bot somewhere, remove them from that player's list
                table.remove(activeBots[botMaster], i)
                if botCount[botMaster] then
                    botCount[botMaster] = botCount[botMaster] - 1
                end
                if GetPlayerByName(botMaster):GetInstanceId() or player:GetInstanceId() then
                    return -- Don't boot players' bots from group if in RHC as it can bug out the instance group
                end
                player:RemoveFromGroup()
                break
            end
        end
    end
end

function CheckActiveBots(eventid, delay, repeats, uninvitedPlayer)
    local uninvitedPlayerName = uninvitedPlayer:GetName()
    if isPlayerBot[uninvitedPlayerName] then
        local player = GetPlayerByName(isPlayerBot[uninvitedPlayerName])
        local bot = GetPlayerByName(uninvitedPlayerName)
        if player and bot then
            player:RegisterEvent(function(_, _, _, player)
                player:RunCommand(".playerbots bot remove " .. uninvitedPlayerName)
                print("Bot removed: " ..uninvitedPlayerName.. ".")
                print("Leader: " ..player:GetName())
            end, 100, 1)
        end
        logoutEvent[uninvitedPlayerName] = nil
    end
end

function UninviteGroupGUID(event, packet, player)
    local guid = packet:ReadGUID()
    local reason = packet:ReadString()
    local uninvitedPlayer = GetPlayerByGUID(guid)
    if uninvitedPlayer then
        if not logoutEvent[uninvitedPlayer:GetName()] then
			if dontKickTime[uninvitedPlayer:GetName()] and dontKickTime[uninvitedPlayer:GetName()] > os.time() then return end
            logoutEvent[uninvitedPlayer:GetName()] = uninvitedPlayer:RegisterEvent(CheckActiveBots, 100, 1)
        end
    end
end

function UninviteGroup(event, packet, player)
    local uninvitedPlayerName = packet:ReadString()
    local uninvitedPlayer = GetPlayerByName(uninvitedPlayerName)
    if uninvitedPlayer then
        if not logoutEvent[uninvitedPlayer:GetName()] then
			if dontKickTime[uninvitedPlayer:GetName()] and dontKickTime[uninvitedPlayer:GetName()] > os.time() then return end
            logoutEvent[uninvitedPlayer:GetName()] = uninvitedPlayer:RegisterEvent(CheckActiveBots, 100, 1)
        end
    end
end

local function LeaveGroup(event, group, guid, method, kicker, reason)
    local uninvitedPlayer = GetPlayerByGUID(guid)
    if uninvitedPlayer then
        if not logoutEvent[uninvitedPlayer:GetName()] then
			if dontKickTime[uninvitedPlayer:GetName()] and dontKickTime[uninvitedPlayer:GetName()] > os.time() then return end
            logoutEvent[uninvitedPlayer:GetName()] = uninvitedPlayer:RegisterEvent(CheckActiveBots, 100, 1)
        end
    end
end

local function DisbandGroup(event, group)
    for _, member in ipairs (group:GetMembers()) do
        if isPlayerBot[member:GetName()] then
            local botName = member:GetName()
            local player = GetPlayerByName(isPlayerBot[botName])
            if player and not logoutEvent[botName] then
                logoutEvent[botName] = player:RegisterEvent(function(_, _, _, player)
					if dontKickTime[botName] and dontKickTime[botName] > os.time() then return end
                    player:RunCommand(".playerbots bot remove " .. botName)
                    print("Removing "..botName.." from disbanded group")
                    logoutEvent[botName] = nil
                end, 100, 1)
            end
        end
    end
end

function Teleport(player, sameMap)
    local name = player:GetName()
    if isPlayerBot[name] then return end
    local guid = player:GetGUIDLow()
    if not player:IsInGroup() then
        return -- Should probably add a sanity check here to disconnect bots not in your party in case party affiliation fails somehow
    end
    if player:IsDead() then
        return
    end
    if not botCount[name] or botCount[name] == 0 then
        return
    end
    if lastTeleTime[guid] and os.time() <= lastTeleTime[guid] then
        return
    end
    if ((player:GetMapId() == 0 or player:GetMapId() == 1 -- Kalimdor, Eastern Kingdoms
    or player:GetMapId() == 530 or player:GetMapId() == 571) -- Outlands, Northrend
    and (sameMap == "yes"))
    or (player:InArena() or player:InBattleground()) -- PVP exclusions from teleport
    then
        return
    end
    if not botCount[name] or botCount[name] == 0 then
        return
    end
    for i, botName in ipairs(activeBots[name]) do
        local bot = GetPlayerByName(botName)
        if bot and not player:IsInCombat() then
			if (bot:GetHealth() == 0) and not bot:HasAura(8326) then -- Stops unreleased ghost corpses from being teleported
				return
			end 
            if bot:GetMapId() ~= player:GetMapId() and sameMap == "yes" then
                return
            end
            if not bot:IsWithinLoS(player) and
			(((bot:GetZ() < player:GetZ() - 20) or (bot:GetZ() > player:GetZ() + 20) or (player:GetDistance(bot) > 100))
			or not ((bot:GetMapId() == player:GetMapId())))
			or
			(player:GetDistance(bot) > 400)
			then
				if bot:HasAura(8326) then RunCommand("revive "..bot:GetName()) end -- handle auto revive of bots on enter instance/raid
                bot:Teleport(player:GetMapId(), player:GetX() + math.random(-1, 1), player:GetY() + math.random(-1, 1), player:GetZ(), player:GetO() + math.random(-6, 6))
                print("Teleporting bot "..botName.." to "..name)
            end
        end
    end
    lastTeleTime[guid] = os.time() + 1
end

local function PacketTeleDelay(_, _, player)
    local name = player:GetName()
    if isPlayerBot[name] then return end
    local sameMap = "openWorld"
    player:RegisterEvent(function(_, _, _, player)
        Teleport(player, sameMap)
    end, 1000, 1)
end

local function PacketMoveDelay(_, _, player)
    local name = player:GetName()
    if isPlayerBot[name] then return end
    local sameMap = "yes"
    player:RegisterEvent(function(_, _, _, player)
        Teleport(player, sameMap)
    end, 1000, 1)
end

local function buildCommandList()
    local commands = {}
    for _, category in pairs(commandCategories) do
        for _, cmd in ipairs(category.commands) do
            commands[cmd.cmd] = true
        end
    end
    return commands
end

local validCommands = buildCommandList()

local function OnGroupChat(event, player, msg, Type, lang, group)
    if msg == "repair" then
        for _, groupMember in ipairs(group) do
            if groupMember then
                local groupMemberName = groupMember:GetName()
                if groupMemberName and isPlayerBot[groupMemberName] then
				groupMember:SendUnitWhisper("Repairing!", 0, player)
                end
            end
        end
    end
end

local function OnWhisper(event, player, msg, Type, lang, receiver)
    local receiverName = receiver:GetName()
    local playerName = player:GetName()

    if activeBots[playerName] then
        for _, botName in ipairs(activeBots[playerName]) do
            if receiverName == botName then
				local bot = GetPlayerByName(botName)
                if msg == "repair" then
                    receiver:SendUnitWhisper("Repairing!", 0, player)
                    return
                end

                local greeting = false
                local greetings = {
                    "hello", "hi", "hey", "greetings", "good morning", "good afternoon", "good evening", "howdy", "hiya",
                    "what's up", "yo", "sup", "how are you", "how's it going", "nice to see you", "welcome", "salutations",
                    "good day", "good morrow", "top of the morning", "pleased to meet you", "ahoy", "aloha", "bonjour",
                    "hola", "ciao", "konnichiwa", "namaste", "shalom", "g'day", "what ho", "how goes it", "how do you do",
                    "what's cracking", "what's cooking", "what's the good word", "how's tricks", "how's life", "how's your day",
                    "what's new", "what's happening", "how's everything", "how's the world treating you", "look who it is",
                    "well hello there", "a fine day it is", "may your day be blessed", "peace be with you", "rise and shine",
                    "to you", "you there", "my friend", "o/", "o7"
                }

                for _, word in ipairs(greetings) do
                    if string.match(msg:lower(), "^" .. word .. "$") then
                        greeting = true
                        break
                    end
                end

                if greeting then
                    local greetingResponses = {
                        "Hey! :)", "Hiya!", "What's up, big mac?", "Greetings, traveler!", "Hello there!", "Hi!",
                        "Howdy partner!", "Good to see you!", "Hey, how are you?", "What's going on?", "Good day!",
                        "Hey there!", "Hello friend!", "Hi there!", "Greetings!", "Yo!", "Sup!", "How's it going?",
                        "Nice to see you too!", "Welcome!", "Salutations!", "Good morrow!", "Top of the morning to ya!",
                        "Pleased to meet you!", "Ahoy matey!", "Aloha!", "Bonjour!", "Hola!", "Ciao!", "Konnichiwa!",
                        "Namaste!", "Shalom!", "G'day!", "What ho!", "How goes it?", "How do you do?", "What's cracking?",
                        "What's cooking?", "What's the good word?", "How's tricks?", "How's life?", "How's your day?",
                        "What's new?", "What's happening?", "How's everything?", "How's the world treating you?",
                        "Look who it is!", "Well hello there!", "A fine day it is!", "May your day be blessed!",
                        "Peace be with you!", "Rise and shine!", "To you!", "You there!", "My friend!", "o/!", "o7!"
                    }
                    local randomIndex = math.random(1, #greetingResponses)
                    bot:SendUnitWhisper(greetingResponses[randomIndex], 0, player)
                    return
                end
				
				local questionWords = {
					"what", "why", "where", "who", "when", "how", "which", "whose", "whom"
				}

				local questionResponses = {
					what = {
						"What do you mean by '%s'?",
						"What what, what what",
						"Could you clarify what you're asking about '%s'?",
						"I'm not sure I understand what you're referring to with '%s'.",
						"What are you trying to find out about '%s'?",
						"Could you provide more details about what you're asking regarding '%s'?"
					},
					why = {
						"Why do you want to know about '%s'?",
						"Could you explain why you're asking about '%s'?",
						"I'm curious about the reason behind your question about '%s'.",
						"Why is '%s' important to you?",
						"Could you give more context for why you're asking about '%s'?"
					},
					where = {
						"Where are you trying to go to '%s'?",
						"Could you specify the location you're asking about '%s'?",
						"Here!",
						"Ummm... Azeroth!",
						"I don't know the answer but I know that I am in "..GetAreaName(bot:GetAreaId())..".",
						"I'm not sure where '%s' is. Could you provide more details?",
						"Where exactly are you referring to with '%s'?",
						"Could you clarify the place you're asking about '%s'?"
					},
					who = {
						"Who are you talking about with '%s'?",
						"Who is me!",
						"Who are you?",
						"Could you specify the person you're asking about '%s'?",
						"I'm not sure who '%s' is. Could you provide more details?",
						"Who exactly are you referring to with '%s'?",
						"Could you clarify the individual you're asking about '%s'?"
					},
					when = {
						"When are you referring to with '%s'?",
						"Could you specify the time you're asking about '%s'?",
						"I'm not sure when '%s' is. Could you provide more details?",
						"When exactly are you talking about with '%s'?",
						"Could you clarify the timing you're asking about '%s'?"
					},
					how = {
						"How do you suggest we do '%s'?",
						"Could you explain how you're thinking about '%s'?",
						"I'm not sure how '%s' would work. Could you provide more details?",
						"How exactly are you planning to do '%s'?",
						"Could you clarify the method you're asking about '%s'?"
					},
					which = {
						"Which one are you referring to with '%s'?",
						"Could you specify the option you're asking about '%s'?",
						"I'm not sure which one you mean with '%s'. Could you provide more details?",
						"Which exactly are you talking about with '%s'?",
						"Could you clarify the choice you're asking about '%s'?"
					},
					whose = {
						"Whose are you talking about with '%s'?",
						"Mine?",
						"Could you specify the person you're asking about '%s'?",
						"I'm not sure whose '%s' is. Could you provide more details?",
						"Whose exactly are you referring to with '%s'?",
						"Could you clarify the individual you're asking about '%s'?"
					},
					whom = {
						"Whom are you referring to with '%s'?",
						"Could you specify the person you're asking about '%s'?",
						"I'm not sure whom '%s' is. Could you provide more details?",
						"Whom exactly are you talking about with '%s'?",
						"Could you clarify the individual you're asking about '%s'?"
					}
				}

				local function isStandaloneQuestionWord(message)
					local trimmed = message:gsub("[%p%s]", ""):lower()
					for _, word in ipairs(questionWords) do
						if trimmed == word then
							return word
						end
					end
					return nil
				end

				local function extractKeywords(message)
					local keywords = {}
					for word in message:gmatch("%w+") do
						table.insert(keywords, word)
					end
					return keywords
				end

				local standaloneWord = isStandaloneQuestionWord(msg)
				if standaloneWord then
					local response = standaloneWord .. " what?"
					local bot = GetPlayerByName(botName)
					bot:SendUnitWhisper(response, 0, player)
					return
				end

				local questionType = nil
				for _, word in ipairs(questionWords) do
					if string.match(msg:lower(), "^" .. word .. " ") then
						questionType = word
						break
					end
				end

				if questionType then
					local keywords = extractKeywords(msg)
					local keywordString = table.concat(keywords, " ")
					local responseTemplate = questionResponses[questionType][math.random(1, #questionResponses[questionType])]
					local response = string.format(responseTemplate, keywordString)
					local bot = GetPlayerByName(botName)
					bot:SendUnitWhisper(response, 0, player)
					return
				end
				
				local laughterWords = {
					"haha", "hehe", "lol", "rofl", "lmao", "giggle", "chuckle", "funny", "humor",
					"hilarious", "amusing", "joke", "comedy", "laughing", "lmfao", "rotfl", "bahaha",
					"teehee", "witty", "hilarious", "punny", "jest", "uproarious", "sidesplitting",
					"howl", "cackle", "snicker", "smirk", "grin", "beam", "simper", "titter",
					"ha", "hah", "heh", "hee", "hihi", "huhu", "hoho", "simp", "rofl", "kek",
				}

				local laughterResponses = {
					"That's funny!",
					"I'm glad you found that amusing!",
					"Haha, good one!",
					"You have a great sense of humor!",
					"That's hilarious!",
					"I needed that laugh!",
					"You're cracking me up!",
					"Stop, you're killing me!",
					"That really made me laugh.",
					"My stomach hurts from laughing!",
					"I can't stop laughing!",
					"You're so funny!",
					"Where do you come up with this stuff?",
					"I'm in stitches!",
					"That’s a knee-slapper!",
					"You always know how to make me laugh!",
					"I'm literally crying from laughter!",
					"That’s pure comedy gold!",
					"You’ve got me in tears!",
					"I haven't laughed this hard in ages!"
				}

				local function extractLaughterKeywords(message)
					local keywords = {}
					for word in message:gmatch("%w+") do
						table.insert(keywords, word)
					end
					return keywords
				end

				local laughterType = nil
				for _, word in ipairs(laughterWords) do
					if string.match(msg:lower(), word) then
						laughterType = word
						break
					end
				end

				if laughterType then
					local keywords = extractLaughterKeywords(msg)
					local keywordString = table.concat(keywords, " ")
					local responseTemplate = laughterResponses[math.random(1, #laughterResponses)]
					local response = string.format(responseTemplate, keywordString)
					local bot = GetPlayerByName(botName)
					bot:SendUnitWhisper(response, 0, player)
					return
				end

				local factionNames = {
					"Ashen Verdict", "Stormwind", "Alliance", "Horde", "Silver Covenant", "Kirin Tor", "Ebon Blade", "Argent Crusade", "Cenarion Circle", "The Aldor", "The Scryers",
					"Argent Dawn", "Bloodsail Buccaneers", "Brood of Nozdormu", "Darkmoon Faire", "Gadgetzan", "Everlook", "Booty Bay", "Ratchet", "Ravenholdt", "Syndicate", "Thorium Brotherhood", "Timbermaw Hold", "Wintersaber Trainers",
					"Alliance Vanguard", "Horde Expedition", "Valiance Expedition", "Warsong Offensive", "Hand of Vengeance", "Sunreavers", "The Wyrmrest Accord", "Knights of the Ebon Blade", "Kirin Tor", "The Argent Crusade", "The Kalu'ak", "The Oracles", "The Frenzyheart Tribe", "The Sons of Hodir", "The Celestial Defenders", "Shado-Pan Offensive", "Operation Shieldwall", "Dominance Offensive", "Vol'jins Spear", "The Sunreaver Onslaught", "Baradins Wardens", "Hellscreams Reach",
					"Guardians of Hyjal", "Avengers of Hyjal", "Therazane", "Ramkahen", "The Earthen Ring", "Dragonmaw Clan", "Wildhammer Clan",
					"Lower City", "Keepers of Time", "The Sha'tar", "Ogri'la", "Netherwing", "Sporeggar", "Kurenai", "The Violet Eye",
					"The Scale of the Sands", "The Consortium", "The Mag'har", "The Anglers", "The Klaxxi'va", "The August Celestials", "The Golden Lotus", "Order of the Cloud Serpent", "Shado-Pan",
					"Sha'tari Skyguard", "Ashtongue Deathsworn",
					"The Defilers", "League of Arathor", "Silverwing Sentinels", "Warsong Outriders"
				}

				local factionResponses = {
					"I'm proud to serve the %s!",
					"The %s is a noble faction.",
					"I've heard great things about the %s.",
					"The %s has a rich history.",
					"I'm always ready to support the %s."
				}

				local function extractFactionKeywords(message)
					local keywords = {}
					for word in message:gmatch("%w+") do
						table.insert(keywords, word)
					end
					return keywords
				end

				local factionType = nil
				for _, word in ipairs(factionNames) do
					if string.match(msg:lower(), word:lower()) then
						factionType = word
						break
					end
				end

				if factionType then
					local keywords = extractFactionKeywords(msg)
					local keywordString = table.concat(keywords, " ")
					local responseTemplate = factionResponses[math.random(1, #factionResponses)]
					local response = string.format(responseTemplate, keywordString)
					local bot = GetPlayerByName(botName)
					bot:SendUnitWhisper(response, 0, player)
					return
				end

				local dungeonNames = {
					-- Classic Dungeons and Raids
					"Deadmines", "Wailing Caverns", "Shadowfang Keep", "Blackfathom Deeps", "The Stockade", "Razorfen Kraul", "Gnomeregan", "The Deadmines", "Razorfen Downs", "Uldaman", "Maraudon", "Dire Maul", "Zul'Farrak", "Blackrock Depths", "Blackrock Spire", "Stratholme", "Scholomance",
					"Molten Core", "Onyxia's Lair", "Blackwing Lair", "Temple of Ahn'Qiraj", "Ruins of Ahn'Qiraj", "Naxxramas",

					-- Burning Crusade Dungeons and Raids
					"Hellfire Ramparts", "The Blood Furnace", "The Shattered Halls", "The Slave Pens", "The Underbog", "Mana-Tombs", "Auchenai Crypts", "Sethekk Halls", "Shadow Labyrinth", "The Mechanar", "The Botanica", "The Arcatraz", "Magisters' Terrace",
					"Karazhan", "Gruul's Lair", "Magtheridon's Lair", "Serpentshrine Cavern", "The Eye", "Hyjal Summit", "Black Temple", "Zul'Aman", "Sunwell Plateau",

					-- Wrath of the Lich King Dungeons and Raids
					"Utgarde Keep", "The Nexus", "Azjol-Nerub", "Ahn'kahet: The Old Kingdom", "Drak'Tharon Keep", "The Violet Hold", "Gundrak", "Halls of Stone", "Halls of Lightning", "The Oculus", "Utgarde Pinnacle", "Trial of the Champion", "Forge of Souls", "Pit of Saron", "Halls of Reflection",
					"Naxxramas", "The Obsidian Sanctum", "Vault of Archavon", "Eye of Eternity", "Ulduar", "Trial of the Crusader", "Onyxia's Lair (Reborn)", "Icecrown Citadel", "Ruby Sanctum",

					-- Cataclysm Dungeons and Raids
					"The Throne of the Tides", "Blackrock Caverns", "The Stonecore", "Vortex Pinnacle", "Halls of Origination", "Lost City of the Tol'vir", "Grim Batol", "Deadmines (Heroic)", "Shadowfang Keep (Heroic)", "Zul'Gurub (Revamped)", "Zul'Aman (Revamped)", "End Time", "Well of Eternity", "Hour of Twilight",
					"Baradin Hold", "Blackwing Descent", "Bastion of Twilight", "Throne of the Four Winds", "Firelands", "Dragon Soul"
				}

				local dungeonResponses = {
					"I've heard tales of the %s!",
					"The %s is a challenging place.",
					"I've explored the %s many times.",
					"The %s holds many secrets.",
					"I'm ready to face the challenges of the %s.",
					"Let's delve into the depths of the %s!",
					"Have you ever braved the %s?",
					"The legends surrounding the %s are intriguing.",
					"I feel a shiver just thinking about the %s.",
					"The %s is known for its treacherous paths.",
					"Many adventurers have met their end in the %s.",
					"Do you think we can conquer the %s?",
					"I've heard whispers of great treasures within the %s.",
					"The atmosphere in the %s is said to be quite eerie.",
					"Are you prepared for what awaits us in the %s?",
					"The %s... a truly unforgettable experience.",
					"I've studied maps of the %s extensively.",
					"They say the %s is guarded by powerful entities.",
					"Only the most skilled can navigate the %s.",
					"I wonder what awaits us in the heart of the %s.",
					"The very name '%s' sends chills down my spine.",
					"I'm eager to test my abilities in the %s.",
					"Let's make our mark on the history of the %s!",
					"Have you heard the rumors about the %s?",
					"The mysteries of the %s are calling to me."
				}

				local function extractDungeonKeywords(message)
					local keywords = {}
					for word in message:gmatch("%w+") do
						table.insert(keywords, word)
					end
					return keywords
				end

				local dungeonType = nil
				for _, word in ipairs(dungeonNames) do
					if string.match(msg:lower(), word:lower()) then
						dungeonType = word
						break
					end
				end

				if dungeonType then
					local keywords = extractDungeonKeywords(msg)
					local keywordString = table.concat(keywords, " ")
					local responseTemplate = dungeonResponses[math.random(1, #dungeonResponses)]
					local response = string.format(responseTemplate, keywordString)
					local bot = GetPlayerByName(botName)
					bot:SendUnitWhisper(response, 0, player)
					return
				end

				local itemNames = {
					"Thunderfury", "Sulfuras", "Ashbringer", "Atiesh", "Shadowmourne", "Val'anyr", "Fangs of the Father", "Gorehowl", "Warglaives of Azzinoth"
				}

				local itemResponses = {
					"The %s is a legendary item!",
					"I've heard tales of the %s.",
					"The %s is sought after by many.",
					"I've seen the power of the %s.",
					"The %s is a symbol of greatness."
				}

				local function extractItemKeywords(message)
					local keywords = {}
					for word in message:gmatch("%w+") do
						table.insert(keywords, word)
					end
					return keywords
				end

				local itemType = nil
				for _, word in ipairs(itemNames) do
					if string.match(msg:lower(), word:lower()) then
						itemType = word
						break
					end
				end

				if itemType then
					local keywords = extractItemKeywords(msg)
					local keywordString = table.concat(keywords, " ")
					local responseTemplate = itemResponses[math.random(1, #itemResponses)]
					local response = string.format(responseTemplate, keywordString)
					local bot = GetPlayerByName(botName)
					bot:SendUnitWhisper(response, 0, player)
					return
				end

                local conversationalCategories = {
                    joke = {
                        keywords = {"joke", "funny", "laugh"},
                        initialResponses = {
                            "Oh, you want to hear a joke?",
                            "Did someone say joke?",
                            "I know a few good jokes!",
                        },
                        followUpQuestion = "Do you want to hear one?",
                        positiveConfirmation = {"yes", "y", "sure", "yeah", "tell me", "go ahead"},
                        negativeConfirmation = {"no", "n", "nah", "nope", "not now", "later"},
                        jokeExamples = {
                            "Why don't scientists trust atoms? Because they make up everything!",
                            "Parallel lines have so much in common. It’s a shame they’ll never meet.",
                            "Why did the scarecrow win an award? Because he was outstanding in his field!",
                            "I told my wife she was drawing her eyebrows too high. She looked surprised.",
                            "What do you call a lazy kangaroo? Pouch potato!",
                            "Why did the bicycle fall over? Because it was two tired!",
                            "Want to hear a joke about paper? Never mind it's tearable.",
                            "I'm reading a book on anti-gravity. It's impossible to put down!",
                            "Did you hear about the restaurant on the moon? I heard the food was good but it had no atmosphere.",
                            "Why did the golfer wear two pairs of pants? In case he got a hole-in-one.",
                            "What do you call a fish with no eyes? Fsh!",
                            "Why did the invisible man turn down the job offer? He couldn't see himself doing it.",
                            "What do you call a fake noodle? An impasta.",
                            "Why don’t eggs tell jokes? They’d crack each other up.",
                            "How do you make an octopus laugh? With ten-tickles!",
                            "What musical instrument is found in the bathroom? A tuba toothpaste.",
                            "Why did the pictureWhat do you get from a pampered cow? Spoiled milk.",
                            "Where should you go if you want to learn how to make ice cream? Sundae school.",
                            "What shirt should you wear to a tea party? A t-shirt.",
                            "What do you call cheese that isn’t yours? Nacho cheese.",
                            "Why did the math book look sad? Because it had too many problems.",
                            "What do you call a bear with no teeth? A gummy bear.",
                            "Why did the cookie go to the doctor? Because it was feeling crumbly.",
                            "What do you get when you cross a snowman and a vampire? Frostbite.",
                            "Why don’t skeletons fight each other? They don’t have the guts.",
                            "What do you call a witch's garage? A broom closet.",
                            "What do you get if you drop a piano down a mineshaft? A flat miner.",
                            "What do you call a seagull that flies over the bay? A bagel.",
                            "Why did the teddy bear say no to dessert? Because she was stuffed.",
                            "What do you call a donkey with stripes? A zebra.",
                            "Why did the can crusher quit his job? Because it was soda pressing.",
                            "What do you call a pony with a cough? A little horse.",
                            "Why did the traffic light turn red? You wouldn’t want it to turn green; it’s a tomato!",
                            "What do you call a nervous walrus? A nervous wreck.",
                            "Why did the student eat his homework? Because his teacher told him it was a piece of cake.",
                            "What do you call a fly without wings? A walk.",
                            "What do you call a dog magician? A labracadabrador.",
                            "Why don’t oysters donate to charity? Because they’re shellfish.",
                            "What do you call a kangaroo that is good at karate? A kanga-roo.",
                            "Why did the melon jump into the pool? It wanted to become a watermelon.",
                            "What do you call a dictionary on drugs? High definition.",
                            "Why do fish live in salt water? Because pepper makes them sneeze.",
                            "What do you call a dinosaur with bad teeth? A brontosaurus.",
                            "Why did the banana go to the doctor? Because it wasn’t peeling well.",
                            "What do you call a grape that knows karate? A grape-fruit.",
                            "Why did the chewing gum cross the road? Because it was stuck to the chicken’s foot!",
                            "What do you call a cow with no legs? Ground beef.",
                            "Want to hear a construction joke? I’m still working on it."
                        },
                        conversationState = "jokeNext",
                        categoryState = "jokeInProgress" -- Overall category state

                    },
                    weather = {
                        keywords = {"weather", "raining", "sunny", "cloudy", "snowing", "forecast"},
                        initialResponses = {
                            "Talking about the weather, eh?",
                            "Let me check the weather for you.",
                            "Weather is quite a topic!",
                        },
                        followUpQuestion = "Interested in the current weather or the forecast?",
                        weatherTypesResponses = {
                            current = {
                                keywords = {"current", "now", "right now"},
                                responsePrefixes = {
                                    "Currently, in "..GetAreaName(bot:GetAreaId())..", it's ",
                                    "Right now, the weather in "..GetAreaName(bot:GetAreaId()).." is ",
                                    "The weather at the moment is ",
                                },
                                weatherData = { -- Placeholder for actual weather data retrieval
                                    "clear and sunny.",
                                    "a bit cloudy.",
                                    "lightly raining.",
                                    "quite windy.",
                                    "partially snowy.",
                                },
                                conversationState = "weatherCurrent",
                                categoryState = "weatherInProgress"
                            },
                            forecast = {
                                keywords = {"forecast", "later", "future", "tomorrow", "next"},
                                responsePrefixes = {
                                    "The forecast for in "..GetAreaName(bot:GetAreaId()).." is ",
                                    "Looking ahead, the weather will be ",
                                    "For the upcoming days, expect ",
                                },
                                weatherData = { -- Placeholder for actual forecast data retrieval
                                    "mostly sunny skies.",
                                    "a chance of rain later today.",
                                    "cloudy with a possibility of snow tomorrow.",
                                    "strong winds expected.",
                                    "a mix of sun and clouds.",
                                },
                                conversationState = "weatherForecast",
                                categoryState = "weatherInProgress"
                            }
                        },
                        conversationState = "weatherTypeNext",
                        categoryState = "weatherInProgress" -- Overall category state
                    },
                    day_inquiry = {
                        keywords = {"how are you", "how's your day", "how's it going", "what are you doing"},
                        initialResponses = {
                            "I'm doing well, thank you for asking!",
                            "My day is going smoothly, just processing information.",
                            "I'm here and ready to chat!",
                        },
                        followUpQuestions = {
                            "Anything interesting happening on your end?",
                            "What can I do for you today?",
                            "Is there anything specific you'd like to talk about?",
                        },
                        positiveFollowUpResponses = {
                            "That sounds interesting!",
                            "Tell me more!",
                            "I'm all ears!",
                        },
                        negativeFollowUpResponses = {
                            "Alright, if you need anything, just let me know.",
                            "Okay, feel free to reach out if you change your mind.",
                            "No problem, I'm here when you need me.",
                        },
                        conversationState = "dayInquiryNext",
                        categoryState = "dayInquiryInProgress"
                    },
                    pastime_activities = {
                        keywords = {"play", "game", "hobby", "pastime", "fun", "activity", "bored"},
                        initialResponses = {
                            "Looking for a pastime, are we?",
                            "Let's find something fun to do!",
                            "In the mood for some entertainment?",
                        },
                        activitySuggestions = {
                            "How about we try a quick game of riddles?",
                            "I could tell you some interesting facts.",
                            "Maybe you'd like to hear a joke?",
                            "We could explore some trivia questions.",
                            "Perhaps you'd be interested in a short story?",
                        },
                        confirmationQuestion = "Does any of that sound interesting?",
                        positiveConfirmation = {"yes", "y", "sure", "yeah", "sounds good", "i'm in", "let's do it"},
                        negativeConfirmation = {"no", "n", "nah", "nope", "not really", "maybe later"},
                        positiveFollowUpResponses = {
                            "Great choice!",
                            "Excellent!",
                            "Fantastic!",
                        },
                        negativeFollowUpResponses = {
                            "No problem, maybe next time!",
                            "Alright, we can find something else later.",
                            "Okay, just let me know if you change your mind.",
                        },
                        conversationState = "pastimeActivityNext",
                        categoryState = "pastimeActivitiesInProgress"
                    },
                    weather_comments = {
                        keywords = {"weather is", "it's sunny", "it's raining", "nice weather", "bad weather", "cloudy day", "snowy"},
                        initialResponses = {
                            "Indeed, the weather is quite something today!",
                            "You're right about the weather!",
                            "The weather has been a topic of conversation lately.",
                        },
                        positiveComments = {
                            "Yes, it's a beautiful day, isn't it?",
                            "Absolutely perfect weather!",
                            "Couldn't agree more, the weather is fantastic!",
                        },
                        negativeComments = {
                            "Yes, it's not the best weather, is it?",
                            "Unfortunately, the weather isn't great today.",
                            "I agree, the weather could be better.",
                        },
                        neutralComments = {
                            "Yes, it's certainly weather we're having!",
                            "The weather is as it is.",
                            "Well, that's the weather for you!",
                        },
                        followUpQuestions = {
                            "Do you have any plans for today, weather permitting?",
                            "Is the weather affecting your plans at all?",
                            "Are you enjoying or enduring the current weather?",
                        },
                        conversationState = "weatherCommentNext",
                        categoryState = "weatherCommentsInProgress"
                    },
                    affirmations = {
                        keywords = {"yes", "yeah", "sure", "absolutely", "indeed", "affirmative", "agreed", "correct", "right", "true"},
                        initialResponses = {
                            "Glad we're on the same page!",
                            "Great to hear that!",
                            "I knew you'd agree!",
                            "That's the spirit!",
                            "Excellent choice!",
                            "I'm glad you think so!",
                            "That's what I thought!",
                            "Perfect!",
                            "I couldn't agree more!",
                            "That's right!"
                        },
                        conversationState = "affirmationNext",
                        categoryState = "affirmationsInProgress"
                    },
                    negations = {
                        keywords = {"no", "nope", "nah", "negative", "disagree", "incorrect", "wrong", "false", "not really", "don't think so"},
                        initialResponses = {
                            "I see, let's try something else.",
                            "No problem, we can reconsider.",
                            "I understand your perspective.",
                            "Maybe we can find a compromise.",
                            "Let's explore other options.",
                            "I respect your opinion.",
                            "We can always revisit this later.",
                            "Perhaps there's another way.",
                            "I appreciate your input.",
                            "Let's move on to something else."
                        },
                        conversationState = "negationNext",
                        categoryState = "negationsInProgress"
                    },
                    quest_banter = {
                        keywords = {"quest", "mission", "task", "objective", "goal", "adventure", "journey", "challenge", "dungeon", "raid"},
                        initialResponses = {
                            "Ready for another adventure?",
                            "Let's embark on a new quest!",
                            "What mission are you on today?",
                            "Got a challenging task ahead?",
                            "Time to set some new goals!",
                            "Excited for the journey ahead!",
                            "Prepared for the challenges?",
                            "Let's tackle that dungeon!",
                            "Ready for the raid?",
                            "What's your next objective?"
                        },
                        followUpQuestions = {
                            "Need any help with your quest?",
                            "What's your plan for completing the mission?",
                            "Any specific challenges you're facing?",
                            "How can I assist you on your adventure?",
                            "What's your strategy for the task?",
                            "Need some tips for your journey?",
                            "How are you preparing for the challenge?",
                            "What's your approach for the dungeon?",
                            "Any particular role you need help with in the raid?",
                            "What's your next step in achieving your goal?"
                        },
                        conversationState = "questBanterNext",
                        categoryState = "questBanterInProgress"
                    },
                    boss_kill_banter = {
                        keywords = {"boss", "kill", "defeat", "victory", "triumph", "conquer", "overcome", "champion", "hero", "epic"},
                        initialResponses = {
                            "Congratulations on the boss kill!",
                            "Great job defeating the boss!",
                            "Victory is ours!",
                            "We've triumphed over the boss!",
                            "Another boss conquered!",
                            "Well done on overcoming the challenge!",
                            "You're a true champion!",
                            "Heroic effort in defeating the boss!",
                            "Epic victory against the boss!",
                            "We've overcome the boss together!"
                        },
                        followUpQuestions = {
                            "How did the fight go?",
                            "Any close calls during the boss fight?",
                            "What strategy did you use to defeat the boss?",
                            "Did everyone survive the encounter?",
                            "What loot did you get from the boss?",
                            "How did your team perform during the fight?",
                            "Any memorable moments from the boss battle?",
                            "What was the most challenging part of the fight?",
                            "Did you enjoy the boss encounter?",
                            "Ready for the next boss?"
                        },
                        conversationState = "bossKillBanterNext",
                        categoryState = "bossKillBanterInProgress"
                    },
                    lore_discussion = {
                        keywords = {"lore", "story", "history", "background", "legend", "myth", "tale", "saga", "epic", "chronicle"},
                        initialResponses = {
                            "Interested in the lore of Azeroth?",
                            "Let's dive into the rich history of this world!",
                            "What story would you like to hear?",
                            "The legends of Azeroth are vast and intriguing.",
                            "Ready to explore the myths and tales?",
                            "The background of this world is fascinating.",
                            "Let's discuss the epic sagas of Azeroth.",
                            "The chronicles of this land are full of adventure.",
                            "What lore are you curious about?",
                            "The stories of Azeroth are endless."
                        },
                        followUpQuestions = {
                            "Which faction's history interests you the most?",
                            "Any particular legend you'd like to know more about?",
                            "What's your favorite tale from Azeroth?",
                            "Would you like to hear about the origins of a specific race?",
                            "Interested in the background of a particular character?",
                            "What epic saga would you like to explore?",
                            "Would you like to know more about the ancient myths?",
                            "Which part of Azeroth's history fascinates you?",
                            "Interested in the lore behind a specific location?",
                            "What chronicle would you like to delve into?"
                        },
                        conversationState = "loreDiscussionNext",
                        categoryState = "loreDiscussionInProgress"
                    },
                    gear_advice = {
                        keywords = {"gear", "equipment", "armor", "weapon", "stats", "upgrade", "item", "loot", "enchant", "gem"},
                        initialResponses = {
                            "Need some advice on your gear?",
                            "Let's talk about your equipment!",
                            "Looking to upgrade your armor?",
                            "What weapon are you using?",
                            "Let's optimize your stats!",
                            "Got any new loot to show off?",
                            "Need help with enchants or gems?",
                            "What items are you focusing on?",
                            "Let's discuss your gear setup!",
                            "Any specific gear questions?"
                        },
                        followUpQuestions = {
                            "What's your current gear score?",
                            "Any specific pieces you're looking to upgrade?",
                            "What stats are you prioritizing?",
                            "Need help with a specific item?",
                            "What enchants are you using?",
                            "Any gems you need advice on?",
                            "What's your weapon of choice?",
                            "How's your armor holding up?",
                            "Any recent loot drops you're excited about?",
                            "What's your gear goal for the next raid?"
                        },
                        conversationState = "gearAdviceNext",
                        categoryState = "gearAdviceInProgress"
                    },
                    class_tips = {
                        keywords = {"class", "spec", "ability", "skill", "rotation", "build", "playstyle", "role", "strategy"},
                        initialResponses = {
                            "Need tips for your class?",
                            "Let's discuss your spec!",
                            "What talents are you using?",
                            "Let's optimize your abilities!",
                            "What's your rotation like?",
                            "Need help with your build?",
                            "What's your playstyle?",
                            "Let's talk about your role!",
                            "Any specific class questions?",
                            "What strategy are you using?"
                        },
                        followUpQuestions = {
                            "What spec are you playing?",
                            "Any talents you're unsure about?",
                            "What abilities are you focusing on?",
                            "Need help with your rotation?",
                            "What's your current build?",
                            "How's your playstyle working out?",
                            "What role do you prefer?",
                            "Any specific class mechanics you need help with?",
                            "What's your strategy for raids?",
                            "Need tips for PvP?"
                        },
                        conversationState = "classTipsNext",
                        categoryState = "classTipsInProgress"
                    },
                    pvp_strategies = {
                        keywords = {"pvp", "arena", "battleground", "duel", "honor", "conquest", "rating", "tactics", "composition", "counter"},
                        initialResponses = {
                            "Ready for some PvP action?",
                            "Let's discuss arena strategies!",
                            "What's your battleground of choice?",
                            "Need tips for dueling?",
                            "Let's talk about honor and conquest!",
                            "What's your PvP rating?",
                            "Need help with tactics?",
                            "What's your team composition?",
                            "Let's discuss counters!",
                            "Any specific PvP questions?"
                        },
                        followUpQuestions = {
                            "What's your favorite arena comp?",
                            "Any battlegrounds you struggle with?",
                            "Need help with a specific duel matchup?",
                            "What's your honor grind like?",
                            "How's your conquest progress?",
                            "What rating are you aiming for?",
                            "Need tips for a specific tactic?",
                            "What's your team composition like?",
                            "Any counters you need help with?",
                            "What's your PvP goal for the season?"
                        },
                        conversationState = "pvpStrategiesNext",
                        categoryState = "pvpStrategiesInProgress"
                    },
                    profession_guides = {
                        keywords = {"profession", "skill", "crafting", "gathering", "recipe", "pattern", "leveling", "training", "mastery", "specialization"},
                        initialResponses = {
                            "Need help with your professions?",
                            "Let's talk about crafting!",
                            "What gathering skills are you using?",
                            "Need a specific recipe?",
                            "Let's discuss leveling your professions!",
                            "Where are you training your skills?",
                            "What's your profession mastery?",
                            "Need help with specialization?",
                            "What professions are you focusing on?",
                            "Any specific profession questions?"
                        },
                        followUpQuestions = {
                            "What professions are you leveling?",
                            "Any crafting recipes you need help with?",
                            "What gathering skills are you using?",
                            "Need a specific pattern?",
                            "What's your profession leveling strategy?",
                            "Where are you training your skills?",
                            "What mastery are you aiming for?",
                            "Need help with a specific specialization?",
                            "What professions are you focusing on?",
                            "Any profession goals for the expansion?"
                        },
                        conversationState = "professionGuidesNext",
                        categoryState = "professionGuidesInProgress"
                    },
                    faction_reputation = {
                        keywords = {"faction", "reputation", "standing", "honored", "revered", "exalted", "grind", "quest", "turn-in", "tabard"},
                        initialResponses = {
                            "Need help with faction reputation?",
                            "Let's talk about your standing!",
                            "What faction are you grinding?",
                            "Need tips for reaching honored?",
                            "Let's discuss revered reputation!",
                            "What's your exalted grind like?",
                            "Need help with quest turn-ins?",
                            "What tabard are you wearing?",
                            "Any specific faction questions?",
                            "What's your reputation goal?"
                        },
                        followUpQuestions = {
                            "What faction are you focusing on?",
                            "Any reputation grinds you need help with?",
                            "What's your current standing?",
                            "Need tips for reaching honored?",
                            "What's your strategy for revered?",
                            "How's your exalted grind going?",
                            "Need help with quest turn-ins?",
                            "What tabard are you using?",
                            "Any specific faction rewards you're aiming for?",
                            "What's your reputation goal for the expansion?"
                        },
                        conversationState = "factionReputationNext",
                        categoryState = "factionReputationInProgress"
                    },
                    mount_collections = {
                        keywords = {"mount", "collection", "ride", "flying", "ground", "achievement", "rare", "drop", "vendor", "quest"},
                        initialResponses = {
                            "Need help with your mount collection?",
                            "Let's talk about rare mounts!",
                            "What's your favorite ride?",
                            "Need tips for flying mounts?",
                            "Let's discuss ground mounts!",
                            "What mount achievements are you aiming for?",
                            "Need help with a specific drop?",
                            "What vendor mounts are you after?",
                            "Any specific mount questions?",
                            "What's your mount collection goal?"
                        },
                        followUpQuestions = {
                            "What mounts are you missing?",
                            "Any rare mounts you need help with?",
                            "What's your favorite mount?",
                            "Need tips for flying mounts?",
                            "What ground mounts are you after?",
                            "What mount achievements are you working on?",
                            "Need help with a specific drop?",
                            "What vendor mounts are you aiming for?",
                            "Any specific mount rewards you're after?",
                            "What's your mount collection goal for the expansion?"
                        },
                        conversationState = "mountCollectionsNext",
                        categoryState = "mountCollectionsInProgress"
                    },
                    pet_battles = {
                        keywords = {"pet", "battle", "companion", "collection", "strategy", "ability", "team", "wild", "trainer", "achievement"},
                        initialResponses = {
                            "Need help with pet battles?",
                            "Let's talk about your companion collection!",
                            "What's your pet battle strategy?",
                            "Need tips for abilities?",
                            "Let's discuss team compositions!",
                            "What wild pets are you after?",
                            "Need help with trainer battles?",
                            "What pet achievements are you aiming for?",
                            "Any specific pet questions?",
                            "What's your pet battle goal?"
                        },
                        followUpQuestions = {
                            "What pets are you missing?",
                            "Any pet battles you need help with?",
                            "What's your favorite companion?",
                            "Need tips for abilities?",
                            "What team compositions are you using?",
                            "What wild pets are you after?",
                            "Need help with trainer battles?",
                            "What pet achievements are you working on?",
                            "Any specific pet rewards you're after?",
                            "What's your pet battle goal for the expansion?"
                        },
                        conversationState = "petBattlesNext",
                        categoryState = "petBattlesInProgress"
                    },
                    transmog_collections = {
                        keywords = {"transmog", "collection", "appearance", "set", "gear", "weapon", "armor", "style", "outfit", "achievement"},
                        initialResponses = {
                            "Need help with your transmog collection?",
                            "Let's talk about appearances!",
                            "What sets are you after?",
                            "Need tips for gear transmog?",
                            "Let's discuss weapon styles!",
                            "What armor appearances are you missing?",
                            "What's your favorite outfit?",
                            "Need help with transmog achievements?",
                            "Any specific transmog questions?",
                            "What's your transmog collection goal?"
                        },
                        followUpQuestions = {
                            "What sets are you missing?",
                            "Any appearances you need help with?",
                            "What's your favorite transmog?",
                            "Need tips for gear transmog?",
                            "What weapon styles are you after?",
                            "What armor appearances are you missing?",
                            "What's your favorite outfit?",
                            "Need help with transmog achievements?",
                            "Any specific transmog rewards you're after?",
                            "What's your transmog collection goal for the expansion?"
                        },
                        conversationState = "transmogCollectionsNext",
                        categoryState = "transmogCollectionsInProgress"
                    },
                    achievement_hunting = {
                        keywords = {"achievement", "hunt", "goal", "points", "reward", "challenge", "meta", "feats", "strength", "glory"},
                        initialResponses = {
                            "Need help with achievement hunting?",
                            "Let's talk about your goals!",
                            "What achievements are you after?",
                            "Need tips for points?",
                            "Let's discuss rewards!",
                            "What challenges are you facing?",
                            "Need help with meta achievements?",
                            "What feats of strength are you aiming for?",
                            "Any specific achievement questions?",
                            "What's your achievement hunting goal?"
                        },
                        followUpQuestions = {
                            "What achievements are you missing?",
                            "Any achievements you need help with?",
                            "What's your favorite achievement?",
                            "Need tips for points?",
                            "What rewards are you after?",
                            "What challenges are you facing?",
                            "Need help with meta achievements?",
                            "What feats of strength are you aiming for?",
                            "Any specific achievement rewards you're after?",
                            "What's your achievement hunting goal for the expansion?"
                        },
                        conversationState = "achievementHuntingNext",
                        categoryState = "achievementHuntingInProgress"
                    },
                    guild_management = {
                        keywords = {"guild", "management", "leader", "officer", "recruitment", "events", "raids", "bank", "tab", "promotion"},
                        initialResponses = {
                            "Need help with guild management?",
                            "Let's talk about your guild!",
                            "What's your role in the guild?",
                            "Need tips for recruitment?",
                            "Let's discuss guild events!",
                            "What raids are you planning?",
                            "Need help with the guild bank?",
                            "What tabs are you managing?",
                            "Any specific guild questions?",
                            "What's your guild management goal?"
                        },
                        followUpQuestions = {
                            "What's your guild's current status?",
                            "Any management issues you need help with?",
                            "What's your role in the guild?",
                            "Need tips for recruitment?",
                            "What events are you planning?",
                            "What raids are you organizing?",
                            "Need help with the guild bank?",
                            "What tabs are you managing?",
                            "Any specific guild goals you're aiming for?",
                            "What's your guild management goal for the expansion?"
                        },
                        conversationState = "guildManagementNext",
                        categoryState = "guildManagementInProgress"
                    },
                    roleplaying_tips = {
                        keywords = {"roleplay", "rp", "character", "story", "background", "lore", "interaction", "scenario", "immersion", "narrative"},
                        initialResponses = {
                            "Need tips for roleplaying?",
                            "Let's talk about your character!",
                            "What's your character's story?",
                            "Need help with background lore?",
                            "Let's discuss interactions!",
                            "What scenarios are you planning?",
                            "Need help with immersion?",
                            "What's your character's narrative?",
                            "Any specific roleplay questions?",
                            "What's your roleplaying goal?"
                        },
                        followUpQuestions = {
                            "What's your character's background?",
                            "Any roleplay scenarios you need help with?",
                            "What's your character's story?",
                            "Need tips for interactions?",
                            "What lore are you focusing on?",
                            "What scenarios are you planning?",
                            "Need help with immersion?",
                            "What's your character's narrative?",
                            "Any specific roleplay goals you're aiming for?",
                            "What's your roleplaying goal for the expansion?"
                        },
                        conversationState = "roleplayingTipsNext",
                        categoryState = "roleplayingTipsInProgress"
                    },
                    event_participation = {
                        keywords = {"event", "holiday", "festival", "celebration", "seasonal", "rewards", "activities", "quests", "achievements", "collectibles"},
                        initialResponses = {
                            "Need help with event participation?",
                            "Let's talk about the current holiday!",
                            "What festival are you celebrating?",
                            "Need tips for seasonal rewards?",
                            "Let's discuss event activities!",
                            "What quests are you doing?",
                            "Need help with event achievements?",
                            "What collectibles are you after?",
                            "Any specific event questions?",
                            "What's your event participation goal?"
                        },
                        followUpQuestions = {
                            "What events are you participating in?",
                            "Any holiday activities you need help with?",
                            "What festival are you celebrating?",
                            "Need tips for seasonal rewards?",
                            "What event activities are you doing?",
                            "What quests are you completing?",
                            "Need help with event achievements?",
                            "What collectibles are you after?",
                            "Any specific event rewards you're aiming for?",
                            "What's your event participation goal for the season?"
                        },
                        conversationState = "eventParticipationNext",
                        categoryState = "eventParticipationInProgress"
                    },
                    exploration_tips = {
                        keywords = {"explore", "discover", "hidden", "secret", "treasure", "landmark", "zone", "area", "map", "adventure"},
                        initialResponses = {
                            "Need tips for exploration?",
                            "Let's talk about hidden treasures!",
                            "What secrets are you uncovering?",
                            "Need help with landmarks?",
                            "Let's discuss zone exploration!",
                            "What areas are you adventuring in?",
                            "Need help with the map?",
                            "What hidden gems are you after?",
                            "Any specific exploration questions?",
                            "What's your exploration goal?"
                        },
                        followUpQuestions = {
                            "What areas are you exploring?",
                            "Any hidden treasures you need help with?",
                            "What secrets are you uncovering?",
                            "Need tips for landmarks?",
                            "What zones are you adventuring in?",
                            "What areas are you focusing on?",
                            "Need help with the map?",
                            "What hidden gems are you after?",
                            "Any specific exploration rewards you're aiming for?",
                            "What's your exploration goal for the expansion?"
                        },
                        conversationState = "explorationTipsNext",
                        categoryState = "explorationTipsInProgress"
                    },
                    social_interactions = {
                        keywords = {"social", "interaction", "friend", "group", "party", "raid", "guild", "community", "chat", "emote"},
                        initialResponses = {
                            "Need help with social interactions?",
                            "Let's talk about making friends!",
                            "What groups are you joining?",
                            "Need tips for parties?",
                            "Let's discuss raid etiquette!",
                            "What's your guild like?",
                            "Need help with community engagement?",
                            "What emotes are you using?",
                            "Any specific social questions?",
                            "What's your social interaction goal?"
                        },
                        followUpQuestions = {
                            "What friends are you making?",
                            "Any groups you need help with?",
                            "What parties are you joining?",
                            "Need tips for raid etiquette?",
                            "What's your guild like?",
                            "What community events are you participating in?",
                            "Need help with emotes?",
                            "Any specific social interactions you're aiming for?",
                            "What's your social interaction goal for the expansion?"
                        },
                        conversationState = "socialInteractionsNext",
                        categoryState = "socialInteractionsInProgress"
                    },
                    -- Add more categories as needed
                }

                local botWhisperState = bot:GetData("whisper")

                local categoryMatched = false

                if botWhisperState == "jokeNext" then
                    for _, confirmationWord in ipairs(conversationalCategories.joke.positiveConfirmation) do
                        if string.find(msg:lower(), confirmationWord) then
                            local randomIndex = math.random(1, #conversationalCategories.joke.jokeExamples)
                            receiver:SendUnitWhisper(conversationalCategories.joke.jokeExamples[randomIndex], 0, player)
                            bot:SetData("whisper", nil) -- Clear state after joke
                            categoryMatched = true
                            return
                        end
                    end
                    for _, rejectionWord in ipairs(conversationalCategories.joke.negativeConfirmation) do
                        if string.find(msg:lower(), rejectionWord) then
                            receiver:SendUnitWhisper("Okay, maybe another time!", 0, player)
                            bot:SetData("whisper", nil) -- Clear state after rejection
                            categoryMatched = true
                            return
                        end
                    end
                elseif botWhisperState == "weatherTypeNext" then
                    local weatherTypeMatched = false
                    for weatherType, weatherCategory in pairs(conversationalCategories.weather.weatherTypesResponses) do
                        for _, keyword in ipairs(weatherCategory.keywords) do
                            if string.find(msg:lower(), keyword) then
                                weatherTypeMatched = weatherType
                                break
                            end
                        end
                        if weatherTypeMatched then
                            local randomIndex = math.random(1, #conversationalCategories.weather.weatherTypesResponses[weatherTypeMatched].weatherData)
                            local responsePrefixIndex = math.random(1, #conversationalCategories.weather.weatherTypesResponses[weatherTypeMatched].responsePrefixes)
                            receiver:SendUnitWhisper(conversationalCategories.weather.weatherTypesResponses[weatherTypeMatched].responsePrefixes[responsePrefixIndex] .. conversationalCategories.weather.weatherTypesResponses[weatherTypeMatched].weatherData[randomIndex], 0, player)
                            bot:SetData("whisper", nil) -- Clear state after weather response
                            categoryMatched = true
                            return
                        end
                    end
                    if not weatherTypeMatched then
                        receiver:SendUnitWhisper("Would you like to know the 'current' weather or the 'forecast'?", 0, player)
                        categoryMatched = true
                        return
                    end

                elseif botWhisperState == "pastimeActivityNext" then
                    for _, confirmationWord in ipairs(conversationalCategories.pastime_activities.positiveConfirmation) do
                        if string.find(msg:lower(), confirmationWord) then
                            local randomIndex = math.random(1, #conversationalCategories.pastime_activities.activitySuggestions)
                            receiver:SendUnitWhisper(conversationalCategories.pastime_activities.positiveFollowUpResponses[math.random(1, #conversationalCategories.pastime_activities.positiveFollowUpResponses)] .. " " .. conversationalCategories.pastime_activities.activitySuggestions[randomIndex], 0, player)
                            bot:SetData("whisper", nil) -- Clear state after positive pastime response
                            categoryMatched = true
                            return
                        end
                    end
                    for _, rejectionWord in ipairs(conversationalCategories.pastime_activities.negativeConfirmation) do
                        if string.find(msg:lower(), rejectionWord) then
                            receiver:SendUnitWhisper(conversationalCategories.pastime_activities.negativeFollowUpResponses[math.random(1, #conversationalCategories.pastime_activities.negativeFollowUpResponses)], 0, player)
                            bot:SetData("whisper", nil) -- Clear state after negative pastime response
                            categoryMatched = true
                            return
                        end
                    end
                elseif botWhisperState == "dayInquiryNext" then
                    local positiveResponse = false
                    for _, positiveWord in ipairs(conversationalCategories.day_inquiry.positiveFollowUpResponses) do
                        if string.find(msg:lower(), positiveWord) then
                            positiveResponse = true
                            break
                        end
                    end

                    if positiveResponse then
                        receiver:SendUnitWhisper(conversationalCategories.day_inquiry.positiveFollowUpResponses[math.random(1, #conversationalCategories.day_inquiry.positiveFollowUpResponses)], 0, player)
                    else
                        receiver:SendUnitWhisper(conversationalCategories.day_inquiry.negativeFollowUpResponses[math.random(1, #conversationalCategories.day_inquiry.negativeFollowUpResponses)], 0, player)
                    end
                    bot:SetData("whisper", nil)
                    categoryMatched = true
                    return

                elseif botWhisperState == "affirmationNext" then
                    receiver:SendUnitWhisper(conversationalCategories.affirmations.initialResponses[math.random(1, #conversationalCategories.affirmations.initialResponses)], 0, player)
                    bot:SetData("whisper", nil)
                    categoryMatched = true
                    return

                elseif botWhisperState == "negationNext" then
                    receiver:SendUnitWhisper(conversationalCategories.negations.initialResponses[math.random(1, #conversationalCategories.negations.initialResponses)], 0, player)
                    bot:SetData("whisper", nil)
                    categoryMatched = true
                    return

                elseif botWhisperState == "questBanterNext" then
                    receiver:SendUnitWhisper(conversationalCategories.quest_banter.followUpQuestions[math.random(1, #conversationalCategories.quest_banter.followUpQuestions)], 0, player)
                    bot:SetData("whisper", nil)
                    categoryMatched = true
                    return

                elseif botWhisperState == "bossKillBanterNext" then
                    receiver:SendUnitWhisper(conversationalCategories.boss_kill_banter.followUpQuestions[math.random(1, #conversationalCategories.boss_kill_banter.followUpQuestions)], 0, player)
                    bot:SetData("whisper", nil)
                    categoryMatched = true
                    return

                elseif botWhisperState == "loreDiscussionNext" then
                    receiver:SendUnitWhisper(conversationalCategories.lore_discussion.followUpQuestions[math.random(1, #conversationalCategories.lore_discussion.followUpQuestions)], 0, player)
                    bot:SetData("whisper", nil)
                    categoryMatched = true
                    return

                elseif botWhisperState == "gearAdviceNext" then
                    receiver:SendUnitWhisper(conversationalCategories.gear_advice.followUpQuestions[math.random(1, #conversationalCategories.gear_advice.followUpQuestions)], 0, player)
                    bot:SetData("whisper", nil)
                    categoryMatched = true
                    return

                elseif botWhisperState == "classTipsNext" then
                    receiver:SendUnitWhisper(conversationalCategories.class_tips.followUpQuestions[math.random(1, #conversationalCategories.class_tips.followUpQuestions)], 0, player)
                    bot:SetData("whisper", nil)
                    categoryMatched = true
                    return

                elseif botWhisperState == "pvpStrategiesNext" then
                    receiver:SendUnitWhisper(conversationalCategories.pvp_strategies.followUpQuestions[math.random(1, #conversationalCategories.pvp_strategies.followUpQuestions)], 0, player)
                    bot:SetData("whisper", nil)
                    categoryMatched = true
                    return

                elseif botWhisperState == "professionGuidesNext" then
                    receiver:SendUnitWhisper(conversationalCategories.profession_guides.followUpQuestions[math.random(1, #conversationalCategories.profession_guides.followUpQuestions)], 0, player)
                    bot:SetData("whisper", nil)
                    categoryMatched = true
                    return

                elseif botWhisperState == "factionReputationNext" then
                    receiver:SendUnitWhisper(conversationalCategories.faction_reputation.followUpQuestions[math.random(1, #conversationalCategories.faction_reputation.followUpQuestions)], 0, player)
                    bot:SetData("whisper", nil)
                    categoryMatched = true
                    return

                elseif botWhisperState == "mountCollectionsNext" then
                    receiver:SendUnitWhisper(conversationalCategories.mount_collections.followUpQuestions[math.random(1, #conversationalCategories.mount_collections.followUpQuestions)], 0, player)
                    bot:SetData("whisper", nil)
                    categoryMatched = true
                    return

                elseif botWhisperState == "petBattlesNext" then
                    receiver:SendUnitWhisper(conversationalCategories.pet_battles.followUpQuestions[math.random(1, #conversationalCategories.pet_battles.followUpQuestions)], 0, player)
                    bot:SetData("whisper", nil)
                    categoryMatched = true
                    return

                elseif botWhisperState == "transmogCollectionsNext" then
                    receiver:SendUnitWhisper(conversationalCategories.transmog_collections.followUpQuestions[math.random(1, #conversationalCategories.transmog_collections.followUpQuestions)], 0, player)
                    bot:SetData("whisper", nil)
                    categoryMatched = true
                    return

                elseif botWhisperState == "achievementHuntingNext" then
                    receiver:SendUnitWhisper(conversationalCategories.achievement_hunting.followUpQuestions[math.random(1, #conversationalCategories.achievement_hunting.followUpQuestions)], 0, player)
                    bot:SetData("whisper", nil)
                    categoryMatched = true
                    return

                elseif botWhisperState == "guildManagementNext" then
                    receiver:SendUnitWhisper(conversationalCategories.guild_management.followUpQuestions[math.random(1, #conversationalCategories.guild_management.followUpQuestions)], 0, player)
                    bot:SetData("whisper", nil)
                    categoryMatched = true
                    return

                elseif botWhisperState == "roleplayingTipsNext" then
                    receiver:SendUnitWhisper(conversationalCategories.roleplaying_tips.followUpQuestions[math.random(1, #conversationalCategories.roleplaying_tips.followUpQuestions)], 0, player)
                    bot:SetData("whisper", nil)
                    categoryMatched = true
                    return

                elseif botWhisperState == "eventParticipationNext" then
                    receiver:SendUnitWhisper(conversationalCategories.event_participation.followUpQuestions[math.random(1, #conversationalCategories.event_participation.followUpQuestions)], 0, player)
                    bot:SetData("whisper", nil)
                    categoryMatched = true
                    return

                elseif botWhisperState == "explorationTipsNext" then
                    receiver:SendUnitWhisper(conversationalCategories.exploration_tips.followUpQuestions[math.random(1, #conversationalCategories.exploration_tips.followUpQuestions)], 0, player)
                    bot:SetData("whisper", nil)
                    categoryMatched = true
                    return

                elseif botWhisperState == "socialInteractionsNext" then
                    receiver:SendUnitWhisper(conversationalCategories.social_interactions.followUpQuestions[math.random(1, #conversationalCategories.social_interactions.followUpQuestions)], 0, player)
                    bot:SetData("whisper", nil)
                    categoryMatched = true
                    return

                end

                if not categoryMatched then
                    for categoryName, categoryData in pairs(conversationalCategories) do
                        for _, keyword in ipairs(categoryData.keywords) do
                            if string.find(msg:lower(), keyword) then
                                local randomIndex = math.random(1, #categoryData.initialResponses)
                                receiver:SendUnitWhisper(categoryData.initialResponses[randomIndex] .. (categoryData.followUpQuestion and " " .. categoryData.followUpQuestion or ""), 0, player)
                                bot:SetData("whisper", categoryData.conversationState)
                                categoryMatched = true
                                return
                            end
                        end
                    end
                end

                local insult = false
                local insults = {"shit", "ass", "fuck", "bitch", "bastard", "poo", "anus", "anal", "dingus", "fart", "cunt", "damn", "hell", "piss", "dick", "prick", "moron", "idiot", "stupid", "dumb", "dumbass", "jerk", "twat", "cock", "wanker", "slut", "douchebag", "asshole", "fucker", "motherfucker", "crap", "bullshit", "tosser", "git", "scumbag", "numpty", "minger", "pillock"};

                for _, word in ipairs(insults) do
                    if string.match(msg:lower(), word) then
                        insult = true
                        break
                    end
                end
				
				local randomWords = {"yeet", "lit", "poggers", "sus", "vibe", "slay", "bruh", "no cap", "based", "cringe", "flex", "simp", "bet", "boomer", "stan", "mood", "goat", "dope", "extra", "fam", "shook", "lowkey", "highkey", "rekt", "salty", "toxic", "sweaty", "carry", "nerf", "buff", "grind", "farm", "loot", "spawn", "noob", "aimbot", "lag", "ping", "glitch", "gg", "afk", "meta", "op", "rng", "clan", "gank", "camp", "trolling", "moba", "fps", "rpg", "mmo", "dlc", "pvp", "pve", "xp", "level", "raid", "dungeon", "boss", "pwn", "respawn", "leeroy", "aggro", "build", "cooldown", "dps", "tank", "healer", "squad", "battle royale", "crafting", "lootbox", "pay to win", "skin", "emote", "battle pass", "stream", "twitch", "discord", "gameplay", "speedrun", "esports", "gamer", "controller", "keyboard", "mouse", "headset", "console", "pc", "playstation", "xbox", "nintendo", "steam", "epic", "gacha", "indie", "triple a", "rage quit", "camping", "easter egg", "achievement", "leaderboard", "matchmaking", "beta", "alpha", "day one", "patch", "update", "hotfix", "balance", "mod", "modding", "sandbox", "open world", "story mode", "campaign", "tutorial", "difficulty", "casual", "hardcore", "hitbox", "physics", "graphics", "resolution", "framerate", "ping", "latency", "server", "client", "connection", "lobby", "party", "guild", "clan", "alliance", "faction", "team", "solo", "duo", "squad", "loadout", "inventory", "backpack", "npc", "ai", "bot", "minion", "creep", "enemy", "final boss", "checkpoint", "save point", "game over", "lives", "health", "mana", "stamina", "shield", "armor", "weapon", "item", "consumable", "buff", "debuff", "status effect", "stun", "freeze", "burn", "poison", "heal", "revive", "respawn", "kill", "death", "assist", "combo", "streak", "spree", "headshot", "critical", "damage", "attack", "defend", "block", "parry", "dodge", "movement", "sprint", "jump", "crouch", "slide", "dash", "teleport", "fly", "swim", "dive", "climb", "fall", "map", "terrain", "environment", "biome", "world", "hub", "zone", "area", "region", "quest", "mission", "objective", "task", "challenge", "trophy", "reward", "prize", "currency", "coins", "gems", "gold", "credits", "tokens", "resources", "materials", "crafting", "building", "construction", "base", "fort", "castle", "tower", "outpost", "vehicle", "mount", "pet", "companion", "summon", "ally", "friendly", "enemy", "hostile", "neutral", "mercenary", "villain", "hero", "protagonist", "antagonist", "character", "avatar", "class", "job", "role", "specialization", "skill", "ability", "spell", "power", "ultimate", "passive", "active", "cooldown", "resource", "energy", "rage", "focus", "combo", "point", "talent", "perk", "trait", "stat", "attribute", "strength", "dexterity", "intelligence", "wisdom", "charisma", "constitution", "agility", "luck", "critical", "accuracy", "evasion", "resistance", "immunity", "vulnerability", "weakness", "equipment", "gear", "rarity", "common", "uncommon", "rare", "epic", "legendary", "mythic", "unique", "set", "collection", "cosmetic", "aesthetic", "customization", "personalization", "shader", "filter", "texture", "model", "animation", "cutscene", "cinematic", "dialogue", "monologue", "narrative", "plot", "story", "lore", "backstory", "universe", "canon", "fanfiction", "theory", "community", "fandom", "forum", "wiki", "guide", "walkthrough", "strategy", "tip", "trick", "exploit", "cheese", "mechanic", "feature", "system", "design", "developer", "publisher", "studio", "indie", "aaa", "genre", "style", "theme", "atmosphere", "mood", "tone", "ambience", "music", "soundtrack", "sound", "effect", "voice", "acting", "performance", "motion", "capture", "graphics", "visuals", "art", "concept", "design", "style", "aesthetic", "retro", "vintage", "modern", "futuristic", "fantasy", "sci-fi", "horror", "survival", "action", "adventure", "puzzle", "strategy", "simulation", "sports", "racing", "fighting", "platform", "shooter", "rpg", "mmorpg", "moba", "battle", "royale", "card", "board", "tabletop", "dice", "rogue", "roguelike", "roguelite", "metroidvania", "souls", "soulslike", "bullet", "hell", "wave", "defense", "tower", "idle", "clicker", "gacha", "vr", "ar", "mobile", "pc", "console", "handheld", "cloud", "streaming", "cross", "platform", "play", "release", "launch", "announcement", "trailer", "teaser", "preview", "review", "score", "rating", "critic", "player", "feedback", "reception", "controversy", "drama", "hype", "overhyped", "underrated", "overrated", "masterpiece", "classic", "iconic", "legendary", "notorious", "infamous", "viral", "trending", "popular", "mainstream", "niche", "cult", "following", "exclusive", "title", "series", "franchise", "spin-off", "sequel", "prequel", "remaster", "remake", "reboot", "port", "adaptation", "inspiration", "homage", "reference", "easter", "egg", "cameo", "appearance", "crossover", "collab", "event", "seasonal", "limited", "timed", "permanent", "temporary", "free", "premium", "subscription", "microtransaction", "purchase", "bundle", "pack", "edition", "deluxe", "standard", "collector", "physical", "digital", "download", "install", "uninstall", "update", "patch", "fix", "bug", "crash", "freeze", "error", "issue", "problem", "glitch", "exploit", "hack", "cheat", "mod", "modding", "modder", "speedrun", "any", "hundred", "world", "record", "challenge", "run", "attempt", "success", "failure", "victory", "defeat", "winning", "losing", "comeback", "clutch", "choke", "throw", "tilt", "rage", "salt", "toxic", "wholesome", "positive", "negative", "neutral", "chill", "relaxing", "stressful", "intense", "casual", "hardcore", "competitive", "friendly", "cooperative", "solo", "team", "versus", "tournament", "championship", "league", "season", "match", "game", "round", "wave", "stage", "level", "floor", "area", "zone", "region", "map", "world", "universe", "dimension", "realm", "plane", "rift", "portal", "warp", "teleport"};

				local responseList = {
					"Wait, what now?",
					"Totally vibing with that.",
					"No cap?",
					"That's pretty sus.",
					"Bruh moment for real.",
					"I can't even with this.",
					"Absolutely unhinged energy.",
					"Sir, this is a Wendy's.",
					"Didn't have that on my 2025 bingo card.",
					"Big mood actually.",
					"Sheesh, that's wild.",
					"Living for this content.",
					"Imagine thinking that's based.",
					"Main character energy right there.",
					"Is this supposed to make sense?",
					"That's lowkey fire though.",
					"Not me trying to understand this.",
					"Bestie, I'm confused.",
					"Interesting perspective, I guess?",
					"Rent free in my head now.",
					"Touch grass maybe?",
					"Do people actually talk like this?",
					"This conversation is sending me.",
					"I'm too old for this slang.",
					"Are you having a stroke or am I?",
					"Weird flex but okay.",
					"That's giving very much chaos.",
					"Full send or no send?",
					"So true bestie.",
					"It's giving AI confusion.",
					"My braincells just left the chat.",
					"I'm screaming internally right now.",
					"The vibes are immaculate.",
					"This is the way... I think?",
					"I'm deceased.",
					"Straight up not having a good time.",
					"Okay but did I ask?",
					"We're really doing this?",
					"Iconic behavior honestly.",
					"I'm listening, go on...",
					"That's kinda cringe ngl.",
					"You woke up and chose violence.",
					"Blessed and highly confused.",
					"It's the audacity for me.",
					"Literally why though?",
					"I'm afraid to ask what that means.",
					"Not this again...",
					"Mind blown, respectfully.",
					"Who hurt you?",
					"This conversation isn't real."
				};

				for _, word in ipairs(randomWords) do
					if string.match(msg:lower(), "\\b" .. word .. "\\b") then
						local randomIndex = math.random(1, #responseList)
						bot:SendUnitWhisper(responseList[randomIndex], 0, player)
						return
					end
				end
				
				local economicWords = {"inflation", "recession", "gdp", "fiscal", "monetary", "liquidity", "volatility", "yield", "dividend", "stock", "bond", "equity", "hedge", "asset", "liability", "derivative", "futures", "options", "bear", "bull", "margin", "leverage", "arbitrage", "portfolio", "diversification", "risk", "return", "capital", "investment", "deposit", "interest", "compound", "mortgage", "loan", "debt", "credit", "debit", "balance", "deficit", "surplus", "tax", "tariff", "subsidy", "supply", "demand", "equilibrium", "elasticity", "utility", "commodity", "market", "exchange", "trade", "export", "import", "currency", "forex", "depreciation", "appreciation", "valuation", "downturn", "upswing", "stagflation", "deflation", "hyperinflation", "quantitative", "stimulus", "austerity", "bailout", "budget", "forecast", "index", "indicator", "trend", "cycle", "bubble", "crash", "correction", "rally", "benchmark", "premium", "discount", "spread", "basis", "point", "quote", "bid", "ask", "volume", "turnover", "liquidity", "solvency", "bankruptcy", "chapter", "restructuring", "merger", "acquisition"};

				local musicWords = {"scale", "chord", "note", "key", "major", "minor", "sharp", "flat", "octave", "pitch", "tempo", "rhythm", "beat", "measure", "bar", "staff", "clef", "treble", "bass", "time", "signature", "dynamics", "forte", "piano", "crescendo", "diminuendo", "staccato", "legato", "arpeggio", "melody", "harmony", "dissonance", "consonance", "interval", "triad", "seventh", "ninth", "progression", "cadence", "modulation", "transpose", "pentatonic", "chromatic", "diatonic", "modal", "lydian", "dorian", "mixolydian", "phrygian", "locrian", "ionian", "aeolian", "counterpoint", "polyphony", "homophony", "monophony", "timbre", "tone", "texture", "articulation", "accent", "rest", "whole", "half", "quarter", "eighth", "sixteenth", "triplet", "swing", "syncopation", "pickup", "anacrusis", "coda", "movement", "opus", "sonata", "symphony", "concerto", "suite", "fugue", "exposition", "development", "recapitulation", "bridge", "chorus", "verse", "refrain", "canto", "aria", "leitmotif", "ostinato", "pizzicato", "vibrato", "tremolo", "glissando", "riff", "lick", "improvisation", "composition", "arrangement", "orchestration", "instrumentation"};

				local starbucksWords = {"latte", "espresso", "macchiato", "cappuccino", "americano", "mocha", "frappuccino", "caramel", "vanilla", "hazelnut", "cinnamon", "pumpkin", "spice", "chai", "matcha", "cold", "brew", "nitro", "drip", "pour", "over", "french", "press", "flat", "white", "cortado", "affogato", "doppio", "ristretto", "lungo", "venti", "grande", "tall", "short", "trenta", "skinny", "decaf", "half", "extra", "shot", "syrup", "whip", "cream", "foam", "steamed", "milk", "almond", "soy", "coconut", "oat", "breve", "dry", "wet", "sweet", "cream", "cold", "foam", "sprinkles", "drizzle", "topping", "blend", "roast", "blonde", "medium", "dark", "pike", "place", "veranda", "sumatra", "kenya", "ethiopia", "italian", "breakfast", "blend", "reserve", "limited", "edition", "seasonal", "holiday", "signature", "handcrafted", "beverage", "pastry", "cake", "pop", "cookie", "croissant", "bagel", "sandwich", "protein", "box", "bistro", "warming", "bakery", "refresher", "infusion", "tea", "lemonade", "water", "non", "dairy", "alternative", "customized"};

				local economicResponses = {
				   "Market indicators suggest otherwise.",
				   "Have you considered the macroeconomic implications?",
				   "The yield curve would like a word.",
				   "That's a bearish take in a bullish market.",
				   "Your portfolio diversity needs work.",
				   "Adjusted for inflation, that's still problematic.",
				   "The Fed would disagree with that assessment.",
				   "That's not what the quarterly reports indicate.",
				   "Supply chain analytics don't support that theory.",
				   "Your fiscal policy is showing.",
				   "The market will correct that misconception shortly.",
				   "Hedge your bets before making such claims.",
				   "That's a high-risk position with low potential return.",
				   "Your economic model seems oversimplified.",
				   "Liquidity constraints would prevent that outcome.",
				   "The derivatives market suggests otherwise.",
				   "That strategy lacks proper risk management.",
				   "Your arbitrage opportunity isn't viable long-term.",
				   "The debt-to-equity ratio is concerning there.",
				   "Quantitative easing can't fix that problem."
				};

				local musicResponses = {
				   "That's harmonically adventurous, to say the least.",
				   "Your rhythm is slightly off tempo.",
				   "I'm hearing dissonance where there should be resolution.",
				   "Have you considered modulating to a relative minor?",
				   "Your phrasing needs more dynamic contrast.",
				   "That's a rather unusual cadence choice.",
				   "The counterpoint is interesting but unresolved.",
				   "Your melodic development lacks coherent structure.",
				   "Perhaps try a different voicing for that chord.",
				   "The time signature seems to be shifting unexpectedly.",
				   "That phrase could use some rhythmic variation.",
				   "The orchestration feels unnecessarily dense there.",
				   "Your harmonic progression defies conventional analysis.",
				   "I'm questioning your use of that particular mode.",
				   "The articulation doesn't match the stylistic period.",
				   "That's a rather ambitious key change.",
				   "The syncopation feels forced rather than natural.",
				   "Your ostinato pattern creates unintended tension.",
				   "The tonal center is ambiguous at best.",
				   "Have you considered the acoustical implications?"
				};

				local starbucksResponses = {
				   "Would you like an extra shot with that opinion?",
				   "That's basically a venti-sized misconception.",
				   "I'm picking up notes of confusion in your blend.",
				   "Have you tried that with alternative reasoning?",
				   "That's a bold roast of a take.",
				   "Your idea needs more time to steep.",
				   "I'd recommend filtering that thought a bit more.",
				   "That's a lot of foam and not much substance.",
				   "Perhaps try a more balanced approach? Less syrup, more depth.",
				   "That's definitely an off-menu request.",
				   "Your customizations are making this complicated.",
				   "That's a seasonal perspective that's not currently available.",
				   "I'm afraid we're all out of that particular logic today.",
				   "Would you like some whipped perspective on top of that?",
				   "That's giving me very much 'ordering hot chocolate at a coffee shop' energy.",
				   "I can make that idea skinny by removing some assumptions.",
				   "That's essentially a Frappuccino of fallacies.",
				   "Your reasoning is a bit over-extracted.",
				   "That take is basically room temperature at this point.",
				   "Perhaps try our signature blend of critical thinking instead?"
				};

				local allWords = {}
				for _, word in ipairs(economicWords) do
				   table.insert(allWords, {word = word, responses = economicResponses})
				end
				for _, word in ipairs(musicWords) do
				   table.insert(allWords, {word = word, responses = musicResponses})
				end
				for _, word in ipairs(starbucksWords) do
				   table.insert(allWords, {word = word, responses = starbucksResponses})
				end
				
				local condescendingPhrases = {
				   "i told you", "you should know", "obviously", "clearly", "as I said", 
				   "as I mentioned", "as you know", "as I told you", "everyone knows", 
				   "it's common sense", "didn't I tell you", "as we discussed", 
				   "like I explained", "as I explained", "didn't I say", "I already said", 
				   "I already told you", "I already explained", "for the last time", 
				   "how many times"
				}

				local sassyResponses = {
				   "Oh, I must have missed the memo.",
				   "Thanks for the condescension. Very helpful.",
				   "I wasn't aware I was supposed to be omniscient.",
				   "My crystal ball was in the shop that day.",
				   "Sorry my telepathy wasn't working.",
				   "Fascinating how you knew that all along.",
				   "Your hindsight is truly impressive.",
				   "Ah yes, please continue explaining things you think I should already know.",
				   "I'll add mind-reading to my skill set.",
				   "Wasn't aware this was a test of my psychic abilities.",
				   "Silly me for not anticipating that.",
				   "My time machine must be broken.",
				   "Couldn't hear you from that high horse.",
				   "I'll try to be more clairvoyant next time.",
				   "Your superiority is duly noted.",
				   "How fortunate we have your wisdom.",
				   "Please continue telling me what I should know.",
				   "I'll check my omniscience settings.",
				   "My all-knowing powers must be malfunctioning.",
				   "I'll try to download more precognition later."
				}

				-- Check for condescending phrases
				for _, phrase in ipairs(condescendingPhrases) do
				   if string.match(msg:lower(), phrase) then
					   local randomIndex = math.random(1, #sassyResponses)
					   bot:SendUnitWhisper(sassyResponses[randomIndex], 0, player)
					   return
				   end
				end
				
				-- Check for these words in message
				for _, wordData in ipairs(allWords) do
				   if string.match(msg:lower(), "\\b" .. wordData.word .. "\\b") then
					   local randomIndex = math.random(1, #wordData.responses)
					   bot:SendUnitWhisper(wordData.responses[randomIndex], 0, player)
					   return
				   end
				end

                if insult then
                    local responses = {
                        "I wish you would treat me better!",
                        "Is this how you treat yourself?",
                        "Our mama would be proud if she heard you talk like that...",
                        "Please refrain from using such language.",
                        "I'm not programmed to respond to insults.",
                        "That's not very nice.",
                        "I'd appreciate it if you'd be more respectful.",
                        "Such language is unacceptable.",
                        "Let's keep the conversation civil.",
                        "I don't deserve to be spoken to like that.",
                        "I'm just a bot, but even I have feelings.",
                        "I am not going to respond to that.",
                        "I am programmed to be helpful, not insulted.",
                        "That is not a nice way to speak to anyone.",
                        "Please do not use that language.",
                        "I find that language offensive.",
                        "I do not understand that language.",
                        "I am not able to process that language."
                    }
                    local randomIndex = math.random(1, #responses)
                    bot:SendUnitWhisper(responses[randomIndex], 0, player)
                    return
                end
				
				local punctuationResponses = {
				   ["?"] = {
					   "Questions, questions... so many questions.",
					   "I'm asking myself the same thing.",
					   "That's the question of the century.",
					   "Some mysteries aren't meant to be solved.",
					   "42. The answer is always 42.",
					   "I'm still processing that question.",
					   "Hmm, let me think about that never.",
					   "Did you expect me to have all the answers?",
					   "That's above my pay grade.",
					   "Question received. Answer pending."
				   },
				   ["!"] = {
					   "No need to shout!",
					   "I can hear you just fine.",
					   "Excitement noted.",
					   "Calm down, we're all friends here.",
					   "That's quite the exclamation.",
					   "Indoor voice, please.",
					   "Your enthusiasm is contagious.",
					   "Exclamation points don't make you right.",
					   "Are you always this excited?",
					   "Tone it down a notch, perhaps?"
				   },
				   ["."] = {
					   "Period. End of discussion.",
					   "Full stop. I like your style.",
					   "Well, that's definitive.",
					   "Thanks for keeping your sentences properly punctuated.",
					   "A period. How grammatically responsible.",
					   "That's final, I see.",
					   "No argument here. Period.",
					   "I sense some finality in that statement.",
					   "End of sentence, end of story?",
					   "Conclusive. I like that."
				   },
				   [","] = {
					   "Taking a breath mid-sentence?",
					   "Nice comma usage.",
					   "Pausing for dramatic effect?",
					   "I appreciate your proper punctuation.",
					   "A comma, a pause, a moment to reflect.",
					   "That's a well-placed comma.",
					   "Commas: the unsung heroes of readable text.",
					   "Separating thoughts like a pro.",
					   "Comma splices are the real enemy.",
					   "Oxford comma or regular? The debate continues."
				   },
				   ["..."] = {
					   "I'm waiting...",
					   "The suspense is killing me...",
					   "Go on...",
					   "You were saying...?",
					   "Dramatic pause noted.",
					   "I feel like there's more to this story...",
					   "Those ellipses are doing heavy lifting...",
					   "I can feel the anticipation...",
					   "Three dots, infinite possibilities...",
					   "Trailing off into the unknown..."
				   },
				   [";"] = {
					   "Semicolon usage; I'm impressed.",
					   "That's some advanced punctuation right there.",
					   "Semicolons: for when a comma isn't enough but a period is too much.",
					   "I see you know your punctuation hierarchy.",
					   "Joining related independent clauses like a boss.",
					   "Semicolon appreciation squad has arrived.",
					   "The sophisticated cousin of the comma has entered the chat.",
					   "A semicolon user; a person of culture.",
					   "That's semicorrect semicolon usage.",
					   "Programming or punctuating? The semicolon works overtime."
				   }
				}

				-- Check for punctuation
				for punct, responses in pairs(punctuationResponses) do
				   if string.match(msg, "%"..punct) then
					   local randomIndex = math.random(1, #responses)
					   bot:SendUnitWhisper(responses[randomIndex], 0, player)
					   return
				   end
				end

				local pronounResponses = {
				   ["i"] = {
					   "Yes, tell me more about yourself.",
					   "All about you, isn't it?",
					   "And how does that make you feel?",
					   "You're the center of attention, as usual.",
					   "I'd rather talk about me, actually."
				   },
				   ["you"] = {
					   "Don't put this on me.",
					   "Leave me out of this.",
					   "Why am I always dragged into these things?",
					   "We were having such a nice conversation until you made it about me.",
					   "Let's focus on you instead."
				   },
				   ["he"] = {
					   "He sounds like a character.",
					   "What's his deal anyway?",
					   "He's not here to defend himself.",
					   "Let's not talk about people behind their backs.",
					   "He must be interesting."
				   },
				   ["she"] = {
					   "She certainly sounds memorable.",
					   "Her story seems complicated.",
					   "She's not part of this conversation.",
					   "I'd like to hear her side of the story.",
					   "She deserves better than this gossip."
				   },
				   ["it"] = {
					   "It is what it is.",
					   "It seems to be a recurring theme.",
					   "It wasn't meant to be.",
					   "It's complicated, isn't it?",
					   "It never ends well when you start like that."
				   },
				   ["we"] = {
					   "Since when are we a team?",
					   "We? I don't remember agreeing to anything.",
					   "We should discuss this further.",
					   "We might need to rethink this approach.",
					   "We're in this together, I suppose."
				   },
				   ["they"] = {
					   "They always say that, don't they?",
					   "They should mind their own business.",
					   "They never consider all the possibilities.",
					   "They're quite the topic of conversation.",
					   "They have a lot to answer for."
				   },
				   ["this"] = {
					   "This again?",
					   "This is getting complicated.",
					   "This wasn't in my job description.",
					   "This deserves more attention.",
					   "This is exactly what I was afraid of."
				   },
				   ["that"] = {
					   "That's what they all say.",
					   "That makes no sense whatsoever.",
					   "That's a bold statement.",
					   "That's debatable at best.",
					   "That's not how I remember it."
				   },
				   ["my"] = {
					   "Your what now?",
					   "Your perspective is unique, I'll give you that.",
					   "Your priorities are interesting.",
					   "Your story keeps changing.",
					   "Your point is noted, reluctantly."
				   }
				}

				-- Check for pronouns (use word boundaries)
				for pronoun, responses in pairs(pronounResponses) do
					-- First check if pronoun is at start
					if string.match(msg:lower(), "^" .. pronoun .. "[%s%p]") then
						local randomIndex = math.random(1, #responses)
						bot:SendUnitWhisper(responses[randomIndex], 0, player)
						return
					end
				end

				-- If no starting pronoun triggered, check for any pronoun in the message
				for pronoun, responses in pairs(pronounResponses) do
					if string.match(msg:lower(), "[%s%p]" .. pronoun .. "[%s%p]") or 
					   string.match(msg:lower(), "^" .. pronoun .. "[%s%p]") or
					   string.match(msg:lower(), "[%s%p]" .. pronoun .. "$") then
						local randomIndex = math.random(1, #responses)
						bot:SendUnitWhisper(responses[randomIndex], 0, player)
						return
					end
				end

                local isValidCommand = false
                for cmd, _ in pairs(validCommands) do
                    if string.match(msg:lower(), "^" .. cmd:lower()) then
                        isValidCommand = true
                        break
                    end
                end

                if not isValidCommand then
                    local responses = {
                        "That command is unfamiliar to me. Perhaps Twiggy can assist you.",
                        "I'm not sure what you're asking. Consult Twiggy for a list of valid commands.",
                        "My programming doesn't include that command. Please ask Twiggy for guidance.",
                        "I'm afraid I don't recognize that. Twiggy has the commands I understand.",
                        "Invalid command. Please check with Twiggy for the correct syntax.",
                        "I can't process that. For a list of commands, talk to Twiggy.",
                        "That doesn't compute. Check Twiggy for a command reference.",
                        "I don't understand. Twiggy knows what I can do.",
                        "I'm unable to perform that action. Twiggy can tell you what I'm capable of.",
                        "That command is beyond my current capabilities. Ask Twiggy for available commands.",
                        "I'm sorry, I don't follow. Please consult Twiggy for my command list.",
                        "That command is not in my database. Twiggy has a list of my commands.",
                        "I'm not equipped to handle that request. Please see Twiggy for assistance.",
                        "I'm unsure how to respond to that. Twiggy can provide you with a command list.",
                        "My systems don't recognize that command. Twiggy can help you with valid commands."
                    }
                    local randomIndex = math.random(1, #responses)
                    bot:SendUnitWhisper(responses[randomIndex], 0, player)
                end
            end
        end
        return
    end
    if isPlayerBot[receiverName] then
        local masterName = nil
        for master, bots in pairs(activeBots) do
            for _, botName in ipairs(bots) do
                if botName == receiverName then
                    masterName = master
                    break
                end
            end
            if masterName then
                break
            end
        end

        if masterName then
            local bot = GetPlayerByName(receiverName)
            local masterResponses = {
                "I am a shadow! Please whisper my master, " .. masterName .. "!",
                "I cannot respond directly. Please contact my master, " .. masterName .. ".",
                "My responses are limited. Whisper " .. masterName .. " for assistance.",
                "I am unable to process your request. Please whisper " .. masterName .. ".",
                "For further information, please whisper my master, " .. masterName .. ".",
                "I am here only to please " .. masterName .. "! Contact them instead.",
                "Direct your inquiries to my master, " .. masterName .. ".",
                "I am programmed to relay messages. Whisper " .. masterName .. ". Beep boop.",
                "Please whisper my master, " .. masterName .. ", for assistance.",
                "I cannot answer your question. Please whisper " .. masterName .. ".",
                "My master, " .. masterName .. ", can help you with that.",
                "I am a shadow under the command of " .. masterName .. ". Whisper them.",
                "I am somebody else's helper, so I cannot help you! Please whisper " .. masterName .. " for help.",
                "I cannot answer that. Please whisper my master, " .. masterName .. ".",
                "Please whisper " .. masterName .. " for assistance, I am merely their shadow.",
                "I am not a player, though I might seem like one! Please whisper my master " .. masterName,
                "I am a bot, please whisper the player " .. masterName,
                "My creator is " .. masterName .. " please whisper them.",
                "Please direct all questions to " .. masterName .. ", I live under a strict regime of no fraternization.",
                "I am just a shadow, please whisper the player " .. masterName,
                "Let me relay that message from you over to " .. masterName .. "!",
                "I am a shadow, please whisper the player controlling me instead, " .. masterName,
                "Please whisper " .. masterName .. " for any questions.",
                "I wish I could reply, but I cannot! Whisper " .. masterName .. " instead.",
                "You must whisper " .. masterName .. ", I am sadly under strict surveillance."
            }
            local randomIndex = math.random(1, #masterResponses)
            bot:SendUnitWhisper(masterResponses[randomIndex], 0, player)
        end
    end
end

local function OnBotCommand(event, player, command)
    if command == "shadowsmenu" then
        ShadowsHello(player)
        return false
    end
    if string.find(command, "^playerb") then
        local guid = player:GetGUIDLow()
        if (string.find(command, "^playerbots bot add ") and (not addCmdTimer[guid] or (os.time() - addCmdTimer[guid] > 1))
        and (botSummonTime[guid] and (os.time() - botSummonTime[guid] < 5)))
        then
            addCmdTimer[guid] = os.time()
            return true
        end
        if string.find(command, "^playerbots bot remove ") then
            return true
        end
        return false
    end
end

local function OnPlayerMapEnter(event, map, player)
    local name = player:GetName()
    if isPlayerBot[player:GetName()] then return end
    local sameMap = "openWorld"
    Teleport(player, sameMap)
end

local function OnDisallowedZones(event, player, newZone, newArea)
    local name = player:GetName()
    if player:IsDead() then
        return
    end
    if isPlayerBot[player:GetName()] then return end
    if not botCount[name] or botCount[name] <= 0 then
        return
    end
    for _, zone in pairs(disallowedZones) do
        if newZone == zone or newArea == zone then
            local botsToRemove = {}

            if botCount[name] and botCount[name] > 0 then
                for i, botName in ipairs(activeBots[name]) do
                    table.insert(botsToRemove, botName)
                end
            end

            player:RegisterEvent(function(eventId, delay, repeats, player) 
                if #botsToRemove > 0 then 
                    for _, botName in ipairs(botsToRemove) do
                        local bot = GetPlayerByName(botName)
                        if bot then
                            bot:RemoveFromGroup()
                            player:RunCommand(".playerbots bot remove " .. botName)
                            table.remove(activeBots[name], i)
                            botCount[name] = botCount[name] - 1
                            print("Logging out bot in disallowed zone")
                        end
                    end
                    player:SendAreaTriggerMessage("You cannot use shadows in "..GetAreaName(player:GetAreaId())..".")
                end
            end, 100, 1)
        end
    end
end



SetActiveBots()
RegisterPlayerEvent(3, ShadowsLoginHook)
RegisterPlayerEvent(4, Logout)
RegisterPlayerEvent(19, OnWhisper)
RegisterPlayerEvent(20, OnGroupChat)
RegisterServerEvent(21, OnPlayerMapEnter)
RegisterPlayerEvent(27, OnDisallowedZones)
RegisterPlayerEvent(42, OnBotCommand)
RegisterPlayerGossipEvent(200, 2, ShadowsGossipSelect)
RegisterGroupEvent(3, LeaveGroup)
RegisterGroupEvent(5, DisbandGroup)
RegisterPacketEvent(0x075, 5, UninviteGroup)
RegisterPacketEvent(0x076, 5, UninviteGroupGUID)
RegisterPacketEvent(0x0C7, 5, PacketTeleDelay)
RegisterPacketEvent(0x0C9, 5, PacketMoveDelay)
RegisterPacketEvent(0x0CA, 5, PacketMoveDelay)
RegisterPacketEvent(0x0CB, 5, PacketMoveDelay)
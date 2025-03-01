
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
           {cmd = "add all loot", name = "Loot All", desc = "Your shadows will loot all items from defeated enemies. Say 'add all loot' in group chat or whisper to instruct shadow."},
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
           {cmd = "c", name = "Inventory", desc = "By whispering 'c' to a shadow, the shadow will whisper back its full inventory."},
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
   }
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
    
    if player:GetData("VIPTime") > os.time() then -- Increased bot limit for VIP
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
       
   elseif intid >= 20 and intid <= 27 then -- Category submenus
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
        
   -- elseif intid >= 300 and intid < 399 then -- Execute command
   --     local categoryIntid = math.floor((intid - 300) / 100) + 20
   --     local commandIndex = (intid - 300) % 100
   --     
   --     for _, category in pairs(commandCategories) do
   --         if category.intid == categoryIntid then
   --             local command = category.commands[commandIndex]
   --             if command then
   --                 player:RunCommand(".playerbots " .. command.cmd)
   --                 player:GossipComplete()
   --                 break
   --             end
   --         end
   --     end

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

    isPlayerBot[name]           = nil
    botsAvailable[accountId]    = nil
    activeBots[name]            = nil
    botCount[name]              = nil
    botMasters[guidlow]         = nil
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
            logoutEvent[uninvitedPlayer:GetName()] = uninvitedPlayer:RegisterEvent(CheckActiveBots, 100, 1)
        end
    end
end

function UninviteGroup(event, packet, player)
    local uninvitedPlayerName = packet:ReadString()
    local uninvitedPlayer = GetPlayerByName(uninvitedPlayerName)
    if uninvitedPlayer then
        if not logoutEvent[uninvitedPlayer:GetName()] then
            logoutEvent[uninvitedPlayer:GetName()] = uninvitedPlayer:RegisterEvent(CheckActiveBots, 100, 1)
        end
    end
end

local function LeaveGroup(event, group, guid, method, kicker, reason)
    local uninvitedPlayer = GetPlayerByGUID(guid)
    if uninvitedPlayer then
        if not logoutEvent[uninvitedPlayer:GetName()] then
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

local function OnWhisper(event, player, msg, Type, lang, receiver)
    local receiverName = receiver:GetName()
    local playerName = player:GetName()
    
    if activeBots[playerName] then
        for _, botName in ipairs(activeBots[playerName]) do
            if receiverName == botName then
                local isValidCommand = false
                for cmd, _ in pairs(validCommands) do
                    if string.match(msg:lower(), "^" .. cmd:lower()) then
                        isValidCommand = true
                        break
                    end
                end
                
                if not isValidCommand then
                    local bot = GetPlayerByName(botName)
                    bot:SendUnitWhisper("I don't understand what you mean! Please check Twiggy for commands I can react to.", 0, player)
                end
            end
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
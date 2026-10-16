
-- Shadows Configs Start

maxBotCount = 4
maxVIPCount = 9
minShadowsLevel = 15 -- Global var also referenced by Twiggy

local BOT_TELE_VISUAL   = 64446
local BotSummonCD       = 10 * 60 -- 10 minutes

local addCmdTimer       =   {}
-- Per-player logout/kick timers live in player:Data("ShadowsLogoutEv")
-- (masters hold "ShadowsLogoutEv:<bot>"), not in a file-local name-keyed table.
local disallowedZones   =   {4298}--, 4197, 3628, 3666} -- Scarlet Enclave (DK start area), Wintergrasp, Halaa
local AllowInBattlefield = false -- Default: False. Prevents usage of shadows in Wintergrasp.

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
   loot = {
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
    player:GossipClearMenu()
    local maxBotsForPlayer = maxBotCount
    local botCount = player:GetBotsCount()

    if not player:GetData("LoginTime") then player:SetData("LoginTime", os.time()) end

    player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_gizmo_02:40:40:-24:0|tHow to use shadows", 0, 2)

    if player:Data():Get("VIPTime") and player:Data():Get("VIPTime") > os.time() then -- Increased bot limit for VIP
        maxBotsForPlayer = maxVIPCount
    end
    
    player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_groupneedmore:40:40:-24:0|tAdd shadow (" .. botCount .. "/"..maxBotsForPlayer..")", 0, 10)
    if botCount > 0 then
        --player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_hunter_improvedtracking:40:40:-24:0|tCommand follow", 0, 3)
        --player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_ghoulfrenzy:40:40:-24:0|tCommand attack", 0, 4)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_unused2:40:40:-24:0|tSummon shadows", 0, 5, false, "Are you sure you want to summon your shadow(s) here?\n \nThis will induce a "..(BotSummonCD/60).."-minute summon cooldown.")
        player:GossipMenuAddItem(4, "|TInterface/PaperDollInfoFrame/UI-GearManager-Undo:40:40:-24:0|tRemove shadow", 0, 6)
    end
    player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_shadow_darksummoning:40:40:-24:0|tShadow bar settings", 0, 7)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:40:40:-24:0|tExit", 0, 1000)
    player:GossipSendMenu(12, player, 200)
end

local function ListActiveShadows(player)
    player:GossipClearMenu()

    player:GossipMenuAddItem(0, "|TInterface/PaperDollInfoFrame/UI-GearManager-Undo:40:40:-24:0|tActive shadows:\n \n ", 0, 6)

    local index = 0
    for _, bot in ipairs(player:GetBots()) do
        if bot then
            index = index + 1
            local menuText = string.format(
                "|TInterface/ICONS/ability_vehicle_loadselfcatapult:40:40:-24:0|t%s\n \n ",
                bot:GetName()
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
	local maxBotsForPlayer = maxBotCount
    
    if player:Data():Get("VIPTime") and player:Data():Get("VIPTime") > os.time() then -- Increased bot limit for VIP
        maxBotsForPlayer = maxVIPCount
    end
    
    if intid == 2 then -- Settings main menu
       player:GossipClearMenu()
       player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_gizmo_02:40:40:-24:0|tHow to use shadows\n \nBy reaching through the Twisting Nether, you are able to summon shadows of the other characters on your account.\n \nTo control and summon a shadow, it must be within ten levels of you.\n \nYour active shadows adjust to your faction.\n \nYou may control up to "..maxBotCount.." shadows at a time, or "..maxVIPCount.." shadows at a time if you have VIP.\n \nThe shadow bar offers quick access to most shadows features. See below for in-depth information on how to control your shadows.\n \n", 0, 2)
       
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
        if player:GetBotsCount() > 0 then
            player:Say("/p follow", 0)
        end
        player:SendAreaTriggerMessage("Your shadows are now following you.")
        ShadowsHello(player)
    elseif intid == 4 then -- Attack
        if player:GetBotsCount() > 0 then
            player:Say("/p attack", 0)
        end
        ShadowsHello(player)
    elseif intid == 5 then -- Summon: world thread pulls every bot
        player:RunCommand(".shadows summon")
        ShadowsHello(player)
    elseif intid == 6 then  -- Show list of active shadows to remove
        ListActiveShadows(player)
	elseif intid == 7 then
		if player:GetData("ShadowBarStatusChecked") then
			player:SendAddonMessage("ShadowsBar", "SETTINGS", 7, player)
		else
			player:SendAreaTriggerMessage("Your shadow bar settings are loading, please try again in a few seconds.")
			player:SendBroadcastMessage("Your shadow bar settings are loading, please try again in a few seconds.")
		end
		ShadowsHello(player)
    elseif intid >= 200 and intid < 299 then  -- Bot removal selection
        local selectedIndex = intid - 200
        local bots = {}
        for _, bot in ipairs(player:GetBots()) do
            if bot then table.insert(bots, bot:GetName()) end
        end

        if bots[selectedIndex] then
           local selectedBot = bots[selectedIndex]
           player:RunCommand(".shadows bot remove " .. selectedBot)
           ListActiveShadows(player)
        end
    elseif intid == 10 then  -- "Add bot" option
        local groupNames = {}
        for _, bot in ipairs(player:GetBots()) do
            if bot then groupNames[bot:GetName()] = true end
        end

        player:GossipClearMenu()
        player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_groupneedmore:40:40:-24:0|tAvailable shadows:\n \n ", 0, 10)

        local available = player:Data():Get("ShadowsAvailable")
        if available and available.AsTable then available = available:AsTable() end
        if available then
            local found = false
            for index, charInfo in ipairs(available) do
                if charInfo.name ~= player:GetName() then
                    local className = GetClassName(charInfo.class)
                    local raceName = GetRaceName(charInfo.race)
                    
                    local raceIcon = GetRaceIconPath(charInfo.race, charInfo.sex)
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
        if (not AllowInBattlefield) and (player:GetMapId() == 571) and (player:GetZoneId() == 4197) and IsWintergraspWarTime() then
            player:GossipComplete()
            player:SendAreaTriggerMessage("You cannot use shadows during active Wintergasp battles.")
            return
        end
        if player:GetLevel() < minShadowsLevel then
            player:SendAreaTriggerMessage("You need to be at least level ".. minShadowsLevel .. " to use shadows!")
            ShadowsHello(player)
            return
        end
        if player:GetBotsCount() < maxBotsForPlayer then
            local selectedIndex = intid - 100
            if addCmdTimer[guid] and not (GetCurrTime() - addCmdTimer[guid] > 300) then
                player:SendAreaTriggerMessage("You can't add shadows that fast!")
                ShadowsHello(player)
                return
            end
            
            local available = player:Data():Get("ShadowsAvailable")
            if available and available.AsTable then available = available:AsTable() end
            if available and available[selectedIndex] then
                local selectedChar = available[selectedIndex]
                player:Data():Set("ShadowsBotSummonTime", os.time())
                player:RunCommand(".shadows bot add " .. selectedChar.name) -- Add bot
                player:Data():Set("ShadowsDontKick:" .. selectedChar.name, os.time() + 3)
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

function SetShadowsBarData()
    local allGuids = {}

    -- Group players by their account ID and collect all GUIDs
    for _, player in pairs(GetPlayersInWorld()) do
        if player then
			player:SetData("ShadowBarStatusChecked", true)
            local guid = player:GetGUIDLow()
            table.insert(allGuids, guid)
        end
    end

    if #allGuids > 0 then
        local guidString = table.concat(allGuids, ",")
			
	    CharDBQueryAsync(
		    string.format("SELECT guid, data FROM character_custom_data WHERE guid IN (%s) AND type = 98", guidString),
		    function(result)
				if result then
					repeat
						local guid = result:GetUInt32(0)
						local data = result:GetString(1)
						if data == "ENABLED" then
				 		    local player = GetPlayerByGUID(GetPlayerGUID(guid))
				 		    if player then
								player:Data():Set("ShadowsBarData", true)
							end
		 		 	    end
		 		    until not result:NextRow()
		 	    end
		    end
	    )
    end
end

-- World
local function ShadowsLogin(event, player) -- Lazy persistent storage solution. Could probably just use characters table directly. Initially wanted cache-persistent value attached to world but not possible in standard AC ELUNA
    local guid = player:GetGUIDLow()
    
    if player:IsBot() then
        if player:HasAura(32113) then player:RemoveAura(32113) end
        
        if (player:GetClass() == 11) and not player:HasAura(57857) then player:AddAura(57857, player) end -- Fixes Druid shadows stuck on Rebirth without mats
        
        if not player:IsInGroup() then return end
        
        local group = player:GetGroup()
        
        local shadow = player:ToShadow()
        local master = shadow and shadow:GetMaster()

        if not master then return end
        
        if master:Data():Get("ShadowsBarData") then
            master:SendAddonMessage("ShadowsBar", "ENABLED", 7, master)
        else
            master:SendAddonMessage("ShadowsBar", "DISABLED", 7, master)
        end
        
        if not group:IsLeader(player:GetGUID()) then return end
        
        if player:IsInSameGroupWith(master) or player:IsInSameRaidWith(master) then
            group:SetLeader(master:GetGUID())
        end
    else
        player:SetData("LoginTime", os.time())
        
        CharDBQueryAsync("SELECT data FROM character_custom_data WHERE guid = "..guid.." AND type = 98", function(result)
            if result then
                local data = result:GetString(0)
                local player = GetPlayerByGUID(GetPlayerGUID(guid))
                if not player then return end
                if data == "ENABLED" then
                    player:Data():Set("ShadowsBarData", true)
                else
                    player:Data():Set("ShadowsBarData", false)
                end
            end
        end)
    end
end

-- World
local function LogoutOrSave(event, player)
    local accountId = player:GetAccountId()
    local guid = player:GetGUIDLow()
    local name = player:GetName()

	if event == 4 or event == 25 then
		if player:Data():Get("ShadowsBarData") then
			CharDBExecute("REPLACE INTO character_custom_data (guid, type, time, data) VALUES ("..guid..", 98, "..os.time()..", 'ENABLED')")
		else
			CharDBExecute("REPLACE INTO character_custom_data (guid, type, time, data) VALUES ("..guid..", 98, "..os.time()..", 'DISABLED')")
		end
	end
	
	if event == 25 then return end

    local shadow = player:ToShadow()
    local master = shadow and shadow:GetMaster()

    if master then
        if master:GetInstanceId() or player:GetInstanceId() then
            return -- Don't boot players' bots from group if in RHC as it can bug out the instance group
        end
        player:RemoveFromGroup()
    end
end

function CheckActiveBots(eventid, delay, repeats, uninvitedPlayer)
    local uninvitedPlayerName = uninvitedPlayer:GetName()
    local shadow = uninvitedPlayer:ToShadow()
    local master = shadow and shadow:GetMaster()
    if master then
        master:RegisterEvent(function(_, _, _, player)
            player:RunCommand(".shadows bot remove " .. uninvitedPlayerName)
            print("Bot removed: " ..uninvitedPlayerName.. ".")
            print("Leader: " ..player:GetName())
        end, 100, 1)
        uninvitedPlayer:Data():Set("ShadowsLogoutEv", nil)
    end
end

-- World
function UninviteGroupGUID(event, packet, player)
    local guid = packet:ReadGUID()
    local reason = packet:ReadString()
    local uninvitedPlayer = GetPlayerByGUID(guid)
    if uninvitedPlayer then
        if not uninvitedPlayer:Data():Get("ShadowsLogoutEv") then
			local ksh = uninvitedPlayer:ToShadow()
			local km = ksh and ksh:GetMaster()
			local kickGuard = km and km:Data():Get("ShadowsDontKick:" .. uninvitedPlayer:GetName())
			if kickGuard and kickGuard > os.time() then return end
			--print("shadows debug - uninvited GUID")
            uninvitedPlayer:Data():Set("ShadowsLogoutEv", uninvitedPlayer:RegisterEvent(CheckActiveBots, 100, 1))
        end 
    end
end

-- World
function UninviteGroup(event, packet, player)
    local uninvitedPlayerName = packet:ReadString()
    local uninvitedPlayer = GetPlayerByName(uninvitedPlayerName)
    if uninvitedPlayer then
        if not uninvitedPlayer:Data():Get("ShadowsLogoutEv") then
			local ksh = uninvitedPlayer:ToShadow()
			local km = ksh and ksh:GetMaster()
			local kickGuard = km and km:Data():Get("ShadowsDontKick:" .. uninvitedPlayer:GetName())
			if kickGuard and kickGuard > os.time() then return end
			--print("shadows debug - uninvited group")
            uninvitedPlayer:Data():Set("ShadowsLogoutEv", uninvitedPlayer:RegisterEvent(CheckActiveBots, 100, 1))
        end
    end
end

-- World
local function LeaveGroup(event, group, guid, method, kicker, reason)
    local uninvitedPlayer = GetPlayerByGUID(guid)
    if uninvitedPlayer then
        if not uninvitedPlayer:Data():Get("ShadowsLogoutEv") then
			local ksh = uninvitedPlayer:ToShadow()
			local km = ksh and ksh:GetMaster()
			local kickGuard = km and km:Data():Get("ShadowsDontKick:" .. uninvitedPlayer:GetName())
			if kickGuard and kickGuard > os.time() then return end
			--print("shadows debug - leaving group")
            uninvitedPlayer:Data():Set("ShadowsLogoutEv", uninvitedPlayer:RegisterEvent(CheckActiveBots, 100, 1))
        end
    end
end

-- World
local function DisbandGroup(event, group)
    for _, member in ipairs (group:GetMembers()) do
        local memberShadow = member:ToShadow()
        local master = memberShadow and memberShadow:GetMaster()
        if master then
            local botName = member:GetName()
            if not master:Data():Get("ShadowsLogoutEv:" .. botName) then
                master:Data():Set("ShadowsLogoutEv:" .. botName, master:RegisterEvent(function(_, _, _, player)
					local kickGuard = player:Data():Get("ShadowsDontKick:" .. botName)
					if kickGuard and kickGuard > os.time() then return end
                    player:RunCommand(".shadows bot remove " .. botName)
                    print("Removing "..botName.." from disbanded group")
                    player:Data():Set("ShadowsLogoutEv:" .. botName, nil)
                end, 100, 1))
            end
        end
    end
end

-- World
local function Teleport(player, sameMap)
    if player:IsBot() then return end
    if not player:IsInGroup() then return end
    if player:IsDead() then return end
    if player:GetBotsCount() == 0 then return end
    if os.time() <= (player:Data():Get("ShadowsLastTele") or 0) then return end
    
    if ((player:GetMapId() == 0 or player:GetMapId() == 1 -- Kalimdor, Eastern Kingdoms
    or player:GetMapId() == 530 or player:GetMapId() == 571) -- Outlands, Northrend
    and (sameMap == "yes"))
    or (player:InArena() or player:InBattleground()) -- PVP exclusions from teleport
    then return end
    
    local myBots = {}
    for _, bot in ipairs(player:GetBots()) do
        if bot then myBots[bot:GetName()] = true end
    end

    for _, bot in ipairs(player:GetMap():GetPlayers()) do
        if bot:IsBot() and myBots[bot:GetName()] then
            if not player:IsInCombat() then
                if (bot:GetHealth() == 0) and not bot:HasAura(8326) then -- Stops unreleased ghost corpses from being teleported
                    return
                end
                if not bot:IsWithinLoS(player) and
                (((bot:GetZ() < player:GetZ() - 20) or (bot:GetZ() > player:GetZ() + 20) or (player:GetDistance(bot) > 100)))
                or
                (player:GetDistance(bot) > 400)
                then
                    if bot:HasAura(8326) then RunCommand("revive "..bot:GetName()) end -- handle auto revive of bots on enter instance/raid
                    bot:Teleport(player:GetMapId(), player:GetX() + math.random(-1, 1), player:GetY() + math.random(-1, 1), player:GetZ(), player:GetO() + math.random(-6, 6))
                    print("Teleporting bot "..bot:GetName().." to "..player:GetName())
                end
            end
        end
    end
    if sameMap ~= "yes" and not player:IsInCombat() then
        for _, shadow in ipairs(player:GetBots()) do
            if shadow and shadow:GetMapId() ~= player:GetMapId() then
                shadow:Teleport(player:GetMapId(), player:GetX() + math.random(-1, 1), player:GetY() + math.random(-1, 1), player:GetZ(), player:GetO() + math.random(-6, 6))
                print("Teleporting bot "..shadow:GetName().." to "..player:GetName())
            end
        end
    end
    player:Data():Set("ShadowsLastTele", os.time() + 1)
end

-- World
local function PacketTeleDelay(_, _, player)
    if player:IsBot() then return end
    local sameMap = "openWorld"
    player:RegisterEvent(function(_, _, _, player)
        Teleport(player, sameMap)
    end, 1000, 1)
end

-- World
local function PacketMoveDelay(_, _, player)
    if player:IsBot() then return end
    local sameMap = "yes"
    player:RegisterEvent(function(_, _, _, player)
        Teleport(player, sameMap)
    end, 1000, 1)
end

-- World
local function OnGroup(event, player, msg, Type, lang, group)
    if msg ~= "repair" then return end
    
	player:RegisterEvent(function(e, d, r, player)
		if not player then return end
		for _, member in ipairs(player:GetBots()) do
			if member and member:IsInSameGroupWith(player) then
				member:SendUnitWhisper("Repairing!", 0, player)
			end
		end
	end, 10)
end

local botWhisperResponses = {
    {
        keywords = {"hello", "hi", "hey", "greetings", "good morning", "good afternoon", "good evening", "howdy", "hiya", "what's up", "yo", "sup", "how are you", "how's it going", "nice to see you", "welcome", "salutations", "good day", "ahoy", "aloha", "bonjour", "hola", "ciao", "o/", "o7"},
        replies = {"Hey! :)", "Hiya!", "What's up?", "Greetings, traveler!", "Hello there!", "Hi!", "Howdy partner!", "Good to see you!", "Hey, how are you?", "Good day!", "Hey there!", "Hello friend!", "Yo!", "Sup!", "How's it going?", "Nice to see you too!", "Welcome!", "Ahoy matey!", "Aloha!", "Bonjour!", "Hola!", "Ciao!", "o/!", "o7!"}
    },
    {
        keywords = {"joke", "funny", "laugh", "haha", "hehe", "lol", "rofl", "lmao", "kek", "heh"},
        replies = {
            "Why don't scientists trust atoms? Because they make up everything!",
            "Parallel lines have so much in common. It's a shame they'll never meet.",
            "Why did the scarecrow win an award? Because he was outstanding in his field!",
            "I told my wife she was drawing her eyebrows too high. She looked surprised.",
            "Why did the bicycle fall over? Because it was two tired!",
            "Want to hear a joke about paper? Never mind, it's tearable.",
            "I'm reading a book on anti-gravity. It's impossible to put down!",
            "Why did the golfer wear two pairs of pants? In case he got a hole-in-one.",
            "What do you call a fish with no eyes? Fsh!",
            "What do you call a fake noodle? An impasta.",
            "Why don't eggs tell jokes? They'd crack each other up.",
            "How do you make an octopus laugh? With ten-tickles!",
            "Why did the math book look sad? Because it had too many problems.",
            "What do you call a bear with no teeth? A gummy bear.",
            "Why don't skeletons fight each other? They don't have the guts.",
            "What do you get if you drop a piano down a mineshaft? A flat miner.",
            "Why did the can crusher quit his job? Because it was soda pressing.",
            "Want to hear a construction joke? I'm still working on it."
        }
    },
    {
        keywords = {"quest", "mission", "task", "objective", "adventure", "journey", "challenge"},
        replies = {"Ready for another adventure!", "Let's embark on a new quest!", "What mission are you on today?", "Got a challenging task ahead?", "Time to set some new goals!", "Excited for the journey ahead!", "Let's tackle that dungeon!", "What's your next objective?"}
    },
    {
        keywords = {"boss", "kill", "defeat", "victory", "triumph", "conquer"},
        replies = {"Congratulations on the boss kill!", "Great job defeating the boss!", "Victory is ours!", "We've triumphed!", "Another boss conquered!", "Well done on overcoming the challenge!", "You're a true champion!", "Epic victory!"}
    },
    {
        keywords = {"lore", "story", "history", "legend", "myth", "tale", "saga"},
        replies = {"Interested in the lore of Azeroth?", "The legends of this world are vast and intriguing.", "The stories of Azeroth are endless.", "What tale would you like to hear?", "The history of this land is fascinating."}
    },
    {
        keywords = {"gear", "equipment", "armor", "weapon", "upgrade", "loot", "enchant", "gem"},
        replies = {"Need some advice on your gear?", "Let's talk about your equipment!", "Looking to upgrade?", "What weapon are you using?", "Got any new loot to show off?", "Need help with enchants or gems?"}
    },
    {
        keywords = {"class", "spec", "talent", "ability", "rotation", "build", "playstyle"},
        replies = {"Need tips for your class?", "Let's discuss your spec!", "What talents are you using?", "What's your rotation like?", "Need help with your build?", "What's your playstyle?"}
    },
    {
        keywords = {"pvp", "arena", "battleground", "duel", "honor"},
        replies = {"Ready for some PvP action?", "Let's discuss arena strategies!", "What's your battleground of choice?", "Need tips for dueling?", "What's your PvP rating?"}
    },
    {
        keywords = {"dungeon", "raid", "instance", "heroic"},
        replies = {"I've heard tales of that place!", "A challenging endeavor awaits!", "I've explored many such places.", "Many adventurers have met their end in there.", "Do you think we can conquer it?", "I wonder what awaits us inside."}
    },
    {
        keywords = {"mount", "ride", "flying"},
        replies = {"Need help with your mount collection?", "What's your favorite ride?", "What mounts are you missing?", "I've heard of some rare ones around here."}
    },
    {
        keywords = {"guild", "leader", "officer", "recruitment"},
        replies = {"Need help with guild management?", "Let's talk about your guild!", "What's your role in the guild?", "Need tips for recruitment?"}
    },
    {
        keywords = {"profession", "crafting", "gathering", "recipe"},
        replies = {"Need help with your professions?", "Let's talk about crafting!", "What gathering skills are you using?", "What's your profession leveling strategy?"}
    },
    {
        keywords = {"weather", "raining", "sunny", "cloudy", "snowing"},
        replies = {"Looks like typical Azeroth weather to me!", "I've seen worse in Northrend.", "At least it's not raining elementals.", "Could be worse, could be a Forsaken winter.", "I prefer the weather in Nagrand myself."}
    },
    {
        keywords = {"i told you", "you should know", "obviously", "clearly", "everyone knows", "it's common sense", "for the last time", "how many times"},
        replies = {"Oh, I must have missed the memo.", "Thanks for the condescension. Very helpful.", "My crystal ball was in the shop that day.", "Sorry my telepathy wasn't working.", "Couldn't hear you from that high horse.", "Please continue telling me what I should know.", "I'll check my omniscience settings."}
    },
    {
        keywords = {"shit", "ass", "fuck", "bitch", "bastard", "cunt", "dick", "prick", "moron", "idiot", "stupid", "dumb", "jerk", "twat", "cock", "wanker", "slut", "douchebag", "asshole", "fucker", "crap", "tosser", "scumbag"},
        replies = {"I wish you would treat me better!", "Is this how you treat yourself?", "Please refrain from using such language.", "That's not very nice.", "I'd appreciate it if you'd be more respectful.", "Let's keep the conversation civil.", "I don't deserve to be spoken to like that."}
    },
}

-- World
local function OnWhisper(event, player, msg, Type, lang, receiver)
    if not player:IsBot() then return end
    
    local receiverName = receiver:GetName()
    local playerName = player:GetName()

    if not receiver:IsBot() then return end

    local receiverShadow = receiver:ToShadow()
    local receiverMaster = receiverShadow and receiverShadow:GetMaster()
    if not receiverMaster then return end

    local masterName = receiverMaster:GetName()

    if playerName ~= masterName then
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
            "I am somebody else's helper! Please whisper " .. masterName .. " for help.",
            "I am not a player, though I might seem like one! Please whisper my master " .. masterName,
            "I am a bot, please whisper the player " .. masterName,
            "Please direct all questions to " .. masterName .. ", I live under a strict regime of no fraternization.",
            "I am just a shadow, please whisper the player controlling me instead, " .. masterName,
        }
        receiver:SendUnitWhisper(masterResponses[math.random(#masterResponses)], 0, player)
        return
    end

    local msgLower = msg:lower()

    for _, category in pairs(commandCategories) do
        for _, cmd in ipairs(category.commands) do
            local clean = cmd.cmd:gsub("%s*<.+>%s*$", ""):lower()
            if msgLower:match("^" .. clean .. "%s*$") or msgLower:match("^" .. clean .. "%s+") then
                return
            end
        end
    end

    if msg == "repair" then
        receiver:SendUnitWhisper("Repairing!", 0, player)
        return
    end

    if msgLower:match("co%s+.+") or msgLower:match("nc%s+.+") or msgLower:match("do%s+.+") then
        return
    end

    local bot = receiver

    for _, category in ipairs(botWhisperResponses) do
        for _, keyword in ipairs(category.keywords) do
            if msgLower:find(keyword, 1, true) then
                bot:SendUnitWhisper(category.replies[math.random(#category.replies)], 0, player)
                return
            end
        end
    end

    local fallback = {
        "That command is unfamiliar to me. Perhaps Twiggy can assist you.",
        "I'm not sure what you're asking. Consult Twiggy for a list of valid commands.",
        "My programming doesn't include that command. Please ask Twiggy for guidance.",
        "I'm afraid I don't recognize that. Twiggy has the commands I understand.",
        "I can't process that. For a list of commands, talk to Twiggy.",
        "That doesn't compute. Check Twiggy for a command reference.",
        "I don't understand. Twiggy knows what I can do.",
        "I'm unable to perform that action. Twiggy can tell you what I'm capable of.",
    }
    bot:SendUnitWhisper(fallback[math.random(#fallback)], 0, player)
end

-- World
local function OnBotCommand(event, player, command)
    if command == "shadowsmenu" then
        local accountId = player:GetAccountId()
        local rows = {}
        for _, char in ipairs(GetCharacterCache()) do
            if char.accountId == accountId then
                table.insert(rows, {name = char.name, race = char.race, class = char.class, level = char.level, sex = char.sex})
            end
        end
        table.sort(rows, function(a, b) return a.level > b.level end)
        player:Data():Set("ShadowsAvailable", rows)
        ShadowsHello(player)
        return false
    end
    if command == "shadows summon" then
        local cd = player:Data():Get("ShadowsSummonCD") or 0
        if cd >= os.time() then
            player:SendAreaTriggerMessage("Your shadows summon is on cooldown for " .. math.floor((cd - os.time()) / 60) .. " minutes and " .. ((cd - os.time()) % 60) .. " seconds.")
            return true
        end
        if player:GetBotsCount() == 0 then
            player:SendAreaTriggerMessage("You have no active shadows.")
            return true
        end
        for _, bot in ipairs(player:GetBots()) do
            if bot then
                bot:Teleport(player:GetMapId(), player:GetX() + math.random(-3, 3), player:GetY() + math.random(-3, 3), player:GetZ() + math.random(0, 0.1), player:GetO() + math.random(-6, 6))
                player:CastSpell(bot, BOT_TELE_VISUAL, true)
                bot:RegisterEvent(function(eventId, delay, repeats, b)
                    if b then b:CastSpell(b, BOT_TELE_VISUAL, true) end
                end, 500, 1)
            end
        end
        player:Data():Set("ShadowsSummonCD", os.time() + BotSummonCD)
        return true
    end
    if string.find(command, "^shadows bot ") then
        local guid = player:GetGUIDLow()
        local name = player:GetName()
        
        if (string.find(command, "^shadows bot add ")
        and (player:Data():Get("ShadowsBotSummonTime") and (os.time() - player:Data():Get("ShadowsBotSummonTime") < 5)))
        then
            local selectedChar = string.match(command, "^shadows bot add (.+)$")

            local exists = false
            for _, bot in ipairs(player:GetBots()) do
                if bot and bot:GetName() == selectedChar then
                    exists = true
                    return false
                end
            end

            if player:GetBotsCount() + 1 > 4 then
                local shadowsGroup = player:GetGroup()
                if shadowsGroup then
                    shadowsGroup:ConvertToRaid()
                end
            end

            player:RegisterEvent(function(e, d, r, player)
                local bot = GetPlayerByName(selectedChar)
                if not bot then return end

                local botGroup = bot:GetGroup()
                local playerGroup = player:GetGroup()

                if botGroup and playerGroup and botGroup ~= playerGroup then
                    bot:RemoveFromGroup()
                    player:GroupInvite(bot)
                elseif botGroup and not playerGroup then
                    bot:RemoveFromGroup()
                    player:GroupInvite(bot)
                end
            end, 200, 1)

            return true
        end
        
        if string.find(command, "^shadows bot remove ") then
            local selectedChar = string.match(command, "^shadows bot remove (.+)$")
            
            local selectedCharObj = GetPlayerByName(selectedChar)
            if selectedCharObj then selectedCharObj:RemoveEvents() end

            return true
        end
        return false
    end

	if command == "shadowslogin" then
		if player:GetData("LoginTime") and (player:GetData("LoginTime") < os.time() + 5) then
			local accountId = player:GetAccountId()
			local name = player:GetName()
			local characters = {}
			for _, char in ipairs(GetCharacterCache()) do
				if char.accountId == accountId and char.name ~= name then
					table.insert(characters, char.name)
				end
			end
			player:SendAddonMessage("Shadows", table.concat(characters, ", "), 7, player)
		end
		return false
	end
	
	if command == "shadowsbaron" then
		player:Data():Set("ShadowsBarData", true)
		player:SendBroadcastMessage("Automatic shadows bar enabled.")
		return false
	elseif command == "shadowsbaroff" then
		player:Data():Set("ShadowsBarData", false)
		player:SendBroadcastMessage("Automatic shadows bar disabled.")
		return false
	elseif command == "shadowsbarstatus" then
		player:SetData("ShadowBarStatusChecked", true)
		if not player:IsInGroup() then
			if player:Data():Get("ShadowsBarData") then
				player:SendAddonMessage("ShadowsBar", "OPEN", 7, player)
			else
				player:SendAddonMessage("ShadowsBar", "CLOSED", 7, player)
			end
		else
			local group = player:GetGroup()
			local groupPlayers = group:GetMembers()
			local foundBot = false
			for _, groupMember in ipairs(groupPlayers) do
				local memberShadow = groupMember:ToShadow()
				local memberMaster = memberShadow and memberShadow:GetMaster()
				if memberMaster and memberMaster:GetName() == player:GetName() and player:Data():Get("ShadowsBarData") then
					player:SendAddonMessage("ShadowsBar", "ENABLED", 7, player)
					foundBot = true
					break
				end
			end
			if not foundBot then
				if player:Data():Get("ShadowsBarData") then
					player:SendAddonMessage("ShadowsBar", "OPEN", 7, player)
				else
					player:SendAddonMessage("ShadowsBar", "CLOSED", 7, player)
				end
			end
		end
		return false
	end

	if string.find(command, "attemptaddbot ") then

	    local bots = string.match(command, "attemptaddbot (.+)$")
	    local botNames = {}
		local maxBotsForPlayer = maxBotCount
	   
	    for botName in string.gmatch(bots, "([^,]+)") do
		    botName = string.gsub(botName, "^%s*(.-)%s*$", "%1")
			table.insert(botNames, botName)
	    end
		
	   
	   if player:IsInGroup() then
		   
		   if player:Data():Get("VIPTime") and player:Data():Get("VIPTime") > os.time() then
				maxBotsForPlayer = maxVIPCount
		   end
		   
		   if #botNames > maxBotsForPlayer then
			   player:SendBroadcastMessage("We could not log in your shadows as the total shadows in your group exceeds your limit of "..maxBotCount..".")
			   return false
		   end
		   
		   local playerGuid = player:GetGUIDLow()
		   
		   for _, botName in ipairs(botNames) do
		 	   player:Data():Set("ShadowsBotSummonTime", os.time())
		 	   player:Data():Set("ShadowsDontKick:" .. botName, os.time() + 3)
		 	   player:RunCommand(".shadows bot add " .. botName)
		    end
	    end
	    return false
	end

end

local function OnPlayerMapEnter(event, map, player)
    if player:IsBot() then return end
    local sameMap = "openWorld"
    Teleport(player, sameMap)
end

local function OnDisallowedZones(event, player, newZone, newArea)
    if player:IsDead() then
        return
    end
    if player:IsBot() then return end
    if player:GetBotsCount() <= 0 then
        return
    end
    for _, zone in pairs(disallowedZones) do
        if newZone == zone or newArea == zone then
            local botsToRemove = {}

            if player:GetBotsCount() > 0 then
                for _, bot in ipairs(player:GetBots()) do
                    if bot then table.insert(botsToRemove, bot:GetName()) end
                end
            end

            player:RegisterEvent(function(eventId, delay, repeats, player)
                if not player then return end
                if #botsToRemove > 0 then
                    local bots = player:GetBots()
                    for _, botName in ipairs(botsToRemove) do
                        for _, bot in ipairs(bots) do
                            if bot and bot:GetName() == botName then
                                bot:RemoveFromGroup()
                                break
                            end
                        end
                        player:RunCommand(".shadows bot remove " .. botName)
                    end
                    player:SendAreaTriggerMessage("You cannot use shadows in "..GetAreaName(player:GetAreaId())..".")
                end
            end, 100, 1)
        end
    end
end

local function DismissWintergraspShadows(event, battleId)
    if battleId == 1 and not AllowInBattlefield then
        for _, player in pairs(GetPlayersInWorld()) do
            if (player:GetMapId() == 571) and (player:GetZoneId() == 4197) and not player:IsBot() and player:GetBotsCount() > 0 then
                local removed = false
                for _, bot in ipairs(player:GetBots()) do
                    if bot then
                        bot:RemoveFromGroup()
                        player:RunCommand(".shadows bot remove " .. bot:GetName())
                        removed = true
                    end
                end
                if removed then
                    player:SendBroadcastMessage("Shadows are not permitted during active Wintergrasp battles. Your shadows have logged off.")
                    player:SendAreaTriggerMessage("Shadows are not permitted during active Wintergrasp battles. Your shadows have logged off.")
                end
            end
        end
    end
end

local function OnGroupChangeLeader(event, packet, player)
    if not player:IsInGroup() then return end
    
    local group = player:GetGroup()
    
    for _, player in ipairs (group:GetMembers()) do
        local memberShadow = player:ToShadow()
        if memberShadow then

            local master = memberShadow:GetMaster()

            if not master then return end
            if group:IsLeader(player:GetGUID()) then
                if player:IsInSameGroupWith(master) or player:IsInSameRaidWith(master) then
                    
                    player:RegisterEvent(function(e, d, r, player)
                        local group = player:GetGroup()
                        if not group then return end

                        local ms = player:ToShadow()
                        local master = ms and ms:GetMaster()
                        if not master then return end
                        group:SetLeader(master:GetGUID())

                    end, 1000)
                    
                    break
                end
            end
        end
    end
end

if not (GetStateMapId() == -1) then
    -- Player map stuff
    RegisterPlayerEvent(27, OnDisallowedZones)

    -- Passes map obj directly in hook, as opposed to RegisterPlayerEvent:OnEnterMap
    RegisterServerEvent(21, OnPlayerMapEnter)

    -- Shadows menu
    RegisterPlayerGossipEvent(200, 2, ShadowsGossipSelect)
end

if GetStateMapId() == -1 then
    -- Shadows bar vars
    SetShadowsBarData()
    
    -- Player world stuff
    RegisterPlayerEvent(3, ShadowsLogin)
    RegisterPlayerEvent(4, LogoutOrSave)
    RegisterPlayerEvent(19, OnWhisper)
    RegisterPlayerEvent(20, OnGroup)
    RegisterPlayerEvent(25, LogoutOrSave)
    RegisterPlayerEvent(42, OnBotCommand)
    
    -- Packet stuff
    RegisterPacketEvent(0x075, 5, UninviteGroup)
    RegisterPacketEvent(0x076, 5, UninviteGroupGUID)
    RegisterPacketEvent(0x0C7, 5, PacketTeleDelay)
    RegisterPacketEvent(0x0C9, 5, PacketMoveDelay)
    RegisterPacketEvent(0x0CA, 5, PacketMoveDelay)
    RegisterPacketEvent(0x0CB, 5, PacketMoveDelay)
    RegisterPacketEvent(0x079, 7, OnGroupChangeLeader)
    
    -- Group stuff
    RegisterGroupEvent(3, LeaveGroup)
    RegisterGroupEvent(5, DisbandGroup)

    RegisterBattlefieldEvent(1, DismissWintergraspShadows)
end
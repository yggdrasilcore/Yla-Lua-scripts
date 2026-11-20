-- Azshara Mall-only script (mall map 37).
if GetStateMapId() ~= 37 then return end
local hasDialogueEvent = {}
local lastGreeting = {}
local morphEventStarted = {}
local morphEventActive = {}

local APPRENTICE_ENTRY = 110007
local MASTER_ENTRY = 110008

local ProfessionMessages = {
    "Did you know that alchemy was one of the precursors to modern chemistry?",
    "The art of blacksmithing dates back to the Bronze Age!",
    "Engineering combines innovation with practical application.",
    "Herbalism requires both knowledge of plants and careful cultivation.",
    "Mining has been essential to civilizational progress throughout history.",
    "The earliest known textiles date back over 30,000 years.",
    -- Add more messages as desired
}

local function OnPeriodicTalk(event, delay, calls, creature)
    creature:SendUnitSay(ProfessionMessages[math.random(#ProfessionMessages)], 0)
    creature:PerformEmote(1)
end

local function ProfDialogue(event, creature, who)
    if who:ToPlayer() then
        if creature:GetDistance(who) > 7 or not creature:IsWithinLoS(who) then
            return
        end
        
        if not hasDialogueEvent[creature:GetGUIDLow()] then
            creature:RegisterEvent(OnPeriodicTalk, 120000, 0)
            hasDialogueEvent[creature:GetGUIDLow()] = true
        end
        if not lastGreeting[creature:GetGUIDLow()] then
            print("Setting last greeting")
            lastGreeting[creature:GetGUIDLow()] = os.time() + 90
            creature:SendUnitSay("Greetings, "..who:GetName()..". Talk to me if you need guidance with your professions.", 0)
            creature:PerformEmote(1)
            return -- Save some processing by returning early
        end
        if (lastGreeting[creature:GetGUIDLow()] and (lastGreeting[creature:GetGUIDLow()] < os.time())) then
            lastGreeting[creature:GetGUIDLow()] = os.time() + 90
            creature:SendUnitSay("Greetings, "..who:GetName()..". Talk to me if you need guidance with your professions.", 0)
            creature:PerformEmote(1)
        end
    end
end

local papaGreeting = os.time()
local twiggyBusyMama = {}
local twiggyBusyPapa = {}

local function PapaDialogue(event, papa, twiggy)
    if papa:GetDistance(twiggy) > 7 or not (papa:IsWithinLoS(twiggy)) then
        return
    end
    if twiggy:GetName() == "Twiggy" and papaGreeting < os.time() then
        papaGreeting = os.time() + 90
        papa:SendUnitSay("Greetings, my child!", 0) 
        papa:SendUnitEmote("Papa Twig waves at Twiggy.") 
        papa:PerformEmote(3)
        twiggyBusyPapa[twiggy:GetGUIDLow()] = true
        
        papa:RegisterEvent(function(eventid, delay, repeats, papa)
            local twiggy = papa:GetNearestCreature(50, 23198)
            if twiggy and not twiggyBusyMama[twiggy:GetGUIDLow()] then
                twiggyBusyPapa[twiggy:GetGUIDLow()] = nil
                twiggy:SendUnitSay("Hello, papa!", 0)
                twiggy:SendUnitEmote("Papa Twig waves at Papa Twig.") 
                twiggy:PerformEmote(3)
            end
        end, 2000)
        
    end
end

local mamaGreeting = os.time()

local function MamaDialogue(event, mama, twiggy)
    if mama:GetDistance(twiggy) > 7 or not (mama:IsWithinLoS(twiggy)) then
        return
    end
    if twiggy:GetName() == "Twiggy" and mamaGreeting < os.time() then
        mamaGreeting = os.time() + 90
        mama:SendUnitSay("Oh, it's so nice to see my little Twiggy again!", 0) 
        mama:SendUnitEmote("Mama Twig waves at Twiggy.") 
        mama:PerformEmote(3)
        twiggyBusyMama[twiggy:GetGUIDLow()] = true
        
        mama:RegisterEvent(function(eventid, delay, repeats, mama)
            local twiggy = mama:GetNearestCreature(50, 23198)
            if twiggy and not twiggyBusyPapa[twiggy:GetGUIDLow()] then
                twiggyBusyMama[twiggy:GetGUIDLow()] = nil
                twiggy:SendUnitSay("Hello, mama!", 0)
                twiggy:SendUnitEmote("Twiggy waves at Mama Twig.") 
                twiggy:PerformEmote(3)
            end
        end, 3000)
    end
end

local guardCooldowns = {}

local guardDialogue = {
    "Stay safe, citizen.",
    "Keep to the path, traveler.",
    "Hello, %s! Up to no trouble, I hope?",
    "Got to keep the streets safe!",
    "Nothing to report today.",
    "Mind the curfew after dark.",
    "No troublemaking in my patrol zone.",
    "I've got my eye on you, stranger.",
    "Beautiful day for patrol duty.",
    "Watch your step around here.",
    "Best keep your weapons sheathed.",
    "See anything suspicious?",
    "I'm watching for suspicious activity.",
    "These streets don't patrol themselves.",
    "Stand back, citizen.",
    "Move along now.",
    "Keep your hands where I can see them.",
    "Report any suspicious activity.",
    "No lollygagging on my watch.",
    "I took an oath to protect these streets."
}

local function PatrolDialogue(event, patrol, who)
    if who:ToPlayer() and patrol:GetDistance(who) < 7 and patrol:IsWithinLoS(who) then
        local guid = patrol:GetGUIDLow()
        
        if guardCooldowns[guid] and (os.time() - guardCooldowns[guid]) then
            return -- No action if same guard had a dialogue in the last 45 sec
        end
        
        if math.random(1, 100) <= 15 then -- Chance to say anything, prevents spam
            local dialogue = guardDialogue[math.random(1, #guardDialogue)]
            dialogue = string.format(dialogue, who:GetName())
            patrol:SendUnitSay(dialogue, 0)
            patrol:PerformEmote(1)
            guardCooldowns[guid] = os.time() + 45
        end
    end
end

local function HunterDialogue(event, creature, who)
    if who:ToPlayer() and creature:GetDistance(who) < 7 and who:GetClass() == 3 and creature:IsWithinLoS(who) then
        if who:HasSpell(19577) then
            return
        end
        if not lastGreeting[creature:GetGUIDLow()] and (lastGreeting[creature:GetGUIDLow()] and (lastGreeting[creature:GetGUIDLow()] < os.time())) then
            lastGreeting[creature:GetGUIDLow()] = os.time() + 90
            creature:SendUnitSay("Greetings, "..who:GetName()..". Talk to me if you are interested in exotic beast master pets.", 0)
            creature:PerformEmote(1)
        end
    end
end

local function XPDialogue(event, creature, who)
    if creature:GetMapId() == 37 then
        if who:ToPlayer() and creature:GetDistance(who) < 10 and creature:IsWithinLoS(who) then
            if who:GetLevel() == 80 then return end
            if not lastGreeting[creature:GetGUIDLow()] or (lastGreeting[creature:GetGUIDLow()] and (lastGreeting[creature:GetGUIDLow()] < os.time())) then
                lastGreeting[creature:GetGUIDLow()] = os.time() + 90
                creature:SendUnitSay("I can change the pace of your experience in Azeroth, "..who:GetName()..". Talk to me to learn more.", 0)
                creature:PerformEmote(1)
            end
        end
    end
end

local function DeadTwig(event, creature, who)
    if who:ToPlayer() and creature:GetDistance(who) < 10 and creature:IsWithinLoS(who) then
        if not (who:GetClass() == 6) then return end -- Only proceed if DK
        if not lastGreeting[creature:GetGUIDLow()] or (lastGreeting[creature:GetGUIDLow()] and (lastGreeting[creature:GetGUIDLow()] < os.time())) then
            lastGreeting[creature:GetGUIDLow()] = os.time() + 90
            creature:SendUnitSay("There's a deep fire smoldering within me, Death Knight "..who:GetName()..". It allows you to Runeforge on my stumps.", 0)
            creature:PerformEmote(1)
        end
    end
end

local function InstanceDialogue(event, creature, who)
    if who:ToPlayer() and creature:GetDistance(who) < 10 and creature:IsWithinLoS(who) then
        if not lastGreeting[creature:GetGUIDLow()] or (lastGreeting[creature:GetGUIDLow()] and (lastGreeting[creature:GetGUIDLow()] < os.time())) then
            lastGreeting[creature:GetGUIDLow()] = os.time() + 90
            if IsVIP(who) then
                creature:SendUnitSay("Psst, "..who:GetName().."! I can reset your instance lockouts through mysterious magic. VIPs like you get two free resets per week!", 0)
            else
                creature:SendUnitSay("Psst, "..who:GetName().."! I can reset your instance lockouts through mysterious magic. First reset per week is free!", 0)
            end
            creature:PerformEmote(1)
            return -- Save some processing by returning early
        end
    end
end

local function PetRenameDialogue(event, creature, who)
    if who:ToPlayer() and creature:GetDistance(who) < 10 and creature:IsWithinLoS(who) then
        if not (who:GetClass() == 9) then return end
        if not lastGreeting[creature:GetGUIDLow()] or (lastGreeting[creature:GetGUIDLow()] and (lastGreeting[creature:GetGUIDLow()] < os.time())) then
            lastGreeting[creature:GetGUIDLow()] = os.time() + 90
            creature:SendUnitSay("Have you ever wanted to rename your demons, "..who:GetName().."? I can help you with that.", 0)
            creature:PerformEmote(1)
        end
    end
end

local function FlightTrainerDialogue(event, creature, who)
    if who:ToPlayer() and creature:GetDistance(who) < 10 and creature:IsWithinLoS(who) then
        if not lastGreeting[creature:GetGUIDLow()] or (lastGreeting[creature:GetGUIDLow()] and (lastGreeting[creature:GetGUIDLow()] < os.time())) then
            lastGreeting[creature:GetGUIDLow()] = os.time() + 90
            local name = who:GetName()
            if creature:GetNearestCreature(50, 190095) then
                creature:SendUnitSay("I wish I could fly as well as the Twig of Flight. I even trained him! Can you believe that, "..name.."?", 0)
            else
                creature:SendUnitSay("Are you looking to learn flight paths? The Twig of Flight is out for a flight now. May I assist in the meantime, "..who:GetName().."?", 0)
            end
            creature:PerformEmote(1)
            local wepname
            creature:RegisterEvent(function(eventid, delay, repeats, creature)
                local wep = creature:GetNearestCreature(20, 95025)
                if wep then
                    wepname = wep:GetName()
                    wep:SendUnitSay("Pfft. What good is flight in a world of warfare? Come to me to acquire real knowledge, "..name..".", 0)
                    wep:SendUnitEmote(wepname.." violently strikes the air.")
                    wep:PerformEmote(35)
                end
            end, 16000)
            creature:RegisterEvent(function(eventid, delay, repeats, creature)
                creature:SendUnitSay("Haha, "..wepname.."! Always so violent!", 0)
                creature:SendUnitEmote(creature:GetName().." laughs.")
                creature:PerformEmote(11)
            end, 27000)
        end
    end
end

local function MogDialogue(event, creature, who)
    if who:ToPlayer() and creature:GetDistance(who) < 12 and creature:IsWithinLoS(who) then
        if not lastGreeting[creature:GetGUIDLow()] or (lastGreeting[creature:GetGUIDLow()] and (lastGreeting[creature:GetGUIDLow()] < os.time())) then
            lastGreeting[creature:GetGUIDLow()] = os.time() + 90
            creature:SendUnitSay("Greetings, "..who:GetName()..". My colleague and I can assist you in altering your appearance in the most incredible ways.", 0)
            creature:PerformEmote(1)
        end
    end
end

local function Guide(event, creature, who)
    if who:ToPlayer() and creature:GetDistance(who) < 10 and creature:IsWithinLoS(who) then
        if not lastGreeting[creature:GetGUIDLow()] or (lastGreeting[creature:GetGUIDLow()] and (lastGreeting[creature:GetGUIDLow()] < os.time())) then
            lastGreeting[creature:GetGUIDLow()] = os.time() + 90
            creature:SendUnitSay("Welcome to the Yggdrasil mall, "..who:GetName().."! Please ask me if you need any directions or pointers.", 0)
            creature:PerformEmote(3)
        end
    end
end

local function Guild(event, creature, who)
    if who:ToPlayer() and creature:GetDistance(who) < 7 and creature:IsWithinLoS(who) then
        if not lastGreeting[creature:GetGUIDLow()] or (lastGreeting[creature:GetGUIDLow()] and (lastGreeting[creature:GetGUIDLow()] < os.time())) then
            lastGreeting[creature:GetGUIDLow()] = os.time() + 90
            creature:SendUnitSay("Hello, "..who:GetName()..". Come to me if you need to rename your guild or create a new one with less than 10 players.", 0)
            creature:PerformEmote(3)
        end
    end
end

local function DruidEnvoy(event, creature, who)
    if who:ToPlayer() and creature:GetDistance(who) < 7 and creature:IsWithinLoS(who) then
        if not lastGreeting[creature:GetGUIDLow()] or (lastGreeting[creature:GetGUIDLow()] and (lastGreeting[creature:GetGUIDLow()] < os.time())) then
            lastGreeting[creature:GetGUIDLow()] = os.time() + 90
            creature:SendUnitSay("It is important for druids to be represented in matters pertaining to the fabric of Yggdrasil's nature.", 0)
            creature:PerformEmote(3)
        end
    end
end

local function EdgeWarning(event, creature, who)
    if who:ToPlayer() and creature:GetDistance(who) < 15 and creature:IsWithinLoS(who) then
        if not lastGreeting[creature:GetGUIDLow()] or (lastGreeting[creature:GetGUIDLow()] and (lastGreeting[creature:GetGUIDLow()] < os.time())) then
            lastGreeting[creature:GetGUIDLow()] = os.time() + 45
            creature:SendUnitSay("Halt, "..who:GetName().."! You mustn't proceed. The area that lies ahead is corrupted and unsafe for travel. Please turn back immediately!", 0)
            creature:PerformEmote(35)
        end
    end
end

local function Scribe(event, creature, who)
    if who:ToPlayer() and creature:GetDistance(who) < 10 and creature:IsWithinLoS(who) then
        if not lastGreeting[creature:GetGUIDLow()] or (lastGreeting[creature:GetGUIDLow()] and (lastGreeting[creature:GetGUIDLow()] < os.time())) then
            lastGreeting[creature:GetGUIDLow()] = os.time() + 90
            creature:SendUnitSay("Did you know papyrus is made of wood, "..who:GetName().."? I wonder why I became a scribe...", 0)
            creature:PerformEmote(1)
        end
    end
end

local function Fish(event, creature, who)
    if who:ToPlayer() and creature:GetDistance(who) < 10 and creature:IsWithinLoS(who) then
        if not lastGreeting[creature:GetGUIDLow()] or (lastGreeting[creature:GetGUIDLow()] and (lastGreeting[creature:GetGUIDLow()] < os.time())) then
            lastGreeting[creature:GetGUIDLow()] = os.time() + 90
            creature:SendUnitSay("Turns out fishing rods are made from trees. Luckily, I am a tree, so I can just use my own twigs!", 0)
            creature:PerformEmote(2)
        end
    end
end

local function Herb(event, creature, who)
    if who:ToPlayer() and creature:GetDistance(who) < 10 and creature:IsWithinLoS(who) then
        if not lastGreeting[creature:GetGUIDLow()] or (lastGreeting[creature:GetGUIDLow()] and (lastGreeting[creature:GetGUIDLow()] < os.time())) then
            lastGreeting[creature:GetGUIDLow()] = os.time() + 90
            creature:SendUnitSay("I became an herbalist to stay in touch with my roots.", 0)
            creature:PerformEmote(1)
            creature:RegisterEvent(function(e, d, r, c)
                local alchemist = c:GetNearestCreature(50, 95001)
                if alchemist then
                    alchemist:SendUnitSay("You keep making the same joke! You are the worst coworker I've ever had!", 0)
                    alchemist:PerformEmote(1)
                end
                c:RegisterEvent(function(e, d, r, c)
                    c:SendUnitSay("And you're the meanest coworker I've ever had...", 0)
                    c:SendUnitEmote(c:GetName().." cries.")
                    c:PerformEmote(18)
                end, 20000)
            end, 10000)
        end
    end
end

local function Feathers(event, creature, who, id)
    -- wp of citizen
    if event == 6 then
        if id == 0 then
            local citizen = creature
            citizen:SendUnitSay("Wow! So you are telling me I could ride that Riding Gryphon right now, if I buy your feathers?", 0)
            creature:PerformEmote(25)
            local creature = citizen:GetNearestCreature(50, 190099)
            if creature then
                creature:RegisterEvent(function(e, d, r, creature)
                    creature:SendUnitSay("Yes, precisely, citizen. If you purchase it now I may even let you try my Gryphon.", 0) 
                end, 10000)
                citizen:RegisterEvent(function(e, d, r, citizen)
                    citizen:SendUnitSay("You're on!", 0) 
                end, 25000)
                citizen:RegisterEvent(function(e, d, r, citizen)
                    citizen:SendUnitEmote("Citizen of Yggdrasil and the bird breeder make the trade.", 0) 
                end, 35000)
                citizen:RegisterEvent(function(e, d, r, citizen)
                    citizen:SendUnitSay("Time to fly! I'm so excited!", 0) 
                    citizen:MoveTo(1, 1048, 409, citizen:GetMap():GetHeight(1048, 409))
                end, 40000)
            end
        elseif id == 1 then
            creature:RegisterEvent(function(e, d, r, creature)
                creature:PerformEmote(69)
                creature:SendUnitEmote("Citizen of Yggdrasil mounts the gryphon.", 0) 
            end, 3000)
            creature:RegisterEvent(function(e, d, r, creature)
                local mount = creature:GetNearestCreature(50, 541)
                if mount then mount:SetRespawnDelay(30) mount:DespawnOrUnsummon() end
                creature:Mount(6852)
                creature:MoveTo(2, 1046, 414, 338.87894)
            end, 6000)
        elseif id == 2 then
            creature:MoveTo(3, 1038,  419, 339.32596)
        elseif id == 3 then
            creature:MoveTo(4, 1028.508,  419.3684, 341.42722)
        elseif id == 4 then
            creature:MoveTo(5, 1022.1253,  417.14633, 343.91782)
        elseif id == 5 then
            creature:SendUnitSay("Taking off!", 0)
            creature:MoveTo(6, 566,  358, 404)
            creature:SetHover(true)
            creature:SetDisableGravity(true)
        elseif id == 6 then
            creature:DespawnOrUnsummon()
        end
        return
    end
    
    -- Initiate event on LOS with feather vendor
    if who:ToPlayer() and creature:GetDistance(who) < 15 and creature:IsWithinLoS(who) then
        if not lastGreeting[creature:GetGUIDLow()] or (lastGreeting[creature:GetGUIDLow()] and (lastGreeting[creature:GetGUIDLow()] < os.time())) then
            lastGreeting[creature:GetGUIDLow()] = os.time() + 300
            creature:SendUnitSay("Hello, citizen! If you want to fly in Azeroth, come to me. My "..GetItemLink(20739).." can make any mount fly in the old world.", 0)
            creature:PerformEmote(3)
            if creature:GetNearestCreature(100, 401250) then return end -- abort if already active event
            local citizen = creature:SpawnCreature(401250, 1044, 370, 333.3795, 1.46, 1, 100000)
            if citizen then
                creature:SetHover(false)
                creature:SetDisableGravity(false)
                citizen:SetWalk(true)
                citizen:MoveTo(0, 1050, 405, 338.3377)
            end
        end
    end
end

local MASTER_COMMANDS = {
   "Okay, druid! Now, cast the %s %s Form!",
   "Great! Now it's time for the %s %s Form!",
   "Show me your %s %s Form, apprentice!", 
   "Let's see your %s %s Form!",
   "Time to practice the %s %s Form!"
}

local APPRENTICE_RESPONSES = {
    "Did I do it?",
    "How's this looking, master?",
    "Was that the right form?",
    "Hnnng!",
    "I hope I got it right this time!",
    "Is this what you were looking for?"
}

local MASTER_FEEDBACK = {
    "Great!",
    "Hmm, not quite!",
    "Perfect form!",
    "Keep practicing!",
    "You're getting the hang of it!",
    "Great! Soon, you'll be ready for trying Flight Form morphs!",
    "Let's try again in a little bit.",
    "Impressive!",
    "Almost there!"
}

local FORM_TYPES = {
   [1] = {name = "Cat", morphs = {}},
   [2] = {name = "Bear", morphs = {}}, 
   [3] = {name = "Travel", morphs = {}},
   [5] = {name = "Tree", morphs = {}},
   [6] = {name = "Moonkin", morphs = {}}
}

local FORM_IDS = {1, 2, 3, 5, 6}

local STATIC_MORPHS = {
    {15506,1,"Springpaw Stalker"},
    {25008,4,"Imperial Eagle"},
    {2161,3,"Tallhorn Stag"},
    {614,1,"Stranglethorn Tigress"},
    {23960,3,"Highland Mustang"},
    {23959,3,"Highland Mustang"},
    {23958,3,"Highland Mustang"},
    {239,3,"Highland Mustang"},
    {21635,2,"Grizzly Bear"},
    {24630,4,"Fern Feeder Moth"},
    {1083,2,"Infected Grizzly Bear"},
    {17547,4,"Feral Dragonhawk Hatchling"},
    {15484,5,"Tender"},
    {15485,5,"Feral Tender"},
    {15507,1,"Springpaw Cub"},
    {2437,1,"Young Panther"},
    {598,1,"Young Stranglethorn Tiger"},
    {1059,1,"Flatland Cougar"},
    {1221,3,"Elder Plainstrider"},
    {643,3,"Prairie Stalker"},
    {1220,3,"Adult Plainstrider"},
    {1229,4,"Swoop"},
    {21975,7,"Orca"},
    {14318,1,"Nightsaber Stalker"},
    {25708,1,"Cursed Offspring of Har'koa"},
    {707,2,"Elder Black Bear"},
    {762,2,"Grizzled Black Bear"},
    {903,3,"Mangy Wolf"},
    {643,3,"Coyote"},
    {410,4,"Young Fleshripper"},
    {802,3,"Rabid Dire Wolf"},
    {801,3,"Starving Dire Wolf"},
    {246,3,"Young Black Ravager"},
    {9562,3,"Black Ravager Mastiff"},
    {741,3,"Black Ravager"},
    {1039,7,"River Crocolisk"},
    {698,1,"Elder Stranglethorn Tiger"},
    {599,1,"Panther"},
    {471,1,"Sin'Dall"},
    {833,7,"Snapjaw Crocolisk"},
    {633,1,"Shadowmaw Panther"},
    {613,1,"Bhag'thera"},
    {10824,4,"Black Slayer"},
    {632,1,"Swamp Jaguar"},
    {814,7,"Young Sawtooth Crocolisk"},
    {807,7,"Sawtooth Crocolisk"},
    {490,4,"Dire Condor"},
    {11415,3,"Prowler"},
    {1006,2,"Young Forest Bear"},
    {23483,4,"Carrion Condor"},
    {23403,4,"Oiled Fledgeling"},
    {22633,4,"Oil-covered Hawk"},
    {604,3,"Snow Tracker Wolf"},
    {785,3,"Winter Wolf"},
    {954,1,"Snow Leopard"},
    {1164,3,"Elder Crag Coyote"},
    {1106,4,"Giant Buzzard"},
    {917,1,"Ridge Stalker Patriarch"},
    {1055,1,"Ridge Huntress"},
    {1105,4,"Buzzard"},
    {1036,7,"Wetlands Crocolisk"},
    {925,7,"Giant Wetlands Crocolisk"},
    {388,4,"Elder Mesa Buzzard"},
    {3201,2,"Elder Gray Bear"},
    {806,2,"Gray Bear"},
    {1059,1,"Starving Mountain Lion"},
    {1007,2,"Vicious Gray Bear"},
    {1058,1,"Mountain Lion"},
    {2300,1,"Hulking Mountain Lion"},
    {11413,3,"Mangy Silvermane"},
    {11419,3,"Silvermane Wolf"},
    {11417,3,"Silvermane Howler"},
    {12238,6,"Primitive Owlbeast"},
    {820,2,"Giant Grizzled Bear"},
    {11421,3,"Worg"},
    {1082,2,"Diseased Black Bear"},
    {4124,3,"Diseased Wolf"},
    {15592,1,"Ghostclaw Ravager"},
    {17545,4,"Crazed Dragonhawk"},
    {18167,1,"Elder Springpaw"},
    {29363,4,"Silvermoon Dragonhawk"},
    {7114,7,"Steeljaw Snapper"},
    {8838,2,"Grizzled Ironfur Bear"},
    {165,3,"Longtooth Runner"},
    {1056,1,"Needles Cougar"},
    {2548,7,"Mottled Drywallow Crocolisk"},
    {1973,1,"Savannah Prowler"},
    {161,3,"Prairie Wolf Alpha"},
    {1192,4,"Dread Swoop"},
    {11453,1,"Twilight Runner"},
    {982,2,"Elder Ashenvale Bear"},
    {2077,5,"Crazed Ancient"},
    {4877,4,"Ironbeak Owl"},
    {9276,2,"Angerclaw Bear"},
    {10829,4,"Ironbeak Hunter"},
    {1083,2,"Angerclaw Mauler"},
    {6351,5,"Irontree Stomper"},
    {10831,4,"Ironbeak Screecher"},
    {12235,6,"Ragged Owlbeast"},
    {10807,4,"Fledgling Chillwind"},
    {865,2,"Shardtooth Bear"},
    {10810,4,"Chillwind Chimaera"},
    {8842,2,"Shardtooth Mauler"},
    {6212,4,"Winterspring Owl"},
    {9953,1,"Frostsaber"},
    {9958,1,"Frostsaber Cub"},
    {11445,1,"Frostsaber Stalker"},
    {9954,1,"Frostsaber Pride Watcher"},
    {11444,1,"Frostsaber Huntress"},
    {1083,2,"Diseased Grizzly"},
    {10833,4,"Winterspring Screecher"},
    {8837,2,"Elder Shardtooth"},
    {10618,2,"Ursius"},
    {12683,4,"Brumeran"},
    {16245,1,"Ghostclaw Lynx"},
    {12238,6,"Vicious Owlbeast"},
    {9562,3,"Silvermane Stalker"},
    {12236,6,"Savage Owlbeast"},
    {14315,2,"Giant Ashenvale Bear"},
    {1283,3,"Giant Foreststrider"},
    {1042,3,"Foreststrider Fledgling"},
    {10824,4,"Young Mesa Buzzard"},
    {321,1,"Moonstalker"},
    {992,7,"Darkshore Thresher"},
    {1035,7,"Young Wetlands Crocolisk"},
    {10832,4,"Strigid Owl"},
    {3030,1,"Elder Nightsaber"},
    {410,4,"Mountain Buzzard"},
    {6805,1,"Nightsaber"},
    {161,3,"Crag Coyote"},
    {632,1,"Ridge Stalker"},
    {11454,1,"Young Nightsaber"},
    {8840,2,"Ice Claw Bear"},
    {8843,2,"Young Black Bear"},
    {748,1,"Juvenile Snow Leopard"},
    {855,3,"Ragged Young Wolf"},
    {31049,3,"Diseased Young Wolf"},
    {380,3,"Gray Forest Wolf"},
    {2305,4,"Fleshripper"},
    {10826,4,"Sky Shadow"},
    {31094,2,"Arcturis"},
    {22088,3,"Savage Worg"},
    {1105,4,"Bonepicker"},
    {14389,7,"Sawfin Frenzy"},
    {705,7,"Sharptooth Frenzy"},
    {320,1,"Stranglethorn Tiger"},
    {2548,7,"Saltwater Crocolisk"},
    {815,7,"Elder Saltwater Crocolisk"},
    {616,1,"King Bangalash"},
    {1977,1,"Savannah Patriarch"},
    {6076,3,"Ornery Plainstrider"},
    {1284,3,"Fleeting Plainstrider"},
    {27975,4,"Aotona"},
    {1250,7,"Dreadmaw Crocolisk"},
    {1056,1,"Savannah Huntress"},
    {178,3,"Greater Plainstrider"},
    {1991,3,"Shadowhorn Stag"},
    {820,2,"Ashenvale Bear"},
    {28649,1,"Loque'nahak"},
    {1917,3,"Wild Buck"},
    {11450,1,"Moonstalker Sire"},
    {14316,2,"Grizzled Thistle Bear"},
    {26165,1,"Frost Leopard"},
    {11449,1,"Moonstalker Runt"},
    {4877,4,"Strigid Screecher"},
    {28871,1,"Gondria"},
    {21975,7,"Glimmer Bay Orca"},
    {22003,3,"Oil-stained Wolf"},
    {23316,4,"Bloodspore Moth"},
    {22044,3,"Tundra Wolf"},
    {12199,7,"Great Reef Shark"},
    {1557,7,"Great Reef Shark"},
    {19219,3,"Talbuk Stag"},
    {18377,4,"Windroc"},
    {19220,3,"Talbuk Thorngrazer"},
    {18378,4,"Greater Windroc"},
    {18383,4,"Gutripper"},
    {18380,4,"Ravenous Windroc"},
    {20223,4,"Spirit Raven"},
    {1192,4,"Bonelasher"},
    {20348,4,"Trachela"},
    {25107,7,"Mangal Crocolisk"},
    {25111,1,"Dreadsaber"},
    {25274,1,"Shango"},
    {16873,3,"Moongraze Buck"},
    {6805,1,"Infected Nightstalker Runt"},
    {178,3,"Timberstrider"},
    {17574,4,"Vale Moth"},
    {16872,3,"Moongraze Stag"},
    {3031,1,"Nightstalker"},
    {17012,3,"Greater Timberstrider"},
    {1006,2,"Brown Bear"},
    {14316,2,"Grizzled Brown Bear"},
    {1990,2,"Elder Brown Bear"},
    {9277,2,"Deathclaw"},
    {17711,4,"Royal Blue Flutterer"},
    {17057,5,"Corrupted Treant"},
    {3201,2,"Ironfur Bear"},
    {3202,3,"Longtooth Howler"},
    {10825,4,"Salt Flats Vulture"},
    {3248,4,"Roc"},
    {18416,1,"Mangy Nightsaber"},
    {9278,3,"Felpaw Scavenger"},
    {9277,2,"Angerclaw Grizzly"},
    {9280,3,"Felpaw Ravager"},
    {4124,3,"Felpaw Wolf"},
    {1992,3,"Elder Shadowhorn Stag"},
    {9593,5,"Withered Ancient"},
    {776,3,"Ghostpaw Alpha"},
    {1105,4,"Mesa Buzzard"},
    {18353,3,"Talbuk Patriarch"},
    {19705,1,"Ripfang Lynx"},
    {19771,4,"Shimmerwing Moth"},
    {2850,7,"Barbscale Crocolisk"},
    {19779,3,"Talbuk Sire"},
    {19696,3,"Talbuk Doe"},
    {22321,4,"Goretalon Roc"},
    {23952,3,"Blighted Elk"},
    {23966,2,"Rabid Grizzly"},
    {10618,2,"Arctic Grizzly"},
    {23962,4,"Dragonbone Condor"},
    {23951,3,"Snowfall Elk"},
    {24453,4,"Emerald Skytalon"},
    {24235,3,"Graymist Hunter"},
    {25925,4,"Goretalon Matriarch"},
    {1105,4,"Carrion Vulture"},
    {1006,2,"Ferocious Grizzled Bear"},
    {741,3,"Bloodsnout Worg"},
    {1056,1,"Feral Mountain Lion"},
    {1004,7,"Loch Frenzy"},
    {867,7,"Young Threshadon"},
    {1034,7,"Loch Crocolisk"},
    {633,1,"Shadow Panther"},
    {2714,3,"Snickerfang Hyena"},
    {8050,3,"Starving Snickerfang"},
    {599,1,"Kurzen War Panther"},
    {11452,1,"Elder Shadowmaw Panther"},
    {15586,5,"Eversong Tender"},
    {15588,5,"Withered Green Keeper"},
    {10830,4,"Strigid Hunter"},
    {5927,6,"Moonkin"},
    {8013,3,"Mosshoof Runner"},
    {10894,3,"Thunderhead Stagwing"},
    {10957,3,"Mosshoof Courser"},
    {4269,4,"Mistwing Ravager"},
    {3200,2,"Rabid Shardtooth"},
    {12237,6,"Moontouched Owlbeast"},
    {12236,6,"Berserk Owlbeast"},
    {1207,3,"Ghostpaw Howler"},
    {2187,3,"Zhevra Charger"},
    {2710,3,"Hecklefang Hyena"},
    {6087,3,"Zhevra Runner"},
    {2713,3,"Pesterhide Hyena"},
    {12235,6,"Raging Owlbeast"},
    {7348,4,"Fire Roc"},
    {1536,3,"Blisterpaw Hyena"},
    {24235,3,"Sinewy Wolf"},
    {38,3,"Strider Clutchmother"},
    {25466,7,"Mangal Crocolisk"},
    {2601,7,"Stranded Thresher"},
    {25005,1,"Dreadsaber"},
    {23951,3,"Silvercoat Stag"},
    {22673,3,"Frosthorn Ram"},
    {22321,4,"Duskwing Eagle"},
    {26388,2,"Brunnhildar Warbear"},
    {8842,2,"Icemaw Bear"},
    {25120,3,"Longneck Grazer"},
    {25121,3,"Longneck Grazer"},
    {25110,1,"Dreadsaber"},
    {17091,4,"Bladewing Bloodletter"},
    {9370,3,"Thunderlord Dire Wolf"},
    {19770,3,"Daggermaw Blackhide"},
    {20604,5,"Outraged Raven's Wood Sapling"},
    {19742,3,"Felsworn Daggermaw"},
    {19758,3,"Bladespire Raptor"},
    {19759,3,"Daggermaw Lashtail"},
    {19758,3,"Scythetooth Raptor"},
    {28647,3,"Devilsaur"},
    {31831,3,"Ironhide Devilsaur"},
    {12199,7,"Moa'ki Bottom Thresher"},
    {1747,3,"Sunscale Screecher"},
    {4473,3,"Barrens Giraffe"},
    {11317,3,"Jungle Stalker"},
    {8472,3,"Tethis"},
    {615,3,"Young Jungle Stalker"},
    {19223,3,"Bach'lor"},
    {17795,4,"Vicious Teromoth"},
    {17574,4,"Teromoth"},
    {18922,5,"Treant"},
    {6086,3,"Zhevra Courser"},
    {2193,3,"Wandering Barrens Giraffe"},
    {12200,7,"Great Reef Shark"},
    {13340,3,"Arctic Ram"},
    {19768,3,"Drakuru Raptor"},
    {10618,2,"Icepaw Bear"},
    {1340,3,"Gundrak Raptor"},
    {25785,3,"Vargul Blighthound"},
    {22042,3,"Duskhowl Prowler"},
    {22003,3,"Fanggore Worg"},
    {22502,3,"Bjomolf"},
    {22089,3,"Winterskorn Worg"},
    {26332,7,"Bull Lion Seal"},
    {26333,7,"Lion Seal"},
    {22611,3,"Spearfang Worg"},
    {17798,4,"Royal Teromoth"},
    {11417,3,"Timber Worg Alpha"},
    {1006,2,"Thistle Bear"},
    {12237,6,"Raging Moonkin"},
    {178,3,"Foreststrider"},
    {994,7,"Elder Darkshore Thresher"},
    {3031,1,"Moonstalker Matriarch"},
    {9390,6,"Young Moonkin"},
    {802,3,"Ghostpaw Runner"},
    {4442,3,"Sunscale Scytheclaw"},
    {1744,3,"Sunscale Lashtail"},
    {5242,3,"Ravasaur"},
    {5290,3,"Ravasaur Runner"},
    {5291,3,"Venomhide Ravasaur"},
    {5292,3,"Ravasaur Hunter"},
    {3200,2,"Ironfur Patriarch"},
    {3203,3,"Rabid Longtooth"},
    {1100,3,"Prairie Wolf"},
    {1228,4,"Wiry Swoop"},
    {1959,3,"Bloodtalon Scythemaw"},
    {787,3,"Corrupted Bloodtalon Scythemaw"},
    {1960,3,"Bloodtalon Taillasher"},
    {788,3,"Lashtail Raptor"},
    {1043,1,"Crag Stalker"},
    {15145,7,"Mangal Crocolisk"},
    {2571,3,"Young Lashtail Raptor"},
    {11316,3,"Highland Strider"},
    {18147,7,"Shimmerscale Eel"},
    {16880,4,"Bonestripper Buzzard"},
    {19286,7,"Umbrafen Eel"},
    {19405,4,"Bloodthirsty Marshfang"},
    {19401,4,"Marshfang Slicer"},
    {21282,4,"Aether Ray"},
    {20013,4,"Dire Raven"},
    {17797,4,"Silkwing"},
    {17834,4,"Mature Silkwing"},
    {19347,3,"Bloodmaul Dire Wolf"},
    {19416,4,"Nether Ray"},
    {20424,1,"Blackwind Sabercat"},
    {20571,4,"Vilewing Chimaera"},
    {20263,4,"Eclipsion Dragonhawk"},
    {6351,5,"Infested Root-Walker"},
    {21087,3,"Lost Torranche"},
    {11419,3,"Timber Worg"},
    {10831,4,"Shadowwing Owl"},
    {22467,2,"Amani Bear"},
    {2298,4,"Highperch Wyvern"},
    {11011,4,"Heartrazor"},
    {4585,4,"Highperch Patriarch"},
    {2297,4,"Highperch Consort"},
    {27469,5,"Crystalline Keeper"},
    {22132,3,"Longhoof Grazer"},
    {10808,4,"Frostwing Chimaera"},
    {2602,7,"River Thresher"},
    {30059,2,"Thistle Cub"},
    {2278,1,"Savannah Cub"},
    {22517,1,"Amani Lynx Cub"},
    {31048,3,"Diseased Timber Wolf"},
    {23946,2,"Arctic Grizzly Cub"},
    {23948,2,"Arctic Grizzly Cub"},
    {23947,2,"Arctic Grizzly Cub"},
    {19705,1,"Grovestalker Lynx"},
    {388,4,"Spiteflayer"},
    {20857,4,"Daggercap Hawk"},
    {21763,7,"Daggercap Hammerhead"},
    {19400,4,"\"Count\" Ungula"},
    {17752,4,"Greater Sporebat"},
    {17751,4,"Sporebat"},
    {705,7,"Mudfin Frenzy"},
    {161,3,"Coyote Packleader"},
    {1105,4,"Greater Fleshripper"},
    {245,7,"Coastal Frenzy"},
    {12207,7,"Mammoth Shark"},
    {12682,4,"Mistwing Rogue"},
    {26618,1,"Pitch"},
    {633,1,"Skullsplitter Panther"},
    {17408,3,"Bonechewer Riding Wolf"},
    {17089,4,"Bonestripper Vulture"},
    {17753,4,"Young Sporebat"},
    {19287,7,"Lagoon Eel"},
    {2571,3,"Razzashi Raptor"},
    {15101,7,"Hooktooth Frenzy"},
    {11031,1,"Zulian Tiger"},
    {15151,1,"Zulian Cub"},
    {673,3,"Highland Lashtail"},
    {649,3,"Highland Scytheclaw"},
    {180,3,"Highland Razormaw"},
    {670,3,"Highland Raptor"},
    {961,3,"Highland Fleshstalker"},
    {23793,3,"Savage Worg"},
    {447,3,"Young Scavenger"},
    {604,3,"Ragged Scavenger"},
    {26661,3,"Tundra Ram"},
    {22131,3,"Shoveltusk Stag"},
    {22536,2,"Hozzer"},
    {24461,4,"Alystros the Verdant Keeper"},
    {12237,6,"Crazed Owlbeast"},
    {2571,3,"Bloodfen Raptor"},
    {14334,3,"Shattered Hand Warhound"},
    {25466,7,"Ravenous Mangal Crocolisk"},
    {12210,7,"Ravenous Jaws"},
    {12208,7,"Ravenous Jaws"},
    {22501,3,"Varg"},
    {22042,3,"Hungry Worg"},
    {24708,3,"Goremaw"},
    {4566,4,"Kaliri Matriarch"},
    {16724,4,"Kaliri Swooper"},
    {6299,4,"Male Kaliri Hatchling"},
    {4615,4,"Female Kaliri Hatchling"},
    {18470,1,"Stabled Tallstrider"},
    {4714,1,"Stabled Boar"},
    {1339,1,"Stabled Raptor"},
    {865,1,"Stabled Bear"},
    {21210,3,"Twilight Serpent"},
    {9022,15,"Frenzied Plaguehound"},
    {14272,16,"Arcane Devourer"},
    {15406,16,"Tainted Arcane Wraith"},
    {18345,29,"Fel Soldier"},
    {18699,17,"Deathwhisperer"},
    {17446,29,"Dread Tactician"},
    {9129,29,"Fel Handler"},
    {16480,23,"Heckling Fel Sprite"},
    {11410,15,"Starving Helboar"},
    {18878,23,"Flamewaker Imp"},
    {8610,29,"Dreadcaller"},
    {10906,29,"Infernal Warbringer"},
    {18701,15,"Deranged Helboar"},
    {19249,15,"Felboar"},
    {19991,29,"Illidari Dreadbringer"},
    {18654,29,"Illidari Shocktrooper"},
    {20214,17,"Illidari Painlasher"},
    {20044,29,"Wrathwalker"},
    {19200,29,"Terrormaster"},
    {19717,17,"Prophetess Cavrylin"},
    {23835,16,"Arcanimus"},
    {19404,4,"Marshfang Ripper"},
    {18029,4,"Sporewing"},
    {6172,15,"Netherhound"},
    {18419,17,"Doomwhisperer"},
    {20045,29,"Wrathguard"},
    {7950,30,"Infernal Siegebreaker"},
    {10906,30,"Infernal Warbringer"},
    {18832,29,"Forge Camp Legionnaire"},
    {18373,29,"Terrorfiend"},
    {4449,23,"Imp Minion"},
    {17312,30,"Infernal Attacker"},
    {788,3,"Stranglethorn Raptor"},
    {180,3,"Young Stranglethorn Raptor"},
    {1042,3,"Timberstrider Fledgling"},
    {16266,6,"Raving Owlbeast"},
    {5927,6,"Aberrant Owlbeast"},
    {17056,6,"Contaminated Wildkin"},
    {17058,6,"Irradiated Wildkin"},
    {10890,3,"Frayfeather Stagwing"},
    {19770,3,"Drakuru Raptor"},
    {913,2,"Bjarn"},
    {180,3,"Highland Thrasher"},
    {18167,1,"Starving Ghostclaw"},
    {295,4,"Pridewing Wyvern"},
    {8015,4,"Fledgling Chimaera"},
    {10273,4,"Dread Flyer"},
    {10957,3,"Dappled Stag"},
    {9590,5,"Dispirited Ent"},
    {10621,5,"Unbound Ent"},
    {11319,3,"Ravasaur Matriarch"},
    {960,3,"Mottled Raptor"},
    {677,3,"Mottled Screecher"},
    {648,3,"Mottled Scytheclaw"},
    {949,3,"Mottled Razormaw"},
    {755,3,"Sarltooth"},
    {15903,3,"Marsh Caribou"},
    {24910,15,"Azure Mage Slayer"},
    {19299,4,"Phoenix-Hawk"},
    {19298,4,"Phoenix-Hawk Hatchling"},
    {599,1,"Jungle Panther"},
    {26423,3,"Wooly Mammoth"},
    {26425,3,"Wooly Mammoth Bull"},
    {781,3,"Vilebranch Wolf Pup"},
    {23434,3,"Mammoth Calf"},
    {2712,3,"Gordok Hyena"},
    {1973,1,"Savannah Highmane"},
    {1034,7,"Corrupted Dreadmaw Crocolisk"},
    {598,1,"Durotar Tiger"},
    {6757,3,"Thunderhead Hippogryph"},
    {245,7,"Whitetail Frenzy"},
    {27235,3,"Ironwool Mammoth"},
    {27277,3,"Emaciated Mammoth Calf"},
    {27271,3,"Emaciated Mammoth Bull"},
    {27275,3,"Emaciated Mammoth"},
    {1557,7,"Moa'ki Bottom Thresher"},
    {246,3,"Mottled Worg"},
    {788,3,"Elder Razormaw"},
    {11420,3,"Slavering Ember Worg"},
    {507,4,"Vultros"},
    {5510,2,"Thistle Cub"},
    {30060,2,"Thistle Cub"},
    {16266,6,"Crazed Wildkin"},
    {20738,4,"Skettis Kaliri"},
    {21396,4,"Monstrous Kaliri"},
    {741,3,"Dark Worg"},
    {19734,3,"Drakkari Gutripper"},
    {19732,3,"Drakkari Scytheclaw"},
    {27281,3,"Stoic Mammoth"},
    {2078,5,"Irontree Wanderer"},
    {6212,4,"Olm the Wise"},
    {10054,1,"Rak'shiri"},
    {10809,4,"Chillwind Ravager"},
    {3210,3,"Frayfeather Hippogryph"},
    {22089,3,"Bloodthirsty Tundra Wolf"},
    {20738,4,"Bird of Prey"},
    {15590,4,"Carrion Bird"},
    {2079,5,"Deeprot Stomper"},
    {13098,5,"Deeprot Tangler"},
    {20729,4,"Avian Warhawk"},
    {20725,4,"Avian Darkhawk"},
    {20730,4,"Avian Ripper"},
    {4472,1,"Ghost Saber"},
    {14390,7,"Lake Thresher"},
    {557,3,"Feral Crag Coyote"},
    {10824,4,"Starving Buzzard"},
    {706,2,"Ol' Sooty"},
    {913,2,"Mangeclaw"},
    {11416,3,"Starving Winter Wolf"},
    {782,3,"Vilebranch Raiding Wolf"},
    {15590,4,"Fjord Crow"},
    {20013,4,"Brood of Anzu"},
    {30521,17,"Sister Svalna"},
    {10113,1,"Shy-Rotam"},
    {10114,1,"Sian-Rotam"},
    {18416,1,"Sable Jaguar"},
    {18417,7,"Darkwater Crocolisk"},
    {14334,3,"Rabid Warhound"},
    {10827,4,"Searing Roc"},
    {2305,4,"Salt Flats Scavenger"},
    {10825,4,"Carrion Horror"},
    {18063,3,"Ironjaw"},
    {10271,3,"Tundra Scavenger"},
    {27235,3,"Emaciated Mammoth"},
    {27278,3,"Emaciated Mammoth Calf"},
    {1988,5,"Mangrove Ent"},
    {9590,5,"Treant Ally"},
    {12682,4,"Chimaera Matriarch"},
    {801,3,"Bleak Worg"},
    {11421,3,"Slavering Worg"},
    {246,3,"Wolfguard Worg"},
    {19531,3,"Bloodmaul Battle Worg"},
    {1923,5,"Raven's Wood Ent"},
    {1744,3,"Deviate Creeper"},
    {1746,3,"Deviate Stalker"},
    {949,3,"Deviate Slayer"},
    {2007,29,"Bleakheart Satyr"},
    {25145,3,"Phantasmal Mammoth"},
    {19685,4,"Bloodfalcon"},
    {9590,5,"Sapling"},
    {17170,7,"Drakkari Frenzy"},
    {3030,1,"Feral Nightsaber"},
    {12238,6,"Deranged Owlbeast"},
    {9390,6,"Nestlewood Owlkin"},
    {17709,4,"Blue Flutterer"},
    {12236,6,"Moonkin Oracle"},
    {1219,3,"Plainstrider"},
    {11451,1,"Mountain Cougar"},
    {10824,4,"Taloned Swoop"},
    {14319,4,"Dread Ripper"},
    {762,2,"Black Bear Patriarch"},
    {706,2,"Big Samras"},
    {9372,3,"Barnabus"},
    {1962,3,"Bloodfen Screecher"},
    {1080,7,"Drywallow Crocolisk"},
    {2574,3,"Bloodfen Lashtail"},
    {21825,3,"Goreclaw the Ravenous"},
    {2425,7,"Young Murk Thresher"},
    {12192,7,"Coral Shark"},
    {2609,7,"Steelsnap"},
    {755,3,"Deviate Guardian"},
    {2996,7,"Deviate Crocolisk"},
    {347,3,"Marsh Fawn"},
    {12189,15,"Ancient Core Hound"},
    {12190,23,"Flame Imp"},
    {24906,15,"Mage Slayer"},
    {20212,17,"Coilfang Priestess"},
    {2850,7,"Sewer Beast"},
    {11412,3,"Lupos"},
    {1337,3,"Takk the Leaper"},
    {4424,1,"Humar the Pridelord"},
    {2601,7,"Murk Thresher"},
    {11316,3,"Razormaw Matriarch"},
    {19586,17,"Irespeaker"},
    {24908,15,"Hungering Plaguehound"},
    {18251,29,"Illidari Centurion"},
    {19991,29,"Illidari Nightlord"},
    {21355,15,"Mutant War Hound"},
    {14334,15,"Shadowmoon War Hound"},
    {21378,15,"Shadowmoon Houndmaster"},
    {19199,17,"Sister of Pleasure"},
    {21252,17,"Mother Shahraz"},
    {10070,17,"Sister of Grief"},
    {18953,16,"Collapsing Voidwalker"},
    {19196,16,"Vacillating Voidcaller"},
    {9562,3,"Bleeding Hollow Riding Worg"},
    {29760,17,"Argent Priestess"},
    {2161,3,"Mosshoof Stag"},
    {19600,7,"Siltslither Eel"},
    {27270,3,"Enraged Mammoth"},
    {26423,3,"Shattertusk Mammoth"},
    {17897,3,"Wild Elekk"},
    {26334,7,"Lion Seal Whelp"},
    {1933,1,"Araga"},
}

local function populatePlayerMorphCache()
    for _, m in ipairs(STATIC_MORPHS) do
        local morphId, form, morphName = m[1], m[2], m[3]
        if FORM_TYPES[form] then
            table.insert(FORM_TYPES[form].morphs, {id = morphId, name = morphName})
        end
    end
end

-- Function to pick a random form type and return both name and morph ID
local function pickRandomForm()
    local formId = FORM_IDS[math.random(#FORM_IDS)]
    local formData = FORM_TYPES[formId]
    
    return formData.name, formData.morphs[math.random(#formData.morphs)]
end

local function MorphScript(creature)
    creature:RegisterEvent(function(eventId, delay, repeats, creature)
        -- Find closest apprentice
        local apprentice = creature:GetNearestCreature(50, APPRENTICE_ENTRY)
        if not apprentice then return end

        -- Select random form type and get both name and morph ID
        local formName, morphData = pickRandomForm()
        local formId

        if formName == "Cat" then formId = 1
        elseif formName == "Bear" then formId = 2
        elseif formName == "Travel" then formId = 3
        elseif formName == "Tree" then formId = 5
        elseif formName == "Boomkin" then formId = 6
        end

        -- Select a random morph from the morphs list for the chosen form
        local selectedMorph = morphData  -- This already contains the correct morph data (id and name)

        -- Master's initial command
        local morphName = selectedMorph.name
        local command = MASTER_COMMANDS[math.random(#MASTER_COMMANDS)]
        creature:SendUnitSay(string.format(command, morphName, formName), 0)
        creature:PerformEmote(1)

        -- Apprentice morphs after 5 seconds
        apprentice:RegisterEvent(function(eventId, delay, repeats, apprentice)
            apprentice:CastSpell(apprentice, 61335, true)
            apprentice:SetDisplayId(selectedMorph.id)
        end, 5000 * 2, 1)

        -- Apprentice response after 8 seconds
        apprentice:RegisterEvent(function(eventId, delay, repeats, apprentice)
            local response = APPRENTICE_RESPONSES[math.random(#APPRENTICE_RESPONSES)]
            apprentice:SendUnitSay(response, 0)
            apprentice:PerformEmote(1)
        end, 8000 * 2, 1)

        -- Master's feedback after 10 seconds
        creature:RegisterEvent(function(eventId, delay, repeats, creature)
            local feedback = MASTER_FEEDBACK[math.random(#MASTER_FEEDBACK)]
            creature:SendUnitSay(feedback, 0)
            creature:PerformEmote(1)
        end, 10000 * 2, 1)
        
        apprentice:RegisterEvent(function(eventId, delay, repeats, apprentice)
            apprentice:DeMorph()
        end, 15000 * 2, 1)
        
        apprentice:RegisterEvent(function(eventId, delay, repeats, apprentice)
            apprentice:SendUnitSay("Ready for next task, master!", 0)
            apprentice:PerformEmote(2)
        end, 20000 * 2, 1)
        
    end, {50000, 200000}, 0)
end

local function ObserverScript(creature)
    creature:RegisterEvent(function(eventId, delay, repeats, creature)
        local i = math.random(1,5)
        if i == 1 then
            creature:SendUnitSay("It's so exciting to watch them learn new morphs!", 0)
        elseif i == 2 then
            creature:SendUnitSay("One day, I hope to get my very own "..GetItemLink(17890).."!", 0)
        elseif i == 3 then
            creature:SendUnitSay("This is my favorite time of day!", 0)
        elseif i == 4 then
            creature:SendUnitSay("Woah! That form is my favorite so far.", 0)
        elseif i == 5 then
            creature:SendUnitSay("Woohoo!", 0)
        end
        creature:PerformEmote(4)
    end, {60000, 190000}, 0)
end

local function ApproachBear(event, creature, who)
    if who:ToPlayer() then
        if not morphEventStarted[creature:GetGUIDLow()] then
            morphEventStarted[creature:GetGUIDLow()] = true
            local masters = {}
            local creaturesInRange = creature:GetCreaturesInRange(200, MASTER_ENTRY)
            
            for _, master in pairs(creaturesInRange) do
                table.insert(masters, master)
            end
            
            for _, master in pairs(masters) do
                if morphEventActive[master:GetGUIDLow()] then
                    return
                end
                morphEventActive[master:GetGUIDLow()] = true
                MorphScript(master)
            end
            
            local observers = {}
            local observersInRange = creature:GetCreaturesInRange(200, 110009)

            for _, observer in pairs(observersInRange) do
                table.insert(observers, observer)
            end

            for _, observer in pairs(observers) do
                if morphEventActive[observer:GetGUIDLow()] then
                    return
                end
                morphEventActive[observer:GetGUIDLow()] = true
                ObserverScript(observer)
            end
        end
        if not lastGreeting[creature:GetGUIDLow()] or (lastGreeting[creature:GetGUIDLow()] and (lastGreeting[creature:GetGUIDLow()] < os.time())) then
            lastGreeting[creature:GetGUIDLow()] = os.time() + 90
            creature:SendUnitSay("Keep practising your "..GetItemLink(17890).." shapeshifts! If you don't have a medallion yet, come talk to me.", 0)
        end
    end
end

local function XPdialogue(event, creature, who)
    if who:ToPlayer() and creature:GetDistance(who) < 10 and creature:IsWithinLoS(who) then
        if not lastGreeting[creature:GetGUIDLow()] or (lastGreeting[creature:GetGUIDLow()] and (lastGreeting[creature:GetGUIDLow()] < os.time())) then
            lastGreeting[creature:GetGUIDLow()] = os.time() + 90
            creature:SendUnitSay("Welcome to Yggdrasil, "..who:GetName().."! Let me know if you would like to adjust your XP rate or learn more about Yggdrasil.", 0)
            creature:PerformEmote(3)
        end
    end
end

RegisterCreatureEvent(35160, 27, DruidEnvoy) -- ally druid
RegisterCreatureEvent(57690, 27, DruidEnvoy) -- horde druid
RegisterCreatureEvent(95026, 27, FlightTrainerDialogue) -- Flight trainer
RegisterCreatureEvent(95005, 27, Herb) -- Herb trainer
RegisterCreatureEvent(95006, 27, Scribe) -- Scribe trainer
RegisterCreatureEvent(95014, 27, Fish) -- Scribe trainer
RegisterCreatureEvent(110000, 27, MamaDialogue) -- Mama Twig
RegisterCreatureEvent(190023, 27, XPdialogue) -- Mama Twig
RegisterCreatureEvent(1900230, 27, XPdialogue) -- Mama Twig
RegisterCreatureEvent(110001, 27, PapaDialogue) -- Papa Twig
RegisterCreatureEvent(110002, 27, PatrolDialogue) -- Twig Patrol
RegisterCreatureEvent(110005, 27, Guide) -- Twig guide
RegisterCreatureEvent(110006, 27, EdgeWarning) -- Twig safekepeer
RegisterCreatureEvent(190099, 27, Feathers) -- feathers vendor
RegisterCreatureEvent(190011, 27, HunterDialogue) -- Hunter pets
RegisterCreatureEvent(190013, 27, ProfDialogue) -- Profession master
RegisterCreatureEvent(190023, 27, XPDialogue) -- XP changer pets
RegisterCreatureEvent(190089, 27, MogDialogue) -- Mog itemizer
RegisterCreatureEvent(190090, 27, InstanceDialogue) -- XP changer pets
RegisterCreatureEvent(190091, 27, PetRenameDialogue) -- Pet renamer
RegisterCreatureEvent(190092, 27, Guild) -- Guild guy
RegisterCreatureEvent(190098, 27, ApproachBear) -- Morph bear
RegisterCreatureEvent(95015, 27, DeadTwig) -- Dead Twig DK Trainer, Runeforging gossip
RegisterCreatureEvent(401250, 6, Feathers) -- feathers event citizen
populatePlayerMorphCache()

print("[MALL]: Loaded mall dialogues")
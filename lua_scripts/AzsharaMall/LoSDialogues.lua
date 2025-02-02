local hasDialogueEvent = {}
local lastGreeting = {}

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
        if not player:HasSpell(19577) then
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

local function InstanceDialogue(event, creature, who)
    if who:ToPlayer() and creature:GetDistance(who) < 10 and creature:IsWithinLoS(who) then
        if not lastGreeting[creature:GetGUIDLow()] or (lastGreeting[creature:GetGUIDLow()] and (lastGreeting[creature:GetGUIDLow()] < os.time())) then
            lastGreeting[creature:GetGUIDLow()] = os.time() + 90
            creature:SendUnitSay("Psst, "..who:GetName().."! I can reset your instance lockouts through mysterious magic. First reset per week is free!", 0)
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

RegisterCreatureEvent(95026, 27, FlightTrainerDialogue) -- Flight trainer
RegisterCreatureEvent(190011, 27, HunterDialogue) -- Hunter pets
RegisterCreatureEvent(190013, 27, ProfDialogue) -- Profession master
RegisterCreatureEvent(190023, 27, XPDialogue) -- XP changer pets
RegisterCreatureEvent(190090, 27, InstanceDialogue) -- XP changer pets
RegisterCreatureEvent(190091, 27, PetRenameDialogue) -- Pet renamer
RegisterCreatureEvent(190089, 27, MogDialogue) -- Mog itemizer
RegisterCreatureEvent(110000, 27, MamaDialogue) -- Mama Twig
RegisterCreatureEvent(110001, 27, PapaDialogue) -- Papa Twig
RegisterCreatureEvent(110002, 27, PatrolDialogue) -- Twig Patrol
RegisterCreatureEvent(110005, 27, Guide) -- Twig Patrol

print("[MALL]: Loaded mall dialogues")
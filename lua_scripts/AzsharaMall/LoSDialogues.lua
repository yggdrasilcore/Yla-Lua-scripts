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
                    citizen:MoveTo(1, 1049.57, 407.32, 338.56534)
                end, 40000)
            end
        elseif id == 1 then
            creature:RegisterEvent(function(e, d, r, creature)
                creature:PerformEmote(69)
                creature:SendUnitEmote("Citizen of Yggdrasil mounts the gryphon.", 0) 
            end, 3000)
            creature:RegisterEvent(function(e, d, r, creature)
                creature:Mount(6852)
                creature:MoveTo(2, 1046, 414, 338.87894)
            end, 7000)
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

RegisterCreatureEvent(35160, 27, DruidEnvoy) -- ally druid
RegisterCreatureEvent(57690, 27, DruidEnvoy) -- horde druid
RegisterCreatureEvent(95026, 27, FlightTrainerDialogue) -- Flight trainer
RegisterCreatureEvent(401250, 6, Feathers) -- Flight trainer
RegisterCreatureEvent(190099, 27, Feathers) -- Flight trainer
RegisterCreatureEvent(190011, 27, HunterDialogue) -- Hunter pets
RegisterCreatureEvent(190013, 27, ProfDialogue) -- Profession master
RegisterCreatureEvent(190023, 27, XPDialogue) -- XP changer pets
RegisterCreatureEvent(190089, 27, MogDialogue) -- Mog itemizer
RegisterCreatureEvent(190090, 27, InstanceDialogue) -- XP changer pets
RegisterCreatureEvent(190091, 27, PetRenameDialogue) -- Pet renamer
RegisterCreatureEvent(190092, 27, Guild) -- Guild guy
RegisterCreatureEvent(110000, 27, MamaDialogue) -- Mama Twig
RegisterCreatureEvent(110001, 27, PapaDialogue) -- Papa Twig
RegisterCreatureEvent(110002, 27, PatrolDialogue) -- Twig Patrol
RegisterCreatureEvent(110005, 27, Guide) -- Twig guide
RegisterCreatureEvent(110006, 27, EdgeWarning) -- Twig safekepeer

print("[MALL]: Loaded mall dialogues")
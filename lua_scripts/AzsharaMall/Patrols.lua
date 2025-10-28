local TwiggyFlight
local TwiggyFlightActive
local lastEvent = {}
local lastGreeting = {}

local function OnWPReached(event, creature, type, id)
    if id == 0 then
        creature:MoveTo(1, 1051, 143, 334)
    elseif id == 1 then
        creature:MoveTo(2, 998, 153, 332)
    elseif id == 2 then
        creature:MoveTo(3, 898, 143, 303)
    elseif id == 3 then
        creature:SendUnitYell("Watch out! I'm comin' in hot!", 0)
        creature:PerformEmote(4)
        creature:MoveTo(4, 915, 192, 309)
    elseif id == 4 then
        creature:MoveTo(5, 926, 234, 316)
    elseif id == 5 then
        creature:MoveTo(6, 964, 270, 329)
    elseif id == 6 then
        creature:MoveTo(7, 1014, 284, 340)
    elseif id == 7 then
        creature:SendUnitSay("Ah, I love the feeling of fresh air in my branches!", 0)
        creature:PerformEmote(4)
        creature:MoveTo(8, 1056, 251, 350)
    elseif id == 8 then
        creature:MoveTo(9, 1138, 176, 367)
    elseif id == 9 then
        creature:MoveHome()
    end
end

local function OnHome(event, creature)
    TwiggyFlight = true
    creature:SendUnitSay("I am ready to teach flight paths to the citizens of Yggdrasil!", 0)
    creature:SetHover(true)
    creature:SetDisableGravity(true)
    creature:RegisterEvent(function(eventid, delay, repeats, creature)
       creature:SendUnitSay("Hold on, I must fly!", 0)
       creature:PerformEmote(3)
       creature:MoveTo(0, 1157, 98, 371)
       TwiggyFlightActive = true
    end, 30 * 1000 * 10)
end

local function WorldDialogue(event, creature, who)
    if who:ToPlayer() and creature:GetDistance(who) < 7 and creature:IsWithinLoS(who) and not TwiggyFlightActive then
        if not TwiggyFlight and creature:GetX() >= 1150 and creature:GetX() <= 1152 then
            creature:SetHomePosition(1151.03, 185.519, 364.122, 0.739941)
            creature:SendUnitSay("Hold on, I must fly!", 0)
            creature:MoveTo(0, 1157, 98, 371)
            TwiggyFlight = true
            TwiggyFlightActive = true
            return
        end
        if not lastGreeting[creature:GetGUIDLow()] or (lastGreeting[creature:GetGUIDLow()] and (lastGreeting[creature:GetGUIDLow()] < os.time())) then
            lastGreeting[creature:GetGUIDLow()] = os.time() + 90
            creature:SendUnitSay("I can teach you how to fly all over the warmer continents, "..who:GetName().."!", 0)
        end
    end
end

local function SandboxWarden(event, creature)
    if event == 6 then
        creature:SendUnitSay("Aren't they beautiful? Go on, give one a spin!", 0)
        creature:RegisterEvent(function(eventid, delay, repeats, creature)
            creature:SendUnitSay("I shall return to my post now.", 0)
            creature:MoveHome()
        end, 10000)
    end
end

local function SandboxWardenLOS(event, creature, var)
    if event == 5 then
        creature:SetHomePosition(881.04, 16.89, 309.34, 4.94)
    elseif event == 27 then
        if var:ToPlayer() and creature:GetDistance(var) < 7 and creature:IsWithinLoS(var) then
            if not creature:GetY() == 309.34393 then return end -- Don't schedule new event if creature is already climbing tower
            if not lastGreeting[creature:GetGUIDLow()] or (lastGreeting[creature:GetGUIDLow()] and (lastGreeting[creature:GetGUIDLow()] < os.time())) then
                lastGreeting[creature:GetGUIDLow()] = os.time() + 300
                creature:SendUnitSay("Greetings, "..var:GetName()..". I watch over a pristine collection of Sandbox Tigers. Come explore my tower to learn more.", 0)
                if lastEvent[creature:GetGUIDLow()] and os.time() < lastEvent[creature:GetGUIDLow()] + 300 then
                    return
                end
                lastEvent[creature:GetGUIDLow()] = os.time()
                creature:RemoveEvents()
                creature:SetSpeed(0, 0.35)
                creature:SetSpeed(1, 0.35)
                creature:RegisterEvent(function(eventid, delay, repeats, creature)
                    creature:MoveTo(0, 881, 14.26, 346.87)
                end, 5000)
            end
        end
    end
end

RegisterCreatureEvent(190095, 6, OnWPReached) -- Flight twig
RegisterCreatureEvent(190095, 24, OnHome) -- Flight twig
RegisterCreatureEvent(190095, 27, WorldDialogue) -- Flight twig

RegisterCreatureEvent(110004, 5, SandboxWardenLOS) -- Sandbox Warden on spawn
RegisterCreatureEvent(110004, 6, SandboxWarden) -- Sandbox Warden on WP reached
RegisterCreatureEvent(110004, 27, SandboxWardenLOS) -- Sandbox Warden on LOS
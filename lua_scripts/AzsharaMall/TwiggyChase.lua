if GetStateMapId() ~= 37 then return end

local targetName = "Twogga"

local function resetChase(eventId, delay, repeats, creature)
    creature:GetNearestCreature(200, 110003):Data():Set("isChaseInProgress", nil)
    creature:RemoveEvents()
    
    creature:SendUnitEmote(creature:GetName().." tags "..targetName..".")
    local dialogueNo = math.random(1,5)
    if dialogueNo == 1 then
        creature:SendUnitSay("Tagged! Good luck tagging me back, "..targetName.."!", 0)
    elseif dialogueNo == 2 then
        creature:SendUnitSay("Got you! You're it, "..targetName.."!", 0)
    elseif dialogueNo == 3 then
        creature:SendUnitSay("I heard "..targetName.." farts out of their stump!", 0)
    elseif dialogueNo == 4 then
        creature:SendUnitSay("No point running! You're already it, "..targetName.."!", 0)
    elseif dialogueNo == 5 then
        creature:SendUnitSay("Tagged you, "..targetName.."!", 0)
    end
    creature:PerformEmote(35)
    creature:MoveClear(true)
    creature:RegisterEvent(function(eventId, delay, repeats, creature)
        creature:MoveHome()
    end, 1000 * 3)
end

local function startChase(eventId, delay, repeats, creature)
    if creature:GetNearestCreature(200, 110003):Data():Get("isChaseInProgress") then
        return
    end
    
    creature:RemoveEvents()
    
    local possibleTargets = {}
    for i = 231980, 231989 do
        if i ~= creature:GetEntry() then
            table.insert(possibleTargets, i)
        end
    end
    
    local target = creature:GetNearestCreature(100, possibleTargets[math.random(#possibleTargets)])
    
    if target then
        target:RemoveEvents()
        creature:GetNearestCreature(200, 110003):Data():Set("isChaseInProgress", true)
        targetName = target:GetName()       
        local dialogueNo = math.random(1,5)
        local aura = creature:AddAura(61204, creature)
        if aura then aura:SetDuration(1000) end
        
        if dialogueNo == 1 then
            creature:SendUnitSay("Arrr! I'm gonna get ya!", 0)
        elseif dialogueNo == 2 then
            creature:SendUnitSay("Bollocks! At least I'm fast!", 0)
        elseif dialogueNo == 3 then
            creature:SendUnitSay("Joke's on you, I just had some "..GetItemLink(23578).." so no one can escape me now!", 0)
        elseif dialogueNo == 4 then
            creature:SendUnitSay("No! You're cheating!", 0)
        elseif dialogueNo == 5 then
            creature:SendUnitSay("I'll tell Papa you touched me!", 0)
        end
        
        creature:MoveFollow(target, 0.1, 0)
        creature:RegisterEvent(resetChase, 5000 * 3)
        target:RegisterEvent(startChase, 6000 * 3)
    end
end

local function teacherChase(eventId, delay, repeats, creature)
    local random_target = creature:GetNearestCreature(100, math.random(231980, 231989))
    if random_target then
        creature:MoveFollow(random_target, 2, 0)
    end
    
    local sayings = {
        "Settle down, children! I must teach you the ways of the world!",
        "So much chaos!",
        "I am tired every day I get home from work...",
        "Why can't you all just sit still for ONE minute?",
        "Back in my day we had DISCIPLINE!",
        "I need a vacation...", 
        "Running around like wild animals!",
        "Where did I put my lesson plans?",
        "I should have been a baker instead...",
        "Children! Children! Pay attention!"
    }
    
    local random_line = sayings[math.random(#sayings)]
    creature:SendUnitSay(random_line, 0)
end

local function OnSchoolSpawn(event, creature, _)
    if event == 24 then
        creature:MoveRandom(20)
    end
    
    if event == 27 and creature:Data():Get("chaseActive") then return end
    
    local entry = creature:GetEntry()
    
    if entry == 231980 then
        creature:RegisterEvent(startChase, 1000, 1)
    elseif entry == 110003 then
        if event == 27 then
            local chaser = creature:GetNearestCreature(100, 231980)
            if chaser then
                chaser:RegisterEvent(startChase, 1000, 1)
                creature:Data():Set("chaseActive", true)
            end
        end
        
        creature:RemoveEvents()
        local random_entry = math.random(231980, 231989)
        local random_target = creature:GetNearestCreature(100, random_entry)
        creature:RegisterEvent(teacherChase, 1, 1)
        creature:RegisterEvent(teacherChase, 30000, 0)
    end
    if event == 5 then
        local baseX, baseY, baseZ, baseOrientation = 789, 165, 272, 4.87
        
        local newX = baseX + math.random(-5, 5)
        local newY = baseY + math.random(-5, 5)
        
        creature:SetHomePosition(newX, newY, baseZ, baseOrientation)
    end
end

for i = 231980, 231989 do
    RegisterCreatureEvent(i, 5, OnSchoolSpawn)
    RegisterCreatureEvent(i, 24, OnSchoolSpawn)
end
RegisterCreatureEvent(110003, 5, OnSchoolSpawn)
RegisterCreatureEvent(110003, 27, OnSchoolSpawn)

-- Map-only script (all hooks fire in map states).
if GetStateMapId() == -1 then return end

local SPELL_ID = 42521
local ITEM_ID = 33113
local newZelfrax = 238640
local origZelfrax = 23864
local QUEST_ID = 11183
local SPAWN_X = -2984.31
local SPAWN_Y = -3853.15
local SPAWN_Z = 45.63
local SPAWN_O = 5.4137
local DEST_X = -2967.5769
local DEST_Y = -3871.569
local DEST_Z = 34.27
local AURA_ID = 29230  -- Aura ID to add and remove

local function origZelSpawn(event, creature)
    print("zelfrax spawned!")
    origZel = creature:GetNearestCreature(10, 23864)
    if origZel then
        creature:DespawnOrUnsummon()
        return
    end
    
    local zelfrax = creature:SpawnCreature(newZelfrax, SPAWN_X, SPAWN_Y, SPAWN_Z, SPAWN_O, 3, 300000)
    if zelfrax then
        print("starting events on new zelfrax!")
        zelfrax:SetDisableGravity(true)
        zelfrax:SetHover(false)
        zelfrax:AddAura(AURA_ID, zelfrax)  -- Add the aura when spawning
        zelfrax:RegisterEvent(function(eventId, delay, repeats, creature)
            creature:SendUnitYell("This land was mine long before you wretched kind set foot here.", 0)
        end, 0, 1)
        zelfrax:RegisterEvent(function(eventId, delay, repeats, creature)
            creature:SendUnitYell("All who venture here belong to me, including you!", 0)
        end, 5000, 1)
        zelfrax:RegisterEvent(function(eventId, delay, repeats, creature)
            creature:MoveStop()
            creature:MoveIdle()
            creature:SetDisableGravity(true)
            creature:SetHover(false)
            creature:MoveTo(1, DEST_X, DEST_Y, DEST_Z)
            creature:SetHomePosition(DEST_X, DEST_Y, DEST_Z, SPAWN_O)
        end, 6000, 1)
        
        zelfrax:RegisterEvent(function(eventId, delay, repeats, creature)
            creature:RemoveAura(AURA_ID)
        end, 6150, 1)

        zelfrax:RegisterEvent(function(eventId, delay, repeats, creature)
            local aggroTarget = creature:GetVictim()
            if aggroTarget and aggroTarget:IsPlayer() then
                creature:MoveChase(aggroTarget)
            end
        end, 6150, 10)
    end
end

local CREDIT_RANGE = 250

local function OnCreatureDeath(event, creature, killer)
    creature:RemoveEvents()
    origZel = creature:GetNearestCreature(200, 23864)
    if origZel then
        origZel:DespawnOrUnsummon()
    end
    if not (killer and killer:IsPlayer()) then return end
    local map = creature:GetMap()
    if not map then
        killer:CompleteQuest(QUEST_ID)
        return
    end
    local instanceId = creature:GetInstanceId()
    for _, member in pairs(map:GetPlayers()) do
        if member and member:IsPlayer() and member:IsInWorld()
            and (not instanceId or member:GetInstanceId() == instanceId)
            and creature:GetDistance(member) <= CREDIT_RANGE
            and (member == killer or killer:IsInSameGroupWith(member) or killer:IsInSameRaidWith(member)) then
            member:CompleteQuest(QUEST_ID)
        end
    end
end

RegisterCreatureEvent(origZelfrax, 5, origZelSpawn)
RegisterCreatureEvent(newZelfrax, 4, OnCreatureDeath)

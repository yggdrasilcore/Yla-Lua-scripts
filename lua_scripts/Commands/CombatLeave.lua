-- Multistate: PLAYER_EVENT_ON_COMMAND (42) fires in the global state while
-- PLAYER_EVENT_ON_ENTER_COMBAT (33) fires in map states. Coordination flags
-- ("isInBossFight", "cbstoptime") therefore live in shared Data() (visible from
-- every state) instead of per-state SetData. Group iteration stays in the
-- global command handler (Group API is world-only). The core "combatstop"
-- command is executed in the global state via EMQ.
local Multistate = require("Multistate")
local EMQ = require("EMQ")

local CLTime = {}

-- Global executor: runs the core combatstop command for the player.
EMQ.RegisterQueue("CombatLeaveStop", function(player, data)
    if player then
        player:RunCommand("combatstop")
    end
end)

local function requestCombatStop(player)
    if Multistate.IsCompat() or Multistate.IsWorld() then
        player:RunCommand("combatstop")
    else
        player:SendEMQMessage("CombatLeaveStop", {})
    end
end

local function ClearCombat(event, player, command)
    if command == "cl" or command == "combatleave" or command == "leavecombat" or command == "lc" then
        print(string.format("Player %s attempting to clear combat", player:GetName()))

        if not player:IsInCombat() then
            print(string.format("Player %s not in combat", player:GetName()))
            player:SendBroadcastMessage("You can't leave combat if you're not in combat!")
            return false
        end

        local isInBossFight

        if Multistate.GetData(player, "isInBossFight") then
            print(string.format("Player %s is in boss fight", player:GetName()))
            isInBossFight = true
            player:SendBroadcastMessage("You can't do that during a boss fight!")
            return false
        end

        local group = player:GetGroup()
        if group then
            print(string.format("Checking group members for player %s", player:GetName()))
            for _, member in ipairs(group:GetMembers()) do
                if Multistate.GetData(member, "isInBossFight") then
                    print(string.format("Group member %s is in boss fight", member:GetName()))
                    isInBossFight = true
                    break
                end
            end
        end

        if isInBossFight then
            player:SendBroadcastMessage("You can't do that during a boss fight!")
            return false
        end

        if not CLTime[player:GetName()] or CLTime[player:GetName()] <= os.time() then
            print(string.format("Clearing combat for player %s", player:GetName()))
            CLTime[player:GetName()] = os.time() + 5 * 60
            Multistate.SetData(player, "cbstoptime", os.time())
            requestCombatStop(player)
            player:SendBroadcastMessage("Your combat state has been cleared.")
        else
            print(string.format("Combat clear on cooldown for player %s", player:GetName()))
            player:SendBroadcastMessage("You can't do that yet!")
        end
        return false
    end
end

local TimedCBCheckTable = {}

local function TimedCBCheck(eventid, delay, repeats, player)
    if not player then return end

    if not player:IsInCombat() then
        Multistate.ClearData(player, "isInBossFight")
        TimedCBCheckTable[player:GetGUIDLow()] = nil
        RemoveEventById(eventid)
        return
    end

    local hasCreatureInReasonableRange = false
    local creatures = player:GetCreaturesInRange(200)

    --print(string.format("Checking %d creatures in range for player %s", #creatures, player:GetName()))

    for _, creature in pairs(creatures) do
        if creature:IsInCombat() then
            hasCreatureInReasonableRange = true
            break
        end
    end

    if not hasCreatureInReasonableRange then
        Multistate.ClearData(player, "isInBossFight")
        print("scheduling combat clear")
    end

    if player:GetInstanceId() and not hasCreatureInReasonableRange then
        print(string.format("Periodic Combat Clear - Player %s is in instance, clearing combat", player:GetName()))
        Multistate.SetData(player, "cbstoptime", os.time())
        requestCombatStop(player)
    end
end

local function EnterCombat(event, player, enemy)
    if enemy then
        local creature = enemy:ToCreature()
        if not creature then
            return
        end
        if creature:GetRank() > 1 then
            Multistate.SetData(player, "isInBossFight", true)
            if not TimedCBCheckTable[player:GetGUIDLow()] then
                TimedCBCheckTable[player:GetGUIDLow()] = true
                player:RegisterEvent(TimedCBCheck, 30000, 0)
            end
        end
    end
end

RegisterPlayerEvent(33, EnterCombat)
RegisterPlayerEvent(42, ClearCombat)

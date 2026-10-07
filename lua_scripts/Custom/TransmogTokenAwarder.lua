-- Multistate: PLAYER_EVENT_ON_COMPLETE_QUEST (54) and PLAYER_EVENT_ON_KILL_CREATURE
-- (7) fire in map states, but Group member listing is world-only, so group-wide
-- awarding is forwarded to the global state via EMQ.
local Multistate = require("Multistate")
local EMQ = require("EMQ")

local TRANSMOG_TOKEN_ID = 37742
local TRANSMOG_TOKEN_COUNT = 1
local LEVEL_DIFFERENCE = 9
local MAX_LEVEL = 80

local function ShouldReward(playerLevel, bossLevel, isWorldBoss)
    return playerLevel == MAX_LEVEL and
        (isWorldBoss or math.abs(playerLevel - bossLevel) <= LEVEL_DIFFERENCE)
end

-- Global executor: awards the killer's group (Group API is world-only).
local function DoTransmogTokenAward(player, data)
    if not player or not data then
        return
    end
    if player:IsInGroup() then
        for _, member in ipairs(player:GetGroup():GetMembers()) do
            if member:IsInWorld() and member:GetMapId() == data.mapId then
                local memberLevel = member:GetLevel()
                if ShouldReward(memberLevel, data.bossLevel, data.isWorldBoss) then
                    member:AddItem(TRANSMOG_TOKEN_ID, TRANSMOG_TOKEN_COUNT)
                    member:SendBroadcastMessage("You have been awarded an Activity Token for killing a boss!")
                end
            end
        end
    elseif ShouldReward(data.killerLevel, data.bossLevel, data.isWorldBoss) then
        player:AddItem(TRANSMOG_TOKEN_ID, TRANSMOG_TOKEN_COUNT)
        player:SendBroadcastMessage("You have been awarded an Activity Token for killing a boss!")
    end
end

EMQ.RegisterQueue("TransmogTokenAward", DoTransmogTokenAward)

-- Multistate: map-only script (all hooks fire in map states; the EMQ queue
-- above must still register in every state, hence the gate sits below it).
if not IsCompatibilityMode() and GetStateMapId() == -1 then return end

local function OnQuestComplete(event, player, quest)
    if player:GetLevel() == MAX_LEVEL
	and not (quest:GetId() == 3503)
	and not (quest:GetId() == 3421)
	then
        player:AddItem(TRANSMOG_TOKEN_ID, TRANSMOG_TOKEN_COUNT)
        player:SendBroadcastMessage("You have been awarded an Activity Token for completing a quest!")
    end
end

local function OnKillCreature(event, player, killed)
    local HP_LIMIT = 80000
    if killed:GetMaxHealth() < HP_LIMIT then return end

    local map = killed:GetMap()
    if map and map:IsRaid() then HP_LIMIT = 500000 end

    if killed:GetMaxHealth() < HP_LIMIT then return end

    if killed:IsDungeonBoss() or killed:IsWorldBoss() then

        local bossLevel = killed:GetLevel()
        local playerLevel = player:GetLevel()

        if not ShouldReward(playerLevel, bossLevel, killed:IsWorldBoss()) and not player:IsInGroup() then
            return
        end

        local data = {
            bossLevel = bossLevel,
            killerLevel = playerLevel,
            isWorldBoss = killed:IsWorldBoss(),
            mapId = player:GetMapId(),
        }
        if Multistate.IsCompat() or Multistate.IsWorld() then
            -- Compatibility/single-state: the global executor can run inline.
            DoTransmogTokenAward(player, data)
        else
            player:SendEMQMessage("TransmogTokenAward", data)
        end
    end
end

RegisterPlayerEvent(54, OnQuestComplete)
RegisterPlayerEvent(7, OnKillCreature)

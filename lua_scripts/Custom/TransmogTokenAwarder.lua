if GetStateMapId() == -1 then return end

local TRANSMOG_TOKEN_ID = 37742
local TRANSMOG_TOKEN_COUNT = 1
local LEVEL_DIFFERENCE = 9
local MAX_LEVEL = 80

local function ShouldReward(playerLevel, bossLevel, isWorldBoss)
    return playerLevel == MAX_LEVEL and
        (isWorldBoss or math.abs(playerLevel - bossLevel) <= LEVEL_DIFFERENCE)
end

local function AwardToken(member)
    member:AddItem(TRANSMOG_TOKEN_ID, TRANSMOG_TOKEN_COUNT)
    member:SendBroadcastMessage("You have been awarded an Activity Token for killing a boss!")
end

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
        local isWorldBoss = killed:IsWorldBoss()

        if not ShouldReward(playerLevel, bossLevel, isWorldBoss) and not player:IsInGroup() then
            return
        end

        if player:IsInGroup() then
            local map = player:GetMap()
            if not map then
                return
            end
            local instanceId = player:GetInstanceId()
            for _, member in pairs(map:GetPlayers()) do
                if member and member:IsInWorld()
                    and (not instanceId or member:GetInstanceId() == instanceId)
                    and (member == player or player:IsInSameGroupWith(member) or player:IsInSameRaidWith(member)) then
                    if ShouldReward(member:GetLevel(), bossLevel, isWorldBoss) then
                        AwardToken(member)
                    end
                end
            end
        elseif ShouldReward(playerLevel, bossLevel, isWorldBoss) then
            AwardToken(player)
        end
    end
end

RegisterPlayerEvent(54, OnQuestComplete)
RegisterPlayerEvent(7, OnKillCreature)

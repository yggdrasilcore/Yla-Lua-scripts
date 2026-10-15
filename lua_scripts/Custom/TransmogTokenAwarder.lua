if GetStateMapId() == -1 then return end

local TRANSMOG_TOKEN_ID = 37742
local TRANSMOG_TOKEN_COUNT = 1
local LEVEL_DIFFERENCE = 9
AWARD_TOKEN_MINIMUM_PLAYER_LEVEL = 1 -- Also referenced by Twiggy dialogue

local function OnQuestComplete(event, player, quest)
    if player:GetLevel() == AWARD_TOKEN_MINIMUM_PLAYER_LEVEL
	and not (quest:GetId() == 3503)
	and not (quest:GetId() == 3421)
	then
        player:AddItem(TRANSMOG_TOKEN_ID, TRANSMOG_TOKEN_COUNT)
        player:SendBroadcastMessage("You have been awarded an Activity Token for completing a quest!")
    end
end

local function OnKillCreature(event, player, killed)
    local hpLimit = 80000
    if killed:GetMap():IsRaid() then hpLimit = 500000 end
    if killed:GetMaxHealth() < hpLimit then return end

    if not (killed:IsDungeonBoss() or killed:IsWorldBoss()) then return end -- Only proceed for bosses

    local recipients = {}
    if player:IsInGroup() then
        for _, member in pairs(player:GetMap():GetPlayers()) do
            if member == player or player:IsInSameGroupWith(member) or player:IsInSameRaidWith(member) then
                table.insert(recipients, member)
            end
        end
    else
        table.insert(recipients, player)
    end

    for _, member in pairs(recipients) do
        if member:GetLevel() < killed:GetLevel() - LEVEL_DIFFERENCE
        or member:GetLevel() > killed:GetLevel() + LEVEL_DIFFERENCE
        then
            return -- If any player too high/low level, don't award tokens
        end
    end

    for _, member in pairs(recipients) do
        if member:GetLevel() == AWARD_TOKEN_MINIMUM_PLAYER_LEVEL then
            member:AddItem(TRANSMOG_TOKEN_ID, TRANSMOG_TOKEN_COUNT)
            member:SendBroadcastMessage("You have been awarded an Activity Token for killing a boss!")
        end
    end
end

RegisterPlayerEvent(54, OnQuestComplete)
RegisterPlayerEvent(7, OnKillCreature)
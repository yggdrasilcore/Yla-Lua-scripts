local TRANSMOG_TOKEN_ID = 37742
local TRANSMOG_TOKEN_COUNT = 1
local LEVEL_DIFFERENCE = 9
local MAX_LEVEL = 80

local function OnQuestComplete(event, player, quest)
    if player:GetLevel() == MAX_LEVEL 
	and not (quest:GetId() == 3503)
	and not (quest:GetId() == 3421)
	then
        player:AddItem(TRANSMOG_TOKEN_ID, TRANSMOG_TOKEN_COUNT)
        player:SendBroadcastMessage("You have been awarded a Transmog Token for completing a quest!")
    end
end

local function OnKillCreature(event, player, killed)
    if killed:GetEntry() == 36633 then return end
    if killed:IsDungeonBoss() or killed:IsWorldBoss() then
        
        local bossLevel = killed:GetLevel()
        local playerLevel = player:GetLevel()
        
        local shouldReward = playerLevel == MAX_LEVEL and 
                             (killed:IsWorldBoss() or math.abs(playerLevel - bossLevel) <= LEVEL_DIFFERENCE)
       
        
        if player:IsInGroup() then
            for _, member in ipairs(player:GetGroup():GetMembers()) do
                if member:IsInWorld() and member:GetMapId() == player:GetMapId() then
                    local memberLevel = member:GetLevel()
                    local shouldRewardMember = memberLevel == MAX_LEVEL and 
                                               (killed:IsWorldBoss() or math.abs(memberLevel - bossLevel) <= LEVEL_DIFFERENCE)
                    
                    if shouldRewardMember then
                        member:AddItem(TRANSMOG_TOKEN_ID, TRANSMOG_TOKEN_COUNT)
                        member:SendBroadcastMessage("You have been awarded a Transmog Token for killing a boss!")
                    end
                end
            end
        elseif shouldReward then
            player:AddItem(TRANSMOG_TOKEN_ID, TRANSMOG_TOKEN_COUNT)
            player:SendBroadcastMessage("You have been awarded a Transmog Token for killing a boss!")
        end
    end
end

RegisterPlayerEvent(54, OnQuestComplete)
RegisterPlayerEvent(7, OnKillCreature)
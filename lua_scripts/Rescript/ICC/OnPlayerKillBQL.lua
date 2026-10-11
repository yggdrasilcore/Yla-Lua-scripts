if not IsCompatibilityMode() and GetStateMapId() ~= 631 then return end

local AURAS = { 70877, 72151, 72649, 71949, 70867, 70879, 70923 }

local function OnPlayerKillBQL(event, player, killed)
    if killed:GetEntry() ~= 37955 then
        return
    end

    -- Fix buggy minchar quest completion
    local minchar = killed:GetNearestCreature(200, 38558, 0, 1)

    local questId = nil
    if minchar then
        local difficulty = player:GetDifficulty()
        questId = 24874 -- 10-man quest

        if difficulty == 1 or difficulty == 3 then
            questId = 24879 -- 25-man quest
        end
    end

    local map = killed:GetMap()
    if not map then
        return
    end
    local instanceId = killed:GetInstanceId()
    for _, member in pairs(map:GetPlayers()) do
        if member and (not instanceId or member:GetInstanceId() == instanceId) then
            for _, aura in ipairs(AURAS) do
                if member:HasAura(aura) then member:RemoveAura(aura) end
            end
            if questId and member:HasQuest(questId) then
                member:CompleteQuest(questId)
            end
        end
    end
end

RegisterPlayerEvent(7, OnPlayerKillBQL)

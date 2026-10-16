local EMQ = require("EMQ")

local MSG_QC = "#qc"

local function DeleteAllItemsInBag(player)
    for slot = 25, 38 do
        local item = player:GetItemByPos(255, slot)
        if item then
            player:RemoveItem(item:GetEntry(), item:GetCount())
        end
    end
end

local function CompleteAndRewardQuest(player, questID)
    if not player:HasQuest(questID) then
        player:AddQuest(questID)
    end
    player:CompleteQuest(questID)
    player:RewardQuest(questID)
    DeleteAllItemsInBag(player)
end

-- Map-state executor (via EMQ, or directly in compatibility mode).
local function DoQuestComplete(player, data)
    if not player then
        return
    end
    local questID = data.questID
    if not questID then
        return
    end
    local sel = player:GetSelection()
    if sel and data.targetGuidLow and sel:GetGUIDLow() == data.targetGuidLow and sel:IsPlayer() then
        CompleteAndRewardQuest(sel, questID)
    elseif data.targetName then
        local target
        for _, p in ipairs(GetStateMap():GetPlayers()) do
            if p:GetName() == data.targetName then target = p break end
        end
        if target then
            CompleteAndRewardQuest(target, questID)
        else
            CompleteAndRewardQuest(player, questID)
        end
    else
        CompleteAndRewardQuest(player, questID)
    end
end

EMQ.RegisterQueue("CmdQuestComplete", DoQuestComplete)

if GetStateMapId() ~= -1 then return end

function QuestAutoComplete(event, player, msg, Type, lang)
    local gmRank = player:GetGMRank()
    if gmRank >= 3 then
        local name = player:GetName()
        local lowerMsg = msg:lower()
        if string.sub(lowerMsg, 1, #MSG_QC) == MSG_QC then
            local questID = tonumber(string.sub(lowerMsg, #MSG_QC + 1))
            if questID then
                -- Capture the selection now; it is re-validated on the map state.
                local target = player:GetSelection()
                local targetGuidLow = nil
                local targetName = nil
                if target and target:IsPlayer() then
                    targetGuidLow = target:GetGUIDLow()
                    targetName = target:GetName()
                end
                WorldDBQueryAsync("SELECT * FROM quest_template WHERE ID = " .. questID, function(result)
                    local player = GetPlayerByName(name)
                    if not player then
                        print("Quest Complete Command error, player has gotten dereferenced!")
                        return
                    end
                    if result then
                        local data = { questID = questID, targetGuidLow = targetGuidLow, targetName = targetName }
                        player:SendEMQMessage("CmdQuestComplete", data)
                    else
                        player:SendBroadcastMessage("Non-existent quest ID: " .. questID)
                    end
                end)
            else
                player:SendBroadcastMessage("Invalid quest ID.")
            end
            return false
        end
    end
end

RegisterPlayerEvent(18, QuestAutoComplete)

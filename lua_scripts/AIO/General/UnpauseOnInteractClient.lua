local AIO = AIO or require("AIO")
if AIO.AddAddon() then
    return
end

local trackedGuid = nil
local pendingGuid = nil
local pendingDelay = 0
local lastSend = 0

local waiter = CreateFrame("Frame")
waiter:SetScript("OnUpdate", function(self, elapsed)
    if not pendingGuid then
        return
    end
    pendingDelay = pendingDelay - elapsed
    if pendingDelay > 0 then
        return
    end
    if GetTime() - lastSend < 5 then
        pendingDelay = 0.5
        return
    end
    lastSend = GetTime()
    if IsInGuild() then
        SendChatMessage(".unpause " .. pendingGuid, "GUILD")
    else
        SendChatMessage(".unpause " .. pendingGuid, "SAY")
    end
    pendingGuid = nil
end)

local frame = CreateFrame("Frame")
frame:RegisterEvent("GOSSIP_SHOW")
frame:RegisterEvent("MERCHANT_SHOW")
frame:RegisterEvent("TRAINER_SHOW")
frame:RegisterEvent("QUEST_GREETING")
frame:RegisterEvent("QUEST_DETAIL")
frame:RegisterEvent("QUEST_PROGRESS")
frame:RegisterEvent("QUEST_COMPLETE")
frame:RegisterEvent("GOSSIP_CLOSED")
frame:RegisterEvent("MERCHANT_CLOSED")
frame:RegisterEvent("TRAINER_CLOSED")
frame:RegisterEvent("QUEST_FINISHED")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "GOSSIP_CLOSED" or event == "MERCHANT_CLOSED"
        or event == "TRAINER_CLOSED" or event == "QUEST_FINISHED" then
        if trackedGuid then
            pendingGuid = trackedGuid
            pendingDelay = 0.5
        end
    else
        local guid = UnitGUID("npc")
        if guid then
            if pendingGuid and pendingGuid ~= guid then
                pendingDelay = 0
            else
                pendingGuid = nil
            end
            trackedGuid = guid
        end
    end
end)

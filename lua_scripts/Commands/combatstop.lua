if GetStateMapId() ~= -1 then return end
local debugprint = 0

local function OnCommand(event, player, command)
    if command:lower() == "combatstop" then
        local gmRank = player:GetGMRank()
        local cbstoptime = player:Data():Get("cbstoptime")
        local currentTime = os.time()
        if gmRank > 2 then
            if debugprint == 1 then
                print("Permitting combatstop command for "..player:GetName())
            end
            return true
        end
        if not (cbstoptime and math.abs(currentTime - cbstoptime) <= 2) then
            if debugprint == 1 then
                print("Denying combatstop command for "..player:GetName())
            end
            return false
        end
        if debugprint == 1 then
            print("Permitting combatstop command for "..player:GetName())
        end
        return true
    end
end

RegisterPlayerEvent(42, OnCommand)

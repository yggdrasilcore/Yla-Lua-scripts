if not (GetStateMapId() == 1) then return end

local function antiGMIslandCheat(event, player, newZone, newArea)
    if newZone == 876 and player:GetGMRank() == 0 then
        player:Teleport(13, 0, 0, 0, 0)
        player:SendAreaTriggerMessage("You have been detected in an area you're not supposed to be in!")
        print("[Anticheat] Player " .. player:GetName() .. " has been detected on GM island with too low GM rank!")
    end
end

RegisterPlayerEvent(27, antiGMIslandCheat)

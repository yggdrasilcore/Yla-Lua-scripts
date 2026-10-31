-- Magisters' Terrace-only script (map 585): quest 11490 The Scryer's Scryer.
if GetStateMapId() ~= 585 then return end

local function OnUseGameObject(event, go, player)
    player:RegisterEvent(function(eventId, delay, repeats, player)
       if player:GetMapId() == 585 and player:HasQuest(11490) then
           player:CompleteQuest(11490)
        end
    end, 10000, 1)
end

RegisterGameObjectEvent(187578, 14, OnUseGameObject)
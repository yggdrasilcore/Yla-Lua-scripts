local QUEST_ID = 11648
local REQUIRED_CASTS = 5
local NPC_ID = 25478
local AREA_ID = 4023
local EMOTE_STATE = 426
local emoteSet = 0

local spellCastCount = {}

local function OnUseZapper(event, player, item, target)
    local playerGUID = player:GetGUIDLow()
    spellCastCount[playerGUID] = (spellCastCount[playerGUID] or 0) + 1
    
    if spellCastCount[playerGUID] >= REQUIRED_CASTS then
        player:CompleteQuest(QUEST_ID)
        spellCastCount[playerGUID] = nil
    else
        local remainingCasts = REQUIRED_CASTS - spellCastCount[playerGUID]
    end
end

local function OnAreaTrigger(event, player, newZone, newArea)
    if newArea == AREA_ID and emoteSet == 0 then
        local npc = player:GetNearestCreature(400, NPC_ID)
        if npc then
            npc:EmoteState(EMOTE_STATE)
			emoteSet = 1
        end
    end
end

RegisterItemEvent(34811, 2, OnUseZapper)
RegisterPlayerEvent(27, OnAreaTrigger)

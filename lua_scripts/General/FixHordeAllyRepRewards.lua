-- Multistate: map-only script (all hooks fire in map states).
if GetStateMapId() == -1 then return end

local ALLIANCE_FACTIONS = {
    [47] = true,   -- Ironforge
    [54] = true,   -- Gnomeregan
    [69] = true,   -- Darnassus
    [71] = true,   -- Hillsbrad Militia
    [72] = true,   -- Stormwind
    [108] = true,  -- Theramore
    [189] = true,  -- Alliance Generic
    [269] = true,  -- Silvermoon Remnant
    [509] = true,  -- The League of Arathor
    [589] = true,  -- Wintersaber Trainers
    [730] = true,  -- Stormpike Guard
    [890] = true,  -- Silverwing Sentinels
    [930] = true,  -- Exodar
    [940] = true,  -- The Sons of Lothar
    [946] = true,  -- Honor Hold
    [959] = true,  -- Actor Good
    [961] = true,  -- Stillpine Furbolg
    [965] = true,  -- Monster Spar
    [966] = true,  -- Monster Spar Buddy
    [978] = true,  -- Kurenai
    [1050] = true, -- Valiance Expedition
    [1068] = true, -- Explorer's League
}

local HORDE_FACTIONS = {
    [66] = true,   -- Horde Generic
    [68] = true,   -- Undercity
    [76] = true,   -- Orgrimmar
    [81] = true,   -- Thunder Bluff
    [510] = true,  -- The Defilers
    [530] = true,  -- Darkspear Trolls
    [729] = true,  -- Frostwolf Clan
    [889] = true,  -- Warsong Outriders
    [911] = true,  -- Silvermoon City
    [922] = true,  -- Tranquillien
    [923] = true,  -- Farstriders
    [941] = true,  -- The Mag'har
    [947] = true,  -- Thrallmar
    [1052] = true, -- Horde Expedition
    [1067] = true, -- The Hand of Vengeance
    [1085] = true, -- Warsong Offensive
    [1124] = true, -- The Sunreavers
}

local function OnReputationChange(event, player, factionId, standing, incremental)
    if incremental then
    
        if player:IsAlliance() and HORDE_FACTIONS[factionId] then
            return -1
        end
        if not player:IsAlliance() and ALLIANCE_FACTIONS[factionId] then
            return -1
        end
        
    end
end

RegisterPlayerEvent(15, OnReputationChange)
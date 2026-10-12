-- Multistate: Azshara Mall-only script (mall map 37).
if GetStateMapId() ~= 37 then return end

local Beastmaster = {
    entry = 190011, -- Beastmaster entry.
    maxObj = 13, -- 13 = Max amount of menu objects.
    GUIDMap = {} -- Table to store player GUIDs
}

local playerPayment = {}

function Beastmaster.OnLogin(event, player)
    local lowGUID = player:GetGUIDLow()
    local name = player:GetName()
    Beastmaster.GUIDMap[name] = lowGUID
end

function Beastmaster.GetGUIDLow(player)
    local name = player:GetName()
    return Beastmaster.GUIDMap[name]
end

function Beastmaster.OnHello(event, player, unit)
    -- Check whether the player is a hunter and has Call Pet spell
    if player:GetClass() == 3 and player:HasSpell(19577) then
        player:GossipMenuAddItem(0, "Do you want to buy a hunter pet for 100 gold?", 0, 1)
        player:GossipSendMenu(1, unit)
    else
        unit:SendUnitWhisper("I only cater to Beastmasters.", 0, player)
        player:GossipComplete()
    end
end

function Beastmaster.OnSelect(event, player, unit, sender, intid, code)
    if intid == 1 then
        -- Check number of pets the player has (in-memory, no DB query)
        local petCount = player:GetPetCount()
        if petCount >= 5 then
            player:SendBroadcastMessage("You can't have more pets.")
            player:GossipComplete()
        else
            Beastmaster.GenerateMenu(1, player, unit)
        end
    elseif intid >= 1000 then
        -- Pet selection handling
        local petEntry = intid - 1000
        Beastmaster.GenerateMenu(intid - petEntry, player, unit)
        local initialPetCount = player:GetPetCount()

        if player:GetCoinage() >= 1000000 then
            -- Spawn a temporary, friendly version of the selected creature and force tame it.
            local pet = PerformIngameSpawn(1, petEntry, unit:GetMapId(), unit:GetInstanceId(), unit:GetX(), unit:GetY(), unit:GetZ(), unit:GetO(), false, 5000)
            pet:SetFaction(35)
            player:CastSpell(pet, 2650, true)
			
			if not playerPayment[player:GetName()] then
				playerPayment[player:GetName()] = player:GetName()
			end
	
            player:GossipComplete()
			player:SendAreaTriggerMessage("Taming pet...")
        
            if player:GetPetCount() > initialPetCount then
                player:ModifyMoney(-1000000)
                player:SendBroadcastMessage("You have been charged 100 gold for taming the pet.")
            else
                player:SendBroadcastMessage("You must stable your pet before you can get another.")
            end
        else
            player:SendBroadcastMessage("You can't afford my services.")
            player:GossipComplete()
        end
    else
        -- Navigation handling
        Beastmaster.GenerateMenu(sender, player, unit)
    end
end

function Beastmaster.GenerateMenu(id, player, unit)
    local low = ((Beastmaster.maxObj * id) - Beastmaster.maxObj + 1)
    local high = Beastmaster.maxObj * id
    
    -- Retrieve the current page sets' gossip option information.
    for i = low, high do
        local t = Beastmaster["Cache"][i]
        
        if t then -- show "i" if only exists in the table
            -- Do not list gossip options with creatures above the player's level.
            if player:GetLevel() >= t["level"] then
                player:GossipMenuAddItem(2, ""..t["name"], 0, 1000 + t["entry"])
            end
        end
    end
    
    -- If the menu is not the first menu, show Previous button.
    if id ~= 1 then
        player:GossipMenuAddItem(4, "<-- Previous", id - 1, 0)
    end
    
    -- If the next menu has available objects and object is within player level, show Next button.
    if Beastmaster["Cache"][high + 1] and (player:GetLevel() >= Beastmaster["Cache"][high + 1]["level"]) then
        player:GossipMenuAddItem(4, "Next -->", id + 1, 0)
    end
    
    player:GossipSendMenu(1, unit)
end

function Beastmaster.LoadCache()
    Beastmaster["Cache"] = {}

    WorldDBQueryAsync("SELECT Entry, Name, MaxLevel FROM creature_template WHERE Type=1 AND Type_Flags&1 <> 0 AND Family!=0 ORDER BY MaxLevel ASC;", function(Query)
        if Query then
            local i = 1
            repeat
                local name = Query:GetString(1)
                -- Check if the name doesn't contain parentheses, square brackets, "unused", or "test"
                if not (name:find("%(") or name:find("%)") or
                        name:find("%[") or name:find("%]") or
                        name:lower():find("unused") or name:lower():find("test")) then
                    Beastmaster["Cache"][i] = {
                        entry = Query:GetUInt32(0),
                        name = name,
                        level = Query:GetUInt32(2)
                    }
                    i = i + 1
                end
            until not Query:NextRow()

            -- Sort the cache alphabetically by name
            table.sort(Beastmaster["Cache"], function(a, b)
                return a.name < b.name
            end)

            print("[Eluna Beastmaster]: Cache initialized. Loaded ".. (i-1) .." tameable beasts.")
        else
            print("[Eluna Beastmaster]: Cache initialized. No results found.")
        end
    end)
end

Beastmaster.LoadCache()
RegisterPlayerEvent(3, Beastmaster.OnLogin)
RegisterCreatureGossipEvent(Beastmaster.entry, 1, Beastmaster.OnHello)
RegisterCreatureGossipEvent(Beastmaster.entry, 2, Beastmaster.OnSelect)

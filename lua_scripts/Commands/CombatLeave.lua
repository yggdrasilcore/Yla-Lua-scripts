local CLTime = {}
local function ClearCombat(event, player, command)
    if command == "cl" or command == "combatleave" or command == "leavecombat" or command == "lc" then
        print(string.format("Player %s attempting to clear combat", player:GetName()))
        
        if not player:IsInCombat() then
            print(string.format("Player %s not in combat", player:GetName()))
            player:SendBroadcastMessage("You can't leave combat if you're not in combat!")
            return false
        end
        
        local isInBossFight
        
        if player:GetData("isInBossFight") then
            print(string.format("Player %s is in boss fight", player:GetName()))
            isInBossFight = true
            player:SendBroadcastMessage("You can't do that during a boss fight!")
            return false
        end
        
        local group = player:GetGroup()
        if group then
            print(string.format("Checking group members for player %s", player:GetName()))
            for _, member in ipairs(group:GetMembers()) do
                if member:GetData("isInBossFight") then
                    print(string.format("Group member %s is in boss fight", member:GetName()))
                    isInBossFight = true
                    break
                end
            end
        end
        
        if isInBossFight then
            player:SendBroadcastMessage("You can't do that during a boss fight!")
            return false
        end
        
        if not CLTime[player:GetName()] or CLTime[player:GetName()] <= os.time() then
            print(string.format("Clearing combat for player %s", player:GetName()))
            CLTime[player:GetName()] = os.time() + 5 * 60
            player:SetData("cbstoptime", os.time())
            player:RunCommand("combatstop")
            player:SendBroadcastMessage("Your combat state has been cleared.")
        else
            print(string.format("Combat clear on cooldown for player %s", player:GetName()))
            player:SendBroadcastMessage("You can't do that yet!")
        end
        return false
    end
end

local TimedCBCheckTable = {}

local function TimedCBCheck(eventid, delay, repeats, player)
    if not player then 
        print("TimedCBCheck: Player is nil")
        return 
    end
    
    if not player:IsInCombat() then
        print(string.format("Player %s no longer in combat, removing boss fight flag", player:GetName()))
        player:SetData("isInBossFight", nil)
        TimedCBCheckTable[player:GetGUIDLow()] = nil
        RemoveEventById(eventid)
        return
    end
    
    local hasBossInRange = false
    local creatures = player:GetCreaturesInRange(200)
    
    --print(string.format("Checking %d creatures in range for player %s", #creatures, player:GetName()))
    
    for _, creature in pairs(creatures) do
        if creature:GetRank() > 1 and creature:IsInCombat() then
            print(string.format("Combat check debug for "..player:GetName()..": Found boss rank creature %s in combat", creature:GetName()))
            hasBossInRange = true
            break
        end
    end
    
    if not hasBossInRange then
        print(string.format("No boss in range for player %s, removing boss fight flag", player:GetName()))
        player:SetData("isInBossFight", nil)
        print("scheduling combat clear")
    end
    
    if player:GetInstanceId() and not hasBossInRange then
        print(string.format("Player %s is in instance, clearing combat", player:GetName()))
        player:SetData("cbstoptime", os.time())
        player:RunCommand("combatstop")
        print("clearing combat")
    end
end

local function EnterCombat(event, player, enemy)    
    if enemy then
        local creature = enemy:ToCreature()
        if not creature then
            return
        end
        if creature:GetRank() > 1 then
            player:SetData("isInBossFight", true)    
            if not TimedCBCheckTable[player:GetGUIDLow()] then
                TimedCBCheckTable[player:GetGUIDLow()] = true
                player:RegisterEvent(TimedCBCheck, 15000, 0)
            end
        end
    end
end

RegisterPlayerEvent(33, EnterCombat)
RegisterPlayerEvent(42, ClearCombat)
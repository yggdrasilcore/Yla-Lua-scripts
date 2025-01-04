local CLTime = {}

local function ClearCombat(event, player, command)
    if command == "cl" or command == "combatleave" or command == "leavecombat" or command == "lc" then
		if not player:IsInCombat() then
			player:SendBroadcastMessage("You can't leave combat if you're not in combat!")
			return false
		end
        
        local isInBossFight
        
        if player:GetData("isInBossFight") then
            isInBossFight = true
            player:SendBroadcastMessage("You can't do that during a boss fight!")
            return false
        end
        
        local group = player:GetGroup()

        if group then
            for _, member in ipairs(group:GetMembers()) do
                if member:GetData("isInBossFight") then
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
            CLTime[player:GetName()] = os.time() + 5 * 60
            player:ClearInCombat()
            player:SendBroadcastMessage("Your combat state has been cleared.")
        else
            player:SendBroadcastMessage("You can't do that yet!")
        end
        return false
    end
end

local function TimedCBCheck(eventid, delay, repeats, player)
    if not player then return end
    
    if not player:IsInCombat() then
        player:SetData("isInBossFight", nil)
        RemoveEventById(eventid)
        return
    end
    
    local hasBossInRange = false
    local creatures = player:GetCreaturesInRange(200)
    
    for _, creature in pairs(creatures) do
        if creature:GetRank() > 2 and creature:IsInCombat() then
            hasBossInRange = true
            break
        end
    end
    
    if not hasBossInRange then
        player:SetData("isInBossFight", nil)
        RemoveEventById(eventid)
    end
end

local function EnterCombat(event, player, enemy)
    if enemy then
        creature = enemy:ToCreature()
        if creature and creature:GetRank() > 2 then
            player:SetData("isInBossFight", true)
            player:RegisterEvent(TimedCBCheck, 20000, 0)
        end
    end
end

RegisterPlayerEvent(33, EnterCombat)
RegisterPlayerEvent(42, ClearCombat)

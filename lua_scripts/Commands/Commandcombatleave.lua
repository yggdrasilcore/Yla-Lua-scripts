local CLTime = {}

local function IsBoss(creature)
    return (creature:IsWorldBoss() and creature:IsInCombat()) or (creature:IsDungeonBoss() and creature:IsInCombat())
end

local function ClearCombat(event, player, command)
    if command == "cl" or command == "combatleave" or command == "leavecombat" or command == "lc" then
		if not player:IsInCombat() then
			player:SendBroadcastMessage("You can't leave combat if you're not in combat!")
			return false
		end
		
        local function CheckForBoss(unit)
            local target = unit:GetSelection()
            if target and IsBoss(target) then
                return true
            end
            return false
        end

        -- Check if player or any group member is targeting a boss
        local group = player:GetGroup()
        local fightingBoss = CheckForBoss(player)

        -- If not fighting a boss, check group members
        if not fightingBoss and group then
            for _, member in ipairs(group:GetMembers()) do
                if CheckForBoss(member) then
                    fightingBoss = true
                    break
                end
            end
        end

        -- Check for nearby hostile bosses
        if not fightingBoss then
            local nearbyCreatures = player:GetCreaturesInRange(110)
            for _, creature in ipairs(nearbyCreatures) do
                if IsBoss(creature) then
                    fightingBoss = true
                    break
                end
            end
        end

        if fightingBoss then
            player:SendBroadcastMessage("You can't do that during a boss fight!")
            return false
        end

        -- Proceed with the original combat leave logic
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

RegisterPlayerEvent(42, ClearCombat)

-- Improves the terrible AzerothCore approach to .learn ###. Won't get stuck if NPC is targeted anymore. made by mostly nick :)

local function onCommand(event, player, command)
    if command:match("^%s*learn%s+(%d+)%s*$") then
        local _, _, spellIdStr = command:find("^%s*learn%s+(%d+)%s*$")
        local spellId = tonumber(spellIdStr)

        if spellId then
            if player:GetSelection() and player:GetSelection():IsPlayer() then
                target:LearnSpell(spellId)
            else
                player:LearnSpell(spellId)
            end
            
            player:RegisterEvent(function(eventId, delay, repeats, player)
                if player:GetSelection() and not player:GetSelection():HasSpell(spellId) then
                    player:SendBroadcastMessage("Invalid spell ID. Please provide a valid number.")
                elseif not player:HasSpell(spellId) then
                    player:SendBroadcastMessage("Invalid spell ID. Please provide a valid number.")
                end
            end, 20, 1)
        else
            player:SendBroadcastMessage("Invalid spell ID. Please provide a valid number.")
        end
        return false
    end
end

RegisterPlayerEvent(42, onCommand)

local SPELL_BINDING_LIFE = 48809
local AREA_ID = 4185
local CHECK_INTERVAL = 30 -- milliseconds
local BINDING_LIFE_DURATION = 600 -- 10 minutes in seconds

local bindingLifeTimer = {}
local playerEvents = {}

local function createCheckPlayerCastingFunction(player)
    local guid = player:GetGUID()
    local playerName = player:GetName()
    return function(eventId, delay, repeats)
        player = GetPlayerByGUID(guid) -- Refresh player object
        if not player or player:GetAreaId() ~= AREA_ID then
            RemoveEventById(eventId)
            playerEvents[playerName] = nil
            bindingLifeTimer[playerName] = nil
            --print("Removed event for player (left area or offline): " .. playerName)
            return
        end

        --print("Checking player: " .. playerName)
        --print("Current bindingLifeTimer table:")
        --for k, v in pairs(bindingLifeTimer) do
            --print(k .. ": " .. v)
        --end

        local timestamp = bindingLifeTimer[playerName]
        if player:IsCasting() and not player:IsInCombat() then
            if timestamp then
                --print("Timestamp detected: " .. timestamp)
                local elapsedTime = os.time() - timestamp
                if elapsedTime < BINDING_LIFE_DURATION then
                    local remainingDuration = BINDING_LIFE_DURATION - elapsedTime
					player:AddAura(SPELL_BINDING_LIFE, player)
                    
                    local aura = player:GetAura(SPELL_BINDING_LIFE)
                    if aura then
                        aura:SetDuration(remainingDuration * 1000) -- Convert to milliseconds
                        --print("Reapplied Binding Life with duration: " .. remainingDuration .. " seconds for " .. playerName)
                    end
                    
                    -- Remove the event after successfully reapplying the buff
                    --RemoveEventById(eventId)
                    --playerEvents[playerName] = nil
                    --bindingLifeTimer[playerName] = nil
                end
            else
                --print("ERROR - No timestamp detected for player: " .. playerName)
            end
        elseif not player:HasAura(SPELL_BINDING_LIFE) then
            -- Remove the event if the player doesn't have the buff and isn't casting
            RemoveEventById(eventId)
            playerEvents[playerName] = nil
            bindingLifeTimer[playerName] = nil
            print("Removed event for player (no aura and not casting): " .. playerName)
        end
    end
end

local function onSpellCast(event, player, spell)
    local spellId = spell:GetEntry()
    local playerName = player:GetName()
    
    if spellId == SPELL_BINDING_LIFE and player:GetAreaId() == AREA_ID then
        bindingLifeTimer[playerName] = os.time()
       
        if not playerEvents[playerName] then
            local checkFunction = createCheckPlayerCastingFunction(player)
            local eventId = CreateLuaEvent(checkFunction, CHECK_INTERVAL, 0)
            playerEvents[playerName] = eventId
            --print("Binding life cast registered at time " .. bindingLifeTimer[playerName] .. " for player: " .. playerName)
        end
		
    elseif player:GetAreaId() == AREA_ID and bindingLifeTimer[playerName] and not player:IsInCombat() then
        local timestamp = bindingLifeTimer[playerName]
		local elapsedTime = os.time() - timestamp
		if elapsedTime < BINDING_LIFE_DURATION then
			local remainingDuration = BINDING_LIFE_DURATION - elapsedTime
			player:AddAura(SPELL_BINDING_LIFE, player)
			
			local aura = player:GetAura(SPELL_BINDING_LIFE)
			if aura then
				aura:SetDuration(remainingDuration * 1000) -- Convert to milliseconds
				--print("Reapplied Binding Life with duration: " .. remainingDuration .. " seconds for " .. playerName)
			end
		end
	end
end

local function onAreaChange(event, player, newArea, oldArea)
    local playerName = player:GetName()
        
    if oldArea == AREA_ID and bindingLifeTimer[playerName] then
        bindingLifeTimer[playerName] = nil
        
        if playerEvents[playerName] then
            RemoveEventById(playerEvents[playerName])
            playerEvents[playerName] = nil
			--print("Player left the Forgotten Shore: " .. playerName)
        end
    end
end

RegisterPlayerEvent(5, onSpellCast)
RegisterPlayerEvent(27, onAreaChange)
print("[Quest 12291 Fix]: Binding Life reapplication script loaded.")
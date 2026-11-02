-- Constants
local QUEST_ID = 30000
local TELEPORT_ITEM = 21878
local QUEST_ITEM = 39163
local AREA_ID = 268 -- Azshara crater temple 
local MAP_ID = 37 -- Azshara crater
local SHADOW_ENTRY = 30842 -- Player shadows
local TIMERENDER_ENTRY = 27900 -- Hostile NPC
local SWIRL_ENTRY = 17838 -- Swirly texture from time warp
local SHACKLE_AURA = 38505 -- Shackle permanent spell
local STUN_AURA = 52165 -- Stun permanent spell, prevents NPC from killing player
local SHADOWFORM_AURA = 58001 -- Makes shadows seem less janky textured
local IMMUNE_ALL = 29230 -- Prevents premature dragon death
local HEARTHSTONE = 8690 -- Teleport player away when done, if no cached location saved
local DespawnTimer = 180000 -- 3 minutes quest time
local EventLocation = {-639.76, -259.62, 352.58, 2.27}

-- World event onCommand
local function OnShadowsEventCommand(event, player, command)
    if command == "startshadowsevent" and player:HasItem(TELEPORT_ITEM) then
    
        if (player:GetAreaId() == AREA_ID) then
            player:SendAreaTriggerMessage("You can't save your shadows from this location! Try again someplace else.")
            player:SendBroadcastMessage("You can't save your shadows from this location! Try again someplace else.")
            return false
        end
        
        if GetWorldData("shadowsQuestCooldown") and GetWorldData("shadowsQuestCooldown") > os.time() then
            player:SendAreaTriggerMessage("You can't save your shadows right now! Try again in a few minutes.")
            player:SendBroadcastMessage("You can't save your shadows right now! Try again in a few minutes.")
            return false
        end
        
        player:Data():Set("OldMap", player:GetMapId())
        player:Data():Set("OldX", player:GetX())
        player:Data():Set("OldY", player:GetY())
        player:Data():Set("OldZ", player:GetZ())
        player:Data():Set("OldO", player:GetO())
        
        SetWorldData("shadowsQuestCooldown", os.time() + DespawnTimer / 1000)
        
        player:Teleport(MAP_ID, EventLocation[1], EventLocation[2], EventLocation[3], EventLocation[4])
        return false
    elseif command == "stopshadowsevent" then
        player:RemoveAura(IMMUNE_ALL)
        player:RemoveAura(SHACKLE_AURA)
        player:Data():Set("shadowsTeleportReason", nil)
        player:Data():Set("ShadowsQuestState", 0)
        if not player:Data():Get("shadowsTeleportReason") or player:Data():Get("shadowsTeleportReason") == "failed" then
            if player and player:GetAreaId() == AREA_ID and (player:HasItem(TELEPORT_ITEM) or player:HasItem(QUEST_ITEM)) then
                player:RemoveItem(TELEPORT_ITEM, 1)
                player:RemoveItem(QUEST_ITEM, 1)
                player:RemoveQuest(QUEST_ID)
                player:AddItem(QUEST_ITEM, 1)
                if player:Data():Get("OldMap") then
                    player:Teleport(player:Data():Get("OldMap"), player:Data():Get("OldX"), player:Data():Get("OldY"), player:Data():Get("OldZ"), player:Data():Get("OldO"))
                else
                    player:CastSpell(player, 8690, true)
                end
                player:SendAreaTriggerMessage("You didn't help your shadows in time and they got pulled into the Twisting Nether! Try again later.")
                player:SendBroadcastMessage("You didn't help your shadows in time and they got pulled into the Twisting Nether! Try again later.")
            end
        else
            if player:Data():Get("OldMap") then
                player:Teleport(player:Data():Get("OldMap"), player:Data():Get("OldX"), player:Data():Get("OldY"), player:Data():Get("OldZ"), player:Data():Get("OldO"))
            else
                player:CastSpell(player, 8690, true)
            end
        end
        
        SetWorldData("shadowsQuestCooldown", os.time() + DespawnTimer / 1000)
        
        return false
    end
end

-- Map event OnPlayerEnterMap
local function ShadowsMap(event, player)
    if player:GetAreaId() == AREA_ID then
        if player:HasQuest(QUEST_ID) then
        
            local playerLocation = {player:GetLocation()}
            if not ((player:GetX() >= EventLocation[1]-1 and player:GetX() <= EventLocation[1]+1) and
                    (player:GetY() >= EventLocation[2]-1 and player:GetY() <= EventLocation[2]+1)) then
                    player:Data():Set("ShadowsQuestEvent", nil)
                return
            end

            player:Data():Set("ShadowsQuestEvent", true)
            
            player:RegisterEvent(function(eventId, delay, repeats, player)
                player:Data():Set("shadowsTeleportReason", "failed")
                player:RunCommand("stopshadowsevent")
            end, 180000, 1)
            
            local shadows = player:GetCreaturesInRange(50, SHADOW_ENTRY)
            for _, shadow in pairs(shadows) do
                shadow:DespawnOrUnsummon()
            end

            local timerender = player:GetNearestCreature(50, TIMERENDER_ENTRY)
            local swirl = player:GetNearestCreature(50, SWIRL_ENTRY)
           
            if timerender then timerender:DespawnOrUnsummon() end
            if swirl then swirl:DespawnOrUnsummon() end
            
            player:Data():Set("ShadowsQuestState", 0)
            
            local x, y, z, o = player:GetLocation()
            local facing = player:GetO()
            
            -- Spawn shadows in cone
            for i = -1, 1 do
                local angle = facing + (i * 0.5)
                local sx = x + (math.cos(angle) * 20)
                local sy = y + (math.sin(angle) * 20)
                local shadow = player:SpawnCreature(SHADOW_ENTRY, sx, sy, z, angle + math.pi, 1, DespawnTimer)
                shadow:SetLevel(player:GetLevel())
                shadow:SetDisplayId(player:GetDisplayId())
                shadow:SetFaction(35)
                shadow:AddAura(SHADOWFORM_AURA, shadow)
                shadow:AddAura(SHACKLE_AURA, shadow)
                shadow:AddAura(STUN_AURA, shadow)
            end
            
            -- Spawn Timerender
            local tx = x + (math.cos(facing) * 30)
            local ty = y + (math.sin(facing) * 30)
            local timerender = player:SpawnCreature(TIMERENDER_ENTRY, tx, ty, z, facing + math.pi, 1, DespawnTimer)
            timerender:SetLevel(player:GetLevel() + 3)
            timerender:AddAura(STUN_AURA, timerender)
            timerender:AddAura(IMMUNE_ALL, timerender)
            
            -- Spawn Swirl
            local twx = x + (math.cos(facing) * 35)
            local twy = y + (math.sin(facing) * 35)
            player:SpawnCreature(SWIRL_ENTRY, twx, twy, z, facing + math.pi, 1, DespawnTimer)
            
            player:AddAura(SHACKLE_AURA, player)
            local playerImmunity = player:AddAura(IMMUNE_ALL, player)
			if playerImmunity then
				playerImmunity:SetDuration(180000)
			end
            player:RegisterEvent(function(eventId, delay, repeats, player)
                local shadowSpeak = player:GetNearestCreature(50, SHADOW_ENTRY)
                shadowSpeak:SendUnitSay("Help us, "..player:GetName().."! We are shadows of your characters and have been trapped in time by the Black Dragonflight! Quickly, instruct us to break these chains and fight back!", 0)
                player:RegisterEvent(function(eventId, delay, repeats, player)
                    player:SendAreaTriggerMessage("Instruct your shadows to defend themselves! Say \"formation shield\"!")
                    player:SendBroadcastMessage("Instruct your shadows to defend themselves! Say \"formation shield\"!")
                end, 5000)
            end, 5000)
        else
            player:Data():Set("ShadowsQuestEvent", nil)
            player:RemoveAura(IMMUNE_ALL)
            player:RemoveAura(SHACKLE_AURA)
        end
    end
end

-- World event
local function Talk(event, player, msg, Type, lang)
    if player:GetAreaId() ~= AREA_ID then return end
    
    if not player:Data():Get("ShadowsQuestEvent") then return end
    
    local shadowSpeak = player:GetNearestCreature(50, SHADOW_ENTRY)
    
    if not shadowSpeak then return end
    
    if msg:lower() == "formation shield" and (player:Data():Get("ShadowsQuestState") or 0) == 0 then
        local shadows = player:GetCreaturesInRange(50, SHADOW_ENTRY)
        local timerender = player:GetNearestCreature(50, TIMERENDER_ENTRY)
        if timerender then
            for _, shadow in pairs(shadows) do
                shadow:SetFacingToObject(timerender)
            end
        end
        
        player:RegisterEvent(function(eventId, delay, repeats, player)
            local shadowSpeak = player:GetNearestCreature(50, SHADOW_ENTRY)
            shadowSpeak:SendUnitSay("Great! Now instruct us to attack our captor!", 0)
            player:RegisterEvent(function(eventId, delay, repeats, player)
                player:SendAreaTriggerMessage("Say \"attack\" to make your shadows attack the captor!")
                player:SendBroadcastMessage("Say \"attack\" to make your shadows attack the captor!")
                player:Data():Set("ShadowsQuestState", 1)
            end, 2000, 1)
        end, 5000, 1)
    elseif msg:lower() == "attack" and (player:Data():Get("ShadowsQuestState") or 0) == 1 then
        local shadowSpeak = player:GetNearestCreature(50, SHADOW_ENTRY)
        local shadows = player:GetCreaturesInRange(50, SHADOW_ENTRY)
        local timerender = player:GetNearestCreature(50, TIMERENDER_ENTRY)
        for _, shadow in pairs(shadows) do
            shadow:RemoveAura(SHACKLE_AURA)
            shadow:RemoveAura(STUN_AURA)
        end
        shadowSpeak:RegisterEvent(function(eventId, delay, repeats, shadowSpeak)
            shadowSpeak:SendUnitSay("We need further directions!", 0)
            local timerender = shadowSpeak:GetNearestCreature(50, TIMERENDER_ENTRY)
            local shadows = shadowSpeak:GetCreaturesInRange(50, SHADOW_ENTRY)
            for _, shadow in pairs(shadows) do
                shadow:Attack(timerender)
            end
            shadowSpeak:Attack(timerender)
        end, 2000, 1)
        player:RegisterEvent(function(eventId, delay, repeats, player)
            player:SendAreaTriggerMessage("Target the Infinite Timerender and say \"cast Frostbolt\"!")
            player:SendBroadcastMessage("Target the Infinite Timerender and say \"cast Frostbolt\"!")
            player:Data():Set("ShadowsQuestState", 2)
        end, 4000, 1)
    elseif msg:lower() == "cast frostbolt" and (player:Data():Get("ShadowsQuestState") or 0) == 2 and player:GetSelection() then
        local shadows = player:GetCreaturesInRange(50, SHADOW_ENTRY)
        local timerender = player:GetNearestCreature(50, TIMERENDER_ENTRY)
        
        if player:GetSelection() == timerender then
            timerender:RemoveAura(IMMUNE_ALL)
            local shadows = player:GetCreaturesInRange(50, SHADOW_ENTRY)
            for _, shadow in pairs(shadows) do
                shadow:CastSpell(timerender, 116, false)
            end
            
            player:RegisterEvent(function(eventId, delay, repeats, player)
                local timerender = player:GetNearestCreature(50, TIMERENDER_ENTRY)
                if timerender then
                    player:Kill(timerender)
                    timerender:DespawnOrUnsummon(5000)
                end
                
                player:CompleteQuest(QUEST_ID)
                
                local shadows = player:GetCreaturesInRange(50, SHADOW_ENTRY)
                for _, shadow in pairs(shadows) do
                    shadow:DespawnOrUnsummon(9000)
                end
                
                local shadowSpeak = player:GetNearestCreature(50, SHADOW_ENTRY)
                shadowSpeak:RegisterEvent(function(eventId, delay, repeats, shadowSpeak)
                    shadowSpeak:SendUnitSay("Thank you, we are free! You can now control your shadows. Speak to your Twiggy to learn more.", 0)
                end, 2000, 1)
                
                shadowSpeak:RegisterEvent(function(eventId, delay, repeats, shadowSpeak)
                    shadowSpeak:SendUnitSay("Allow us to teleport you back to your original location.", 0)
                end, 10000, 1)
                
                player:RegisterEvent(function(eventId, delay, repeats, player)
                    player:RemoveItem(QUEST_ITEM, 1)
                    player:RemoveItem(TELEPORT_ITEM, 1)
                    player:RewardQuest(QUEST_ID)
                    
                    local shadows = player:GetCreaturesInRange(50, SHADOW_ENTRY)
                    for _, shadow in pairs(shadows) do
                        shadow:CastSpell(shadow, 32783, false)
                    end
                end, 12000, 1)
                
                local swirl = player:GetCreaturesInRange(50, SWIRL_ENTRY)[1]
                if swirl then
                    swirl:DespawnOrUnsummon(13000)
                end
                
                player:RegisterEvent(function(eventId, delay, repeats, player)
                    player:Data():Set("shadowsTeleportReason", "success")
                    player:RunCommand("stopshadowsevent")
                end, 13000, 1)
                
            end, 4000, 1)
        end
    end
end

-- Creature events
local function AddLostAura(event, shadow, target)
    if shadow:GetAreaId() == AREA_ID then
        shadow:RegisterEvent(function(eventId, delay, repeats, shadow)
            shadow:AddAura(SHADOWFORM_AURA, shadow)
        end, 10, 1)
    end
end

-- Item map event onUseItem, bridges to world state through deferred command exec
local function ShadowsTeleItem(event, player, item, target)
    player:RunCommand("startshadowsevent")
    return false
end

-- Player map event OnLevelUp
local function OnLevelUp(event, player, oldLevel)
    if player:GetAreaId() == 609 then return end
    if (player:GetQuestStatus(QUEST_ID) == 6) then return end
    if player:HasItem(TELEPORT_ITEM, 1) then return end
    player:AddItem(39163, 1)
    player:SendBroadcastMessage("You hear mysterious whispers echo in the horizon... An unknown item from the void appears!")
end

-- Player map event OnQuestAbandon
local function OnQuestAbandon(event, player, questId)
    if questId == QUEST_ID then
        player:AddItem(QUEST_ITEM, 1)
    end
end

-- Player world event OnLogin
local function OnLogin(event, player)
    if player:GetAreaId() == 609 then return end
    if player:GetLevel() < minShadowsLevel then return end
    
    if player:HasQuest(QUEST_ID) and player:HasItem(TELEPORT_ITEM, 1) and player:HasItem(QUEST_ITEM, 1) then
        player:RemoveItem(QUEST_ITEM, 1)
    end
    if player:HasQuest(QUEST_ID) and not player:HasItem(TELEPORT_ITEM, 1) then
        player:AddItem(TELEPORT_ITEM, 1)
    end
    if not player:HasQuest(QUEST_ID) and not (player:GetQuestStatus(QUEST_ID) == 6) and not player:HasItem(QUEST_ITEM) then
        if player:HasItem(TELEPORT_ITEM, 1) then
            player:RemoveItem(TELEPORT_ITEM, 1)
        end
        player:AddItem(QUEST_ITEM, 1)
        player:RegisterEvent(function(eventId, delay, repeats, player)
            player:SendBroadcastMessage("You hear mysterious whispers echo in the horizon... An unknown item from the void appears!")
        end, 1000, 1)
    end
    if player:HasItem(TELEPORT_ITEM, 1) and (player:GetQuestStatus(30000) == 6) then
        player:RemoveItem(TELEPORT_ITEM, 1)
        if player:HasQuest(QUEST_ID) then
            player:RemoveQuest(QUEST_ID)
        end
    end
    if player:HasItem(QUEST_ITEM, 1) and (player:GetQuestStatus(30000) == 6) then
        player:RemoveItem(QUEST_ITEM, 1)
        if player:HasQuest(QUEST_ID) then
            player:RemoveQuest(QUEST_ID)
        end
    end
end

if GetStateMapId() == 37 then -- Only Azshara Mall
    RegisterPlayerEvent(28, ShadowsMap)
    RegisterCreatureEvent(SHADOW_ENTRY, 1, AddLostAura)
    RegisterCreatureEvent(SHADOW_ENTRY, 2, AddLostAura)
elseif GetStateMapId() == -1 then -- Only world
    RegisterPlayerEvent(3, OnLogin)
    RegisterPlayerEvent(18, Talk)
    RegisterPlayerEvent(42, OnShadowsEventCommand)
    SetWorldData("shadowsQuestCooldown", os.time())
else -- All maps
    RegisterItemEvent(TELEPORT_ITEM, 2, ShadowsTeleItem)
    RegisterPlayerEvent(13, OnLevelUp)
    RegisterPlayerEvent(38, OnQuestAbandon)
end

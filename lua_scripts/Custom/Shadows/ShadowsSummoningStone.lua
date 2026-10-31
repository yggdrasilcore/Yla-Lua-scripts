-- Shadows summoning stone. Cross-map summons run through a world command.

local function SelectedLow(player)
    local guid = player:GetSelectionGUID()
    if guid and GetGUIDType(guid) == 0 then
        local low = GetGUIDLow(guid)
        if low ~= 0 then return low end
    end
end

local function SummonCommand(player, targetLow, ritual)
    player:RunCommand(("shadowsummon %d %d %f %f %f %f %d"):format(targetLow, player:GetMapId(), player:GetX(), player:GetY(), player:GetZ(), player:GetO(), ritual))
end

local function CheckGroup(player, target)
    if player:IsInSameGroupWith(target) or player:IsInSameRaidWith(target) then return true end
    player:SendBroadcastMessage("You can only summon shadows in your group.")
end

local function CheckCombat(player, target)
    if not target:IsInCombat() then return true end
    player:SendBroadcastMessage("You cannot summon a shadow while it is in combat.")
end

local function OnShadowsSummonCommand(event, player, command)
    local targetLow, map, x, y, z, o, ritual = command:match("^shadowsummon (%d+) (%d+) (%S+) (%S+) (%S+) (%S+) (%d)$")
    if targetLow then
        local target = GetPlayerByGUID(tonumber(targetLow))
        if not target then return false end
        if ritual == "0" and not player:IsBot() then return false end
        if CheckGroup(player, target) and CheckCombat(player, target) then
            target:Teleport(tonumber(map), tonumber(x), tonumber(y), tonumber(z), tonumber(o))
        end
        return false
    end
end

local function SummonShadows(event, player, spell)
    local targetLow = SelectedLow(player)
    if not targetLow then return end
    if player:IsBot() then SummonCommand(player, targetLow, 0) end
end

local function CompleteSummonIfShadowNearby(event, player, spell)
    for _, bot in ipairs(player:GetPlayersInRange(10, 2, 1)) do
        if not bot:IsBot() then return end
        if not (player:IsInSameGroupWith(bot) or player:IsInSameRaidWith(bot)) then return end
        local rootAura = bot:AddAura(32113, bot)
        rootAura:SetDuration(5000)
        bot:CastSpell(bot, 45789, true)
        bot:RegisterEvent(function(e, d, r, bot)
            if bot:IsInCombat() then return end
            bot:StopSpellCast()
        end, 5000)
        player:RegisterEvent(function(e, d, r, player)
            if not player:IsCasting() then return end
            player:StopSpellCast()
            local targetLow = SelectedLow(player)
            if not targetLow then return end
            local target
            for _, p in ipairs(GetStateMap():GetPlayers()) do
                if p:GetGUIDLow() == targetLow then target = p break end
            end
            if not target then
                SummonCommand(player, targetLow, player:IsBot() and 0 or 1)
                return
            end
            if not player:IsBot() then
                player:CastSpell(target, 7720, true)
                return
            end
            SummonCommand(player, targetLow, 0)
        end, 5000)
        break
    end
end

local function OnCastRitualOfSummoning(event, portal)
    local firstName
    local consecutiveSeconds = 0
    local lastCastingSet = {}
    local function CheckRitual(e, d, r, portal)
        local currentCasting = {}
        local casterSpells = {}
        local botsCasting = {}
        local firstCasting
        if firstName then
            for _, p in ipairs(GetStateMap():GetPlayers()) do
                if p:GetName() == firstName then firstCasting = p break end
            end
        end
        for _, player in ipairs(portal:GetPlayersInRange(10, 2, 1)) do
            local spell = player:GetCurrentSpell(2)
            local entry = spell and spell:GetEntry()
            if entry == 698 or entry == 45789 then
                if not firstName and entry == 698 then
                    firstName = player:GetName()
                    firstCasting = player
                end
                if player:IsBot() then botsCasting[player:GetName()] = true end
                currentCasting[#currentCasting + 1] = player:GetGUIDLow()
                casterSpells[#casterSpells + 1] = spell
            end
        end
        if #currentCasting < 3 and firstCasting then
            local need = 3 - #currentCasting
            for _, player in ipairs(portal:GetPlayersInRange(10, 2, 1)) do
                if need <= 0 then break end
                if player:IsBot() and player:IsInSameGroupWith(firstCasting) and not botsCasting[player:GetName()] then
                    player:CastSpell(player, 45789, true)
                    player:RegisterEvent(function(e, d, r, player) player:StopSpellCast() end, 20000)
                    need = need - 1
                end
            end
        end
        if #currentCasting == 3 then
            table.sort(currentCasting)
            local same = #lastCastingSet == 3
            if same then
                for i = 1, 3 do
                    if currentCasting[i] ~= lastCastingSet[i] then same = false break end
                end
            end
            if same then
                consecutiveSeconds = consecutiveSeconds + 1
                if consecutiveSeconds >= 10 and firstCasting then
                    for _, spell in ipairs(casterSpells) do spell:Cancel() end
                    firstCasting:CastSpell(firstCasting:GetSelection(), 61993, true)
                    portal:Despawn()
                end
            else
                consecutiveSeconds = 1
                lastCastingSet = currentCasting
            end
        else
            consecutiveSeconds = 0
            lastCastingSet = {}
        end
    end
    portal:RegisterEvent(CheckRitual, 2000, 120)
end

if GetStateMapId() == -1 then
    RegisterPlayerEvent(42, OnShadowsSummonCommand)
else
    RegisterSpellEvent(23598, 2, CompleteSummonIfShadowNearby)
    RegisterSpellEvent(7720, 2, SummonShadows)
    RegisterGameObjectEvent(194108, 2, OnCastRitualOfSummoning)
end

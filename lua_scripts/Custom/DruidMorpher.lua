--VARIABLES
local ITEM_ID = 17890 -- On-use trigger item
local MorphApplicationDelay = 15-- Delay in MS, if too fast it will throw off the shapeshift
local MorphRepeats = 1 -- In case too fast, try again after a short delay (optional, 1 = only one attempt)
local MorphReqRare = 100 -- Skill required to claim morph forms of elites
local MorphReqElite = 50 -- Skill required to claim morph forms of elites
local MaxMorphSkill = 300 -- Max morphing skill cap, just used to reward players

FastFlightMounts = {40192, 59976, 72808, 58615, 64927, 65439, 72807, 63956, 44317, -- 310% mounts
44744, 63796, 3363, 69395, 32345, 60021, 67336, 63963, 37015, 49193, 60024, 71810} -- 310% mounts

local ITEMS_PER_PAGE = 13
local PVP_MSG = "You can't use druid morphs while flagged for PvP."

local NAMES = {"Cat", "Bear", "Travel", "Flight", "Tree", "Boomkin", "Aquatic"}
local ICONS = {"ability_druid_catform", "ability_racial_bearform", "ability_druid_travelform", "ability_druid_flightform", "ability_druid_treeoflife", "spell_nature_forceofnature", "ability_druid_aquaticform"}
local FORM_AURAS = {{768, 1}, {3025, 1}, {32356, 1}, {9634, 2}, {5487, 2}, {783, 3}, {40120, 4}, {33943, 4}, {33891, 5}, {24858, 6}, {1066, 7}}
local AURAS = {768, 9634, 5487, 783, 40120, 33943, 33891, 24858, 1066}
local SPEED = {
    [3] = {move = 1, step = 10, cap = 5},
    [4] = {move = 6, step = 5, cap = 5},
    [7] = {move = 3, step = 5, cap = 8}
}

local DEVILSAUR = {33505, 28647, "Devilsaur"}
local IRONHIDE = {40404, 31831, "Ironhide Devilsaur"}
local LOQUE = {33510, 28649, "Loque'nahak"}
local REMAP = {
    [32485] = DEVILSAUR, [27483] = DEVILSAUR, [6584] = DEVILSAUR, [6498] = DEVILSAUR, [6500] = DEVILSAUR,
    [20931] = IRONHIDE, [6499] = IRONHIDE,
    [32517] = LOQUE
}

local EXCLUDE = [[ AND name NOT LIKE '%(%' AND name NOT LIKE '%"%' AND name NOT LIKE '%[%' AND name NOT LIKE '%UNUSED%' AND name NOT LIKE '%TEST%' AND name NOT LIKE '%STABLED%' AND name NOT LIKE '%TAMED%' AND name NOT LIKE '%TOTEM%']]
local EXTRA = {
    [1] = " AND name NOT LIKE '%DESIGNER%'",
    [3] = " AND name NOT LIKE '%REMA%'"
}

local function Like(...)
    local t = {}
    for _, n in ipairs({...}) do
        t[#t + 1] = "name LIKE '%" .. n .. "%'"
    end
    return table.concat(t, " OR ")
end

local QUERIES = {
    "family = 2 OR ((" .. Like("panther", "gondria", "loque") .. ") AND type = 1)",
    "family = 4 OR " .. Like("arcturis", "grizzly cub"),
    "family IN (7, 26, 30, 33, 34, 37, 38) OR ((" .. Like("highperch", "wyvern", "heartrazor") .. ") AND type = 1)",
    "family IN (1, 11, 12, 39) OR ((" .. Like("riding wolf", "caribou", "fawn", "bach", "grazer", "giraffe", "gazelle", "zhevra", "snickerfang", "hyena", "tundra scavenger", "mosshoof", "talbuk", "elk", "stag", "mammoth", "elekk", "feathermoon", "hippogryph", "goat", "mustang", "buck", "ram", "twilight serpent") .. ") AND type = 1)",
    Like("owlkin", "wildkin", "owlbeast", "moonkin"),
    "(" .. Like("root-walker", "treant", "withered green keeper", "Withered Ancient", "Wood Ent", "Unbound Ent", "Mangrove Ent", "Dispirited Ent", "sapling", "Darnassian Proector", "Crazed Ancient", "Crystalline Keeper", "Irontree", "Force of Nature", "Deeprot", "tender") .. ") AND type = 4",
    "(" .. Like("sewer beast", "mako", "seal", "rippa", "orca", "lake frenzy", "sporewind frenzy", "underbog frenzy", "yellowgill frenzy", "reef frenzy", "canal frenzy", "muck frenzy", "coilfang frenzy", "sharptooth frenzy", "coastal frenzy", "drakkari frenzy", "loch frenzy", "hooktooth", "mudfin", "shark", "thresh", "eel", "hammerhead", "whitetail", "crocolisk", "sawfin") .. ") AND type = 1"
}

local caches

local function LoadCaches()
    if caches then return end
    local loaded = {}
    for i = 1, 7 do
        local shared = GetWorldData("DruidMorphCache" .. i)
        if not shared then return end
        if type(shared) == "table" and shared.AsTable then
            shared = shared:AsTable()
        end
        loaded[i] = shared
    end
    caches = loaded
end

local function IsDruid(player)
    return player:GetClass() == 11 and not player:IsBot() and player:HasItem(ITEM_ID)
end

local function Icon(name)
    return "|TInterface/ICONS/" .. name .. ":32:32:-25:0|t"
end

local function Find(list, displayId)
    for n = 1, #list do
        if list[n].displayId == displayId then
            return list[n]
        end
    end
end

local function FormIndex(player)
    for n = 1, #FORM_AURAS do
        local a = FORM_AURAS[n]
        if player:HasAura(a[1]) then
            return a[2]
        end
    end
end

local DATA_KEY = "DruidMorphState"

local function LoadData(player)
    local stored = player:Data():Get(DATA_KEY)
    if stored then
        return stored:AsTable()
    end
    return {}
end

local function SaveData(player, d)
    player:Data():Set(DATA_KEY, d)
end

local function PlayerData(player)
    local d = LoadData(player)
    if d.morphs then return d end
    if d.loading then return end
    d.loading = true
    SaveData(player, d)
    local name = player:GetName()
    CharDBQueryAsync("SELECT name, id, form, active FROM acore_eluna.character_morphs WHERE guid = " .. player:GetGUIDLow(), function(r)
        local p
        for _, pl in pairs(GetStateMap():GetPlayers()) do
            if pl:GetName() == name then
                p = pl
                break
            end
        end
        if not p then return end
        local morphs, active = {{}, {}, {}, {}, {}, {}, {}}, {}
        if r then
            repeat
                local displayId, form = r:GetUInt32(1), r:GetUInt32(2)
                if morphs[form] then
                    table.insert(morphs[form], {name = r:GetString(0), displayId = displayId})
                    if r:GetUInt32(3) == 1 then
                        active[form] = displayId
                    end
                end
            until not r:NextRow()
        end
        local pd = LoadData(p)
        pd.morphs, pd.active, pd.loading = morphs, active, nil
        SaveData(p, pd)
        if FormIndex(p) and not p:IsPvPFlagged() then
            p:RegisterEvent(Morpher, 20, 1)
        end
    end)
end

local function Skill(d)
    local morphs, total = d.morphs, 0
    for i = 1, 7 do
        total = total + #morphs[i]
    end
    return math.min(total, MaxMorphSkill)
end

local function FormSpeed(player, idx, count)
    local s = SPEED[idx]
    if not s or count < s.step then return end
    local tier = math.min(math.floor(count / s.step), s.cap)
    local speed, pct
    if idx == 3 then
        speed, pct = 1.4 + tier * 0.1, 40 + tier * 10
    elseif idx == 4 then
        speed, pct = 2.5, 150
        if player:HasSpell(40120) then speed, pct = 3.8, 280 end
        for _, id in ipairs(FastFlightMounts) do
            if player:HasSpell(id) then
                speed, pct = 4.1, 310
                break
            end
        end
        speed, pct = speed + tier * 0.05, pct + tier * 5
    else
        speed, pct = 1.5 + tier * 0.05 * 0.75, 50 + tier * 5
    end
    return s.move, speed, pct, count == tier * s.step
end

local function FormLabel(player, idx)
    return (idx == 4 and player:HasSpell(40120) and "swift flight" or NAMES[idx]:lower()) .. " form"
end

local function Reshift(player, remove)
    for n = 1, #AURAS do
        local id = AURAS[n]
        if player:HasAura(id) then
            if remove then player:RemoveAura(id) end
            player:AddAura(id, player)
            return
        end
    end
end

function Morpher(eventId, delay, repeats, player)
    if not (player and IsDruid(player) and not player:IsPvPFlagged() and player:IsAlive()) then return end
    local idx = FormIndex(player)
    if not idx then return end
    local d = PlayerData(player)
    if not d or not d.morphs then return end
    local active = d.active[idx]
    if not active or active == 0 then return end
    player:SetDisplayId(active)
    local move, speed = FormSpeed(player, idx, #d.morphs[idx])
    if move then
        player:SetSpeed(move, speed)
    end
end

local function CheckIfNeedToApplyMorph(event, player)
    if IsDruid(player) and PlayerData(player) and not player:IsPvPFlagged() and FormIndex(player) then
        player:RegisterEvent(Morpher, 100, 1)
    end
end

local function OnShapeshift(event, unit, form)
end

local function OnDisplayChange(event, unit, displayId)
    local player = unit:ToPlayer()
    if not caches and player and IsDruid(player) then
        LoadCaches()
    end
    
    if player and FormIndex(player) and IsDruid(player) and not player:IsPvPFlagged() then
        player:RegisterEvent(Morpher, MorphApplicationDelay, MorphRepeats)
    end
end

local function OnKillCreature(event, player, creature)
    if not IsDruid(player) then return end
    LoadCaches()
    if not caches then return end

    local entry, displayId, name = creature:GetEntry(), creature:GetDisplayId(), creature:GetName()
    local remap = REMAP[entry]
    if remap then
        entry, displayId, name = remap[1], remap[2], remap[3]
    end

    local idx
    for i = 1, 7 do
        if caches[i][entry] then
            idx = i
            break
        end
    end
    if not idx then return end

    local d = PlayerData(player)
    if not d or not d.morphs then return end
    local list = d.morphs[idx]
    if Find(list, displayId) then return end

    local rank = creature:GetRank()
    if rank == 3 then return end
    local req = rank == 1 and MorphReqElite or (rank == 2 or rank == 4) and MorphReqRare or 0
    local skill = Skill(d)
    if skill < req then
        player:SendBroadcastMessage("You need to have a morph skill of " .. req .. " before you can learn " .. (rank == 1 and "elite" or "rare") .. " morphs. Your skill is currently " .. skill .. ".")
        return
    end

    list[#list + 1] = {name = name, displayId = displayId}
    SaveData(player, d)
    local escapedName = string.gsub(name, "'", "''") -- Fixes crashes on Loque'Nahak and other NPCs with ' in name
    CharDBExecute("REPLACE INTO acore_eluna.character_morphs (guid, name, id, form) VALUES (" .. player:GetGUIDLow() .. ", '" .. escapedName .. "', " .. displayId .. ", " .. idx .. ")")
    skill = Skill(d)
    player:SendBroadcastMessage("You have released " .. name .. "'s spirit and learned how to morph into their " .. NAMES[idx] .. " form." .. (skill < MaxMorphSkill and " Your morph skill has increased to " .. skill .. "." or ""))

    local _, _, pct, exact = FormSpeed(player, idx, #list)
    if exact then
        player:SendBroadcastMessage("Through your exquisite knowledge of " .. NAMES[idx]:lower() .. " forms, your " .. FormLabel(player, idx) .. " speed has increased to " .. pct .. "%.")
    end
    CheckIfNeedToApplyMorph(nil, player)
end

local function ShowInitialGossipMenu(player)
    local d = PlayerData(player)
    player:GossipMenuAddItem(4, Icon("inv_misc_questionmark") .. "How does morphing work?", 0, 10)
    player:GossipMenuAddItem(4, Icon("inv_misc_spyglass_02") .. "Search morphs", 0, 11)
    for i = 1, 7 do
        local active, name = d.active[i], "Default"
        if active and active ~= 0 then
            local m = Find(d.morphs[i], active)
            name = m and m.name or "Unknown"
        end
        player:GossipMenuAddItem(4, Icon(ICONS[i]) .. NAMES[i] .. " form: " .. name, 0, i)
    end
    player:GossipMenuAddItem(4, Icon("spell_nature_earthbind") .. "Remove current morph", 0, 8)
    player:GossipMenuAddItem(4, Icon("achievement_quests_completed_daily_08") .. "Morph skill: " .. Skill(d) .. "/" .. MaxMorphSkill, 0, 9)
    player:GossipSendMenu(12, player, 0)
end

local function Collect(d, first, last, term)
    local list = {}
    for i = first, last do
        local forms = d.morphs[i]
        for n = 1, #forms do
            local m = forms[n]
            if not term or m.name:lower():find(term, 1, true) then
                list[#list + 1] = {name = m.name, displayId = m.displayId, formId = i}
            end
        end
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    d.results = list
    d.suffix = term ~= nil
end

local function ShowPage(player, page)
    local d = PlayerData(player)
    local results = d.results
    if not results or #results == 0 then
        player:SendAreaTriggerMessage(d.suffix and "No morphs found matching your search!" or "You have no available morphs for this form!")
        ShowInitialGossipMenu(player)
        return
    end

    player:GossipClearMenu()
    local first = (page - 1) * ITEMS_PER_PAGE + 1
    local last = math.min(first + ITEMS_PER_PAGE - 1, #results)
    local seen = {}
    for n = first, last do
        local r = results[n]
        local label = r.name
        seen[label] = (seen[label] or 0) + 1
        if seen[label] > 1 then
            label = label .. " " .. seen[label]
        end
        if d.suffix then
            label = label .. " (" .. NAMES[r.formId] .. ")"
        end
        player:GossipMenuAddItem(4, Icon(ICONS[r.formId]) .. label, 0, r.formId * 1000000 + r.displayId)
    end

    if page > 1 then
        player:GossipMenuAddItem(4, Icon("inv_misc_map_01") .. "Previous Page", 0, 400000 + page - 1)
    end
    if last < #results then
        player:GossipMenuAddItem(4, Icon("inv_misc_map_01") .. "Next Page", 0, 400000 + page + 1)
    end
    if d.suffix then
        player:GossipMenuAddItem(4, Icon("inv_misc_spyglass_02") .. "New search", 0, 11)
    end
    player:GossipMenuAddItem(4, Icon("Trade_Engineering") .. "Back to main menu", 0, 9)
    player:GossipSendMenu(12, player, 0)
end

local function ApplyMorph(player, d, idx, morph)
    local guid = player:GetGUIDLow()
    d.active[idx] = morph.displayId
    SaveData(player, d)
    local msg = "You have morphed your " .. FormLabel(player, idx) .. " into " .. morph.name .. "."
    local move, speed, pct = FormSpeed(player, idx, #d.morphs[idx])
    if move then
        msg = msg .. " Your " .. NAMES[idx]:lower() .. " speed is now " .. pct .. "%."
    end
    if FormIndex(player) == idx then
        player:SetDisplayId(morph.displayId)
        if move then
            player:SetSpeed(move, speed)
        end
    end
    CharDBExecute("UPDATE acore_eluna.character_morphs SET active = 0 WHERE guid = " .. guid .. " AND form = " .. idx)
    CharDBExecute("UPDATE acore_eluna.character_morphs SET active = 1 WHERE guid = " .. guid .. " AND form = " .. idx .. " AND id = " .. morph.displayId)
    player:SendBroadcastMessage(msg)
    player:GossipComplete()
end

local function OnGossipSelect(event, player, object, sender, intid, code, menu_id)
    if not IsDruid(player) then return end
    if player:IsPvPFlagged() then player:SendAreaTriggerMessage(PVP_MSG) return false end
    local d = PlayerData(player)
    if not d or not d.morphs then return end

    if intid == 10 then
        player:GossipMenuAddItem(4, Icon("inv_misc_questionmark") .. "How does morphing work?\n \nMorphing is an ancient Darnassian magic that permits druids to transmogrify their shapeshifts into the shapes of creatures they have released the spirit from.\n \nKilling a valid creature lets you morph your shapeshift of the same type into the newly acquired form. Every unique form claimed increases your morphing skill by 1.\n \nTo claim the form of elite creatures, you need to have a morphing skill of at least " .. MorphReqElite .. ", and to claim the form of rare creatures, you need a skill of " .. MorphReqRare .. ".\n \nFor a full list of creatures whose forms you can claim unless an identical form has already been claimed, consult your Twiggy and ask him about Yggdrasil's features.\n ", 0, 10)
        player:GossipMenuAddItem(4, Icon("Trade_Engineering") .. "Go back", 0, 9)
        player:GossipSendMenu(12, player, 0)
    elseif intid == 8 then
        local idx = FormIndex(player)
        if idx then
            d.active[idx] = 0
            SaveData(player, d)
            CharDBExecute("UPDATE acore_eluna.character_morphs SET active = 0 WHERE guid = " .. player:GetGUIDLow() .. " AND form = " .. idx)
            Reshift(player, true)
        end
        ShowInitialGossipMenu(player)
    elseif intid >= 1 and intid <= 7 then
        Collect(d, intid, intid)
        SaveData(player, d)
        ShowPage(player, 1)
    elseif intid == 11 then
        player:GossipMenuAddItem(5, "Enter search term:", 0, 12, true)
        player:GossipSendMenu(12, player, 0)
    elseif intid == 12 then
        if code and code ~= "" then
            Collect(d, 1, 7, code:lower())
            SaveData(player, d)
            ShowPage(player, 1)
        else
            player:SendAreaTriggerMessage("Please enter a search term!")
            ShowInitialGossipMenu(player)
        end
    elseif intid >= 400000 and intid < 500000 then
        ShowPage(player, intid - 400000)
    elseif intid >= 1000000 and intid < 8000000 then
        local idx = math.floor(intid / 1000000)
        local morph = Find(d.morphs[idx], intid - idx * 1000000)
        if morph then
            ApplyMorph(player, d, idx, morph)
        end
    else
        ShowInitialGossipMenu(player)
    end
end

local function OnGossipHello(event, player, object)
    if player:GetClass() == 11 then
        if player:IsPvPFlagged() then player:SendAreaTriggerMessage(PVP_MSG) return false end
        local d = PlayerData(player)
        if d and d.morphs then
            player:GossipComplete()
            ShowInitialGossipMenu(player)
        else
            player:SendAreaTriggerMessage("Loading your morphs, try again in a moment.")
        end
    end
    return false
end

local function OnCombat(event, player, enemy)
    if not IsDruid(player) then return end
    if enemy and enemy:IsPvPFlagged() then
        player:DeMorph()
        Reshift(player)
    end
end

if GetStateMapId() == -1 then -- World stuff
    for i, cond in ipairs(QUERIES) do
        WorldDBQueryAsync("SELECT entry, name FROM creature_template WHERE (" .. cond .. ")" .. EXCLUDE .. (EXTRA[i] or ""), function(results)
            local cache = {}
            if results then
                repeat
                    cache[results:GetUInt32(0)] = results:GetString(1)
                until not results:NextRow()
            end
            SetWorldData("DruidMorphCache" .. i, cache)
        end)
    end
else -- Map stuff
    RegisterPlayerEvent(7, OnKillCreature)
    RegisterPlayerEvent(28, CheckIfNeedToApplyMorph)
    RegisterPlayerEvent(33, OnCombat)
    RegisterUnitEvent(1, OnDisplayChange)
    RegisterUnitEvent(2, OnShapeshift)
    RegisterItemGossipEvent(ITEM_ID, 1, OnGossipHello)
    RegisterPlayerGossipEvent(0, 2, OnGossipSelect)
end
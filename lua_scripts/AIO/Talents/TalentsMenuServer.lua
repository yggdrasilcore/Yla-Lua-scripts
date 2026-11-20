if GetStateMapId() ~= -1 then return end

local AIO = AIO or require("AIO")

local DATA_TYPE = 100
local MAX_SPECS = 20
local MAX_TALENT_LEVEL = 80

local function HasClassBit(classMask, classId)
    return math.floor(classMask / (2 ^ (classId - 1))) % 2 >= 1
end

local classTalentCache = {}

local function BuildClassTalents(classId)
    if classTalentCache[classId] then return classTalentCache[classId] end

    local talents = GetDBCEntries("Talent")
    local tabs = GetDBCEntries("TalentTab")
    if not talents or not tabs then return nil end

    local tabPage = {}
    for _, tab in ipairs(tabs) do
        local tabId = tab:GetId()
        local classMask = tab:GetClassMask()
        local page = tab:GetTabPage()
        if tabId and classMask and page and HasClassBit(classMask, classId) then
            tabPage[tabId] = page
        end
    end

    local spellsByTab = { {}, {}, {} }
    for _, talent in ipairs(talents) do
        local page = tabPage[talent:GetTab()]
        if page and page >= 0 and page <= 2 then
            spellsByTab[page + 1][#spellsByTab[page + 1] + 1] = {
                id = talent:GetId(),
                row = talent:GetRow(),
                col = talent:GetCol(),
                ranks = talent:GetRanks(),
                dependsOn = talent:GetDependsOn(),
                dependsOnRank = talent:GetDependsOnRank(),
            }
        end
    end

    for tab = 1, 3 do
        table.sort(spellsByTab[tab], function(a, b)
            if a.row ~= b.row then return a.row < b.row end
            return a.col < b.col
        end)
    end

    classTalentCache[classId] = spellsByTab
    return spellsByTab
end

local classTalentTreeCache = {}

local function BuildTalentTrees(classId)
    if classTalentTreeCache[classId] then return classTalentTreeCache[classId] end

    local spellsByTab = BuildClassTalents(classId)
    if not spellsByTab then return nil end

    local byId = {}
    for tab = 1, 3 do
        for _, spell in ipairs(spellsByTab[tab]) do
            byId[spell.id] = spell
        end
    end

    local trees = {}
    for tab = 1, 3 do
        local tree = {}
        for _, spell in ipairs(spellsByTab[tab]) do
            if spell.ranks and spell.ranks[1] and spell.ranks[1] ~= 0 then
                local dep = byId[spell.dependsOn]
                tree[#tree + 1] = {
                    id = spell.id,
                    row = spell.row,
                    col = spell.col,
                    ranks = spell.ranks,
                    depRow = dep and dep.row or nil,
                    depCol = dep and dep.col or nil,
                }
            end
        end
        trees[tab] = tree
    end

    classTalentTreeCache[classId] = trees
    return trees
end

local function ParseLink(spellsByTab, link)
    local tabLinks = {}

    local start = 1
    for i = 1, #link do
        if link:sub(i, i) == "-" then
            tabLinks[#tabLinks + 1] = link:sub(start, i - 1)
            start = i + 1
        end
    end
    tabLinks[#tabLinks + 1] = link:sub(start)

    local ordersByTab = { {}, {}, {} }
    for tab = 0, 2 do
        local tabLink = tabLinks[tab + 1] or ""
        local spells = spellsByTab[tab + 1]
        local tabOrders = ordersByTab[tab + 1]
        for i = 1, #tabLink do
            if i > #spells then break end
            local rank = tonumber(tabLink:sub(i, i)) or 0
            if rank > 0 then
                tabOrders[#tabOrders + 1] = {
                    tab = tab,
                    row = spells[i].row,
                    col = spells[i].col,
                    rank = rank,
                }
            end
        end
    end

    local tabOrder = { 1, 2, 3 }
    table.sort(tabOrder, function(a, b)
        return #ordersByTab[a] > #ordersByTab[b]
    end)

    local orders = {}
    for _, tab in ipairs(tabOrder) do
        for _, order in ipairs(ordersByTab[tab]) do
            orders[#orders + 1] = order
        end
    end
    return orders
end

local function GetSpecLinksForLevel(classId, specNo, level)
    local function GetLink(lvl)
        local link = GetConfigValue("AiShadow.PremadeSpecLink." .. classId .. "." .. specNo .. "." .. lvl)
        if type(link) == "string" and link ~= "" then return link end
        return nil
    end

    local startLevel = level
    while startLevel > 1 and startLevel < MAX_TALENT_LEVEL and not GetLink(startLevel) do
        startLevel = startLevel - 1
    end

    local links = {}
    for lvl = startLevel, MAX_TALENT_LEVEL do
        local link = GetLink(lvl)
        if link then links[#links + 1] = link end
    end
    return links
end

local function GetHighestSpecLink(classId, specNo)
    local best, bestLevel
    for lvl = 1, MAX_TALENT_LEVEL do
        local link = GetConfigValue("AiShadow.PremadeSpecLink." .. classId .. "." .. specNo .. "." .. lvl)
        if type(link) == "string" and link ~= "" then
            best, bestLevel = link, lvl
        end
    end
    return best, bestLevel
end

local function FindTalent(spellsByTab, tab, row, col)
    local spells = spellsByTab[tab + 1]
    for _, spell in ipairs(spells) do
        if spell.row == row and spell.col == col then return spell end
    end
    return nil
end

local function BuildSpecRanks(spellsByTab, link)
    local ranks = {}
    for _, order in ipairs(ParseLink(spellsByTab, link)) do
        local talent = FindTalent(spellsByTab, order.tab, order.row, order.col)
        if talent then
            ranks[talent.id] = order.rank
        end
    end
    return ranks
end

local function SpecKey(classId, specNo)
    return classId .. "." .. specNo
end

local function ParseSpecKey(key)
    if type(key) ~= "string" then return nil end
    local classId, specNo = key:match("^(%d+)%.(%d+)$")
    if not classId then return nil end
    return tonumber(classId), tonumber(specNo)
end

local function GetSpecName(classId, specNo)
    local name = GetConfigValue("AiShadow.PremadeSpecName." .. classId .. "." .. specNo)
    if type(name) == "string" then return name end
    return nil
end

local function GetSpecPoints(classId, specNo)
    local link = GetHighestSpecLink(classId, specNo)
    if not link then return "0-0-0" end
    local spellsByTab = BuildClassTalents(classId)
    if not spellsByTab then return "0-0-0" end
    local counts = { 0, 0, 0 }
    for _, order in ipairs(ParseLink(spellsByTab, link)) do
        counts[order.tab + 1] = counts[order.tab + 1] + order.rank
    end
    return counts[1] .. "-" .. counts[2] .. "-" .. counts[3]
end

local applying = {}

local function ApplySpec(player, classId, specNo)
    local guid = player:GetGUIDLow()
    if applying[guid] then return false end
    applying[guid] = true

    local links = GetSpecLinksForLevel(classId, specNo, player:GetLevel())
    local spellsByTab = BuildClassTalents(classId)
    if #links == 0 or not spellsByTab then
        applying[guid] = nil
        return false
    end

    player:ResetTalents(true)

    for _, link in ipairs(links) do
        for _, order in ipairs(ParseLink(spellsByTab, link)) do
            local free = player:GetFreeTalentPoints()
            if free <= 0 then break end

            local talent = FindTalent(spellsByTab, order.tab, order.row, order.col)
            if talent then
                if talent.dependsOn and talent.dependsOn ~= 0 then
                    local depRank = math.min(talent.dependsOnRank, free - 1)
                    if depRank >= 0 then
                        player:LearnTalent(talent.dependsOn, depRank)
                    end
                end

                free = player:GetFreeTalentPoints()
                if free <= 0 then break end

                local rank = math.min(order.rank, free) - 1
                if rank >= 0 then
                    player:LearnTalent(talent.id, rank)
                end
            end
        end

        if player:GetFreeTalentPoints() <= 0 then break end
    end

    applying[guid] = nil
    return true
end

local function SavePrefs(player)
    local spec = player:Data():Get("TalentsMenuSpec") or ""
    local auto = player:Data():Get("TalentsMenuAuto") and 1 or 0
    CharDBExecute("REPLACE INTO ycore_yla.character_custom_data (guid, type, time, data) VALUES (" ..
        player:GetGUIDLow() .. ", " .. DATA_TYPE .. ", " .. os.time() .. ", '" .. spec .. "|" .. auto .. "')")
end

local function LoadPrefs(player, callback)
    local guid = player:GetGUIDLow()
    CharDBQueryAsync("SELECT data FROM ycore_yla.character_custom_data WHERE guid = " .. guid ..
        " AND type = " .. DATA_TYPE, function(result)
        local target = GetPlayerByGUID(GetPlayerGUID(guid))
        if not target then return end

        local spec, auto = "", 0
        if result then
            local data = result:GetString(0)
            spec, auto = data:match("^(.-)|(%d+)$")
            spec = spec or ""
            auto = tonumber(auto) or 0
        end

        target:Data():Set("TalentsMenuSpec", spec ~= "" and spec or nil)
        target:Data():Set("TalentsMenuAuto", auto == 1)
        target:Data():Set("TalentsMenuLoaded", true)

        if callback then callback(target) end
    end)
end

local function EnsureLoaded(player, callback)
    if player:Data():Get("TalentsMenuLoaded") then
        callback(player)
    else
        LoadPrefs(player, callback)
    end
end

local function BuildSpecList(player)
    local classId = player:GetClass()
    local specs = {}
    local spellsByTab = BuildClassTalents(classId)

    for specNo = 0, MAX_SPECS - 1 do
        local name = GetSpecName(classId, specNo)
        if not name then break end
        local ranks = {}
        local link = GetHighestSpecLink(classId, specNo)
        if link and spellsByTab then
            ranks = BuildSpecRanks(spellsByTab, link)
        end
        specs[#specs + 1] = {
            key = SpecKey(classId, specNo),
            name = name,
            points = GetSpecPoints(classId, specNo),
            ranks = ranks,
        }
    end

    return specs
end

local function ShowMenu(player)
    local specs = BuildSpecList(player)
    if #specs == 0 then
        player:SendBroadcastMessage("No talent presets are configured for your class.")
        return
    end
    local classId = player:GetClass()
    local trees = BuildTalentTrees(classId)
    if not trees then
        player:SendBroadcastMessage("Talent data could not be read from the server.")
        return
    end

    AIO.Handle(player, "TalentsMenu", "Show", specs,
        player:Data():Get("TalentsMenuSpec") or "",
        player:Data():Get("TalentsMenuAuto") and true or false,
        trees)
end

local function AssignFromCommand(player, specKey)
    local classId, specNo = ParseSpecKey(specKey)
    if not classId or not specNo or classId ~= player:GetClass() then
        player:SendBroadcastMessage("That talent preset is not available for your class.")
        return
    end
    if not GetSpecName(classId, specNo) then
        player:SendBroadcastMessage("That talent preset is not available.")
        return
    end

    player:Data():Set("TalentsMenuSpec", specKey)
    SavePrefs(player)
    ApplySpec(player, classId, specNo)
    ShowMenu(player)
end

local TalentHandlers = AIO.AddHandlers("TalentsMenu", {})

function TalentHandlers.Request(player)
    EnsureLoaded(player, ShowMenu)
end

function TalentHandlers.Assign(player, specKey)
    EnsureLoaded(player, function(p)
        AssignFromCommand(p, specKey)
    end)
end

function TalentHandlers.SetAuto(player, enabled)
    EnsureLoaded(player, function(p)
        p:Data():Set("TalentsMenuAuto", enabled and true or false)
        SavePrefs(p)
        ShowMenu(p)
    end)
end

local function OnCommand(event, player, command)
    if not player then return end
    if command == "talentsmenu" then
        EnsureLoaded(player, ShowMenu)
        return false
    end
end

local function OnLogin(event, player)
    if player:IsBot() then return end
    LoadPrefs(player, function(p)
        if not p:Data():Get("TalentsMenuAuto") then return end
        local specKey = p:Data():Get("TalentsMenuSpec")
        local classId, specNo = ParseSpecKey(specKey)
        if classId and specNo and classId == p:GetClass() then
            ApplySpec(p, classId, specNo)
        end
    end)
end

local function OnLevelChange(event, player, oldLevel)
    if player:IsBot() then return end
    EnsureLoaded(player, function(p)
        if not p:Data():Get("TalentsMenuAuto") then return end
        local specKey = p:Data():Get("TalentsMenuSpec")
        local classId, specNo = ParseSpecKey(specKey)
        if classId and specNo and classId == p:GetClass() then
            ApplySpec(p, classId, specNo)
        end
    end)
end

RegisterPlayerEvent(42, OnCommand)
RegisterPlayerEvent(3, OnLogin)
RegisterPlayerEvent(13, OnLevelChange)

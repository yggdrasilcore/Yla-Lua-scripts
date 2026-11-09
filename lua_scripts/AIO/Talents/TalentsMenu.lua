local AIO = AIO or require("AIO")
if AIO.AddAddon() then
    return
end

local PARCHMENT = "Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal"
local GOLD_BORDER = "Interface\\Tooltips\\UI-Tooltip-Border"

local TREE_OFFSET = 34
local TREE_ICON = 30
local TREE_HEADER = 26
local TREE_WIDTH = 4 * TREE_OFFSET + 8
local TREE_GAP = 6
local TREE_ROWS = 11

local THEME = {
    frameBg = { 0.24, 0.19, 0.14, 1 },
    frameBorder = { 0.65, 0.52, 0.20, 1 },
    buttonBg = { 0.30, 0.22, 0.10, 1 },
    buttonBgHighlight = { 0.45, 0.32, 0.14, 1 },
    borderHover = { 0.95, 0.80, 0.30, 1 },
    title = { 0.95, 0.82, 0.30 },
    goldText = { 1, 0.82, 0 },
    selected = { 0.20, 0.45, 0.15, 1 },
    selectedBorder = { 0.45, 0.95, 0.35, 1 },
}

local function ApplyParchment(frame, bgColor)
    frame:SetBackdrop({
        bgFile = PARCHMENT,
        edgeFile = GOLD_BORDER,
        tile = false,
        edgeSize = 12,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    local color = bgColor or THEME.frameBg
    frame:SetBackdropColor(color[1], color[2], color[3], color[4])
    local border = THEME.frameBorder
    frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4])
end

local function AddSpecialFrame(name)
    for _, value in ipairs(UISpecialFrames) do
        if value == name then return end
    end
    tinsert(UISpecialFrames, name)
end

local function CreateDialog(name, width, height, title)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:SetSize(width, height)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    ApplyParchment(frame)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOP", 0, -14)
    titleText:SetText(title)
    titleText:SetTextColor(THEME.title[1], THEME.title[2], THEME.title[3])

    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetTexture("Interface\\Buttons\\WHITE8X8")
    divider:SetVertexColor(0.55, 0.45, 0.15, 1)
    divider:SetHeight(2)
    divider:SetPoint("TOPLEFT", 30, -36)
    divider:SetPoint("TOPRIGHT", -30, -36)

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 2, 0)

    AddSpecialFrame(name)
    return frame
end

local function StyleButton(button, text)
    ApplyParchment(button, THEME.buttonBg)
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.text:SetPoint("CENTER")
    button.text:SetWidth(button:GetWidth() - 20)
    button.text:SetJustifyH("CENTER")
    button.text:SetText(text)
    button.text:SetTextColor(THEME.goldText[1], THEME.goldText[2], THEME.goldText[3])

    button:SetScript("OnEnter", function(self)
        local bg = THEME.buttonBgHighlight
        self:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
        local border = THEME.borderHover
        self:SetBackdropBorderColor(border[1], border[2], border[3], border[4])
        self.text:SetTextColor(1, 1, 1)
    end)
    button:SetScript("OnLeave", function(self)
        local bg = self.selected and THEME.selected or THEME.buttonBg
        self:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
        local border = self.selected and THEME.selectedBorder or THEME.frameBorder
        self:SetBackdropBorderColor(border[1], border[2], border[3], border[4])
        self.text:SetTextColor(THEME.goldText[1], THEME.goldText[2], THEME.goldText[3])
    end)
end

local frame
local scrollFrame
local scrollChild
local scrollBar
local autoCheck
local statusText
local previewFrame
local specButtons = {}
local treePanels = {}
local talentButtons = {}
local specsByKey = {}
local treeSignature
local selectedKey
local autoAssign

local function UpdateScrollHeight(contentHeight)
    scrollChild:SetHeight(math.max(contentHeight, scrollFrame:GetHeight()))
    local range = math.max(0, contentHeight - scrollFrame:GetHeight())
    scrollBar:SetMinMaxValues(0, range)
    if range == 0 then
        scrollBar:Hide()
    else
        scrollBar:Show()
    end
end

local function GetTreeTabInfo(tab)
    local name, _, _, background
    if GetTalentTabInfo then
        name, _, _, background = GetTalentTabInfo(tab)
    end
    return name or ("Tree " .. tab), background
end

local function GetTalentIcon(talent)
    for i = 1, #(talent.ranks or {}) do
        local spellId = talent.ranks[i]
        if spellId and spellId ~= 0 then
            local icon = select(3, GetSpellInfo(spellId))
            if icon then return icon end
        end
    end
    return nil
end

local function GetTalentMaxRank(talent)
    local maxRank = 0
    for i = 1, #(talent.ranks or {}) do
        local spellId = talent.ranks[i]
        if spellId and spellId ~= 0 then maxRank = i end
    end
    return maxRank
end

local function CreateTreePanels(trees)
    for _, panel in ipairs(treePanels) do
        panel:Hide()
    end
    treePanels = {}
    talentButtons = {}
    if not trees then return end

    local maxRow = 0
    for tab = 1, 3 do
        for _, talent in ipairs(trees[tab] or {}) do
            if talent.row and talent.row > maxRow then maxRow = talent.row end
        end
    end
    local height = TREE_HEADER + (maxRow + 1) * TREE_OFFSET + 6

    for tab = 1, 3 do
        local panel = CreateFrame("Frame", nil, previewFrame)
        panel:SetSize(TREE_WIDTH, height)
        panel:SetPoint("TOPLEFT", previewFrame, "TOPLEFT", (tab - 1) * (TREE_WIDTH + TREE_GAP), 0)
        panel:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = GOLD_BORDER,
            edgeSize = 8,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        panel:SetBackdropColor(THEME.buttonBg[1], THEME.buttonBg[2], THEME.buttonBg[3], 0.45)
        panel:SetBackdropBorderColor(THEME.frameBorder[1], THEME.frameBorder[2], THEME.frameBorder[3], 1)

        local name = GetTreeTabInfo(tab)
        panel.treeName = name
        panel.header = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        panel.header:SetPoint("TOP", 0, -6)
        panel.header:SetWidth(TREE_WIDTH - 8)
        panel.header:SetTextColor(THEME.title[1], THEME.title[2], THEME.title[3])
        panel.header:SetText(name .. " (0)")
        panel.talentButtons = {}

        for _, talent in ipairs(trees[tab] or {}) do
            local button = CreateFrame("Button", nil, panel)
            button:SetSize(TREE_ICON, TREE_ICON)
            button:SetPoint("TOPLEFT", panel, "TOPLEFT",
                6 + (talent.col or 0) * TREE_OFFSET,
                -(TREE_HEADER + (talent.row or 0) * TREE_OFFSET))
            button.talent = talent
            button.maxRank = GetTalentMaxRank(talent)
            button.previewRank = 0

            button.icon = button:CreateTexture(nil, "ARTWORK")
            button.icon:SetAllPoints()
            local icon = GetTalentIcon(talent)
            if icon then button.icon:SetTexture(icon) end
            button.icon:SetDesaturated(true)
            button.icon:SetAlpha(0.45)

            button.rank = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            button.rank:SetPoint("BOTTOMRIGHT", 2, -1)
            button.rank:Hide()

            button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

            button:SetScript("OnEnter", function(self)
                local rank = self.previewRank or 0
                local spellId = self.talent.ranks and self.talent.ranks[rank > 0 and rank or 1]
                if spellId and spellId ~= 0 then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetHyperlink("spell:" .. spellId)
                    GameTooltip:Show()
                end
            end)
            button:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)

            panel.talentButtons[#panel.talentButtons + 1] = button
            talentButtons[talent.id] = button
        end

        treePanels[tab] = panel
    end
end

local function UpdateTreePreview(ranks)
    ranks = ranks or {}
    for tab = 1, 3 do
        local panel = treePanels[tab]
        if panel then
            local points = 0
            for _, button in ipairs(panel.talentButtons) do
                local rank = ranks[button.talent.id] or 0
                button.previewRank = rank
                points = points + rank
                if rank > 0 then
                    button.icon:SetDesaturated(false)
                    button.icon:SetAlpha(1)
                    button.rank:SetText(rank)
                    button.rank:Show()
                    if rank >= button.maxRank then
                        button.rank:SetTextColor(1, 1, 1)
                    else
                        button.rank:SetTextColor(0.2, 1, 0.2)
                    end
                else
                    button.icon:SetDesaturated(true)
                    button.icon:SetAlpha(0.45)
                    button.rank:Hide()
                end
            end
            panel.header:SetText(panel.treeName .. " (" .. points .. ")")
        end
    end
end

local function ShowSpecPreview(key)
    local spec = specsByKey[key]
    UpdateTreePreview(spec and spec.ranks or nil)
end

local function GetTreesSignature(trees)
    if not trees then return "" end
    local parts = {}
    for tab = 1, 3 do
        local tree = trees[tab] or {}
        parts[#parts + 1] = tostring(#tree)
        for _, talent in ipairs(tree) do
            parts[#parts + 1] = tostring(talent.id)
        end
    end
    return table.concat(parts, ",")
end

local function SetSelected(key)
    selectedKey = key
    for specKey, button in pairs(specButtons) do
        local isSelected = specKey == key
        button.selected = isSelected
        local bg = isSelected and THEME.selected or THEME.buttonBg
        button:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
        local border = isSelected and THEME.selectedBorder or THEME.frameBorder
        button:SetBackdropBorderColor(border[1], border[2], border[3], border[4])
    end
    ShowSpecPreview(key)
end

local function CreateFrameOnce()
    if frame then return end

    frame = CreateDialog("TalentsMenuFrame", 820, 620, "Talents")

    scrollFrame = CreateFrame("ScrollFrame", nil, frame)
    scrollFrame:SetPoint("TOPLEFT", 16, -48)
    scrollFrame:SetPoint("BOTTOMLEFT", 16, 104)
    scrollFrame:SetWidth(280)

    scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(264)
    scrollFrame:SetScrollChild(scrollChild)

    scrollBar = CreateFrame("Slider", nil, scrollFrame, "UIPanelScrollBarTemplate")
    scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 4, -16)
    scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 16)
    scrollBar:SetWidth(16)
    scrollBar:SetMinMaxValues(0, 0)
    scrollBar:SetValueStep(30)
    scrollBar:SetValue(0)
    scrollBar:SetScript("OnValueChanged", function(self, value)
        scrollFrame:SetVerticalScroll(value)
    end)

    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        scrollBar:SetValue(scrollBar:GetValue() - delta * 30)
    end)

    previewFrame = CreateFrame("Frame", nil, frame)
    previewFrame:SetPoint("TOPLEFT", 312, -48)
    previewFrame:SetPoint("BOTTOMRIGHT", -20, 104)

    statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusText:SetPoint("BOTTOMLEFT", 20, 76)
    statusText:SetWidth(780)
    statusText:SetJustifyH("LEFT")
    statusText:SetTextColor(0.80, 0.70, 0.50)

    autoCheck = CreateFrame("CheckButton", "TalentsMenuAutoAssignCheck", frame, "UICheckButtonTemplate")
    autoCheck:SetSize(24, 24)
    autoCheck:SetPoint("BOTTOMLEFT", 20, 44)

    local autoLabel = autoCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    autoLabel:SetPoint("LEFT", autoCheck, "RIGHT", 4, 0)
    autoLabel:SetText("Auto-assign this spec when I level up")
    autoLabel:SetTextColor(THEME.goldText[1], THEME.goldText[2], THEME.goldText[3])

    autoCheck:SetScript("OnClick", function(self)
        autoAssign = self:GetChecked() and true or false
        AIO.Handle("TalentsMenu", "SetAuto", autoAssign)
    end)
end

local function RebuildSpecButtons(specs)
    for _, button in pairs(specButtons) do
        button:Hide()
    end
    specButtons = {}

    local y = 0
    for _, spec in ipairs(specs) do
        local button = CreateFrame("Button", nil, scrollChild)
        button:SetSize(264, 28)
        button:SetPoint("TOP", 0, -y)
        StyleButton(button, spec.name .. "  |cffa0a0a0(" .. spec.points .. ")|r")

        local onEnter = button:GetScript("OnEnter")
        local onLeave = button:GetScript("OnLeave")
        button:SetScript("OnEnter", function(self)
            if onEnter then onEnter(self) end
            ShowSpecPreview(spec.key)
        end)
        button:SetScript("OnLeave", function(self)
            if onLeave then onLeave(self) end
            ShowSpecPreview(selectedKey)
        end)

        button:SetScript("OnClick", function()
            SetSelected(spec.key)
            AIO.Handle("TalentsMenu", "Assign", spec.key)
        end)
        specButtons[spec.key] = button
        y = y + 32
    end

    UpdateScrollHeight(y)
end

local Handlers = AIO.AddHandlers("TalentsMenu", {})

function Handlers.Show(player, specs, currentKey, auto, trees)
    CreateFrameOnce()

    specs = specs or {}
    specsByKey = {}
    for _, spec in ipairs(specs) do
        specsByKey[spec.key] = spec
    end

    local signature = GetTreesSignature(trees)
    if signature ~= treeSignature then
        treeSignature = signature
        CreateTreePanels(trees)
    end

    RebuildSpecButtons(specs)
    SetSelected(currentKey)
    autoAssign = auto and true or false
    autoCheck:SetChecked(autoAssign)

    if currentKey and currentKey ~= "" then
        statusText:SetText("Click a specialization to apply it immediately.")
    else
        statusText:SetText("Choose a specialization, then optionally enable auto-assign.")
    end

    frame:Show()
end

SLASH_TALENTSMENU1 = "/talentsmenu"
SlashCmdList["TALENTSMENU"] = function()
    AIO.Handle("TalentsMenu", "Request")
end

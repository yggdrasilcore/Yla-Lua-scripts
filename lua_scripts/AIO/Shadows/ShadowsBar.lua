local AIO = AIO or require("AIO")
if AIO.AddAddon() then
    return
end

-----------------------------------------------------------
-- Shared helpers
-----------------------------------------------------------
local function GetGroupChannel()
    return GetNumRaidMembers() > 0 and "RAID" or GetNumPartyMembers() > 0 and "PARTY" or nil
end

local function GetUnitIdByName(name)
    if UnitName("player") == name then
        return "player"
    end
    for i = 1, 4 do
        if UnitName("party"..i) == name then
            return "party"..i
        end
    end
    for i = 1, 40 do
        if UnitName("raid"..i) == name then
            return "raid"..i
        end
    end
    return nil
end

function tContains(tbl, item)
    for _, value in ipairs(tbl) do
        if value == item then return true end
    end
    return false
end

function tIndexOf(tbl, item)
    for i, value in ipairs(tbl) do
        if value == item then return i end
    end
    return -1
end

local function AddSpecialFrame(name)
    if not tContains(UISpecialFrames, name) then
        tinsert(UISpecialFrames, name)
    end
end

local function SetDialogBackdrop(frame, bgFile, r, g, b, a)
    frame:SetBackdrop({
        bgFile = bgFile,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(r, g, b, a)
end

local function MakeMovable(frame)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
end

local function AddCloseButton(frame, onClose)
    local button = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    button:SetPoint("TOPRIGHT", 2, 0)
    button:SetScript("OnClick", function()
        frame:Hide()
        if onClose then onClose() end
    end)
    return button
end

-- Standard dialog frame: centered, skinable, movable, titled, with close button.
local function CreateDialog(name, width, height, title, opts)
    opts = opts or {}
    local bg = opts.bgColor or {0.1, 0.1, 0.1, 0.9}
    local frame = CreateFrame("Frame", name, UIParent)
    frame:SetSize(width, height)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata(opts.strata or "DIALOG")
    if opts.level then frame:SetFrameLevel(opts.level) end
    if opts.toplevel then frame:SetToplevel(true) end
    SetDialogBackdrop(frame, opts.bgFile or "Interface\\Tooltips\\UI-Tooltip-Background", bg[1], bg[2], bg[3], bg[4])
    if opts.movable ~= false then MakeMovable(frame) end
    if title then
        local text = frame:CreateFontString(nil, "OVERLAY", opts.font or "GameFontNormalLarge")
        text:SetPoint("TOP", 0, opts.titleY or -12)
        text:SetText(title)
    end
    AddCloseButton(frame, opts.onClose)
    AddSpecialFrame(name)
    return frame
end

local function CreateScrollList(name, width, height, title, opts)
    opts = opts or {}
    local frame = CreateDialog(name, width, height, title, {
        font = "GameFontNormal",
        bgColor = {0.1, 0.1, 0.1, 0.9},
    })
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame)
    scrollFrame:SetPoint("TOPLEFT", 10, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", opts.rightInset or -10, 10)
    local child = CreateFrame("Frame")
    child:SetWidth(opts.childWidth or (width - 20))
    scrollFrame:SetScrollChild(child)
    local bar = CreateFrame("Slider", nil, scrollFrame, "UIPanelScrollBarTemplate")
    bar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", -12, -16)
    bar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", -12, 16)
    bar:SetWidth(16)
    bar:SetMinMaxValues(0, 0)
    bar:SetValueStep(20)
    bar:SetValue(0)
    bar.scrollStep = 20
    bar:SetScript("OnValueChanged", function(self, value)
        scrollFrame:SetVerticalScroll(value)
    end)
    if opts.thumbHeight then
        bar:GetThumbTexture():SetHeight(opts.thumbHeight)
    end
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        bar:SetValue(bar:GetValue() - (delta * bar:GetValueStep()))
    end)
    frame.scrollFrame, frame.scrollChild, frame.scrollBar = scrollFrame, child, bar
    return frame
end

local function UpdateScrollList(frame, contentHeight)
    local child, bar = frame.scrollChild, frame.scrollBar
    child:SetHeight(math.max(contentHeight, frame.scrollFrame:GetHeight()))
    local range = math.max(0, contentHeight - frame.scrollFrame:GetHeight())
    bar:SetMinMaxValues(0, range)
    bar:SetValue(0)
    if range == 0 then bar:Hide() else bar:Show() end
end

local function SetHoverText(button, region)
    region = region or button.text
    button:SetScript("OnEnter", function() region:SetTextColor(1, 1, 1) end)
    button:SetScript("OnLeave", function() region:SetTextColor(1, 0.82, 0) end)
end

local function CreateHorizontalIconButton(parent, width, height, iconPath, text, opts)
    opts = opts or {}
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, height)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetSize(opts.iconSize or 32, opts.iconSize or 32)
    button.icon:SetPoint("LEFT", opts.iconX or 10, 0)
    button.icon:SetTexture(iconPath)
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.text:SetPoint("LEFT", button.icon, "RIGHT", opts.textGap or 10, 0)
    button.text:SetText(text)
    if opts.justifyLeft then button.text:SetJustifyH("LEFT") end
    SetHoverText(button)
    return button
end

local function CreateVerticalIconButton(parent, width, height, iconPath, text)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, height)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetSize(32, 32)
    button.icon:SetPoint("TOP", 0, -5)
    button.icon:SetTexture(iconPath)
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.text:SetPoint("TOP", button.icon, "BOTTOM", 0, -5)
    button.text:SetText(text)
    SetHoverText(button)
    return button
end

local function CreateTextButton(parent, width, height, text, onClick)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, height)
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.text:SetPoint("CENTER")
    button.text:SetText(text)
    if onClick then button:SetScript("OnClick", onClick) end
    SetHoverText(button)
    return button
end

local function SetSimpleTooltip(button, text)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(text, 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-----------------------------------------------------------
-- Interface options
-----------------------------------------------------------
local addedButtonForShadows = false
local SHADOWS_BUTTON_NUMBER = nil
local shadowButton
local ShadowsBarStatus = "ENABLED"
local ShadowsBarToggleStatus = "ENABLED"

local SHADOWS_PANEL_WIDGETS = {
    "ShadowsBarCheckbox",
    "ShadowsKeybindButton",
    "ShadowsResetButton",
    "ResetBotAIButton",
    "headerText",
}

local function SetShadowsPanelWidgetsVisible(visible)
    for _, name in ipairs(SHADOWS_PANEL_WIDGETS) do
        local widget = _G[name]
        if widget then
            if visible then widget:Show() else widget:Hide() end
        end
    end
end

local function ShowShadowsSettingsPanel()
    for i = 1, 30 do
        local button = _G["InterfaceOptionsFrameCategoriesButton"..i]
        if button and button:GetText() ~= "Shadows" then
            button:UnlockHighlight()
        end
    end

    for _, child in ipairs({InterfaceOptionsFramePanelContainer:GetChildren()}) do
        child:Hide()
    end

    if shadowButton then
        shadowButton:LockHighlight()
    end

    local frame = _G["ShadowsSettingsFrame"]
    if not frame then
        frame = CreateFrame("Frame", "ShadowsSettingsFrame", InterfaceOptionsFramePanelContainer)
        frame:SetAllPoints(InterfaceOptionsFramePanelContainer)

        local header = frame:CreateFontString("headerText", "ARTWORK", "GameFontNormalLarge")
        header:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -16)
        header:SetText("Shadows and Shadow Bar Settings")

        local checkBox = CreateFrame("CheckButton", "ShadowsBarCheckbox", frame, "InterfaceOptionsCheckButtonTemplate")
        checkBox:SetPoint("TOPLEFT", 16, -40)
        checkBox:SetText("Enable Shadows Bar")
        checkBox:SetScript("OnClick", function(self)
            SendChatMessage(self:GetChecked() and ".shadowsbaron" or ".shadowsbaroff", "GUILD")
        end)

        local autoOpenText = checkBox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        autoOpenText:SetPoint("LEFT", checkBox, "RIGHT", 4, 0)
        autoOpenText:SetText("Automatically Open Shadows Bar If Grouped With Shadows")
        autoOpenText:SetTextColor(1, 1, 1)

        local keyBindButton = CreateFrame("Button", "ShadowsKeybindButton", frame, "UIPanelButtonTemplate")
        keyBindButton:SetPoint("TOPLEFT", checkBox, "BOTTOMLEFT", 0, -10)
        keyBindButton:SetSize(230, 30)
        keyBindButton:SetText("Shadows Bar Keyboard Shortcuts")
        keyBindButton:SetScript("OnClick", function()
            SlashCmdList["SHADOWSHORTCUTS"]()
        end)

        local resetButton = CreateFrame("Button", "ShadowsResetButton", frame, "UIPanelButtonTemplate")
        resetButton:SetPoint("TOPLEFT", keyBindButton, "BOTTOMLEFT", 0, -10)
        resetButton:SetSize(230, 30)
        resetButton:SetText("Reset Shadows Bar")
        resetButton:SetScript("OnClick", function()
            BotControlBar:Hide()
            SlashCmdList["BOTCONTROLBAR"]()
        end)

        local resetShadowsButton = CreateFrame("Button", "ResetBotAIButton", frame, "UIPanelButtonTemplate")
        resetShadowsButton:SetPoint("TOPLEFT", resetButton, "BOTTOMLEFT", 0, -10)
        resetShadowsButton:SetSize(230, 30)
        resetShadowsButton:SetText("Reset Shadows Settings")
        resetShadowsButton:SetScript("OnClick", function()
            SendChatMessage(".unmuteshadows", "GUILD")
            SendChatMessage("reset botAI", GetGroupChannel())
        end)

        frame.name = "Shadows"

        if ShadowsBarStatus == "ENABLED" or ShadowsBarToggleStatus == "OPEN" then
            checkBox:SetChecked(true)
        end
        if ShadowsBarStatus == "DISABLED" or ShadowsBarToggleStatus == "CLOSED" then
            checkBox:SetChecked(false)
        end
    else
        frame:Show()
        local checkBox = _G["ShadowsBarCheckbox"]
        if checkBox then
            checkBox:SetChecked(ShadowsBarToggleStatus == "OPEN")
        end
        SetShadowsPanelWidgetsVisible(true)
    end
end

local function AddShadowsButtonToOptions()
    local lastButton, lastNumber
    for i = 1, 30 do
        local button = _G["InterfaceOptionsFrameCategoriesButton"..i]
        if not button or not button:IsVisible() then break end
        lastButton, lastNumber = button, i
    end

    SHADOWS_BUTTON_NUMBER = lastNumber + 1
    shadowButton = CreateFrame("Button", "InterfaceOptionsFrameCategoriesButton"..SHADOWS_BUTTON_NUMBER,
        InterfaceOptionsFrameCategories, "OptionsListButtonTemplate")
    shadowButton:SetText("Shadows")
    shadowButton:SetWidth(lastButton:GetWidth())
    shadowButton:SetHeight(lastButton:GetHeight())
    shadowButton:SetPoint("TOP", lastButton, "BOTTOM", 7, 0)
    shadowButton:SetScript("OnClick", ShowShadowsSettingsPanel)
    _G[shadowButton:GetName().."Text"]:SetJustifyH("LEFT")
end

local function AddShadowsButtonOnce()
    if addedButtonForShadows then return end
    AddShadowsButtonToOptions()
    addedButtonForShadows = true
end

InterfaceOptionsFrameCategories:HookScript("OnShow", AddShadowsButtonOnce)

if InterfaceOptionsFrameCategories:IsShown() then
    local button1 = _G["InterfaceOptionsFrameCategoriesButton1"]
    if button1 and button1:IsVisible() then
        AddShadowsButtonOnce()
    end
end

InterfaceOptionsFrameTab2:HookScript("OnClick", function()
    if shadowButton then shadowButton:UnlockHighlight() end
    SetShadowsPanelWidgetsVisible(false)
end)

for i = 1, 30 do
    local button = _G["InterfaceOptionsFrameCategoriesButton"..i]
    if button then
        button:HookScript("OnClick", function(self)
            if self:GetText() ~= "Shadows" then
                if shadowButton then shadowButton:UnlockHighlight() end
                SetShadowsPanelWidgetsVisible(false)
            end
            self:LockHighlight()
        end)
    end
end

-----------------------------------------------------------
-- Shadows control bar
-----------------------------------------------------------
BOT_BAR_SETTINGS = BOT_BAR_SETTINGS or {
    posX = 0,
    posY = -200,
    width = 400,
    scale = 1,
    enabled = true,
}

AIO.AddSavedVar("BOT_BAR_SETTINGS")

local function CreateBotControlBar()
    local itemCache = {}
    local lastUpdate = 0
    local itemListFrame
    local questCache = {}
    local questLastUpdate = 0

    local messageQueue = {}
    local messageCount = 0
    local countResetTime = 0
    local isThrottled = false
    local lastSendTime = 0
    local isProcessingQueue = false

    local queueFrame = CreateFrame("Frame")

    local function ProcessMessageQueue(self)
        if #messageQueue == 0 then
            isProcessingQueue = false
            self:SetScript("OnUpdate", nil)
            return
        end
        local now = GetTime()
        local delay = isThrottled and 2 or 0
        if now - lastSendTime >= delay then
            local nextMessage = table.remove(messageQueue, 1)
            SendChatMessage(nextMessage.msg, nextMessage.type, nextMessage.lang, nextMessage.target)
            lastSendTime = now
            messageCount = messageCount + 1
        end
    end

    local function SendThrottledChatMessage(message, chatType, language, target)
        local now = GetTime()

        if now - countResetTime >= 15 then
            messageCount = 0
            isThrottled = false
            countResetTime = now
        end

        if now - countResetTime <= 5 and messageCount >= 10 and not isThrottled then
            isThrottled = true
            StaticPopupDialogs["COMMAND_QUEUE_FULL"] = {
                text = "Please slow down - you cannot issue shadows commands that fast. Your commands are queued for processing.",
                button1 = "OK",
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                preferredIndex = 3,
            }
            StaticPopup_Show("COMMAND_QUEUE_FULL")
        end

        if not chatType or chatType == "RAID" or chatType == "PARTY" then
            chatType = GetGroupChannel()
            if not chatType then return end
        end

        table.insert(messageQueue, {msg = message, type = chatType, lang = language, target = target})

        if not isProcessingQueue then
            isProcessingQueue = true
            queueFrame:SetScript("OnUpdate", ProcessMessageQueue)
        end
    end

    local function SendCommands(command)
        for cmd in string.gmatch(command, "[^\n]+") do
            SendThrottledChatMessage(cmd)
        end
    end

    local function AfterDelay(seconds, callback)
        local delayFrame = CreateFrame("Frame")
        delayFrame.elapsed = 0
        delayFrame:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = self.elapsed + elapsed
            if self.elapsed >= seconds then
                self:SetScript("OnUpdate", nil)
                self:Hide()
                callback()
            end
        end)
    end

    local frame = CreateFrame("Frame", "BotControlBar", UIParent, "SecureHandlerStateTemplate")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local left, top = self:GetLeft(), self:GetTop()
        local screenWidth, screenHeight = UIParent:GetWidth(), UIParent:GetHeight()
        local frameWidth, frameHeight = self:GetWidth(), self:GetHeight()

        left = math.max(0, math.min(left, screenWidth - frameWidth))
        top = math.max(frameHeight, math.min(top, screenHeight))

        if left ~= self:GetLeft() or top ~= self:GetTop() then
            self:ClearAllPoints()
            self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
        end

        BOT_BAR_SETTINGS.posX = left
        BOT_BAR_SETTINGS.posY = top
    end)

    local originalWidth, originalHeight = 400, 50
    frame.originalAspectRatio = originalWidth / originalHeight

    SetDialogBackdrop(frame, "Interface\\Tooltips\\UI-Tooltip-Background", 0, 0, 0, 0.8)

    local resizeHandle = CreateFrame("Button", nil, frame)
    resizeHandle:SetSize(16, 16)
    resizeHandle:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeHandle:SetFrameLevel(frame:GetFrameLevel() + 1)
    resizeHandle:EnableMouse(true)
    resizeHandle:RegisterForDrag("LeftButton")

    resizeHandle:SetScript("OnDragStart", function(self)
        frame:StartSizing("BOTTOMRIGHT")
        self:GetHighlightTexture():Hide()
        frame.resizing = true
        frame.startWidth, frame.startHeight = frame:GetSize()
    end)

    resizeHandle:SetScript("OnDragStop", function(self)
        frame:StopMovingOrSizing()
        self:GetHighlightTexture():Show()
        frame.resizing = false
        local width, height = frame:GetSize()
        BOT_BAR_SETTINGS.width = width
        BOT_BAR_SETTINGS.scale = height / originalHeight
    end)

    frame:SetScript("OnSizeChanged", function(self, width, height)
        if frame.resizing then
            self:SetHeight(width / frame.originalAspectRatio)
            AdjustButtons(frame)
        end
    end)

    frame:SetResizable(true)
    frame:SetMinResize(originalWidth * 0.5, originalHeight * 0.5)
    frame:SetMaxResize(originalWidth * 3, originalHeight * 3)

    SetSimpleTooltip(resizeHandle, "Resize")

    local movementGroup = {
        {text = "Attack", icon = "ability_ghoulfrenzy", command = "attack", movement = true},
        {text = "Follow", icon = "Ability_Tracking", command = "follow", movement = true, default = true},
        {text = "Stay", icon = "spell_nature_timestop", command = "stay", movement = true},
    }

    local combatGroup = {
        {text = "Aggressive", icon = "ability_racial_bloodrage", command = "co +grind,-passive", combat = true},
        {text = "Defensive", icon = "Ability_Warrior_DefensiveStance", command = "co -grind,-passive", combat = true, default = true},
        {text = "Passive", icon = "ability_seal", command = "co -grind,-stay,+follow,+passive\nnc -stay,+follow", combat = true, forceFollow = true},
    }

    local toggleButtons = {
        {text = "Toggle Burst Mode", icon = "Ability_Shaman_Heroism", command = "boost", toggle = true, default = true},
        {text = "Toggle Food Between Fights", icon = "INV_Misc_Food_10", command = "food", toggle = true, default = true},
        {text = "Toggle Healer DPS", icon = "Spell_Holy_HolySmite", command = "healer dps", toggle = true, default = true},
        {text = "Group Setup", icon = "INV_Misc_GroupLooking", onClick = function() ShowGroupSetupWindow() end},
    }

    local buttons = {}
    for _, group in ipairs({movementGroup, toggleButtons, combatGroup}) do
        for _, info in ipairs(group) do
            table.insert(buttons, info)
        end
    end

    frame.movementGroup = movementGroup
    frame.combatGroup = combatGroup
    frame.buttons = buttons

    local function UpdateButtonTooltip(button)
        if GameTooltip:IsOwned(button) then
            GameTooltip:SetOwner(button, "ANCHOR_TOP")
            GameTooltip:SetText(button.info.text, 1, 1, 1)
            if button.info.toggle then
                GameTooltip:AddLine(button.state and "|cFF00FF00Enabled|r" or "|cFFFF0000Disabled|r", 1, 1, 1)
            elseif button.state and frame.currentMode == "combat" then
                GameTooltip:AddLine("|cFF00FF00Active|r", 1, 1, 1)
            end
            GameTooltip:Show()
        end
    end

    local function CreateButton(i, btnInfo, buttonWidth, buttonHeight, spacing)
        local button = CreateFrame("Button", "BotControlBarButton"..i, frame, "SecureActionButtonTemplate")
        button:SetSize(buttonWidth, buttonHeight)
        button:SetPoint("LEFT", frame, "LEFT", 10 + ((i - 1) * (buttonWidth + spacing)), 0)
        button.info = btnInfo

        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetAllPoints()
        button.icon:SetTexture("Interface\\Icons\\"..btnInfo.icon)

        button.border = button:CreateTexture(nil, "OVERLAY")
        button.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        button.border:SetBlendMode("ADD")
        button.border:SetAlpha(0)
        button.border:SetPoint("CENTER", button, "CENTER", 0, 1)
        button.border:SetSize(buttonWidth * 1.60, buttonHeight * 1.60)

        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(self.info.text, 1, 1, 1)
            if self.info.toggle then
                GameTooltip:AddLine(self.state and "|cFF00FF00Enabled|r" or "|cFFFF0000Disabled|r", 1, 1, 1)
            elseif self.state then
                GameTooltip:AddLine("|cFF00FF00Active|r", 1, 1, 1)
            end
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
        button:SetScript("OnMouseDown", function(self)
            self.icon:SetVertexColor(0.5, 0.5, 0.5)
        end)
        button:SetScript("OnMouseUp", function(self)
            self.icon:SetVertexColor(1, 1, 1)
        end)

        return button
    end

    local function GetBarButton(info)
        return _G["BotControlBarButton"..tIndexOf(frame.originalButtons, info)]
    end

    local function SetButtonState(button, active, refreshTooltip)
        if not button then return end
        button.state = active
        button.border:SetAlpha(active and 1 or 0)
        if refreshTooltip then UpdateButtonTooltip(button) end
    end

    local function SetMovementState(command)
        for _, info in ipairs(frame.movementGroup) do
            if info.command == "follow" or info.command == "stay" then
                SetButtonState(GetBarButton(info), info.command == command, true)
            end
        end
    end

    local passiveInfo, defensiveInfo = combatGroup[3], combatGroup[2]

    local function SetCombatButtonClickHandler(button)
        button:SetScript("OnClick", function(self)
            local info = self.info

            if info.onClick then
                info.onClick()
                return
            end

            if info.guild then
                SendThrottledChatMessage(info.command, "GUILD")
                return
            end

            if info.forceFollow then
                SetMovementState("follow")
            end

            local passiveButton = GetBarButton(passiveInfo)
            if passiveButton and passiveButton.state and info.movement and info.command == "attack" then
                if not UnitExists("target") then
                    UIErrorsFrame:AddMessage("You don't have a target.", 1.0, 1.0, 0.0, 1.0, 6)
                else
                    SetButtonState(passiveButton, false, true)
                    SetButtonState(GetBarButton(defensiveInfo), true, true)
                    SendThrottledChatMessage("follow")
                    AfterDelay(0.5, function() SendThrottledChatMessage("attack") end)
                end
                return
            end

            if info.movement then
                if info.command == "attack" then
                    if not UnitExists("target") then
                        UIErrorsFrame:AddMessage("You don't have a target.", 1.0, 1.0, 0.0, 1.0, 6)
                    else
                        SendThrottledChatMessage(info.command)
                    end
                    return
                end
                SetMovementState(info.command)
                SendThrottledChatMessage(info.command)
                return
            end

            if info.combat then
                for _, other in ipairs(combatGroup) do
                    SetButtonState(GetBarButton(other), false, true)
                end
                SetButtonState(self, true, true)
                SendCommands(info.command)
                return
            end

            if info.toggle then
                self.state = not self.state
                if info.command == "boost" then
                    if self.state then
                        SendThrottledChatMessage("co +boost")
                        SendThrottledChatMessage("ss -2825,-32182")
                    else
                        SendThrottledChatMessage("co -boost")
                        SendThrottledChatMessage("ss +2825,+32182")
                    end
                elseif info.command == "food" then
                    SendThrottledChatMessage(self.state and "nc +food" or "nc -food")
                elseif info.command == "healer dps" then
                    SendThrottledChatMessage(self.state and "co +healer dps" or "co -healer dps")
                end
                self.border:SetAlpha(self.state and 1 or 0)
                UpdateButtonTooltip(self)
            else
                SendCommands(info.command)
            end
        end)
    end

    for i, info in ipairs(buttons) do
        local button = CreateButton(i, info, 36, 36, 2)
        button.state = info.default or false
        button.border:SetAlpha(button.state and 1 or 0)
        SetCombatButtonClickHandler(button)
    end

    frame:SetWidth(originalWidth + 10)

    frame.closeButton = CreateFrame("Button", "BotControlBarToggleButton", frame)
    local closeButton = frame.closeButton
    closeButton:SetSize(24, 24)
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    closeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    closeButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    closeButton:GetNormalTexture():SetSize(24, 24)
    closeButton:GetPushedTexture():SetSize(24, 24)
    closeButton:GetHighlightTexture():SetSize(24, 24)
    closeButton:SetScript("OnClick", function()
        if frame:IsVisible() then
            frame:Hide()
        else
            frame:Show()
        end
    end)
    SetSimpleTooltip(closeButton, "Close Control Bar")

    frame.modeButton = CreateFrame("Button", "BotControlBarModeButton", frame, "SecureActionButtonTemplate")
    local modeButton = frame.modeButton
    modeButton:SetSize(18, 18)
    modeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -25)
    modeButton.info = {
        text = "Utility Mode",
        icon = "Spell_Shadow_Teleport",
        command = "changemode",
    }

    modeButton.icon = modeButton:CreateTexture(nil, "ARTWORK")
    modeButton.icon:SetAllPoints()
    modeButton.icon:SetTexture("Interface\\Icons\\"..modeButton.info.icon)

    modeButton.border = modeButton:CreateTexture(nil, "OVERLAY")
    modeButton.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    modeButton.border:SetBlendMode("ADD")
    modeButton.border:SetAlpha(0)
    modeButton.border:SetPoint("CENTER", modeButton, "CENTER", 0, 1)
    modeButton.border:SetSize(20 * 1.50, 20 * 1.50)
    modeButton:SetFrameLevel(frame:GetFrameLevel() + 2)

    modeButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(self.info.text, 1, 1, 1)
        GameTooltip:Show()
    end)
    modeButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    modeButton:SetScript("OnMouseDown", function(self)
        self.icon:SetVertexColor(0.5, 0.5, 0.5)
    end)
    modeButton:SetScript("OnMouseUp", function(self)
        self.icon:SetVertexColor(1, 1, 1)
    end)

    frame.currentMode = "combat"
    frame.originalButtons = frame.buttons
    frame.originalMovementGroup = frame.movementGroup
    frame.originalCombatGroup = frame.combatGroup

    local utilityButtons = {
        {text = "Use Objects", icon = "INV_Misc_EngGizmos_02", command = "los", action = "objects"},
        {
            text = "Loot Strategy",
            icon = "INV_Misc_Coin_01",
            dropdown = {
                {text = "Don't loot anything", command = "ll none"},
                {text = "Loot all items", command = "ll all"},
                {text = "Loot anything except BoP items", command = "ll normal"},
                {text = "Loot quest objects only", command = "ll quest"},
                {text = "Loot only gray items", command = "ll gray"},
                {text = "Loot only skill items", command = "ll skill"},
            },
        },
        {
            text = "Formation",
            icon = "Ability_Warrior_ShieldWall",
            dropdown = {
                {text = "Shield", command = "formation shield"},
                {text = "Arrow", command = "formation arrow"},
                {text = "Chaos", command = "formation chaos"},
                {text = "Queue", command = "formation queue"},
                {text = "Circle", command = "formation circle"},
                {text = "Near", command = "formation near"},
                {text = "Melee", command = "formation melee"},
            },
        },
        {
            text = "NPC Interaction",
            icon = "achievement_character_human_male",
            dropdown = {
                {text = "Talk to NPC", command = "talk", requiresTarget = true},
                {text = "Repair", command = "repair", requiresTarget = true, requiresRepairVendor = true},
                {text = "Train", command = "trainer learn", requiresTarget = true, requiresTrainer = true},
            },
        },
        {text = "Summon", icon = "Spell_Shadow_Teleport", command = ".shadowsmenu", action = "summon"},
        {text = "Shadows Chatter", icon = "Spell_Holy_Silence", toggle = true, default = true, command = ".muteshadow", action = "chatter"},
        {
            text = "Quest",
            icon = "INV_Letter_11",
            dropdown = {
                {text = "Show quest progress", command = "quests all"},
                {text = "Accept quests", command = "accept *"},
                {text = "Abandon quest", command = "quests all", abandonQuest = true},
            },
        },
        {text = "Inventory", icon = "inv_misc_bag_07_black", command = "c"},
        {text = "Set Hearthstone", icon = "INV_Misc_Rune_01", command = "home"},
        {
            text = "Ghost Commands",
            icon = "spell_holy_guardianspirit",
            dropdown = {
                {text = "Release spirit", command = "release"},
                {text = "Revive at spirit healer", command = "revive"},
            },
        },
    }

    local dropdown

    local function RequestQuestData(command, abandon)
        wipe(questCache)
        questLastUpdate = 0
        SendThrottledChatMessage(command)

        local questFrame = CreateFrame("Frame")
        questFrame:RegisterEvent("CHAT_MSG_WHISPER")
        questFrame:SetScript("OnEvent", function(self, event, msg, sender)
            local data = questCache[sender]
            if not data then
                data = {completed = {}, incompleted = {}, summary = ""}
                questCache[sender] = data
            end

            if msg:match("%-%-%-") then
                if msg:match("Completed quests") then
                    data.currentSection = "completed"
                elseif msg:match("Incompleted quests") then
                    data.currentSection = "incompleted"
                elseif msg:match("Summary") then
                    data.currentSection = "summary"
                end
            elseif data.currentSection == "summary" then
                data.summary = msg
            else
                local questLink = msg:match("(%[.-%])")
                if questLink and data.currentSection then
                    table.insert(data[data.currentSection], questLink)
                end
            end

            questLastUpdate = GetTime()
        end)

        local timer = CreateFrame("Frame")
        timer.elapsed = 0
        timer:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = self.elapsed + elapsed

            if questLastUpdate > 0 and (GetTime() - questLastUpdate) >= 1 and next(questCache) then
                if abandon then ShowQuestAbandonList() else ShowQuestList() end
                questLastUpdate = 0
                questFrame:UnregisterEvent("CHAT_MSG_WHISPER")
                self:SetScript("OnUpdate", nil)
            elseif self.elapsed >= 5 then
                questFrame:UnregisterEvent("CHAT_MSG_WHISPER")
                self:SetScript("OnUpdate", nil)
            end
        end)
    end

    local function OpenUtilityDropdown(button)
        if not dropdown then
            dropdown = CreateFrame("Frame", "TempDropdown", UIParent, "UIDropDownMenuTemplate")
        end
        dropdown:ClearAllPoints()
        dropdown:SetPoint("TOP", button, "BOTTOM", 0, -5)
        dropdown.button = button

        UIDropDownMenu_Initialize(dropdown, function(self, level)
            local info = UIDropDownMenu_CreateInfo()
            for _, item in ipairs(dropdown.button.info.dropdown) do
                info.text = item.text
                info.func = function()
                    local skip = false
                    if item.requiresTarget and not UnitExists("target") then
                        local errorMsg = "You must have a target."
                        if item.requiresTrainer then
                            errorMsg = "You must have a trainer targeted."
                        end
                        UIErrorsFrame:AddMessage(errorMsg, 1.0, 1.0, 0.0, 1.0, 6)
                        skip = true
                    elseif item.requiresRepairVendor and not CanMerchantRepair() then
                        UIErrorsFrame:AddMessage("Cannot repair at this vendor.", 1.0, 1.0, 0.0, 1.0, 6)
                        skip = true
                    elseif item.text == "Accept quests" then
                        if not UnitExists("target") then
                            UIErrorsFrame:AddMessage("You must have a quest giver targeted.", 1.0, 1.0, 0.0, 1.0, 6)
                            skip = true
                        end
                    elseif item.questList or item.abandonQuest then
                        RequestQuestData(item.command, item.abandonQuest)
                        skip = true
                    end
                    if not skip then
                        SendThrottledChatMessage(item.command)
                    end
                    CloseDropDownMenus()
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end)

        dropdown:Hide()
        ToggleDropDownMenu(1, nil, dropdown, button, 0, 0)
    end

    function HandleUtilityButtonAction(button)
        local info = button.info

        if info.action == "objects" then
            SendThrottledChatMessage("los")

            local responseReceived = false
            local responseFrame = CreateFrame("Frame")
            responseFrame:RegisterEvent("CHAT_MSG_WHISPER")
            responseFrame:SetScript("OnEvent", function(self, event, msg)
                local lowerMsg = msg:lower()
                if lowerMsg:match("spell") or lowerMsg:match("quest") then return end
                local itemName = msg:match("%[(.-)%]")
                if itemName then
                    responseReceived = true
                    if not itemCache[itemName] then
                        itemCache[itemName] = true
                        lastUpdate = GetTime()
                    end
                end
            end)

            local timer = CreateFrame("Frame")
            timer.elapsed = 0
            timer:SetScript("OnUpdate", function(self, elapsed)
                self.elapsed = self.elapsed + elapsed

                if self.elapsed >= 5 and not responseReceived then
                    UIErrorsFrame:AddMessage("No usable objects nearby.", 1.0, 1.0, 0.0, 1.0, 6)
                    responseFrame:UnregisterEvent("CHAT_MSG_WHISPER")
                    self:SetScript("OnUpdate", nil)
                elseif lastUpdate > 0 and (GetTime() - lastUpdate) >= 1 and next(itemCache) then
                    ShowItemList()
                    lastUpdate = 0
                    responseFrame:UnregisterEvent("CHAT_MSG_WHISPER")
                    self:SetScript("OnUpdate", nil)
                end
            end)
        elseif info.action == "summon" then
            SendChatMessage(".shadows summon", "GUILD")
        elseif info.action == "chatter" then
            button.state = not button.state
            button.border:SetAlpha(button.state and 1 or 0)
            SendChatMessage(button.state and ".unmuteshadows" or ".muteshadows", "GUILD")
            UpdateButtonTooltip(button)
        elseif info.dropdown then
            OpenUtilityDropdown(button)
        else
            SendThrottledChatMessage(info.command)
        end
    end

    local function SaveToggleStates(list, lookup)
        local states = {}
        for _, info in ipairs(list) do
            if info.toggle then
                local button = _G["BotControlBarButton"..tIndexOf(lookup, info)]
                if button then
                    states[info.text] = button.state
                end
            end
        end
        return states
    end

    local function FindActiveText(group, lookup)
        for _, info in ipairs(group) do
            local button = _G["BotControlBarButton"..tIndexOf(lookup, info)]
            if button and button.state then
                return info.text
            end
        end
        return nil
    end

    local function SetModeInfo(text, icon)
        modeButton.info = {text = text, icon = icon, command = "changemode"}
        modeButton.icon:SetTexture("Interface\\Icons\\"..icon)
    end

    local function GetBarButtonByIndex(i)
        return _G["BotControlBarButton"..i]
    end

    local function SwitchMode()
        if frame.currentMode == "combat" then
            frame.previousCombatToggleStates = SaveToggleStates(frame.originalButtons, frame.originalButtons)
            frame.previousCombatMovementActive = FindActiveText(frame.movementGroup, frame.originalButtons)
            frame.previousCombatCombatActive = FindActiveText(frame.combatGroup, frame.originalButtons)

            frame.currentMode = "utility"
            SetModeInfo("Combat Mode", "Ability_DualWield")

            for i = 1, #frame.originalButtons do
                local button = GetBarButtonByIndex(i)
                if button then button:Hide() end
            end

            frame.buttons = utilityButtons
            for i, info in ipairs(utilityButtons) do
                local button = GetBarButtonByIndex(i)
                if not button then
                    button = CreateButton(i, info, 36, 36, 2)
                else
                    button:Show()
                    button:SetSize(36, 36)
                    button:SetPoint("LEFT", frame, "LEFT", 10 + ((i - 1) * (36 + 2)), 0)
                    button.info = info
                    button.icon:SetTexture("Interface\\Icons\\"..info.icon)
                    button.border:SetAlpha(0)
                    button.state = false
                end

                if info.toggle then
                    button.state = info.default or false
                    button.border:SetAlpha(button.state and 1 or 0)
                end

                button:SetScript("OnClick", function(self)
                    HandleUtilityButtonAction(self)
                end)
            end

            for _, info in ipairs(utilityButtons) do
                if info.toggle then
                    local button = GetBarButtonByIndex(tIndexOf(utilityButtons, info))
                    if button then
                        button.state = info.default or false
                        if frame.previousUtilityToggleStates and frame.previousUtilityToggleStates[info.text] ~= nil then
                            button.state = frame.previousUtilityToggleStates[info.text]
                        end
                        button.border:SetAlpha(button.state and 1 or 0)
                    end
                end
            end

            for i = #utilityButtons + 1, #frame.originalButtons do
                local button = GetBarButtonByIndex(i)
                if button then button:Hide() end
            end

            AdjustButtons(frame)
        else
            frame.previousUtilityToggleStates = SaveToggleStates(utilityButtons, utilityButtons)

            frame.currentMode = "combat"
            SetModeInfo("Utility Mode", "Spell_Shadow_Teleport")

            for i = 1, #utilityButtons do
                local button = GetBarButtonByIndex(i)
                if button then button:Hide() end
            end
            if dropdown then dropdown:Hide() end

            frame.buttons = frame.originalButtons
            frame.movementGroup = frame.originalMovementGroup
            frame.combatGroup = frame.originalCombatGroup

            for i, info in ipairs(frame.originalButtons) do
                local button = GetBarButtonByIndex(i)
                if not button then
                    button = CreateButton(i, info, 36, 36, 2)
                else
                    button:Show()
                    button:SetSize(36, 36)
                    button:SetPoint("LEFT", frame, "LEFT", 10 + ((i - 1) * (36 + 2)), 0)
                    button.info = info
                    button.icon:SetTexture("Interface\\Icons\\"..info.icon)
                end

                SetCombatButtonClickHandler(button)

                if info.toggle then
                    button.state = info.default or false
                    if frame.previousCombatToggleStates and frame.previousCombatToggleStates[info.text] ~= nil then
                        button.state = frame.previousCombatToggleStates[info.text]
                    end
                else
                    button.state = false
                end

                if frame.previousCombatMovementActive and info.text == frame.previousCombatMovementActive and info.movement then
                    button.state = true
                end
                if frame.previousCombatCombatActive and info.text == frame.previousCombatCombatActive and info.combat then
                    button.state = true
                end
                button.border:SetAlpha(button.state and 1 or 0)
            end

            for i = #frame.originalButtons + 1, #utilityButtons do
                local button = GetBarButtonByIndex(i)
                if button then button:Hide() end
            end

            AdjustButtons(frame)
        end
    end

    modeButton:SetScript("OnClick", SwitchMode)

    function AdjustButtons(f)
        local currentWidth, currentHeight = f:GetSize()
        local scale = currentHeight / originalHeight

        local buttonWidth = 36 * scale
        local buttonHeight = 36 * scale
        local spacing = 2 * scale
        local leftMargin = 10 * scale
        local closeButtonSize = 24 * scale
        local modeButtonSize = 18 * scale
        local rightMargin = 20 * scale

        local availableWidth = currentWidth - leftMargin - rightMargin
        local totalButtonsWidth = (#f.buttons * buttonWidth) + ((#f.buttons - 1) * spacing)

        if totalButtonsWidth > availableWidth then
            local maxButtonWidth = (availableWidth - ((#f.buttons - 1) * spacing)) / #f.buttons
            buttonWidth = math.max(20 * scale, maxButtonWidth)
        end

        for i, info in ipairs(f.buttons) do
            local button = _G["BotControlBarButton"..i]
            if button then
                button:SetSize(buttonWidth, buttonHeight)
                button:SetPoint("LEFT", f, "LEFT", leftMargin + ((i - 1) * (buttonWidth + spacing)), 0)
                if button.border then
                    button.border:SetSize(buttonWidth * 1.60, buttonHeight * 1.60)
                    button.border:SetPoint("CENTER", button, "CENTER", 0, 1)
                end
            end
        end

        if f.closeButton then
            f.closeButton:SetSize(closeButtonSize, closeButtonSize)
            f.closeButton:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
            f.closeButton:GetNormalTexture():SetSize(closeButtonSize, closeButtonSize)
            f.closeButton:GetPushedTexture():SetSize(closeButtonSize, closeButtonSize)
            f.closeButton:GetHighlightTexture():SetSize(closeButtonSize, closeButtonSize)
        end

        if f.modeButton then
            f.modeButton:SetSize(modeButtonSize, modeButtonSize)
            f.modeButton:SetPoint("TOPRIGHT", f, "TOPRIGHT", (-3 * scale), (-25 * scale))
            if f.modeButton.border then
                f.modeButton.border:SetSize(modeButtonSize * 1.50, modeButtonSize * 1.50)
                f.modeButton.border:SetPoint("CENTER", f.modeButton, "CENTER", 0, 1)
            end
        end
    end

    function ShowItemList()
        if not itemListFrame then
            itemListFrame = CreateScrollList("ShadowItemListFrame", 220, 300, "Choose object to use", {
                childWidth = 200,
                rightInset = -10,
                thumbHeight = 16,
            })
            itemListFrame.buttons = {}
        end

        for _, button in ipairs(itemListFrame.buttons) do
            button:Hide()
        end
        wipe(itemListFrame.buttons)

        local itemList = {}
        for link in pairs(itemCache) do
            table.insert(itemList, link)
        end
        table.sort(itemList)

        local yOffset = 0
        for _, link in ipairs(itemList) do
            local button = CreateFrame("Button", nil, itemListFrame.scrollChild)
            button:SetSize(190, 20)
            button:SetPoint("TOPLEFT", 0, -yOffset)

            local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetAllPoints()
            text:SetJustifyH("LEFT")
            text:SetText(link)

            button:SetScript("OnClick", function()
                SendThrottledChatMessage("u "..link)
                itemListFrame:Hide()
            end)

            tinsert(itemListFrame.buttons, button)
            yOffset = yOffset + 20
        end

        UpdateScrollList(itemListFrame, yOffset)
        wipe(itemCache)
        itemListFrame:Show()
    end

    local questListFrame

    function ShowQuestList()
        if not questListFrame then
            questListFrame = CreateScrollList("ShadowQuestListFrame", 400, 500, "Quest Progress", {
                childWidth = 360,
                rightInset = -30,
            })
            questListFrame.content = {}
        end

        for _, region in ipairs(questListFrame.content) do
            region:Hide()
        end
        wipe(questListFrame.content)

        local child = questListFrame.scrollChild

        local function AddLine(font, text, xOffset, yOffset, color, width)
            local line = child:CreateFontString(nil, "OVERLAY", font)
            line:SetPoint("TOPLEFT", xOffset, -yOffset)
            line:SetText(text)
            if color then line:SetTextColor(color[1], color[2], color[3]) end
            if width then
                line:SetWidth(width)
                line:SetJustifyH("LEFT")
            end
            tinsert(questListFrame.content, line)
            return line
        end

        local yOffset = 0
        for sender, data in pairs(questCache) do
            AddLine("GameFontNormalLarge", sender, 5, yOffset, {1, 0.82, 0})
            yOffset = yOffset + 20

            if #data.incompleted > 0 then
                AddLine("GameFontNormal", "--- Incompleted quests ---", 10, yOffset, {1, 0.5, 0.5})
                yOffset = yOffset + 15
                for _, quest in ipairs(data.incompleted) do
                    AddLine("GameFontNormal", quest, 15, yOffset, nil, 340)
                    yOffset = yOffset + 15
                end
            end

            if #data.completed > 0 then
                AddLine("GameFontNormal", "--- Completed quests ---", 10, yOffset, {0.5, 1, 0.5})
                yOffset = yOffset + 15
                for _, quest in ipairs(data.completed) do
                    AddLine("GameFontNormal", quest, 15, yOffset, nil, 340)
                    yOffset = yOffset + 15
                end
            end

            if data.summary ~= "" then
                AddLine("GameFontNormal", "--- Summary ---", 10, yOffset, {0.5, 0.5, 1})
                yOffset = yOffset + 15
                AddLine("GameFontNormal", data.summary, 15, yOffset, nil, 340)
                yOffset = yOffset + 15
            end

            yOffset = yOffset + 10
        end

        UpdateScrollList(questListFrame, yOffset)
        questListFrame:Show()
    end

    local abandonListFrame

    function ShowQuestAbandonList()
        if not abandonListFrame then
            abandonListFrame = CreateScrollList("ShadowQuestAbandonFrame", 400, 500, "Which quest would you like to abandon?", {
                childWidth = 360,
                rightInset = -30,
            })
            abandonListFrame.content = {}
        end

        for _, region in ipairs(abandonListFrame.content) do
            region:Hide()
        end
        wipe(abandonListFrame.content)

        local child = abandonListFrame.scrollChild

        local function AddLine(font, text, xOffset, yOffset, color)
            local line = child:CreateFontString(nil, "OVERLAY", font)
            line:SetPoint("TOPLEFT", xOffset, -yOffset)
            line:SetText(text)
            if color then line:SetTextColor(color[1], color[2], color[3]) end
            tinsert(abandonListFrame.content, line)
            return line
        end

        local yOffset = 0
        for sender, data in pairs(questCache) do
            AddLine("GameFontNormalLarge", sender, 5, yOffset, {1, 0.82, 0})
            yOffset = yOffset + 20

            local allQuests = {}
            for _, quest in ipairs(data.incompleted) do
                table.insert(allQuests, quest)
            end
            for _, quest in ipairs(data.completed) do
                table.insert(allQuests, quest)
            end

            for _, questLink in ipairs(allQuests) do
                local button = CreateFrame("Button", nil, child)
                button:SetSize(340, 20)
                button:SetPoint("TOPLEFT", 10, -yOffset)

                local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                text:SetAllPoints()
                text:SetJustifyH("LEFT")
                text:SetText(questLink)

                button:SetScript("OnClick", function()
                    StaticPopupDialogs["ABANDON_QUEST_CONFIRM"] = {
                        text = "Are you sure you want "..sender.." to abandon quest "..questLink.."?",
                        button1 = "Yes",
                        button2 = "No",
                        OnAccept = function()
                            SendThrottledChatMessage("drop "..questLink, "WHISPER", nil, sender)
                            abandonListFrame:Hide()
                        end,
                        timeout = 0,
                        whileDead = true,
                        hideOnEscape = true,
                        preferredIndex = 3,
                    }
                    StaticPopup_Show("ABANDON_QUEST_CONFIRM")
                end)

                tinsert(abandonListFrame.content, button)
                yOffset = yOffset + 20
            end

            yOffset = yOffset + 10
        end

        UpdateScrollList(abandonListFrame, yOffset)
        abandonListFrame:Show()
    end

    function ShowRoleManagementWindow()
        if _G["ShadowRoleManagementFrame"] then
            _G["ShadowRoleManagementFrame"]:Hide()
            _G["ShadowRoleManagementFrame"] = nil
        end

        local roleData = {tanks = {}, healers = {}, dps = {}}
        local channel = GetGroupChannel()
        if not channel then
            print("You must be in a group to manage roles.")
            return
        end

        local responseFrame = CreateFrame("Frame")
        responseFrame:RegisterEvent("CHAT_MSG_WHISPER")
        responseFrame:SetScript("OnEvent", function(self, event, msg, sender)
            local lowerMsg = msg:lower()
            if lowerMsg:match("tank") then
                table.insert(roleData.tanks, sender)
            elseif lowerMsg:match("heal") then
                table.insert(roleData.healers, sender)
            elseif lowerMsg:match("dps") then
                table.insert(roleData.dps, sender)
            end
        end)

        SendThrottledChatMessage("co ?", channel)

        local waitFrame = CreateFrame("Frame")
        waitFrame.elapsed = 0
        waitFrame.lastReceive = GetTime()
        waitFrame:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = self.elapsed + elapsed

            if (GetTime() - self.lastReceive) >= 0.5 then
                DisplayRoleWindow(roleData)
                responseFrame:UnregisterEvent("CHAT_MSG_WHISPER")
                self:SetScript("OnUpdate", nil)
            elseif self.elapsed >= 5 then
                DisplayRoleWindow(roleData)
                responseFrame:UnregisterEvent("CHAT_MSG_WHISPER")
                self:SetScript("OnUpdate", nil)
            end
        end)

        local originalOnEvent = responseFrame:GetScript("OnEvent")
        responseFrame:SetScript("OnEvent", function(self, event, msg, sender)
            originalOnEvent(self, event, msg, sender)
            waitFrame.lastReceive = GetTime()
        end)
    end

    local CLASS_ICON_TCOORDS = {
        ["WARRIOR"] = {0, 0.25, 0, 0.25},
        ["MAGE"] = {0.25, 0.49609375, 0, 0.25},
        ["ROGUE"] = {0.49609375, 0.7421875, 0, 0.25},
        ["DRUID"] = {0.7421875, 0.98828125, 0, 0.25},
        ["HUNTER"] = {0, 0.25, 0.25, 0.5},
        ["SHAMAN"] = {0.25, 0.49609375, 0.25, 0.5},
        ["PRIEST"] = {0.49609375, 0.7421875, 0.25, 0.5},
        ["WARLOCK"] = {0.7421875, 0.98828125, 0.25, 0.5},
        ["PALADIN"] = {0, 0.25, 0.5, 0.75},
        ["DEATHKNIGHT"] = {0.25, 0.49609375, 0.5, 0.75},
    }

    local function GetPlayerClass(playerName)
        if cachedNames and cachedNames[playerName] then
            return string.upper(cachedNames[playerName])
        end
        return nil
    end

    function DisplayRoleWindow(roleData)
        if _G["ShadowRoleManagementFrame"] then
            _G["ShadowRoleManagementFrame"]:Hide()
        end

        local columnWidth = 190
        local frameWidth = (3 * columnWidth) + 40
        local maxPlayers = math.max(#roleData.tanks, #roleData.healers, #roleData.dps)
        if maxPlayers == 0 then maxPlayers = 1 end
        local frameHeight = 120 + (maxPlayers * 25)

        local roleFrame = CreateDialog("ShadowRoleManagementFrame", frameWidth, frameHeight, "Group Roles", {
            strata = "FULLSCREEN_DIALOG",
            bgFile = "Interface\\Buttons\\WHITE8X8",
            bgColor = {0, 0, 0, 1},
            level = 100,
        })

        local function CreatePlayerButton(playerName, xOffset, yOffset)
            local button = CreateFrame("Button", nil, roleFrame)
            button:SetSize(170, 20)
            button:SetPoint("TOPLEFT", xOffset, yOffset)

            local playerClass = GetPlayerClass(playerName)
            if playerClass and CLASS_ICON_TCOORDS[playerClass] then
                local classIcon = button:CreateTexture(nil, "ARTWORK")
                classIcon:SetSize(16, 16)
                classIcon:SetPoint("LEFT", 0, 0)
                classIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
                classIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[playerClass]))
            end

            button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            button.text:SetPoint("LEFT", 20, 0)
            button.text:SetText(playerName)
            button.text:SetJustifyH("LEFT")
            button:SetScript("OnClick", function()
                ShowRoleChangePrompt(playerName)
            end)
            SetHoverText(button)
            return button
        end

        local columns = {
            {title = "Tanks", data = roleData.tanks, icon = "Interface\\Icons\\Ability_Defend", xOffset = 20},
            {title = "Healers", data = roleData.healers, icon = "Interface\\Icons\\Spell_Nature_HealingWaveGreater", xOffset = 20 + columnWidth},
            {title = "DPS", data = roleData.dps, icon = "Interface\\Icons\\INV_Sword_27", xOffset = 20 + (columnWidth * 2)},
        }

        for _, column in ipairs(columns) do
            local iconTexture = roleFrame:CreateTexture(nil, "ARTWORK")
            iconTexture:SetSize(20, 20)
            iconTexture:SetPoint("TOPLEFT", column.xOffset, -40)
            iconTexture:SetTexture(column.icon)

            local header = roleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            header:SetPoint("TOPLEFT", column.xOffset + 25, -40)
            header:SetText(column.title..":")
            header:SetTextColor(1, 0.82, 0)

            if #column.data == 0 then
                local noneText = roleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                noneText:SetPoint("TOPLEFT", column.xOffset + 20, -65)
                noneText:SetText("None")
                noneText:SetTextColor(0.5, 0.5, 0.5)
            else
                for i, playerName in ipairs(column.data) do
                    CreatePlayerButton(playerName, column.xOffset, -65 - ((i - 1) * 25))
                end
            end
        end

        roleFrame:Show()
    end

    function ShowRoleChangePrompt(shadowName)
        StaticPopupDialogs["ROLE_CHANGE_WARNING"] = {
            text = "Do you want to change the role for "..shadowName.."?\n\nWARNING: Roles are supposed to come from talents and should only be changed manually if needed.",
            button1 = "Yes",
            button2 = "Cancel",
            OnAccept = function()
                ShowRoleSelectionWindow(shadowName)
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("ROLE_CHANGE_WARNING")
    end

    function ShowRoleSelectionWindow(shadowName)
        if _G["ShadowRoleSelectionFrame"] then
            _G["ShadowRoleSelectionFrame"]:Hide()
        end

        local selectionFrame = CreateDialog("ShadowRoleSelectionFrame", 400, 250,
            "What role do you want to assign to \nshadow "..shadowName.."?", {
                strata = "FULLSCREEN_DIALOG",
                bgFile = "Interface\\Buttons\\WHITE8X8",
                bgColor = {0, 0, 0, 1},
                level = 110,
            })

        local roles = {
            {
                name = "Tank",
                icon = "Ability_Warrior_DefensiveStance",
                command = "co +tank,+tank assist,+tank face,+bear,-heal,-healer dps,-dps assist,-cat",
            },
            {
                name = "Healer",
                icon = "Spell_Holy_FlashHeal",
                command = function()
                    local healerDpsBtn = _G["BotControlBarButton6"]
                    local healerDpsEnabled = healerDpsBtn and healerDpsBtn.state
                    if healerDpsEnabled then
                        return "co +heal,+healer dps,-tank,-tank assist,-tank face,-bear,-dps assist,-cat"
                    end
                    return "co +heal,-healer dps,-tank,-tank assist,-tank face,-bear,-dps assist,-cat"
                end,
            },
            {
                name = "DPS",
                icon = "Ability_DualWield",
                command = "co +dps,+dps assist,-tank,-tank assist,-tank face,-bear,-heal,-healer dps,-cat",
            },
        }

        for i, role in ipairs(roles) do
            local button = CreateHorizontalIconButton(selectionFrame, 200, 50,
                "Interface\\Icons\\"..role.icon, role.name, {iconX = 10, textGap = 10})
            button:SetPoint("TOP", 0, -60 - ((i - 1) * 60))
            button:SetScript("OnClick", function()
                local command = type(role.command) == "function" and role.command() or role.command
                SendThrottledChatMessage(command, "WHISPER", nil, shadowName)
                print("Set "..shadowName.." to role: "..role.name)
                selectionFrame:Hide()
                ShadowRoleManagementFrame:Hide()
            end)
        end

        selectionFrame:Show()
    end

    function ShowTalentManagementPrompt()
        if _G["ShadowTalentSelectionFrame"] then
            _G["ShadowTalentSelectionFrame"]:Show()
            return
        end

        local matches = {}
        for name in pairs(cachedNames) do
            table.insert(matches, name)
        end

        if #matches == 0 then
            return
        end

        local selectionFrame = CreateDialog("ShadowTalentSelectionFrame", 400, 100 + (#matches * 30),
            "Which shadow's talents do you want to manage?", {
                font = "GameFontNormal",
                titleY = -20,
                strata = "FULLSCREEN_DIALOG",
                bgFile = "Interface\\Buttons\\WHITE8X8",
                bgColor = {0, 0, 0, 1},
            })

        for i, name in ipairs(matches) do
            local button = CreateTextButton(selectionFrame, 360, 25, name, function()
                ShowTalentManagementWindow(name)
                selectionFrame:Hide()
            end)
            button:SetPoint("TOP", 0, -50 - ((i - 1) * 30))
        end

        selectionFrame:Show()
    end

    local function WaitForShadowMessage(shadowName, matcher, popupKey, popupText)
        local responseFrame = CreateFrame("Frame")
        responseFrame:RegisterEvent("CHAT_MSG_WHISPER")
        responseFrame:SetScript("OnEvent", function(self, event, msg, sender)
            if sender == shadowName and matcher(msg) then
                StaticPopupDialogs[popupKey] = {
                    text = popupText(msg),
                    button1 = "OK",
                    timeout = 0,
                    whileDead = true,
                    hideOnEscape = true,
                    preferredIndex = 3,
                }
                StaticPopup_Show(popupKey)
                self:UnregisterEvent("CHAT_MSG_WHISPER")
            end
        end)

        local timeout = CreateFrame("Frame")
        timeout.elapsed = 0
        timeout:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = self.elapsed + elapsed
            if self.elapsed >= 5 then
                responseFrame:UnregisterEvent("CHAT_MSG_WHISPER")
                self:SetScript("OnUpdate", nil)
            end
        end)
    end

    function ShowTalentManagementWindow(shadowName)
        if talentFrame then
            if talentFrame.shadowName == shadowName and talentFrame:IsShown() then
                return
            end
            talentFrame:Hide()
            talentFrame = nil
        end

        talentFrame = CreateDialog("ShadowTalentManagementFrame", 400, 300,
            "Talent Management: "..shadowName, {
                strata = "FULLSCREEN_DIALOG",
                bgFile = "Interface\\Buttons\\WHITE8X8",
                bgColor = {0, 0, 0, 1},
            })
        talentFrame.shadowName = shadowName

        local buttons = {
            {
                name = "Show Active Talents",
                icon = "Ability_Marksmanship",
                yOffset = -60,
                onClick = function()
                    ShowActiveTalents(shadowName)
                end,
            },
            {
                name = "Change Talent Set",
                icon = "ability_dualwield",
                yOffset = -120,
                onClick = function()
                    if not talentFrame.talentSet then talentFrame.talentSet = 1 end

                    WaitForShadowMessage(shadowName, function(msg)
                        return msg:match("primary talents") or msg:match("secondary talents")
                    end, "TALENT_SWITCH_CONFIRM", function(msg)
                        return shadowName..": "..msg
                    end)

                    SendThrottledChatMessage("talents switch "..talentFrame.talentSet, "WHISPER", nil, shadowName)
                    talentFrame.talentSet = 3 - talentFrame.talentSet
                end,
            },
            {
                name = "Auto Pick Talents",
                icon = "ability_shootwand",
                yOffset = -180,
                onClick = function()
                    WaitForShadowMessage(shadowName, function(msg)
                        return msg:match("Auto pick talents")
                    end, "AUTOPICK_CONFIRM", function()
                        return shadowName.." has auto picked their talents."
                    end)

                    SendThrottledChatMessage("talents autopick", "WHISPER", nil, shadowName)
                end,
            },
            {
                name = "Respec",
                icon = "ability_dualwieldspecialization",
                yOffset = -240,
                onClick = function()
                    ShowRespecWindow(shadowName)
                end,
            },
        }

        for _, info in ipairs(buttons) do
            local button = CreateHorizontalIconButton(talentFrame, 300, 40,
                "Interface\\Icons\\"..info.icon, info.name, {iconX = 10, textGap = 10, justifyLeft = true})
            button:SetPoint("TOP", 0, info.yOffset)
            button:SetScript("OnClick", info.onClick)
        end

        talentFrame:Show()
    end

    function ShowActiveTalents(shadowName)
        if _G["ShadowTalentResponseFrame"] then
            _G["ShadowTalentResponseFrame"]:Hide()
        end

        local talentResponse
        local responseFrame = CreateFrame("Frame")
        responseFrame:RegisterEvent("CHAT_MSG_WHISPER")
        responseFrame:SetScript("OnEvent", function(self, event, msg, sender)
            if sender == shadowName and msg:match("My current talent spec is:") then
                talentResponse = msg
                self:UnregisterEvent("CHAT_MSG_WHISPER")
            end
        end)

        SendThrottledChatMessage("talents", "WHISPER", nil, shadowName)

        local waitFrame = CreateFrame("Frame")
        waitFrame.elapsed = 0
        waitFrame:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = self.elapsed + elapsed

            if talentResponse then
                ShowTalentResponsePopup(talentResponse)
                responseFrame:UnregisterEvent("CHAT_MSG_WHISPER")
                self:SetScript("OnUpdate", nil)
            elseif self.elapsed >= 5 then
                print("No response received from "..shadowName)
                responseFrame:UnregisterEvent("CHAT_MSG_WHISPER")
                self:SetScript("OnUpdate", nil)
            end
        end)
    end

    function ShowTalentResponsePopup(responseText)
        if _G["ShadowRespecFrame"] then
            _G["ShadowRespecFrame"]:Hide()
        end

        local popup = CreateDialog("ShadowTalentResponseFrame", 500, 150, nil, {
            strata = "TOOLTIP",
            bgFile = "Interface\\Buttons\\WHITE8X8",
            bgColor = {0, 0, 0, 1},
        })

        local text = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("TOP", 0, -30)
        text:SetWidth(460)
        text:SetJustifyH("CENTER")
        text:SetText(responseText:match("(.-)Talents usage") or responseText)

        local okButton = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
        okButton:SetSize(100, 30)
        okButton:SetPoint("BOTTOM", 0, 20)
        okButton:SetText("OK")
        okButton:SetScript("OnClick", function()
            popup:Hide()
        end)

        popup:Show()
    end

    function ShowRespecWindow(shadowName)
        if _G["ShadowRespecFrame"] then
            _G["ShadowRespecFrame"]:Hide()
        end

        local respecResponse = {}
        local lastReceiveTime = 0

        local responseFrame = CreateFrame("Frame")
        responseFrame:RegisterEvent("CHAT_MSG_WHISPER")
        responseFrame:SetScript("OnEvent", function(self, event, msg, sender)
            if sender == shadowName then
                if msg:match("%d+%.") or msg:match("%(") then
                    table.insert(respecResponse, msg)
                    lastReceiveTime = GetTime()
                end
            end
        end)

        SendThrottledChatMessage("talents spec list", "WHISPER", nil, shadowName)

        local waitFrame = CreateFrame("Frame")
        waitFrame.elapsed = 0
        waitFrame:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = self.elapsed + elapsed

            if #respecResponse > 0 and lastReceiveTime > 0 and (GetTime() - lastReceiveTime) >= 0.5 then
                ShowRespecSelectionPopup(shadowName, respecResponse)
                responseFrame:UnregisterEvent("CHAT_MSG_WHISPER")
                self:SetScript("OnUpdate", nil)
            elseif self.elapsed >= 5 then
                if #respecResponse == 0 then
                    print("No talent specs available for "..shadowName)
                else
                    ShowRespecSelectionPopup(shadowName, respecResponse)
                end
                responseFrame:UnregisterEvent("CHAT_MSG_WHISPER")
                self:SetScript("OnUpdate", nil)
            end
        end)
    end

    function ShowRespecSelectionPopup(shadowName, specList)
        if _G["ShadowTalentResponseFrame"] then
            _G["ShadowTalentResponseFrame"]:Hide()
        end

        local popup = CreateDialog("ShadowRespecFrame", 400, 100 + (#specList * 30),
            "Select Talent Spec for "..shadowName, {
                strata = "TOOLTIP",
                bgFile = "Interface\\Buttons\\WHITE8X8",
                bgColor = {0, 0, 0, 1},
            })

        for i, specLine in ipairs(specList) do
            local specName = specLine:match("%d+%.%s*(.-)%s*%(")
            if not specName then
                specName = specLine:match("%d+%.%s*(.*)")
            end

            local button = CreateTextButton(popup, 360, 25, specLine, function()
                if specName then
                    SendThrottledChatMessage("talents spec "..specName, "WHISPER", nil, shadowName)
                end
                popup:Hide()
            end)
            button:SetPoint("TOP", 0, -50 - ((i - 1) * 30))
        end

        popup:Show()
    end

    function HasShadowClass(class)
        for _, cachedClass in pairs(cachedNames) do
            if cachedClass and string.upper(cachedClass) == string.upper(class) then
                return true
            end
        end
        return false
    end

    function PromptShadowSelection(class, callback)
        local matches = {}
        for name, cachedClass in pairs(cachedNames) do
            if cachedClass and string.upper(cachedClass) == string.upper(class) then
                table.insert(matches, name)
            end
        end

        if #matches == 0 then
            return
        elseif #matches == 1 then
            callback(matches[1])
            return
        end

        if _G["ShadowSelectionFrame"] then
            _G["ShadowSelectionFrame"]:Hide()
        end

        local selectionFrame = CreateDialog("ShadowSelectionFrame", 300, 100 + (#matches * 30),
            "Which shadow do you add this strategy to?", {
                font = "GameFontNormal",
                titleY = -20,
                strata = "FULLSCREEN_DIALOG",
                bgFile = "Interface\\Buttons\\WHITE8X8",
                bgColor = {0, 0, 0, 1},
                movable = false,
            })

        for i, name in ipairs(matches) do
            local button = CreateTextButton(selectionFrame, 260, 25, name, function()
                callback(name)
                selectionFrame:Hide()
            end)
            button:SetPoint("TOP", 0, -50 - ((i - 1) * 30))
        end

        selectionFrame:Show()
    end

    local function BuildStrategyCommand(strategy, others)
        local command = "+"..strategy
        for _, other in ipairs(others) do
            command = command..",-"..other
        end
        return command
    end

    local function SendStrategyToShadow(requiredClass, classLabel, strategy, others, prefixes, enabledLabel)
        if not HasShadowClass(requiredClass) then
            print("No "..classLabel.." shadow found.")
            return
        end

        PromptShadowSelection(requiredClass, function(targetName)
            local command = BuildStrategyCommand(strategy, others)
            for _, prefix in ipairs(prefixes) do
                SendThrottledChatMessage(prefix..command, "WHISPER", nil, targetName)
            end
            print("Shadow "..targetName.." has enabled "..enabledLabel)
        end)
    end

    local function HasMasterDemonologist(name)
        local unitId = GetUnitIdByName(name)
        if not unitId then return false end

        local masterDemoIds = {23785, 23822, 23823, 23824, 23825}
        for i = 1, 40 do
            local buffName, _, _, _, _, _, _, _, _, _, spellId = UnitAura(unitId, i, "HELPFUL")
            if not buffName then break end
            for _, buffId in ipairs(masterDemoIds) do
                if spellId == buffId then
                    return true
                end
            end
        end
        return false
    end

    local activeClassFrame = nil

    local function CenterColumn(buttons, xOffset, columnWidth, yStart, step)
        local startX = xOffset + ((columnWidth - buttons[1]:GetWidth()) / 2)
        for i, button in ipairs(buttons) do
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", startX, -(yStart + ((i - 1) * step)))
        end
    end

    local function ShowClassSettings(globalVar, frameName, width, height, title, build)
        if activeClassFrame then
            activeClassFrame:Hide()
        end

        local existing = _G[frameName]
        if existing then
            existing:Show()
            activeClassFrame = existing
            _G[globalVar] = existing
            return
        end

        local classFrame = CreateDialog(frameName, width, height, title, {
            strata = "FULLSCREEN",
            bgFile = "Interface\\Buttons\\WHITE8X8",
            bgColor = {0, 0, 0, 1},
            onClose = function()
                activeClassFrame = nil
            end,
        })

        build(classFrame)
        activeClassFrame = classFrame
        _G[globalVar] = classFrame
        classFrame:Show()
    end

    local function CreateStrategyButton(parent, width, height, icon, text)
        return CreateVerticalIconButton(parent, width, height, "Interface\\Icons\\"..icon, text)
    end

    function ShowPaladinSettings()
        ShowClassSettings("paladinFrame", "ShadowPaladinSettingsFrame", 600, 550, "Paladin Settings", function(classFrame)
            local blessingsLabel = classFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            blessingsLabel:SetPoint("TOP", -140, -40)
            blessingsLabel:SetText("Blessing Strategies:")

            local blessings = {
                {name = "Might", strategy = "bdps", others = {"bmana", "bstats", "bhealth"}, icon = "Spell_Holy_FistOfJustice"},
                {name = "Wisdom", strategy = "bmana", others = {"bdps", "bstats", "bhealth"}, icon = "Spell_Holy_SealOfWisdom"},
                {name = "Kings", strategy = "bstats", others = {"bdps", "bmana", "bhealth"}, icon = "Spell_Magic_MageArmor"},
                {name = "Sanctuary", strategy = "bhealth", others = {"bdps", "bmana", "bstats"}, icon = "Spell_Nature_LightningShield"},
            }

            local blessingButtons = {}
            for i, blessing in ipairs(blessings) do
                local button = CreateStrategyButton(classFrame, 120, 60, blessing.icon, blessing.name)
                button:SetPoint("TOPLEFT", 30, -60 - ((i - 1) * 70))
                button:SetScript("OnClick", function()
                    SendStrategyToShadow("PALADIN", "paladin", blessing.strategy, blessing.others, {"co "}, blessing.name)
                end)
                tinsert(blessingButtons, button)
            end
            CenterColumn(blessingButtons, 10, 280, 60, 70)

            local aurasLabel = classFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            aurasLabel:SetPoint("TOP", 140, -40)
            aurasLabel:SetText("Aura Strategies:")

            local auras = {
                {name = "Fire Resistance", strategy = "rfire", others = {"rfrost", "rshadow", "baoe", "barmor", "bcast", "bspeed"}, icon = "Spell_Fire_SealOfFire"},
                {name = "Frost Resistance", strategy = "rfrost", others = {"rfire", "rshadow", "baoe", "barmor", "bcast", "bspeed"}, icon = "Spell_Frost_WizardMark"},
                {name = "Shadow Resistance", strategy = "rshadow", others = {"rfire", "rfrost", "baoe", "barmor", "bcast", "bspeed"}, icon = "Spell_Shadow_SealOfKings"},
                {name = "Retribution", strategy = "baoe", others = {"rfire", "rfrost", "rshadow", "barmor", "bcast", "bspeed"}, icon = "Spell_Holy_AuraOfLight"},
                {name = "Devotion", strategy = "barmor", others = {"rfire", "rfrost", "rshadow", "baoe", "bcast", "bspeed"}, icon = "Spell_Holy_DevotionAura"},
                {name = "Concentration", strategy = "bcast", others = {"rfire", "rfrost", "rshadow", "baoe", "barmor", "bspeed"}, icon = "Spell_Holy_MindSooth"},
                {name = "Crusader", strategy = "bspeed", others = {"rfire", "rfrost", "rshadow", "baoe", "barmor", "bcast"}, icon = "Spell_Holy_CrusaderAura"},
            }

            local auraButtons = {}
            for i, aura in ipairs(auras) do
                local button = CreateStrategyButton(classFrame, 140, 60, aura.icon, aura.name)
                button:SetPoint("TOPLEFT", 310, -60 - ((i - 1) * 70))
                button:SetScript("OnClick", function()
                    SendStrategyToShadow("PALADIN", "paladin", aura.strategy, aura.others, {"co ", "nc "}, aura.name)
                end)
                tinsert(auraButtons, button)
            end
            CenterColumn(auraButtons, 300, 280, 60, 70)
        end)
    end

    function ShowHunterSettings()
        ShowClassSettings("hunterFrame", "ShadowHunterSettingsFrame", 400, 350, "Hunter Aspect Settings", function(classFrame)
            local aspectsLabel = classFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            aspectsLabel:SetPoint("TOP", 0, -40)
            aspectsLabel:SetText("Aspect Strategies:")

            local aspects = {
                {name = "Hawk/Dragonhawk", strategy = "bdps", others = {"bspeed", "bmana", "rnature"}, icon = "ability_hunter_pet_dragonhawk"},
                {name = "Pack", strategy = "bspeed", others = {"bdps", "bmana", "rnature"}, icon = "Ability_Mount_WhiteTiger"},
                {name = "Viper", strategy = "bmana", others = {"bdps", "bspeed", "rnature"}, icon = "Ability_Hunter_AspectOfTheViper"},
                {name = "Wild", strategy = "rnature", others = {"bdps", "bspeed", "bmana"}, icon = "Spell_Nature_ProtectionformNature"},
            }

            local aspectButtons = {}
            for i, aspect in ipairs(aspects) do
                local button = CreateStrategyButton(classFrame, 180, 60, aspect.icon, aspect.name)
                button:SetPoint("TOPLEFT", 30, -70 - ((i - 1) * 70))
                button:SetScript("OnClick", function()
                    SendStrategyToShadow("HUNTER", "hunter", aspect.strategy, aspect.others, {"co "}, aspect.name)
                end)
                tinsert(aspectButtons, button)
            end
            CenterColumn(aspectButtons, 0, 400, 70, 70)
        end)
    end

    function ShowWarlockSettings()
        ShowClassSettings("warlockFrame", "ShadowWarlockSettingsFrame", 450, 450, "Warlock Pet Settings", function(classFrame)
            local petsLabel = classFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            petsLabel:SetPoint("TOP", 0, -40)
            petsLabel:SetText("Pet Strategies:")

            local noteLabel = classFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            noteLabel:SetPoint("TOP", 0, -55)
            noteLabel:SetText("(Defaults: Affliction=Felhunter, Demonology=Felguard, Destruction=Imp)")
            noteLabel:SetTextColor(0.7, 0.7, 0.7)

            local pets = {
                {name = "Imp", strategy = "imp", icon = "Spell_Shadow_Summonimp", others = {"voidwalker", "succubus", "felhunter", "felguard"}},
                {name = "Voidwalker", strategy = "voidwalker", icon = "Spell_Shadow_SummonVoidWalker", others = {"imp", "succubus", "felhunter", "felguard"}},
                {name = "Succubus", strategy = "succubus", icon = "Spell_Shadow_SummonSuccubus", others = {"imp", "voidwalker", "felhunter", "felguard"}},
                {name = "Felhunter", strategy = "felhunter", icon = "Spell_Shadow_SummonFelHunter", others = {"imp", "voidwalker", "succubus", "felguard"}},
                {name = "Felguard", strategy = "felguard", icon = "Spell_Shadow_SummonFelGuard", others = {"imp", "voidwalker", "succubus", "felhunter"}},
            }

            local petButtons = {}
            for i, pet in ipairs(pets) do
                local button = CreateStrategyButton(classFrame, 150, 60, pet.icon, pet.name)
                button:SetPoint("TOPLEFT", 30, -75 - ((i - 1) * 70))
                button:SetScript("OnClick", function()
                    if not HasShadowClass("WARLOCK") then
                        print("No warlock shadow found.")
                        return
                    end

                    PromptShadowSelection("WARLOCK", function(targetName)
                        local hasMasterDemo = HasMasterDemonologist(targetName)
                        if pet.strategy == "felguard" and not hasMasterDemo then
                            print("This shadow cannot summon Felguard.")
                            return
                        end

                        local others = {}
                        for _, other in ipairs(pet.others) do
                            if other ~= "felguard" or hasMasterDemo then
                                table.insert(others, other)
                            end
                        end

                        SendThrottledChatMessage("nc "..BuildStrategyCommand(pet.strategy, others), "WHISPER", nil, targetName)
                        print("Shadow "..targetName.." has enabled "..pet.name)
                    end)
                end)
                tinsert(petButtons, button)
            end
            CenterColumn(petButtons, 0, 450, 75, 70)
        end)
    end

    local priestShadowProtEnabled = false

    function ShowPriestSettings()
        ShowClassSettings("priestFrame", "ShadowPriestSettingsFrame", 400, 200, "Priest Buff Settings", function(classFrame)
            local buffsLabel = classFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            buffsLabel:SetPoint("TOP", 0, -40)
            buffsLabel:SetText("Buff Strategies:")

            local button = CreateStrategyButton(classFrame, 150, 60, "Spell_Shadow_AntiShadow", "Shadow Protection")
            button:SetPoint("TOP", 0, -80)

            button.status = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            button.status:SetPoint("TOP", button.text, "BOTTOM", 0, -5)
            button.status:SetTextColor(1, 0, 0)
            button.status:SetText("OFF")

            button:SetScript("OnClick", function()
                if not HasShadowClass("PRIEST") then
                    print("No priest shadow found.")
                    return
                end

                PromptShadowSelection("PRIEST", function(targetName)
                    if priestShadowProtEnabled then
                        SendThrottledChatMessage("co -rshadow", "WHISPER", nil, targetName)
                        priestShadowProtEnabled = false
                        button.status:SetTextColor(1, 0, 0)
                        button.status:SetText("OFF")
                        print("Shadow "..targetName.." has disabled Shadow Protection")
                    else
                        SendThrottledChatMessage("co +rshadow", "WHISPER", nil, targetName)
                        priestShadowProtEnabled = true
                        button.status:SetTextColor(0, 1, 0)
                        button.status:SetText("ON")
                        print("Shadow "..targetName.." has enabled Shadow Protection")
                    end
                end)
            end)
        end)
    end

    function ShowShamanSettings()
        ShowClassSettings("shamanFrame", "ShadowShamanSettingsFrame", 800, 430, "Shaman Totem Settings", function(classFrame)
            local totems = {
                water = {
                    {name = "Healing Stream", strategy = "healing stream", others = {"mana spring", "cleansing", "fire resistance"}, icon = "INV_Spear_04"},
                    {name = "Mana Spring", strategy = "mana spring", others = {"healing stream", "cleansing", "fire resistance"}, icon = "Spell_Nature_ManaRegenTotem"},
                    {name = "Cleansing", strategy = "cleansing", others = {"healing stream", "mana spring", "fire resistance"}, icon = "Spell_Frost_SummonWaterElemental"},
                    {name = "Fire Resistance", strategy = "fire resistance", others = {"healing stream", "mana spring", "cleansing"}, icon = "Spell_FireResistanceTotem_01"},
                },
                earth = {
                    {name = "Stoneskin", strategy = "stoneskin", others = {"strength of the earth", "tremor"}, icon = "Spell_Nature_StoneSkinTotem"},
                    {name = "Strength of Earth", strategy = "strength of the earth", others = {"stoneskin", "tremor"}, icon = "Spell_Nature_EarthBindTotem"},
                    {name = "Tremor", strategy = "tremor", others = {"stoneskin", "strength of the earth"}, icon = "Spell_Nature_TremorTotem"},
                },
                fire = {
                    {name = "Searing", strategy = "searing", others = {"magma", "flametongue", "frost resistance", "wrath"}, icon = "Spell_Fire_SearingTotem"},
                    {name = "Magma", strategy = "magma", others = {"searing", "flametongue", "frost resistance", "wrath"}, icon = "Spell_Fire_SelfDestruct"},
                    {name = "Flametongue", strategy = "flametongue", others = {"searing", "magma", "frost resistance", "wrath"}, icon = "Spell_Nature_GuardianWard"},
                    {name = "Frost Resistance", strategy = "frost resistance", others = {"searing", "magma", "flametongue", "wrath"}, icon = "Spell_FrostResistanceTotem_01"},
                    {name = "Totem of Wrath", strategy = "totem of wrath", others = {"frost resistance", "searing", "magma", "flametongue"}, icon = "Spell_Fire_TotemOfWrath"},
                },
                air = {
                    {name = "Windfury", strategy = "windfury", others = {"wrath of air", "nature resistance"}, icon = "Spell_Nature_Windfury"},
                    {name = "Wrath of Air", strategy = "wrath of air", others = {"windfury", "nature resistance"}, icon = "Spell_Nature_SlowingTotem"},
                    {name = "Nature Resistance", strategy = "nature resistance", others = {"windfury", "wrath of air"}, icon = "Spell_Nature_NatureResistanceTotem"},
                },
            }

            local categories = {
                {name = "Water", type = "water", xOffset = 20},
                {name = "Earth", type = "earth", xOffset = 220},
                {name = "Fire", type = "fire", xOffset = 420},
                {name = "Air", type = "air", xOffset = 620},
            }

            for _, category in ipairs(categories) do
                local label = classFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                label:SetPoint("TOP", classFrame, "TOPLEFT", category.xOffset + 75, -40)
                label:SetText(category.name..":")

                for i, totem in ipairs(totems[category.type]) do
                    local button = CreateStrategyButton(classFrame, 140, 60, totem.icon, totem.name)
                    button:SetPoint("TOPLEFT", category.xOffset, -70 - ((i - 1) * 70))
                    button:SetScript("OnClick", function()
                        SendStrategyToShadow("SHAMAN", "shaman", totem.strategy, totem.others, {"co "}, "Totem: "..totem.name)
                    end)
                end
            end
        end)
    end

    function ShowGroupSetupWindow()
        if setupFrame then
            if setupFrame:IsShown() then
                setupFrame:Hide()
            else
                setupFrame:Show()
            end
            return
        end

        local frameWidth = 500
        setupFrame = CreateDialog("ShadowGroupSetupFrame", frameWidth, 100, "Group Setup", {
            bgFile = "Interface\\Buttons\\WHITE8X8",
            bgColor = {0, 0, 0, 1},
        })

        local function CreateSetupButton(text, icon, onClick)
            local button = CreateHorizontalIconButton(setupFrame, 140, 40,
                "Interface\\Icons\\"..icon, text, {iconX = 5, textGap = 5, justifyLeft = true})
            button:SetScript("OnClick", function()
                AIO.Handle("ShadowsCache", "RequestCache")
                onClick()
            end)
            return button
        end

        local function CenterRow(buttons, yOffset)
            local spacing = 10
            local totalWidth = 0
            for i, button in ipairs(buttons) do
                totalWidth = totalWidth + button:GetWidth()
                if i < #buttons then
                    totalWidth = totalWidth + spacing
                end
            end

            local startX = (frameWidth - totalWidth) / 2
            for _, button in ipairs(buttons) do
                button:ClearAllPoints()
                button:SetPoint("TOPLEFT", setupFrame, "TOPLEFT", startX, yOffset)
                startX = startX + button:GetWidth() + spacing
            end
        end

        local function AddSeparator(yOffset)
            local line = setupFrame:CreateTexture(nil, "ARTWORK")
            line:SetTexture(1, 1, 1)
            line:SetVertexColor(0.5, 0.5, 0.5, 1)
            line:SetHeight(1)
            line:SetPoint("TOPLEFT", setupFrame, "TOPLEFT", 20, yOffset)
            line:SetPoint("TOPRIGHT", setupFrame, "TOPRIGHT", -20, yOffset)
        end

        local function AddSectionLabel(text, yOffset)
            local label = setupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetPoint("TOP", setupFrame, "TOP", 0, yOffset)
            label:SetText(text)
        end

        local currentY = -50

        AddSeparator(currentY)
        currentY = currentY - 10
        AddSectionLabel("General Setup:", currentY)
        currentY = currentY - 30

        local row1 = {
            CreateSetupButton("Shadows Menu", "Spell_Shadow_AntiShadow", function()
                SendThrottledChatMessage(".shadowsmenu", "GUILD")
            end),
            CreateSetupButton("System Settings", "INV_Misc_Gear_01", function()
                InterfaceOptionsFrame_Show()
                ShowShadowsSettingsPanel()
                setupFrame:Hide()
            end),
            CreateSetupButton("Shortcuts", "INV_Misc_Book_09", function()
                ShowShadowsShortcutsMenu()
                setupFrame:Hide()
            end),
        }
        CenterRow(row1, currentY)

        currentY = currentY - 50
        currentY = currentY - 40

        AddSeparator(currentY)
        currentY = currentY - 10
        AddSectionLabel("Group Loadout:", currentY)
        currentY = currentY - 30

        local row2 = {
            CreateSetupButton("Talents", "Ability_Marksmanship", function()
                ShowTalentManagementPrompt()
            end),
            CreateSetupButton("Role", "Ability_Hunter_MasterMarksman", function()
                ShowRoleManagementWindow()
            end),
        }
        CenterRow(row2, currentY)

        currentY = currentY - 50
        currentY = currentY - 40

        AddSeparator(currentY)
        currentY = currentY - 10
        AddSectionLabel("Class Settings:", currentY)
        currentY = currentY - 30

        local row3 = {
            CreateSetupButton("Paladin", "INV_Helmet_06", function()
                ShowPaladinSettings()
            end),
            CreateSetupButton("Shaman", "Spell_Nature_BloodLust", function()
                ShowShamanSettings()
            end),
            CreateSetupButton("Hunter", "INV_Weapon_Bow_07", function()
                ShowHunterSettings()
            end),
        }
        CenterRow(row3, currentY)

        currentY = currentY - 50

        local row4 = {
            CreateSetupButton("Warlock", "Spell_Nature_FaerieFire", function()
                ShowWarlockSettings()
            end),
            CreateSetupButton("Priest", "INV_Staff_30", function()
                ShowPriestSettings()
            end),
        }
        CenterRow(row4, currentY)

        currentY = currentY - 50

        setupFrame:SetSize(frameWidth, math.abs(currentY) + 20)
        setupFrame:Show()
    end

    SLASH_BOTCONTROLBAR1 = "/shadowsbar"
    SlashCmdList["BOTCONTROLBAR"] = function()
        if frame:IsShown() then
            frame:Hide()
        else
            frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            frame:Show()
        end
    end

    frame:SetSize(BOT_BAR_SETTINGS.width, originalHeight * BOT_BAR_SETTINGS.scale)
    AdjustButtons(frame)

    frame:ClearAllPoints()
    local screenWidth = UIParent:GetWidth()
    local screenHeight = UIParent:GetHeight()
    local frameWidth = frame:GetWidth()
    local frameHeight = frame:GetHeight()

    local clampedPosX = math.max(0, math.min(BOT_BAR_SETTINGS.posX, screenWidth - frameWidth))
    local clampedPosY = math.max(frameHeight, math.min(BOT_BAR_SETTINGS.posY, screenHeight))

    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", clampedPosX, clampedPosY)

    if clampedPosX ~= BOT_BAR_SETTINGS.posX or clampedPosY ~= BOT_BAR_SETTINGS.posY then
        BOT_BAR_SETTINGS.posX = clampedPosX
        BOT_BAR_SETTINGS.posY = clampedPosY
    end

    local resetDetectionFrame = CreateFrame("Frame")
    resetDetectionFrame:RegisterEvent("CHAT_MSG_WHISPER")

    local function ReapplyShadowSettings()
        local wasInUtilityMode = frame.currentMode == "utility"

        if wasInUtilityMode then
            frame.modeButton:Click()
        end

        local delayFrame = CreateFrame("Frame")
        delayFrame.timeElapsed = 0
        delayFrame:SetScript("OnUpdate", function(self, elapsed)
            self.timeElapsed = self.timeElapsed + elapsed
            if self.timeElapsed >= 0.5 then
                for i, info in ipairs(frame.buttons) do
                    local button = _G["BotControlBarButton"..i]
                    if button and button.state then
                        if info.toggle then
                            button:Click()
                            button:Click()
                        else
                            button:Click()
                        end
                    end
                end

                if wasInUtilityMode then
                    frame.modeButton:Click()
                end

                self:SetScript("OnUpdate", nil)
            end
        end)
    end

    resetDetectionFrame:SetScript("OnEvent", function(self, event, msg)
        if msg and msg:lower():match("ai was reset to defaults") and not self.waitingForReset then
            self.waitingForReset = true

            if not self.throttleFrame then
                self.throttleFrame = CreateFrame("Frame")
            end

            self.throttleFrame:SetScript("OnUpdate", function(throttleFrame, elapsed)
                throttleFrame.elapsed = (throttleFrame.elapsed or 0) + elapsed

                if throttleFrame.elapsed >= 2 then
                    ReapplyShadowSettings()
                    resetDetectionFrame.waitingForReset = false
                    throttleFrame.elapsed = 0
                    throttleFrame:SetScript("OnUpdate", nil)
                end
            end)
        end
    end)

    return frame
end

CreateBotControlBar()

BotControlBar:Hide()

-----------------------------------------------------------
-- Shadows bar keyboard shortcuts
-----------------------------------------------------------
ShadowShortcuts = {}

function ShowShadowsShortcutsMenu()
    if not ShadowShortcuts.configFrame then
        ShadowShortcuts.configFrame = ShadowShortcuts.CreateConfigWindow()
    end
    ShadowShortcuts.configFrame:Show()
end

function ShadowShortcuts.UpdateKeyTexts()
    for _, buttonInfo in ipairs(ShadowShortcuts.buttons) do
        local configButton = ShadowShortcuts.configButtons[buttonInfo.action]
        if configButton then
            local clickBinding = "CLICK "..buttonInfo.buttonName..":LeftButton"
            configButton.keyText:SetText(GetBindingKey(clickBinding) or "Not bound")
        end
    end
end

function ShadowShortcuts.CreateConfigWindow()
    local frame = CreateFrame("Frame", "ShadowShortcutsConfig", UIParent)
    frame:SetWidth(400)
    frame:SetHeight(500)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:Hide()

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -15)
    title:SetText("Shadows Bar Keyboard Shortcuts")

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function() frame:Hide() end)

    ShadowShortcuts.buttons = {
        {text = "Show/Hide Control Bar", buttonName = "BotControlBarToggleButton", action = "BOTCONTROLBAR_TOGGLE"},
        {text = "Mode Button", buttonName = "BotControlBarModeButton", action = "BOTCONTROLBAR_MODE"},
        {text = "Button 1", buttonName = "BotControlBarButton1", action = "BOTCONTROLBAR_BUTTON1"},
        {text = "Button 2", buttonName = "BotControlBarButton2", action = "BOTCONTROLBAR_BUTTON2"},
        {text = "Button 3", buttonName = "BotControlBarButton3", action = "BOTCONTROLBAR_BUTTON3"},
        {text = "Button 4", buttonName = "BotControlBarButton4", action = "BOTCONTROLBAR_BUTTON4"},
        {text = "Button 5", buttonName = "BotControlBarButton5", action = "BOTCONTROLBAR_BUTTON5"},
        {text = "Button 6", buttonName = "BotControlBarButton6", action = "BOTCONTROLBAR_BUTTON6"},
        {text = "Button 7", buttonName = "BotControlBarButton7", action = "BOTCONTROLBAR_BUTTON7"},
        {text = "Button 8", buttonName = "BotControlBarButton8", action = "BOTCONTROLBAR_BUTTON8"},
        {text = "Button 9", buttonName = "BotControlBarButton9", action = "BOTCONTROLBAR_BUTTON9"},
        {text = "Button 10", buttonName = "BotControlBarButton10", action = "BOTCONTROLBAR_BUTTON10"},
    }

    ShadowShortcuts.configButtons = {}

    local lastButton
    for _, buttonInfo in ipairs(ShadowShortcuts.buttons) do
        local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        button:SetWidth(200)
        button:SetHeight(25)
        button:SetText(buttonInfo.text)

        if lastButton then
            button:SetPoint("TOP", lastButton, "BOTTOM", 0, -10)
        else
            button:SetPoint("TOP", 0, -40)
        end
        lastButton = button

        local keyText = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        keyText:SetPoint("LEFT", button, "RIGHT", 10, 0)
        keyText:SetText("Not bound")

        button:SetScript("OnClick", function()
            local dialog = StaticPopup_Show("SHADOWSHORTCUTS_KEYBIND")
            if dialog then
                dialog.data = buttonInfo
                dialog.keyText = keyText
            end
        end)

        ShadowShortcuts.configButtons[buttonInfo.action] = button
        button.keyText = keyText
    end

    ShadowShortcuts.UpdateKeyTexts()
    AddSpecialFrame("ShadowShortcutsConfig")

    return frame
end

SLASH_SHADOWSHORTCUTS1 = "/shadowshortcuts"
SlashCmdList["SHADOWSHORTCUTS"] = function()
    ShowShadowsShortcutsMenu()
end

SLASH_SHADOW1 = "/shadow"
SLASH_SHADOW2 = "/shadowsmenu"
SlashCmdList["SHADOW"] = function()
    SendChatMessage(".shadowsmenu", "GUILD")
end

SLASH_SHADOWS1 = "/shadows"
SlashCmdList["SHADOWS"] = function()
    SendChatMessage(".shadowsmenu", "GUILD")
end

StaticPopupDialogs["SHADOWSHORTCUTS_KEYBIND"] = {
    text = "Press a key to bind to this button",
    button1 = "Cancel",
    button2 = "Remove keybind",
    button3 = "Set keybind",
    OnShow = function(self)
        self.keyPressed = nil
        self.currentButton = nil
        self:SetFrameStrata("DIALOG")
        self.button3:Disable()
        self.text:SetText("Press a key to bind to this button\n\nKey selected: |cFF00FF00None|r\n\nThis will unbind: |cFFFF0000Nothing|r")
        self:SetScript("OnKeyDown", function(frame, key)
            if key == "ESCAPE" then
                StaticPopup_Hide("SHADOWSHORTCUTS_KEYBIND")
                return
            end

            if key == "LSHIFT" or key == "RSHIFT" or key == "LCTRL" or key == "RCTRL" or key == "LALT" or key == "RALT" then
                return
            end

            local keyPressed = key
            if IsShiftKeyDown() then keyPressed = "SHIFT-"..keyPressed end
            if IsControlKeyDown() then keyPressed = "CTRL-"..keyPressed end
            if IsAltKeyDown() then keyPressed = "ALT-"..keyPressed end

            self.keyPressed = keyPressed
            local currentCommand = GetBindingAction(keyPressed)
            self.currentButton = currentCommand ~= "" and currentCommand or nil

            local keyText = "Key selected: |cFF00FF00"..keyPressed.."|r"
            local unbindText = "This will unbind: |cFFFF0000"..(self.currentButton or "Nothing").."|r"
            self.text:SetText("Press a key to bind to this button\n\n"..keyText.."\n\n"..unbindText)
            self.button2:Enable()
            self.button3:Enable()
        end)
    end,
    OnHide = function(self)
        self:SetScript("OnKeyDown", nil)
    end,
    OnAlt = function(self)
        if not self.data or not self.keyPressed then return end

        local clickBinding = "CLICK "..self.data.buttonName..":LeftButton"
        local existingKey = GetBindingKey(clickBinding)
        if existingKey then
            SetBinding(existingKey, nil)
        end

        SetBinding(self.keyPressed, nil)
        SetBindingClick(self.keyPressed, self.data.buttonName)
        SaveBindings(GetCurrentBindingSet())
        ShadowShortcuts.UpdateKeyTexts()
        print(string.format("Bound |cFF00FF00%s|r to |cFFFFFF00%s|r", self.keyPressed, self.data.buttonName))
    end,
    OnCancel = function(self)
        if not self.data then return end

        local clickBinding = "CLICK "..self.data.buttonName..":LeftButton"
        local removedKeys = 0
        while true do
            local key = GetBindingKey(clickBinding)
            if not key then break end
            SetBinding(key, nil)
            removedKeys = removedKeys + 1
        end

        SaveBindings(GetCurrentBindingSet())
        ShadowShortcuts.UpdateKeyTexts()
        print(string.format("Removed all bindings for |cFFFFFF00%s|r", self.data.buttonName))
        StaticPopup_Hide("SHADOWSHORTCUTS_KEYBIND")
    end,
    OnAccept = function(self)
        if not self.data then return end
        StaticPopup_Hide("SHADOWSHORTCUTS_KEYBIND")
    end,
    timeout = 0,
    exclusive = 1,
    whileDead = 1,
    hideOnEscape = 1,
    multipleButtons = true,
}

for _, keyId in ipairs({
    "TOGGLE", "MODE", "BUTTON1", "BUTTON2", "BUTTON3", "BUTTON4",
    "BUTTON5", "BUTTON6", "BUTTON7", "BUTTON8", "BUTTON9", "BUTTON10",
}) do
    _G["BINDING_NAME_BOTCONTROLBAR_"..keyId] = "Bot Control Bar: "..keyId
end

local function CreateBindingButton(name)
    local button = CreateFrame("Button", "BotControlBarBinding_"..name, UIParent, "SecureActionButtonTemplate")
    button:SetAttribute("type", "macro")
    button:SetAttribute("macrotext", "/run ShadowShortcuts.HandleKeyPress('BOTCONTROLBAR_"..name.."')")
    button:Hide()
    return button
end

CreateBindingButton("TOGGLE")
CreateBindingButton("MODE")
for i = 1, 10 do
    CreateBindingButton("BUTTON"..i)
end

ShadowShortcuts.HandleKeyPress = function(action)
    for _, buttonInfo in ipairs(ShadowShortcuts.buttons) do
        if buttonInfo.action == action then
            local button = _G[buttonInfo.buttonName]
            if button and button:IsVisible() then
                button:Click()
                break
            end
        end
    end
end

-----------------------------------------------------------
-- Server communication
-----------------------------------------------------------
cachedNames = {}

AIO.Handle("ShadowsCache", "RequestCache")

local chatFrame = CreateFrame("Frame")
chatFrame:RegisterEvent("CHAT_MSG_SYSTEM")
chatFrame:SetScript("OnEvent", function(self, event, msg)
    local addedName = msg:match("add: (.+) %- Login successful%.")
    if addedName and addedName ~= UnitName("player") and not cachedNames[addedName] then
        local class = GetClassByName(addedName)
        if class then
            cachedNames[addedName] = class
        end
    end

    local removedName = msg:match("remove: (.+) %- Logout successful%.")
    if removedName and cachedNames[removedName] then
        cachedNames[removedName] = nil
    end
end)

local ShadowsCacheHandlers = AIO.AddHandlers("ShadowsCache", {})

function ShadowsCacheHandlers.LoadCache(player, data)
    cachedNames = {}
    for name, class in pairs(data) do
        cachedNames[name] = class
    end
end

function GetClassByName(name)
    local unitId = GetUnitIdByName(name)
    if unitId then
        local _, class = UnitClass(unitId)
        return class
    end
    return nil
end

local function onShadowsBarAddonMessage(self, event, prefix, message, channel, sender)
    if prefix == "ShadowsBar" then
        if message and message:find("ENABLED") then
            ShadowsBarStatus = "ENABLED"
            BotControlBar:Show()
        elseif message and message:find("DISABLED") then
            ShadowsBarStatus = "DISABLED"
            BotControlBar:Hide()
        elseif message and message:find("OPEN") then
            ShadowsBarToggleStatus = "OPEN"
        elseif message and message:find("CLOSED") then
            ShadowsBarToggleStatus = "CLOSED"
        elseif message and message:find("SETTINGS") then
            InterfaceOptionsFrame_Show()
            ShowShadowsSettingsPanel()
        end
    elseif prefix == "ShadowsLoginShowBar" then
        if BotControlBar and (ShadowsBarToggleStatus == "ENABLED" or ShadowsBarToggleStatus == "OPEN") then
            BotControlBar:Show()
        end
    end
end

SendChatMessage(".shadowsbarstatus", "GUILD")

local ShadowsBarAddonMsg = CreateFrame("Frame")
ShadowsBarAddonMsg:RegisterEvent("CHAT_MSG_ADDON")
ShadowsBarAddonMsg:SetScript("OnEvent", onShadowsBarAddonMessage)

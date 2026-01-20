local AIO = AIO or require("AIO")
if AIO.AddAddon() then
    return
end

-----------------------------------------------------------
-- Inteface options
-----------------------------------------------------------
local addedButtonForShadows = false
local SHADOWS_BUTTON_NUMBER = nil
local shadowButtonName
local shadowButton

local function ShowShadowsSettingsPanel()
    -- Deactivate all other buttons
    for i = 1, 30 do
        local button = _G["InterfaceOptionsFrameCategoriesButton" .. i]
        if button and button:GetText() ~= "Shadows" then
            button:UnlockHighlight()
        end
    end

    -- Hide all other panel children
    for _, child in ipairs({InterfaceOptionsFramePanelContainer:GetChildren()}) do
        child:Hide()
    end    

     shadowButton:LockHighlight()  -- Lock highlight for this button
	 if not _G["ShadowsSettingsFrame"] then
		local frame = CreateFrame("Frame", "ShadowsSettingsFrame", InterfaceOptionsFramePanelContainer)
		frame:SetAllPoints(InterfaceOptionsFramePanelContainer)

		-- Add header text
		local headerText = frame:CreateFontString("headerText", "ARTWORK", "GameFontNormalLarge")
		headerText:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -16)
		headerText:SetText("Shadows and Shadow Bar Settings")
		
		local checkBox = CreateFrame("CheckButton", "ShadowsBarCheckbox", frame, "InterfaceOptionsCheckButtonTemplate")
		checkBox:SetPoint("TOPLEFT", 16, -40)
		checkBox:SetText("Enable Shadows Bar")
		if ShadowsBarStatus == "ENABLED" or ShadowsBarToggleStatus == "OPEN" then
			checkBox:SetChecked(true)
		end
		if ShadowsBarStatus == "DISABLED" or ShadowsBarToggleStatus == "CLOSED" then
			checkBox:SetChecked(false)
		end
		checkBox:SetScript("OnClick", function(self)
			if not self:GetChecked() then
				SendChatMessage(".shadowsbaroff", "GUILD")
			else
				SendChatMessage(".shadowsbaron", "GUILD")
			end
		end)

		local text = checkBox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		text:SetPoint("LEFT", checkBox, "RIGHT", 4, 0)
		text:SetText("Automatically Open Shadows Bar If Grouped With Shadows")
        text:SetTextColor(1, 1, 1)
		
		local keyBindButton = CreateFrame("Button", "ShadowsKeybindButton", frame, "UIPanelButtonTemplate")
		keyBindButton:SetPoint("TOPLEFT", checkBox, "BOTTOMLEFT", 0, -10)
		keyBindButton:SetWidth(230)
		keyBindButton:SetHeight(30)
		keyBindButton:SetText("Shadows Bar Keyboard Shortcuts")
		keyBindButton:SetScript("OnClick", function()
			SlashCmdList["SHADOWSHORTCUTS"]()
		end)

		local resetButton = CreateFrame("Button", "ShadowsResetButton", frame, "UIPanelButtonTemplate")
		resetButton:SetPoint("TOPLEFT", keyBindButton, "BOTTOMLEFT", 0, -10)
		resetButton:SetWidth(230)
		resetButton:SetHeight(30)
		resetButton:SetText("Reset Shadows Bar")
		resetButton:SetScript("OnClick", function()
			BotControlBar:Hide()
			SlashCmdList["BOTCONTROLBAR"]()
		end)

        local resetShadowsButton = CreateFrame("Button", "ResetBotAIButton", frame, "UIPanelButtonTemplate")
        resetShadowsButton:SetPoint("TOPLEFT", resetButton, "BOTTOMLEFT", 0, -10)
        resetShadowsButton:SetWidth(230)
        resetShadowsButton:SetHeight(30)
        resetShadowsButton:SetText("Reset Shadows Settings")
        resetShadowsButton:SetScript("OnClick", function()
            local names = {}
            for name, _ in pairs(cachedNames) do
                table.insert(names, name)
            end
            local namesString = table.concat(names, " ")
            SendChatMessage(".unmuteshadow " .. namesString, "GUILD")
            
            local channel = GetNumRaidMembers() > 0 and "RAID" or GetNumPartyMembers() > 0 and "PARTY" or nil
            SendChatMessage("reset botAI", channel)
        end)
        frame.name = "Shadows"
	else
		local frame = _G["ShadowsSettingsFrame"]
		frame:Show()
		
		local checkBox = _G["ShadowsBarCheckbox"]
		local keyBindButton = _G["ShadowsKeybindButton"]
		local resetButton = _G["ShadowsResetButton"]
		local resetShadowsButton = _G["ResetBotAIButton"]
		local header	= _G["headerText"]
		
		if checkBox and not checkBox:IsVisible() then checkBox:Show() end
		if keyBindButton and not keyBindButton:IsVisible()  then keyBindButton:Show() end
		if resetButton and not resetButton:IsVisible()  then resetButton:Show() end
		if resetShadowsButton and not resetShadowsButton:IsVisible() then resetShadowsButton:Show() end
		if header and not header:IsVisible()  then header:Show() end
	end
end

local function AddShadowsButtonToOptions()
    local highestButtonNumber = 0
    local lastButton = nil

    for i = 1, 30 do
        local button = _G["InterfaceOptionsFrameCategoriesButton" .. i]
        if not button or not button:IsVisible() then break end
        
        highestButtonNumber = i
        lastButton = button
    end

    -- Create new button with the next sequential number
    SHADOWS_BUTTON_NUMBER = highestButtonNumber + 1  -- Store globally
    local newButtonName = "InterfaceOptionsFrameCategoriesButton" .. SHADOWS_BUTTON_NUMBER
    shadowButton = CreateFrame("Button", newButtonName, InterfaceOptionsFrameCategories, "OptionsListButtonTemplate")
    
    shadowButton:SetText("Shadows")
    shadowButton:SetWidth(lastButton:GetWidth())
    shadowButton:SetHeight(lastButton:GetHeight())
    shadowButton:SetPoint("TOP", lastButton, "BOTTOM", 7, 0) 
    shadowButton:SetScript("OnClick", function()
        ShowShadowsSettingsPanel()
    end)
    
    _G[shadowButton:GetName().."Text"]:SetJustifyH("LEFT")
end

InterfaceOptionsFrameCategories:HookScript("OnShow", function(self)
    if not addedButtonForShadows then
        AddShadowsButtonToOptions()
        addedButtonForShadows = true
    end
end)

InterfaceOptionsFrameTab2:HookScript("OnClick", function(self)
    local checkBox = _G["ShadowsBarCheckbox"]
    local keyBindButton = _G["ShadowsKeybindButton"]
    local resetButton = _G["ShadowsResetButton"]
    local resetShadowsButton = _G["ResetBotAIButton"]
    local header = _G["headerText"]
    
    -- Ensure shadowButton is accessible and unlock it
    if shadowButton then
        shadowButton:UnlockHighlight()  -- Unlock highlight
    end
    
    if checkBox and keyBindButton and resetButton and header then
        checkBox:Hide()
        keyBindButton:Hide()
        resetButton:Hide()
        resetShadowsButton:Hide()
        header:Hide()
    end
end)

for i = 1, 30 do
    local button = _G["InterfaceOptionsFrameCategoriesButton" .. i]
    if button then
        button:HookScript("OnClick", function()
            if button:GetText() ~= "Shadows" then
                local checkBox = _G["ShadowsBarCheckbox"]
                local keyBindButton = _G["ShadowsKeybindButton"]
                local resetButton = _G["ShadowsResetButton"]
                local resetShadowsButton = _G["ResetBotAIButton"]
                local header = _G["headerText"]
                
                -- Ensure shadowButton is accessible, unlock and hide it
                if shadowButton then
                    shadowButton:UnlockHighlight()
                end
               
                if checkBox and keyBindButton and resetButton and header then
                    checkBox:Hide()
                    keyBindButton:Hide()
                    resetButton:Hide()
                    resetShadowsButton:Hide()
                    header:Hide()
                end
            end
            button:LockHighlight()  -- Lock the highlight for the clicked button
        end)
    end
end

BOT_BAR_SETTINGS = BOT_BAR_SETTINGS or {
    posX = 0,
    posY = -200,
	width = 400,
    scale = 1,
	enabled = true,
}

local ShadowsBarStatus = "ENABLED"
local ShadowsBarToggleStatus = "ENABLED"

AIO.AddSavedVar("BOT_BAR_SETTINGS")

local function CreateBotControlBar()
    local itemCache = {}
    local lastUpdate = 0
    local itemListFrame
    local isFleeActive = false
    local isStayActive = false
    local resetCombatButtons = false
    local isPassiveActive = false
    local questCache = {}
    local questLastUpdate = 0
	
    local messageQueue = {}
    local messageCount = 0
    local countResetTime = 0
    local isThrottled = false
    local lastSendTime = 0

    local function SendThrottledChatMessage(message, chatType, language, target)
        local currentTime = GetTime()
        
        if currentTime - countResetTime >= 15 then
            messageCount = 0
            isThrottled = false
            countResetTime = currentTime
        end
        
        if currentTime - countResetTime <= 5 and messageCount >= 10 and not isThrottled then
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
            local numRaid = GetNumRaidMembers()
            local numParty = GetNumPartyMembers()
            
            if numRaid == 0 and numParty == 0 then
                return
            end
            
            if numRaid > 0 then
                chatType = "RAID"
            elseif numParty > 0 then
                chatType = "PARTY"
            end
        end
        
        table.insert(messageQueue, {msg = message, type = chatType, lang = language, target = target})
        
        if not isProcessingQueue then
            isProcessingQueue = true
            local queueFrame = CreateFrame("Frame")
            queueFrame:SetScript("OnUpdate", function(self, elapsed)
                if #messageQueue == 0 then
                    isProcessingQueue = false
                    self:SetScript("OnUpdate", nil)
                    return
                end
                
                local currentTime = GetTime()
                local delay = isThrottled and 2 or 0
                if currentTime - lastSendTime >= delay then
                    local nextMessage = table.remove(messageQueue, 1)
                    SendChatMessage(nextMessage.msg, nextMessage.type, nextMessage.lang, nextMessage.target)
                    lastSendTime = currentTime
                    messageCount = messageCount + 1
                end
            end)
        end
    end

    local frame = CreateFrame("Frame", "BotControlBar", UIParent, "SecureHandlerStateTemplate")
	
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", function(self)
		frame:StopMovingOrSizing()
		local scale = frame:GetEffectiveScale()
		local left = frame:GetLeft()
		local top = frame:GetTop()
		
		local screenWidth = UIParent:GetWidth()
		local screenHeight = UIParent:GetHeight()
		local frameWidth = frame:GetWidth()
		local frameHeight = frame:GetHeight()
		
		left = math.max(0, math.min(left, screenWidth - frameWidth))
		top = math.max(frameHeight, math.min(top, screenHeight))
		
		if left ~= frame:GetLeft() or top ~= frame:GetTop() then
			frame:ClearAllPoints()
			frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
		end
		
		BOT_BAR_SETTINGS.posX = left
		BOT_BAR_SETTINGS.posY = top
	end)

	local originalWidth = 400
	local originalHeight = 50
	frame.originalAspectRatio = originalWidth / originalHeight
	
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)
	
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
        frame.endWidth, frame.endHeight = frame:GetSize()
		
        local currentWidth, currentHeight = frame:GetSize()
        local scale = currentHeight / originalHeight
		BOT_BAR_SETTINGS.width = currentWidth
		BOT_BAR_SETTINGS.scale = scale
	end)

    frame:SetScript("OnSizeChanged", function(self, width, height)
        if frame.resizing then
            local newHeight = width / frame.originalAspectRatio
            self:SetHeight(newHeight)
            AdjustButtons(frame)
        end
    end)

    frame:SetResizable(true)
    frame:SetMinResize(originalWidth * 0.5, originalHeight * 0.5)
    frame:SetMaxResize(originalWidth * 3, originalHeight * 3)

    resizeHandle:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Resize", 1, 1, 1)
        GameTooltip:Show()
    end)

    resizeHandle:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        ResetCursor()
    end)

    local movementGroup = {
        {text = "Attack", icon = "ability_ghoulfrenzy", command = "attack"},
        {text = "Follow", icon = "Ability_Tracking", command = "follow"},
        {text = "Stay", icon = "spell_nature_timestop", command = "stay"},
    }

    local combatGroup = {
        {text = "Aggressive", icon = "ability_racial_bloodrage", command = "co +grind,-passive"},
        {text = "Defensive", icon = "Ability_Warrior_DefensiveStance", command = "co -grind,-passive"},
        {text = "Passive", icon = "ability_seal", command = "co -grind,-stay,+follow,+passive\nnc -stay,+follow"},
    }

    local toggleButtons = {
        {text = "Toggle Burst Mode", icon = "Ability_Shaman_Heroism", command = "boost", toggle = true, default = true},
        {text = "Toggle Food Between Fights", icon = "INV_Misc_Food_10", command = "food", toggle = true, default = true},
        {text = "Toggle Healer DPS", icon = "Spell_Holy_HolySmite", command = "healer dps", toggle = true, default = true},
        {text = "Group Setup", icon = "INV_Misc_GroupLooking", command = "groupsetup", special = true},
    }

    local buttons = {}
    for _, btn in ipairs(movementGroup) do table.insert(buttons, btn) end
    for _, btn in ipairs(toggleButtons) do table.insert(buttons, btn) end
    for _, btn in ipairs(combatGroup) do table.insert(buttons, btn) end

    frame.movementGroup = movementGroup
    frame.combatGroup = combatGroup
    frame.buttons = buttons

    frame.delayedCommand = nil
    frame.delayTimer = 0
	
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
        button:SetPoint("LEFT", frame, "LEFT", 10 + ((i-1) * (buttonWidth + spacing)), 0)
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

    local function SetCombatButtonClickHandler(button)
        button:SetScript("OnClick", function(self, mouseButton)
            if self.info.text == "Passive" then
                isFleeActive = true
                isPassiveActive = true
                
                local followBtn = _G["BotControlBarButton2"]
                local stayBtn = _G["BotControlBarButton3"]
                
                if followBtn and stayBtn then
                    followBtn.state = true
                    followBtn.border:SetAlpha(1)
                    
                    stayBtn.state = false
                    stayBtn.border:SetAlpha(0)
                    
                    UpdateButtonTooltip(followBtn)
                    UpdateButtonTooltip(stayBtn)
                end
            end
            
            if self.info.text == "Group Setup" then
                ShowGroupSetupWindow()
                return
            end

            if self.info.guild then
                SendThrottledChatMessage(self.info.command, "GUILD")
                return
            end

            local channel = GetNumRaidMembers() > 0 and "RAID" or GetNumPartyMembers() > 0 and "PARTY" or nil

            local function tIndexOf(table, item)
                for i, value in ipairs(table) do
                    if value.text == item.text and value.icon == item.icon and value.command == item.command then
                        return i
                    end
                end
                return -1
            end

            local passiveButton = _G["BotControlBarButton"..(tIndexOf(buttons, combatGroup[3]))]
            local isPassiveActive = passiveButton and passiveButton.state

            if isPassiveActive and tContains(movementGroup, self.info) then
                if self.info.text == "Attack" then
                    if not UnitExists("target") then
                        UIErrorsFrame:AddMessage("You don't have a target.", 1.0, 1.0, 0.0, 1.0, 6)
                    else                        
                        local passiveBtn = _G["BotControlBarButton10"]
                        if passiveBtn then
                            passiveBtn.state = false
                            passiveBtn.border:SetAlpha(0)
                            UpdateButtonTooltip(passiveBtn)
                        end

                        
                        local defensiveBtn = _G["BotControlBarButton9"]
                        if defensiveBtn then
                            defensiveBtn.state = true
                            defensiveBtn.border:SetAlpha(1)
                            UpdateButtonTooltip(defensiveBtn)
                        end
                        
                        SendThrottledChatMessage("follow", channel)
                        local delayFrame = CreateFrame("Frame")
                        delayFrame.timeElapsed = 0
                        delayFrame:SetScript("OnUpdate", function(self, elapsed)
                            self.timeElapsed = self.timeElapsed + elapsed
                            if self.timeElapsed >= 0.5 then
                                self:SetScript("OnUpdate", nil)
                                self:Hide()
                                SendThrottledChatMessage("attack", channel)
                            end
                        end)
                    end
                    return
                end
            end

            if tContains(movementGroup, self.info) then
                local followBtn = _G["BotControlBarButton"..(tIndexOf(buttons, {text = "Follow", icon = "Ability_Tracking", command = "follow"}))]
                local stayBtn = _G["BotControlBarButton"..(tIndexOf(buttons, {text = "Stay", icon = "spell_nature_timestop", command = "stay"}))]
                local attackBtn = _G["BotControlBarButton"..(tIndexOf(buttons, {text = "Attack", icon = "ability_ghoulfrenzy", command = "attack"}))]

                if self.info.text == "Attack" then
                    if not UnitExists("target") then
                        UIErrorsFrame:AddMessage("You don't have a target.", 1.0, 1.0, 0.0, 1.0, 6)
                    else
                        SendThrottledChatMessage(self.info.command, channel)
                    end
                    return
                end

                if self.info.text == "Follow" then
                    followBtn.state = true
                    followBtn.border:SetAlpha(1)
                    stayBtn.state = false
                    stayBtn.border:SetAlpha(0)
                elseif self.info.text == "Stay" then
                    stayBtn.state = true
                    stayBtn.border:SetAlpha(1)
                    followBtn.state = false
                    followBtn.border:SetAlpha(0)
                    if self.info.text == "Passive" then
                        isFleeActive = true
                        isPassiveActive = true
                        
                        local passiveBtn = _G["BotControlBarButton10"]
                        local defensiveBtn = _G["BotControlBarButton9"]
                        
                        if passiveBtn and defensiveBtn then
                            passiveBtn.state = false
                            passiveBtn.border:SetAlpha(0)
                            
                            defensiveBtn.state = true
                            defensiveBtn.border:SetAlpha(1)
                            
                            UpdateButtonTooltip(passiveBtn)
                            UpdateButtonTooltip(defensiveBtn)
                        end
                    end
                end

                UpdateButtonTooltip(followBtn)
                UpdateButtonTooltip(stayBtn)
            end

            if tContains(combatGroup, self.info) then
                for _, btn in ipairs(combatGroup) do
                    local otherBtn = _G["BotControlBarButton"..(tIndexOf(buttons, btn))]
                    if otherBtn then
                        otherBtn.state = false
                        otherBtn.border:SetAlpha(0)
                        UpdateButtonTooltip(otherBtn)
                    end
                end
                self.state = true
                self.border:SetAlpha(1)
                
                for cmd in string.gmatch(self.info.command, "[^\n]+") do
                    SendThrottledChatMessage(cmd, channel)
                end
                
                UpdateButtonTooltip(self)
                return
            end

            if self.info.toggle then
                self.state = not self.state

				if self.info.command == "boost" then
					if self.state then
						SendThrottledChatMessage("co +boost", channel)
						SendThrottledChatMessage("ss -2825,-32182", channel)
					else
						SendThrottledChatMessage("co -boost", channel)
						SendThrottledChatMessage("ss +2825,+32182", channel)
					end
                elseif self.info.command == "food" then
                    local cmd = self.state and "nc +food" or "nc -food"
                    SendThrottledChatMessage(cmd, channel)
                elseif self.info.command == "healer dps" then
                    local cmd = self.state and "co +healer dps" or "co -healer dps"
                    SendThrottledChatMessage(cmd, channel)
                end

                self.border:SetAlpha(self.state and 1 or 0)
                UpdateButtonTooltip(self)
            else
                if channel then
                    for cmd in string.gmatch(self.info.command, "[^\n]+") do
                        SendThrottledChatMessage(cmd, channel)
                    end
                end
            end
        end)
    end

    local buttonWidth = 36
    local buttonHeight = 36
    local spacing = 2

    for i, btnInfo in ipairs(buttons) do
        local button = CreateButton(i, btnInfo, buttonWidth, buttonHeight, spacing)

        if btnInfo.toggle then
            button.state = btnInfo.default or false
            button.border:SetAlpha(button.state and 1 or 0)
        else
            button.state = false
        end

        if btnInfo.text == "Follow" then
            button.state = true
            button.border:SetAlpha(1)
        elseif btnInfo.text == "Defensive" then
            button.state = true
            button.border:SetAlpha(1)
        end

        SetCombatButtonClickHandler(button)
    end

    frame:SetScript("OnUpdate", function(self, elapsed)

        if self.delayedCommand then
            self.delayTimer = self.delayTimer - elapsed
            if self.delayTimer <= 0 then
                SendThrottledChatMessage(self.delayedCommand.command, self.delayedCommand.channel)

                if self.delayedCommand.defensiveButton then
                    for _, btn in ipairs(combatGroup) do
                        local otherBtn = _G["BotControlBarButton"..(tIndexOf(buttons, btn))]
                        if otherBtn then
                            otherBtn.state = false
                            otherBtn.border:SetAlpha(0)
                            UpdateButtonTooltip(otherBtn)
                        end
                    end

                    self.delayedCommand.defensiveButton.state = true
                    self.delayedCommand.defensiveButton.border:SetAlpha(1)
                    UpdateButtonTooltip(self.delayedCommand.defensiveButton)
                end

                self.delayedCommand = nil
            end
        end
    end)

    function tContains(table, item)
        for _, value in pairs(table) do
            if value == item then return true end
        end
        return false
    end

    function tIndexOf(table, item)
        for i, value in ipairs(table) do
            if value == item then return i end
        end
        return -1
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

    closeButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Close Control Bar", 1, 1, 1)
        GameTooltip:Show()
    end)

    closeButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    frame.modeButton = CreateFrame("Button", "BotControlBarModeButton", frame, "SecureActionButtonTemplate")
    local modeButton = frame.modeButton
    modeButton:SetSize(18, 18)
    modeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -25)
    modeButton.info = {
        text = "Utility Mode",
        icon = "Spell_Shadow_Teleport",
        command = "changemode"
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
        {
            text = "Use Objects",
            icon = "INV_Misc_EngGizmos_02",
            command = "los"
        },
        {
            text = "Loot Strategy",
            icon = "INV_Misc_Coin_01",
            dropdown = {
                {text = "Don't loot anything", command = "ll none"},
                {text = "Loot all items", command = "ll all"},
                {text = "Loot anything except BoP items", command = "ll normal"},
                {text = "Loot quest objects only", command = "ll quest"},
                {text = "Loot only gray items", command = "ll gray"},
                {text = "Loot only skill items", command = "ll skill"}
            }
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
                {text = "Melee", command = "formation melee"}
            }
        },
        {
            text = "NPC Interaction",
            icon = "achievement_character_human_male",
            dropdown = {
                {text = "Talk to NPC", command = "talk", requiresTarget = true},
                {text = "Repair", command = "repair", requiresTarget = true, requiresRepairVendor = true},
                {text = "Train", command = "trainer learn", requiresTarget = true, requiresTrainer = true}
            }
        },
        {
            text = "Summon",
            icon = "Spell_Shadow_Teleport",
            command = ".shadowsmenu",
            guild = true,
            clickGossip = true
        },
        {
            text = "Shadows Chatter",
            icon = "Spell_Holy_Silence",
            toggle = true,
            default = true,
            command = ".muteshadow",
            guild = true
        },
        {
            text = "Quest",
            icon = "INV_Letter_11",
            dropdown = {
                {text = "Show quest progress", command = "quests all"},
                {text = "Accept quests", command = "accept *"},
                {text = "Abandon quest", command = "quests all", abandonQuest = true}
            }
        },
        {
            text = "Inventory",
            icon = "inv_misc_bag_07_black",
            command = "c"
        },
        {
            text = "Set Hearthstone",
            icon = "INV_Misc_Rune_01",
            command = "home"
        },
        {
            text = "Ghost Commands",
            icon = "spell_holy_guardianspirit",
            dropdown = {
                {text = "Release spirit", command = "release"},
                {text = "Revive at spirit healer", command = "revive"}
            }
        }
    }

    function HandleUtilityButtonAction(button)
        if button.info.text == "Use Objects" then
            local channel = GetNumRaidMembers() > 0 and "RAID" or GetNumPartyMembers() > 0 and "PARTY" or nil
            SendThrottledChatMessage("los", channel)
            
            local responseReceived = false
            
            local frame = CreateFrame("Frame")
            frame:RegisterEvent("CHAT_MSG_WHISPER")
            frame:SetScript("OnEvent", function(self, event, msg, sender)
            if msg:lower():match("spell") or msg:lower():match("quest") then return end
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
            timer.timeElapsed = 0
            timer:SetScript("OnUpdate", function(self, elapsed)
                self.timeElapsed = self.timeElapsed + elapsed
                
                if self.timeElapsed >= 5 and not responseReceived then
                    UIErrorsFrame:AddMessage("No usable objects nearby.", 1.0, 1.0, 0.0, 1.0, 6)
                    frame:UnregisterEvent("CHAT_MSG_WHISPER")
                    self:SetScript("OnUpdate", nil)
                elseif lastUpdate > 0 and (GetTime() - lastUpdate) >= 1 and next(itemCache) then
                    ShowItemList()
                    lastUpdate = 0
                    frame:UnregisterEvent("CHAT_MSG_WHISPER")
                    self:SetScript("OnUpdate", nil)
                end
            end)
        elseif button.info.text == "Summon" then
            SendChatMessage(".shadowsmenu", "GUILD")
            local delayFrame = CreateFrame("Frame")
            delayFrame.timeElapsed = 0
            delayFrame:SetScript("OnUpdate", function(self, elapsed)
                self.timeElapsed = self.timeElapsed + elapsed
                if self.timeElapsed >= 0.5 then
                    self:SetScript("OnUpdate", nil)
                    if GossipTitleButton3 then
                        GossipTitleButton3:Click()
                    end
                end
            end)
        elseif button.info.text == "Shadows Chatter" then
            button.state = not button.state
            button.border:SetAlpha(button.state and 1 or 0)
            
            local names = {}
            for name, _ in pairs(cachedNames) do
                table.insert(names, name)
            end
            
            local namesString = table.concat(names, " ")
            local cmd
            if button.state then
                cmd = ".unmuteshadow " .. namesString
                print("Unmuted: " .. namesString)
            else
                cmd = ".muteshadow " .. namesString
                print("Muted: " .. namesString)
            end
            SendChatMessage(cmd, "GUILD")
            
            UpdateButtonTooltip(button)
        elseif button.info.dropdown then
            local dropdown = CreateFrame("Frame", "TempDropdown", UIParent, "UIDropDownMenuTemplate")
            dropdown:SetPoint("TOP", button, "BOTTOM", 0, -5)

            dropdown.button = button

            UIDropDownMenu_Initialize(dropdown, function(self, level)
                local info = UIDropDownMenu_CreateInfo()
                for _, item in ipairs(dropdown.button.info.dropdown) do
                    info.text = item.text
                    info.func = function()
                        local channel = GetNumRaidMembers() > 0 and "RAID" or GetNumPartyMembers() > 0 and "PARTY" or nil
                        local skip = false
                        if item.text == "Release spirit" then
                            isStayActive = true
                        elseif item.requiresTarget and not UnitExists("target") then
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
                            wipe(questCache)
                            questLastUpdate = 0
                            SendThrottledChatMessage(item.command, channel)
                            
                            local questFrame = CreateFrame("Frame")
                            questFrame:RegisterEvent("CHAT_MSG_WHISPER")
                            questFrame.isAbandon = item.abandonQuest
                            questFrame:SetScript("OnEvent", function(self, event, msg, sender)
                                if not questCache[sender] then
                                    questCache[sender] = {completed = {}, incompleted = {}, summary = ""}
                                end
                                
                                if msg:match("%-%-%-") then
                                    if msg:match("Completed quests") then
                                        questCache[sender].currentSection = "completed"
                                    elseif msg:match("Incompleted quests") then
                                        questCache[sender].currentSection = "incompleted"
                                    elseif msg:match("Summary") then
                                        questCache[sender].currentSection = "summary"
                                    end
                                elseif questCache[sender].currentSection == "summary" then
                                    questCache[sender].summary = msg
                                else
                                    local questLink = msg:match("(%[.-%])")
                                    if questLink and questCache[sender].currentSection then
                                        table.insert(questCache[sender][questCache[sender].currentSection], questLink)
                                    end
                                end
                                
                                questLastUpdate = GetTime()
                            end)
                            
                            local timer = CreateFrame("Frame")
                            timer.timeElapsed = 0
                            timer:SetScript("OnUpdate", function(self, elapsed)
                                self.timeElapsed = self.timeElapsed + elapsed
                                
                                if questLastUpdate > 0 and (GetTime() - questLastUpdate) >= 1 and next(questCache) then
                                    if questFrame.isAbandon then
                                        ShowQuestAbandonList()
                                    else
                                        ShowQuestList()
                                    end
                                    questLastUpdate = 0
                                    questFrame:UnregisterEvent("CHAT_MSG_WHISPER")
                                    self:SetScript("OnUpdate", nil)
                                elseif self.timeElapsed >= 5 then
                                    questFrame:UnregisterEvent("CHAT_MSG_WHISPER")
                                    self:SetScript("OnUpdate", nil)
                                end
                            end)
                            
                            skip = true
                        end
                        if not skip then
                            SendThrottledChatMessage(item.command, channel)
                        end
                        CloseDropDownMenus()
                    end
                    UIDropDownMenu_AddButton(info, level)
                end
            end)

            dropdown:Hide()
            ToggleDropDownMenu(1, nil, dropdown, button, 0, 0)
        else
            local channel = GetNumRaidMembers() > 0 and "RAID" or GetNumPartyMembers() > 0 and "PARTY" or nil
            SendThrottledChatMessage(button.info.command, channel)
        end
    end

    local function SwitchMode()		
        if frame.currentMode == "combat" then
            frame.previousCombatToggleStates = {}
            for _, btnInfo in ipairs(frame.originalButtons) do
                if btnInfo.toggle then
                    local button = _G["BotControlBarButton"..(tIndexOf(frame.originalButtons, btnInfo))]
                    if button then
                        frame.previousCombatToggleStates[btnInfo.text] = button.state
                    end
                end
            end

            frame.previousCombatMovementActive = nil
            for _, btnInfo in ipairs(frame.movementGroup) do
                local button = _G["BotControlBarButton"..(tIndexOf(frame.originalButtons, btnInfo))]
                if button and button.state then
                    frame.previousCombatMovementActive = btnInfo.text
                    break
                end
            end

            frame.previousCombatCombatActive = nil
            for _, btnInfo in ipairs(frame.combatGroup) do
                local button = _G["BotControlBarButton"..(tIndexOf(frame.originalButtons, btnInfo))]
                if button and button.state then
                    frame.previousCombatCombatActive = btnInfo.text
                    break
                end
            end

            frame.currentMode = "utility"
            modeButton.info = {
                text = "Combat Mode",
                icon = "Ability_DualWield",
                command = "changemode"
            }
            modeButton.icon:SetTexture("Interface\\Icons\\"..modeButton.info.icon)
			
            for i = 1, #frame.originalButtons do
                local button = _G["BotControlBarButton"..i]
                if button then button:Hide() end
            end

            frame.buttons = utilityButtons
            for i, btnInfo in ipairs(utilityButtons) do
                local button = _G["BotControlBarButton"..i]
                if not button then
                    button = CreateButton(i, btnInfo, 36, 36, 2)
                else
                    button:Show()
                    button:SetSize(36, 36)
                    button:SetPoint("LEFT", frame, "LEFT", 10 + ((i-1) * (36 + 2)), 0)
                    button.info = btnInfo
                    button.icon:SetTexture("Interface\\Icons\\"..btnInfo.icon)
                    button.border:SetAlpha(0)
                    button.state = false
                end
                
                if btnInfo.toggle then
                    button.state = btnInfo.default or false
                    button.border:SetAlpha(button.state and 1 or 0)
                end
    
                button:SetScript("OnClick", function(self)
                    HandleUtilityButtonAction(self)
                end)
            end

            for i, btnInfo in ipairs(utilityButtons) do
                local button = _G["BotControlBarButton"..i]
                if btnInfo.toggle then
                    button.state = btnInfo.default or false
                    if frame.previousUtilityToggleStates and frame.previousUtilityToggleStates[btnInfo.text] ~= nil then
                        button.state = frame.previousUtilityToggleStates[btnInfo.text]
                    end
                    button.border:SetAlpha(button.state and 1 or 0)
                end
            end

            for i = #utilityButtons + 1, #frame.originalButtons do
                local button = _G["BotControlBarButton"..i]
                if button then button:Hide() end
            end

            AdjustButtons(frame)
        else
            frame.previousUtilityToggleStates = {}
            for _, btnInfo in ipairs(utilityButtons) do
                if btnInfo.toggle then
                    local button = _G["BotControlBarButton"..(tIndexOf(utilityButtons, btnInfo))]
                    if button then
                        frame.previousUtilityToggleStates[btnInfo.text] = button.state
                    end
                end
            end
            frame.currentMode = "combat"
            modeButton.info = {
                text = "Utility Mode",
                icon = "Spell_Shadow_Teleport",
                command = "changemode"
            }
            modeButton.icon:SetTexture("Interface\\Icons\\"..modeButton.info.icon)

            for i = 1, #utilityButtons do
                local button = _G["BotControlBarButton"..i]
                if button then
                    button:Hide()
                    if button.dropdown then
                        button.dropdown:Hide()
                    end
                end
            end

            frame.buttons = frame.originalButtons
            frame.movementGroup = frame.originalMovementGroup
            frame.combatGroup = frame.originalCombatGroup

            for i, btnInfo in ipairs(frame.originalButtons) do
                local button = _G["BotControlBarButton"..i]
                if not button then
                    button = CreateButton(i, btnInfo, 36, 36, 2)
                    SetCombatButtonClickHandler(button)
                else
                    button:Show()
                    button:SetSize(36, 36)
                    button:SetPoint("LEFT", frame, "LEFT", 10 + ((i-1) * (36 + 2)), 0)
                    button.info = btnInfo
                    button.icon:SetTexture("Interface\\Icons\\"..btnInfo.icon)
                end

                SetCombatButtonClickHandler(button)
				
				if resetCombatButtons then
                    button.state = btnInfo.default or false
                    button.border:SetAlpha(button.state and 1 or 0)
                    if isStayActive then
                        if btnInfo.text == "Stay" then
                            button.state = true
                            button.border:SetAlpha(1)
                        end
                    else
                        if btnInfo.text == "Follow" then
                            button.state = true
                            button.border:SetAlpha(1)
                        end
                    end
                    if btnInfo.text == "Defensive" then
                        button.state = true
                        button.border:SetAlpha(1)
                    end
                else
                    if btnInfo.toggle then
                        button.state = btnInfo.default or false
                        if frame.previousCombatToggleStates and frame.previousCombatToggleStates[btnInfo.text] ~= nil then
                            button.state = frame.previousCombatToggleStates[btnInfo.text]
                        end
                        button.border:SetAlpha(button.state and 1 or 0)
                    else
                        button.state = false
                    end

                    if frame.previousCombatMovementActive and btnInfo.text == frame.previousCombatMovementActive and tContains(frame.movementGroup, btnInfo) then
                        button.state = true
                        button.border:SetAlpha(1)
                    end

                    if frame.previousCombatCombatActive and btnInfo.text == frame.previousCombatCombatActive and tContains(frame.combatGroup, btnInfo) then
                        button.state = true
                        button.border:SetAlpha(1)
                    end
                end
            end

            for i = #frame.originalButtons + 1, #utilityButtons do
                local button = _G["BotControlBarButton"..i]
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
        local rightMargin = (20 * scale)

        local availableWidth = currentWidth - leftMargin - rightMargin

        local totalButtonsWidth = (#f.buttons * buttonWidth) + ((#f.buttons - 1) * spacing)

        if totalButtonsWidth > availableWidth then
            local maxButtonWidth = (availableWidth - ((#f.buttons - 1) * spacing)) / #f.buttons
            buttonWidth = math.max(20 * scale, maxButtonWidth)
        end

        for i, btnInfo in ipairs(f.buttons) do
            local button = _G["BotControlBarButton"..i]
            if button then
                button:SetSize(buttonWidth, buttonHeight)
                button:SetPoint("LEFT", f, "LEFT", leftMargin + ((i-1) * (buttonWidth + spacing)), 0)

                if button.border then
                    local borderWidth = buttonWidth * 1.60
                    local borderHeight = buttonHeight * 1.60
                    button.border:SetSize(borderWidth, borderHeight)
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
                local borderWidth = modeButtonSize * 1.50
                local borderHeight = modeButtonSize * 1.50
                f.modeButton.border:SetSize(borderWidth, borderHeight)
                f.modeButton.border:SetPoint("CENTER", f.modeButton, "CENTER", 0, 1)
            end
        end
    end

	function ShowItemList()
		if not itemListFrame then
			itemListFrame = CreateFrame("Frame", "ShadowItemListFrame", UIParent)
			itemListFrame:SetSize(220, 300)
			itemListFrame:SetPoint("CENTER")
			itemListFrame:SetFrameStrata("DIALOG")

			itemListFrame:SetBackdrop({
				bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = true,
				tileSize = 16,
				edgeSize = 16,
				insets = {left = 4, right = 4, top = 4, bottom = 4}
			})
			itemListFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)

			local title = itemListFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			title:SetPoint("TOP", 0, -12)
			title:SetText("Choose object to use")

			local scrollFrame = CreateFrame("ScrollFrame", nil, itemListFrame)
			scrollFrame:SetPoint("TOPLEFT", 10, -30)
			scrollFrame:SetPoint("BOTTOMRIGHT", -10, 10)

			local scrollChild = CreateFrame("Frame")
			scrollChild:SetWidth(200)
			scrollFrame:SetScrollChild(scrollChild)

			local scrollBar = CreateFrame("Slider", nil, scrollFrame, "UIPanelScrollBarTemplate")
			scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", -12, -16)
			scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", -12, 16)
			scrollBar:SetWidth(16)
			scrollBar:SetMinMaxValues(0, 0)
			scrollBar:SetValueStep(20)
			scrollBar:SetValue(0)
			scrollBar.scrollStep = 20
			scrollBar:SetScript("OnValueChanged", function(self, value)
				scrollFrame:SetVerticalScroll(value)
			end)

			local thumbTexture = scrollBar:GetThumbTexture()
			thumbTexture:SetHeight(16)

			scrollFrame:EnableMouseWheel(true)
			scrollFrame:SetScript("OnMouseWheel", function(self, delta)
				local current = scrollBar:GetValue()
				local newValue = current - (delta * scrollBar:GetValueStep())
				scrollBar:SetValue(newValue)
			end)

			itemListFrame.scrollFrame = scrollFrame
			itemListFrame.scrollChild = scrollChild
			itemListFrame.scrollBar = scrollBar
			itemListFrame.buttons = {}

			itemListFrame:SetMovable(true)
			itemListFrame:EnableMouse(true)
			itemListFrame:RegisterForDrag("LeftButton")
			itemListFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
			itemListFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

			local exitButton = CreateFrame("Button", nil, itemListFrame, "UIPanelCloseButton")
			exitButton:SetPoint("TOPRIGHT", 2, 0)
			exitButton:SetScript("OnClick", function()
				itemListFrame:Hide()
			end)

			tinsert(UISpecialFrames, "ShadowItemListFrame")
		end

		for _, btn in ipairs(itemListFrame.buttons) do
			btn:Hide()
		end
		wipe(itemListFrame.buttons)

		local itemList = {}
		for link in pairs(itemCache) do
			table.insert(itemList, link)
		end
		table.sort(itemList)

		local yOffset = 0
		for _, link in ipairs(itemList) do
			local btn = CreateFrame("Button", nil, itemListFrame.scrollChild)
			btn:SetSize(190, 20)
			btn:SetPoint("TOPLEFT", 0, -yOffset)

			local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			text:SetAllPoints()
			text:SetJustifyH("LEFT")
			text:SetText(link)

			btn:SetScript("OnClick", function()
                local channel = GetNumRaidMembers() > 0 and "RAID" or GetNumPartyMembers() > 0 and "PARTY" or nil
				SendThrottledChatMessage("u "..link, channel)
				itemListFrame:Hide()
			end)

			tinsert(itemListFrame.buttons, btn)
			yOffset = yOffset + 20
		end

		itemListFrame.scrollChild:SetHeight(yOffset)
		local scrollRange = max(0, yOffset - itemListFrame.scrollFrame:GetHeight())
		itemListFrame.scrollBar:SetMinMaxValues(0, scrollRange)
		itemListFrame.scrollBar:SetValue(0)

		if scrollRange == 0 then
			itemListFrame.scrollBar:Hide()
		else
			itemListFrame.scrollBar:Show()
		end

		wipe(itemCache)
		itemListFrame:Show()
	end

    function ShowQuestList()
        local questListFrame = CreateFrame("Frame", "ShadowQuestListFrame", UIParent)
        questListFrame:SetSize(400, 500)
        questListFrame:SetPoint("CENTER")
        questListFrame:SetFrameStrata("DIALOG")

        questListFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        questListFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)

        local title = questListFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", 0, -12)
        title:SetText("Quest Progress")

        local scrollFrame = CreateFrame("ScrollFrame", nil, questListFrame)
        scrollFrame:SetPoint("TOPLEFT", 10, -30)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

        local scrollChild = CreateFrame("Frame")
        scrollChild:SetWidth(360)
        scrollFrame:SetScrollChild(scrollChild)

        local scrollBar = CreateFrame("Slider", nil, scrollFrame, "UIPanelScrollBarTemplate")
        scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", -12, -16)
        scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", -12, 16)
        scrollBar:SetWidth(16)
        scrollBar:SetMinMaxValues(0, 0)
        scrollBar:SetValueStep(20)
        scrollBar:SetValue(0)
        scrollBar.scrollStep = 20
        scrollBar:SetScript("OnValueChanged", function(self, value)
            scrollFrame:SetVerticalScroll(value)
        end)

        scrollFrame:EnableMouseWheel(true)
        scrollFrame:SetScript("OnMouseWheel", function(self, delta)
            local current = scrollBar:GetValue()
            local newValue = current - (delta * scrollBar:GetValueStep())
            scrollBar:SetValue(newValue)
        end)

        questListFrame:SetMovable(true)
        questListFrame:EnableMouse(true)
        questListFrame:RegisterForDrag("LeftButton")
        questListFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        questListFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

        local exitButton = CreateFrame("Button", nil, questListFrame, "UIPanelCloseButton")
        exitButton:SetPoint("TOPRIGHT", 2, 0)
        exitButton:SetScript("OnClick", function()
            questListFrame:Hide()
        end)

        local yOffset = 0
        for sender, data in pairs(questCache) do
            local playerName = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            playerName:SetPoint("TOPLEFT", 5, -yOffset)
            playerName:SetText(sender)
            playerName:SetTextColor(1, 0.82, 0)
            yOffset = yOffset + 20

            if #data.incompleted > 0 then
                local incompletedHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                incompletedHeader:SetPoint("TOPLEFT", 10, -yOffset)
                incompletedHeader:SetText("--- Incompleted quests ---")
                incompletedHeader:SetTextColor(1, 0.5, 0.5)
                yOffset = yOffset + 15

                for _, quest in ipairs(data.incompleted) do
                    local questText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    questText:SetPoint("TOPLEFT", 15, -yOffset)
                    questText:SetText(quest)
                    questText:SetWidth(340)
                    questText:SetJustifyH("LEFT")
                    yOffset = yOffset + 15
                end
            end

            if #data.completed > 0 then
                local completedHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                completedHeader:SetPoint("TOPLEFT", 10, -yOffset)
                completedHeader:SetText("--- Completed quests ---")
                completedHeader:SetTextColor(0.5, 1, 0.5)
                yOffset = yOffset + 15

                for _, quest in ipairs(data.completed) do
                    local questText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    questText:SetPoint("TOPLEFT", 15, -yOffset)
                    questText:SetText(quest)
                    questText:SetWidth(340)
                    questText:SetJustifyH("LEFT")
                    yOffset = yOffset + 15
                end
            end

            if data.summary ~= "" then
                local summaryHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                summaryHeader:SetPoint("TOPLEFT", 10, -yOffset)
                summaryHeader:SetText("--- Summary ---")
                summaryHeader:SetTextColor(0.5, 0.5, 1)
                yOffset = yOffset + 15

                local summaryText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                summaryText:SetPoint("TOPLEFT", 15, -yOffset)
                summaryText:SetText(data.summary)
                summaryText:SetWidth(340)
                summaryText:SetJustifyH("LEFT")
                yOffset = yOffset + 15
            end

            yOffset = yOffset + 10
        end

        scrollChild:SetHeight(math.max(yOffset, scrollFrame:GetHeight()))
        local scrollRange = math.max(0, yOffset - scrollFrame:GetHeight())
        scrollBar:SetMinMaxValues(0, scrollRange)
        scrollBar:SetValue(0)

        if scrollRange == 0 then
            scrollBar:Hide()
        else
            scrollBar:Show()
        end

        tinsert(UISpecialFrames, "ShadowQuestListFrame")
        questListFrame:Show()
    end

    function ShowQuestAbandonList()
        local abandonListFrame = CreateFrame("Frame", "ShadowQuestAbandonFrame", UIParent)
        abandonListFrame:SetSize(400, 500)
        abandonListFrame:SetPoint("CENTER")
        abandonListFrame:SetFrameStrata("DIALOG")

        abandonListFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        abandonListFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)

        local title = abandonListFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", 0, -12)
        title:SetText("Which quest would you like to abandon?")

        local scrollFrame = CreateFrame("ScrollFrame", nil, abandonListFrame)
        scrollFrame:SetPoint("TOPLEFT", 10, -30)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

        local scrollChild = CreateFrame("Frame")
        scrollChild:SetWidth(360)
        scrollFrame:SetScrollChild(scrollChild)

        local scrollBar = CreateFrame("Slider", nil, scrollFrame, "UIPanelScrollBarTemplate")
        scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", -12, -16)
        scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", -12, 16)
        scrollBar:SetWidth(16)
        scrollBar:SetMinMaxValues(0, 0)
        scrollBar:SetValueStep(20)
        scrollBar:SetValue(0)
        scrollBar.scrollStep = 20
        scrollBar:SetScript("OnValueChanged", function(self, value)
            scrollFrame:SetVerticalScroll(value)
        end)

        scrollFrame:EnableMouseWheel(true)
        scrollFrame:SetScript("OnMouseWheel", function(self, delta)
            local current = scrollBar:GetValue()
            local newValue = current - (delta * scrollBar:GetValueStep())
            scrollBar:SetValue(newValue)
        end)

        abandonListFrame:SetMovable(true)
        abandonListFrame:EnableMouse(true)
        abandonListFrame:RegisterForDrag("LeftButton")
        abandonListFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        abandonListFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

        local exitButton = CreateFrame("Button", nil, abandonListFrame, "UIPanelCloseButton")
        exitButton:SetPoint("TOPRIGHT", 2, 0)
        exitButton:SetScript("OnClick", function()
            abandonListFrame:Hide()
        end)

        local yOffset = 0
        for sender, data in pairs(questCache) do
            local playerName = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            playerName:SetPoint("TOPLEFT", 5, -yOffset)
            playerName:SetText(sender)
            playerName:SetTextColor(1, 0.82, 0)
            yOffset = yOffset + 20

            local allQuests = {}
            for _, quest in ipairs(data.incompleted) do
                table.insert(allQuests, quest)
            end
            for _, quest in ipairs(data.completed) do
                table.insert(allQuests, quest)
            end

            for _, questLink in ipairs(allQuests) do
                local btn = CreateFrame("Button", nil, scrollChild)
                btn:SetSize(340, 20)
                btn:SetPoint("TOPLEFT", 10, -yOffset)

                local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                text:SetAllPoints()
                text:SetJustifyH("LEFT")
                text:SetText(questLink)

                btn:SetScript("OnClick", function()
                    local questName = questLink:match("%[(.-)%]")
                    StaticPopupDialogs["ABANDON_QUEST_CONFIRM"] = {
                        text = "Are you sure you want " .. sender .. " to abandon quest " .. questLink .. "?",
                        button1 = "Yes",
                        button2 = "No",
                        OnAccept = function()
                            SendThrottledChatMessage("drop " .. questLink, "WHISPER", nil, sender)
                            abandonListFrame:Hide()
                        end,
                        timeout = 0,
                        whileDead = true,
                        hideOnEscape = true,
                        preferredIndex = 3,
                    }
                    StaticPopup_Show("ABANDON_QUEST_CONFIRM")
                end)

                yOffset = yOffset + 20
            end

            yOffset = yOffset + 10
        end

        scrollChild:SetHeight(math.max(yOffset, scrollFrame:GetHeight()))
        local scrollRange = math.max(0, yOffset - scrollFrame:GetHeight())
        scrollBar:SetMinMaxValues(0, scrollRange)
        scrollBar:SetValue(0)

        if scrollRange == 0 then
            scrollBar:Hide()
        else
            scrollBar:Show()
        end

        tinsert(UISpecialFrames, "ShadowQuestAbandonFrame")
        abandonListFrame:Show()
    end

    function ShowRoleManagementWindow()
        if _G["ShadowRoleManagementFrame"] then
            _G["ShadowRoleManagementFrame"]:Hide()
            _G["ShadowRoleManagementFrame"] = nil
        end
        
        local roleData = {
            tanks = {},
            healers = {},
            dps = {}
        }
        
        local channel = GetNumRaidMembers() > 0 and "RAID" or GetNumPartyMembers() > 0 and "PARTY" or nil
        if not channel then
            print("You must be in a group to manage roles.")
            return
        end
        
        local responseFrame = CreateFrame("Frame")
        responseFrame:RegisterEvent("CHAT_MSG_WHISPER")
        responseFrame:SetScript("OnEvent", function(self, event, msg, sender)
            local lowerMsg = msg:lower()
            
            -- Categorize by priority: tank > heal > dps
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

    function DisplayRoleWindow(roleData)
        if _G["ShadowRoleManagementFrame"] then
            _G["ShadowRoleManagementFrame"]:Hide()
        end
        
        local columnWidth = 190
        local frameWidth = (3 * columnWidth) + 40
        
        local maxPlayers = math.max(#roleData.tanks, #roleData.healers, #roleData.dps)
        if maxPlayers == 0 then maxPlayers = 1 end
        local frameHeight = 120 + (maxPlayers * 25)
        
        local roleFrame = CreateFrame("Frame", "ShadowRoleManagementFrame", UIParent)
        roleFrame:SetSize(frameWidth, frameHeight)
        roleFrame:SetPoint("CENTER")
        roleFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        roleFrame:SetFrameLevel(100)
        
        roleFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        roleFrame:SetBackdropColor(0, 0, 0, 1)
        
        roleFrame:SetMovable(true)
        roleFrame:EnableMouse(true)
        roleFrame:RegisterForDrag("LeftButton")
        roleFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        roleFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        
        local title = roleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -12)
        title:SetText("Group Roles")
        
        local exitButton = CreateFrame("Button", nil, roleFrame, "UIPanelCloseButton")
        exitButton:SetPoint("TOPRIGHT", 2, 0)
        exitButton:SetScript("OnClick", function()
            roleFrame:Hide()
        end)
        
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
        
        local columns = {
            {
                title = "Tanks", 
                data = roleData.tanks, 
                icon = "Interface\\Icons\\Ability_Defend",
                xOffset = 20
            },
            {
                title = "Healers", 
                data = roleData.healers, 
                icon = "Interface\\Icons\\Spell_Nature_HealingWaveGreater",
                xOffset = 20 + columnWidth
            },
            {
                title = "DPS", 
                data = roleData.dps, 
                icon = "Interface\\Icons\\INV_Sword_27",
                xOffset = 20 + (columnWidth * 2)
            }
        }
        
        for _, col in ipairs(columns) do
            local iconTexture = roleFrame:CreateTexture(nil, "ARTWORK")
            iconTexture:SetSize(20, 20)
            iconTexture:SetPoint("TOPLEFT", col.xOffset, -40)
            iconTexture:SetTexture(col.icon)
            
            local header = roleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            header:SetPoint("TOPLEFT", col.xOffset + 25, -40)
            header:SetText(col.title .. ":")
            header:SetTextColor(1, 0.82, 0)
            
            if #col.data == 0 then
                local noneText = roleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                noneText:SetPoint("TOPLEFT", col.xOffset + 20, -65)
                noneText:SetText("None")
                noneText:SetTextColor(0.5, 0.5, 0.5)
            else
                for i, playerName in ipairs(col.data) do
                    local btn = CreateFrame("Button", nil, roleFrame)
                    btn:SetSize(170, 20)
                    btn:SetPoint("TOPLEFT", col.xOffset, -65 - ((i-1) * 25))
                    
                    local playerClass = GetPlayerClass(playerName)
                    if playerClass and CLASS_ICON_TCOORDS[playerClass] then
                        local classIcon = btn:CreateTexture(nil, "ARTWORK")
                        classIcon:SetSize(16, 16)
                        classIcon:SetPoint("LEFT", 0, 0)
                        classIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
                        classIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[playerClass]))
                    end
                    
                    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    btn.text:SetPoint("LEFT", 20, 0)
                    btn.text:SetText(playerName)
                    btn.text:SetJustifyH("LEFT")
                    
                    btn:SetScript("OnClick", function()
                        ShowRoleChangePrompt(playerName)
                    end)
                    
                    btn:SetScript("OnEnter", function(self)
                        self.text:SetTextColor(1, 1, 1)
                    end)
                    
                    btn:SetScript("OnLeave", function(self)
                        self.text:SetTextColor(1, 0.82, 0)
                    end)
                end
            end
        end
        
        tinsert(UISpecialFrames, "ShadowRoleManagementFrame")
        roleFrame:Show()
    end

    function ShowRoleChangePrompt(shadowName)
        StaticPopupDialogs["ROLE_CHANGE_WARNING"] = {
            text = "Do you want to change the role for " .. shadowName .. "?\n\nWARNING: Roles are supposed to come from talents and should only be changed manually if needed.",
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
        
        local selectionFrame = CreateFrame("Frame", "ShadowRoleSelectionFrame", UIParent)
        selectionFrame:SetSize(400, 250)
        selectionFrame:SetPoint("CENTER")
        selectionFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        selectionFrame:SetFrameLevel(110)
        
        selectionFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        selectionFrame:SetBackdropColor(0, 0, 0, 1)
        
        selectionFrame:SetMovable(true)
        selectionFrame:EnableMouse(true)
        selectionFrame:RegisterForDrag("LeftButton")
        selectionFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        selectionFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        
        local title = selectionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -12)
        title:SetText("What role do you want to assign to \nshadow " .. shadowName .. "?")
        
        local exitButton = CreateFrame("Button", nil, selectionFrame, "UIPanelCloseButton")
        exitButton:SetPoint("TOPRIGHT", 2, 0)
        exitButton:SetScript("OnClick", function()
            selectionFrame:Hide()
        end)
        
        local roles = {
            {
                name = "Tank",
                icon = "Ability_Warrior_DefensiveStance",
                command = "co +tank,+tank assist,+tank face,+bear,-heal,-healer dps,-dps assist,-cat"
            },
            {
                name = "Healer",
                icon = "Spell_Holy_FlashHeal",
                command = function()
                    local healerDpsBtn = _G["BotControlBarButton6"]
                    local healerDpsEnabled = healerDpsBtn and healerDpsBtn.state
                    
                    if healerDpsEnabled then
                        return "co +heal,+healer dps,-tank,-tank assist,-tank face,-bear,-dps assist,-cat"
                    else
                        return "co +heal,-healer dps,-tank,-tank assist,-tank face,-bear,-dps assist,-cat"
                    end
                end
            },
            {
                name = "DPS",
                icon = "Ability_DualWield",
                command = "co +dps,+dps assist,-tank,-tank assist,-tank face,-bear,-heal,-healer dps,-cat"
            }
        }
        
        for i, role in ipairs(roles) do
            local btn = CreateFrame("Button", nil, selectionFrame)
            btn:SetSize(200, 50)
            btn:SetPoint("TOP", 0, -60 - ((i-1) * 60))
            
            btn.icon = btn:CreateTexture(nil, "ARTWORK")
            btn.icon:SetSize(32, 32)
            btn.icon:SetPoint("LEFT", 10, 0)
            btn.icon:SetTexture("Interface\\Icons\\" .. role.icon)
            
            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            btn.text:SetPoint("LEFT", btn.icon, "RIGHT", 10, 0)
            btn.text:SetText(role.name)
            
            btn:SetScript("OnClick", function()
                local cmd = type(role.command) == "function" and role.command() or role.command
                SendThrottledChatMessage(cmd, "WHISPER", nil, shadowName)
                print("Set " .. shadowName .. " to role: " .. role.name)
                selectionFrame:Hide()
                ShadowRoleManagementFrame:Hide()
            end)
            
            btn:SetScript("OnEnter", function(self)
                self.text:SetTextColor(1, 1, 1)
            end)
            
            btn:SetScript("OnLeave", function(self)
                self.text:SetTextColor(1, 0.82, 0)
            end)
        end
        
        tinsert(UISpecialFrames, "ShadowRoleSelectionFrame")
        selectionFrame:Show()
    end

    function ShowTalentManagementPrompt()
        if _G["ShadowTalentSelectionFrame"] then
            _G["ShadowTalentSelectionFrame"]:Show()
            return
        end
        local matches = {}
        for name, _ in pairs(cachedNames) do
            table.insert(matches, name)
        end
        
        if #matches == 0 then
            return
        end
        
        local selectionFrame = CreateFrame("Frame", "ShadowTalentSelectionFrame", UIParent)
        selectionFrame:SetSize(400, 100 + (#matches * 30))
        selectionFrame:SetPoint("CENTER")
        selectionFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        selectionFrame:SetMovable(true)
        selectionFrame:EnableMouse(true)
        selectionFrame:RegisterForDrag("LeftButton")
        selectionFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        selectionFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        
        selectionFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        selectionFrame:SetBackdropColor(0, 0, 0, 1)
        
        local title = selectionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", 0, -20)
        title:SetText("Which shadow's talents do you want to manage?")
        
        for i, name in ipairs(matches) do
            local btn = CreateFrame("Button", nil, selectionFrame)
            btn:SetSize(360, 25)
            btn:SetPoint("TOP", 0, -50 - ((i-1) * 30))
            
            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            btn.text:SetPoint("CENTER")
            btn.text:SetText(name)
            
            btn:SetScript("OnClick", function()
                ShowTalentManagementWindow(name)
                selectionFrame:Hide()
            end)
            
            btn:SetScript("OnEnter", function(self)
                self.text:SetTextColor(1, 1, 1)
            end)
            
            btn:SetScript("OnLeave", function(self)
                self.text:SetTextColor(1, 0.82, 0)
            end)
        end
        
        local exitButton = CreateFrame("Button", nil, selectionFrame, "UIPanelCloseButton")
        exitButton:SetPoint("TOPRIGHT", 2, 0)
        exitButton:SetScript("OnClick", function()
            selectionFrame:Hide()
        end)
        
        tinsert(UISpecialFrames, "ShadowTalentSelectionFrame")
        selectionFrame:Show()
    end

    function ShowTalentManagementWindow(shadowName)
        if talentFrame and talentFrame:IsShown() then
            return
        elseif talentFrame and not talentFrame:IsShown() then
            talentFrame:Show()
            return
        end
        
        talentFrame = CreateFrame("Frame", "ShadowTalentManagementFrame", UIParent)
        talentFrame:SetSize(400, 300)
        talentFrame:SetPoint("CENTER")
        talentFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        talentFrame:SetMovable(true)
        talentFrame:EnableMouse(true)
        talentFrame:RegisterForDrag("LeftButton")
        talentFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        talentFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        
        talentFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        talentFrame:SetBackdropColor(0, 0, 0, 1)
        
        local title = talentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -12)
        title:SetText("Talent Management: " .. shadowName)
        
        talentFrame:SetMovable(true)
        talentFrame:EnableMouse(true)
        talentFrame:RegisterForDrag("LeftButton")
        talentFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        talentFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        
        local exitButton = CreateFrame("Button", nil, talentFrame, "UIPanelCloseButton")
        exitButton:SetPoint("TOPRIGHT", 2, 0)
        exitButton:SetScript("OnClick", function()
            talentFrame:Hide()
        end)
        
        local buttons = {
            {
                name = "Show Active Talents",
                icon = "Ability_Marksmanship",
                yOffset = -60,
                onClick = function()
                    ShowActiveTalents(shadowName)
                end
            },
            {
                name = "Change Talent Set",
                icon = "ability_dualwield",
                yOffset = -120,
                onClick = function()
                    if not talentFrame.talentSet then talentFrame.talentSet = 1 end
                    
                    local responseFrame = CreateFrame("Frame")
                    responseFrame:RegisterEvent("CHAT_MSG_WHISPER")
                    responseFrame:SetScript("OnEvent", function(self, event, msg, sender)
                        if sender == shadowName and (msg:match("primary talents") or msg:match("secondary talents")) then
                            StaticPopupDialogs["TALENT_SWITCH_CONFIRM"] = {
                                text = shadowName .. ": " .. msg,
                                button1 = "OK",
                                timeout = 0,
                                whileDead = true,
                                hideOnEscape = true,
                                preferredIndex = 3,
                            }
                            StaticPopup_Show("TALENT_SWITCH_CONFIRM")
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
                    
                    SendThrottledChatMessage("talents switch " .. talentFrame.talentSet, "WHISPER", nil, shadowName)
                    talentFrame.talentSet = 3 - talentFrame.talentSet
                end
            },
            {
                name = "Auto Pick Talents",
                icon = "ability_shootwand",
                yOffset = -180,
                onClick = function()
                    local responseFrame = CreateFrame("Frame")
                    responseFrame:RegisterEvent("CHAT_MSG_WHISPER")
                    responseFrame:SetScript("OnEvent", function(self, event, msg, sender)
                        if sender == shadowName and msg:match("Auto pick talents") then
                            StaticPopupDialogs["AUTOPICK_CONFIRM"] = {
                                text = shadowName .. " has auto picked their talents.",
                                button1 = "OK",
                                timeout = 0,
                                whileDead = true,
                                hideOnEscape = true,
                                preferredIndex = 3,
                            }
                            StaticPopup_Show("AUTOPICK_CONFIRM")
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
                    
                    SendThrottledChatMessage("talents autopick", "WHISPER", nil, shadowName)
                end
            },
            {
                name = "Respec",
                icon = "ability_dualwieldspecialization",
                yOffset = -240,
                onClick = function()
                    ShowRespecWindow(shadowName)
                end
            }
        }
        
        for _, btnInfo in ipairs(buttons) do
            local btn = CreateFrame("Button", nil, talentFrame)
            btn:SetSize(300, 40)
            btn:SetPoint("TOP", 0, btnInfo.yOffset)
            
            btn.icon = btn:CreateTexture(nil, "ARTWORK")
            btn.icon:SetSize(32, 32)
            btn.icon:SetPoint("LEFT", 10, 0)
            btn.icon:SetTexture("Interface\\Icons\\" .. btnInfo.icon)
            
            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            btn.text:SetPoint("LEFT", btn.icon, "RIGHT", 10, 0)
            btn.text:SetText(btnInfo.name)
            btn.text:SetJustifyH("LEFT")
            
            btn:SetScript("OnClick", btnInfo.onClick)
            
            btn:SetScript("OnEnter", function(self)
                self.text:SetTextColor(1, 1, 1)
            end)
            
            btn:SetScript("OnLeave", function(self)
                self.text:SetTextColor(1, 0.82, 0)
            end)
        end
        
        tinsert(UISpecialFrames, "ShadowTalentManagementFrame")
        talentFrame:Show()
    end

    function ShowActiveTalents(shadowName)
        if _G["ShadowTalentResponseFrame"] then
            _G["ShadowTalentResponseFrame"]:Hide()
        end
        local talentResponse = nil
        
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
        waitFrame.timeElapsed = 0
        waitFrame:SetScript("OnUpdate", function(self, elapsed)
            self.timeElapsed = self.timeElapsed + elapsed
            
            if talentResponse then
                ShowTalentResponsePopup(talentResponse)
                responseFrame:UnregisterEvent("CHAT_MSG_WHISPER")
                self:SetScript("OnUpdate", nil)
            elseif self.timeElapsed >= 5 then
                print("No response received from " .. shadowName)
                responseFrame:UnregisterEvent("CHAT_MSG_WHISPER")
                self:SetScript("OnUpdate", nil)
            end
        end)
    end

    function ShowTalentResponsePopup(responseText)
        if _G["ShadowRespecFrame"] then
            _G["ShadowRespecFrame"]:Hide()
        end
        local popup = CreateFrame("Frame", "ShadowTalentResponseFrame", UIParent)
        popup:SetSize(500, 150)
        popup:SetPoint("CENTER")
        popup:SetFrameStrata("TOOLTIP")
        
        popup:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        popup:SetBackdropColor(0, 0, 0, 1)
        
        popup:SetMovable(true)
        popup:EnableMouse(true)
        popup:RegisterForDrag("LeftButton")
        popup:SetScript("OnDragStart", function(self) self:StartMoving() end)
        popup:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        
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
        
        local exitButton = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
        exitButton:SetPoint("TOPRIGHT", 2, 0)
        exitButton:SetScript("OnClick", function()
            popup:Hide()
        end)
        
        tinsert(UISpecialFrames, "ShadowTalentResponseFrame")
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
        waitFrame.timeElapsed = 0
        waitFrame:SetScript("OnUpdate", function(self, elapsed)
            self.timeElapsed = self.timeElapsed + elapsed
            
            if #respecResponse > 0 and lastReceiveTime > 0 and (GetTime() - lastReceiveTime) >= 0.5 then
                ShowRespecSelectionPopup(shadowName, respecResponse)
                responseFrame:UnregisterEvent("CHAT_MSG_WHISPER")
                self:SetScript("OnUpdate", nil)
            elseif self.timeElapsed >= 5 then
                if #respecResponse == 0 then
                    print("No talent specs available for " .. shadowName)
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
        local popup = CreateFrame("Frame", "ShadowRespecFrame", UIParent)
        popup:SetSize(400, 100 + (#specList * 30))
        popup:SetPoint("CENTER")
        popup:SetFrameStrata("TOOLTIP")
        popup:SetMovable(true)
        popup:EnableMouse(true)
        popup:RegisterForDrag("LeftButton")
        popup:SetScript("OnDragStart", function(self) self:StartMoving() end)
        popup:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        
        popup:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        popup:SetBackdropColor(0, 0, 0, 1)
        
        local title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -12)
        title:SetText("Select Talent Spec for " .. shadowName)
        
        popup:SetMovable(true)
        popup:EnableMouse(true)
        popup:RegisterForDrag("LeftButton")
        popup:SetScript("OnDragStart", function(self) self:StartMoving() end)
        popup:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        
        for i, specLine in ipairs(specList) do
            local specName = specLine:match("%d+%.%s*(.-)%s*%(")
            if not specName then
                specName = specLine:match("%d+%.%s*(.*)")
            end
            
            local btn = CreateFrame("Button", nil, popup)
            btn:SetSize(360, 25)
            btn:SetPoint("TOP", 0, -50 - ((i-1) * 30))
            
            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            btn.text:SetPoint("CENTER")
            btn.text:SetText(specLine)
            
            btn:SetScript("OnClick", function()
                if specName then
                    SendThrottledChatMessage("talents spec " .. specName, "WHISPER", nil, shadowName)
                end
                popup:Hide()
            end)
            
            btn:SetScript("OnEnter", function(self)
                self.text:SetTextColor(1, 1, 1)
            end)
            
            btn:SetScript("OnLeave", function(self)
                self.text:SetTextColor(1, 0.82, 0)
            end)
        end
        
        local exitButton = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
        exitButton:SetPoint("TOPRIGHT", 2, 0)
        exitButton:SetScript("OnClick", function()
            popup:Hide()
        end)
        
        tinsert(UISpecialFrames, "ShadowRespecFrame")
        popup:Show()
    end

    function ShowGroupSetupWindow()
        if setupFrame and not setupFrame:IsShown() then
            setupFrame:Show()
            return
        end
        
        if setupFrame and setupFrame:IsShown() then
            setupFrame:Hide()
            return
        end
        
        if setupFrame then
            return
        end
        
        setupFrame = CreateFrame("Frame", "ShadowGroupSetupFrame", UIParent)
        setupFrame:SetPoint("CENTER")
        setupFrame:SetFrameStrata("DIALOG")

        setupFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        setupFrame:SetBackdropColor(0, 0, 0, 1)

        local title = setupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -12)
        title:SetText("Group Setup")

        setupFrame:SetMovable(true)
        setupFrame:EnableMouse(true)
        setupFrame:RegisterForDrag("LeftButton")
        setupFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        setupFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

        local exitButton = CreateFrame("Button", nil, setupFrame, "UIPanelCloseButton")
        exitButton:SetPoint("TOPRIGHT", 2, 0)
        exitButton:SetScript("OnClick", function()
            setupFrame:Hide()
        end)

        local function CreateSetupButton(text, icon, xOffset, yOffset, onClick)
            local btn = CreateFrame("Button", nil, setupFrame)
            btn:SetSize(140, 40)
            btn:SetPoint("TOPLEFT", setupFrame, "TOPLEFT", xOffset, yOffset)

            btn.icon = btn:CreateTexture(nil, "ARTWORK")
            btn.icon:SetSize(32, 32)
            btn.icon:SetPoint("LEFT", 5, 0)
            btn.icon:SetTexture("Interface\\Icons\\"..icon)

            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            btn.text:SetPoint("LEFT", btn.icon, "RIGHT", 5, 0)
            btn.text:SetText(text)
            btn.text:SetJustifyH("LEFT")

			btn:SetScript("OnClick", function()
				AIO.Handle("ShadowsCache", "RequestCache")
				onClick()
			end)
    
            btn:SetScript("OnEnter", function(self)
                self.text:SetTextColor(1, 1, 1)
            end)

            btn:SetScript("OnLeave", function(self)
                self.text:SetTextColor(1, 0.82, 0)
            end)

            return btn
        end

        local function CenterButtons(buttons, yOffset, frameWidth)
            local totalWidth = 0
            local spacing = 10
            for i, btn in ipairs(buttons) do
                totalWidth = totalWidth + btn:GetWidth()
                if i < #buttons then
                    totalWidth = totalWidth + spacing
                end
            end
            local startX = (frameWidth - totalWidth) / 2
            for i, btn in ipairs(buttons) do
                btn:ClearAllPoints()
                btn:SetPoint("TOPLEFT", setupFrame, "TOPLEFT", startX, yOffset)
                startX = startX + btn:GetWidth() + spacing
            end
        end

        local currentY = -50
        local frameWidth = 500
        local sectionSpacing = 40
        local lineColor = {0.5, 0.5, 0.5, 1}

        local topLine1 = setupFrame:CreateTexture(nil, "ARTWORK")
        topLine1:SetTexture(1, 1, 1)
        topLine1:SetVertexColor(lineColor[1], lineColor[2], lineColor[3], lineColor[4])
        topLine1:SetHeight(1)
        topLine1:SetPoint("TOPLEFT", setupFrame, "TOPLEFT", 20, currentY)
        topLine1:SetPoint("TOPRIGHT", setupFrame, "TOPRIGHT", -20, currentY)

        currentY = currentY - 10

        local row1Label = setupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row1Label:SetPoint("TOP", setupFrame, "TOP", 0, currentY)
        row1Label:SetText("General Setup:")

        currentY = currentY - 30

        local row1 = {}
        table.insert(row1, CreateSetupButton("Shadows Menu", "Spell_Shadow_AntiShadow", 0, 0, function()
            SendThrottledChatMessage(".shadowsmenu", "GUILD")
        end))
        table.insert(row1, CreateSetupButton("System Settings", "INV_Misc_Gear_01", 0, 0, function()
            InterfaceOptionsFrame_Show()
            ShowShadowsSettingsPanel()
            setupFrame:Hide()
        end))
        table.insert(row1, CreateSetupButton("Shortcuts", "INV_Misc_Book_09", 0, 0, function()
            ShowShadowsShortcutsMenu()
            setupFrame:Hide()
        end))
        CenterButtons(row1, currentY, frameWidth)

        currentY = currentY - 50

        currentY = currentY - sectionSpacing

        local topLine2 = setupFrame:CreateTexture(nil, "ARTWORK")
        topLine2:SetTexture(1, 1, 1)
        topLine2:SetVertexColor(lineColor[1], lineColor[2], lineColor[3], lineColor[4])
        topLine2:SetHeight(1)
        topLine2:SetPoint("TOPLEFT", setupFrame, "TOPLEFT", 20, currentY)
        topLine2:SetPoint("TOPRIGHT", setupFrame, "TOPRIGHT", -20, currentY)

        currentY = currentY - 10

        local row2Label = setupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row2Label:SetPoint("TOP", setupFrame, "TOP", 0, currentY)
        row2Label:SetText("Group Loadout:")

        currentY = currentY - 30

        local row2 = {}
        table.insert(row2, CreateSetupButton("Talents", "Ability_Marksmanship", 0, 0, function()
            ShowTalentManagementPrompt()
        end))
        table.insert(row2, CreateSetupButton("Role", "Ability_Hunter_MasterMarksman", 0, 0, function()
            ShowRoleManagementWindow()
        end))
        CenterButtons(row2, currentY, frameWidth)

        currentY = currentY - 50

        currentY = currentY - sectionSpacing

        local topLine3 = setupFrame:CreateTexture(nil, "ARTWORK")
        topLine3:SetTexture(1, 1, 1)
        topLine3:SetVertexColor(lineColor[1], lineColor[2], lineColor[3], lineColor[4])
        topLine3:SetHeight(1)
        topLine3:SetPoint("TOPLEFT", setupFrame, "TOPLEFT", 20, currentY)
        topLine3:SetPoint("TOPRIGHT", setupFrame, "TOPRIGHT", -20, currentY)

        currentY = currentY - 10

        local row3Label = setupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row3Label:SetPoint("TOP", setupFrame, "TOP", 0, currentY)
        row3Label:SetText("Class Settings:")

        currentY = currentY - 30

        local row3 = {}
        table.insert(row3, CreateSetupButton("Paladin", "INV_Helmet_06", 0, 0, function()
            ShowPaladinSettings()
        end))
        table.insert(row3, CreateSetupButton("Shaman", "Spell_Nature_BloodLust", 0, 0, function()
            ShowShamanSettings()
        end))
        table.insert(row3, CreateSetupButton("Hunter", "INV_Weapon_Bow_07", 0, 0, function()
            ShowHunterSettings()
        end))
        CenterButtons(row3, currentY, frameWidth)

        currentY = currentY - 50

        local row4 = {}
        table.insert(row4, CreateSetupButton("Warlock", "Spell_Nature_FaerieFire", 0, 0, function()
            ShowWarlockSettings()
        end))
        table.insert(row4, CreateSetupButton("Priest", "INV_Staff_30", 0, 0, function()
            ShowPriestSettings()
        end))
        CenterButtons(row4, currentY, frameWidth)

        currentY = currentY - 50

        local frameHeight = math.abs(currentY) + 20
        setupFrame:SetSize(frameWidth, frameHeight)

        tinsert(UISpecialFrames, "ShadowGroupSetupFrame")
        setupFrame:Show()
    end
    
    function HasShadowClass(class)
        for name, cachedClass in pairs(cachedNames) do
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
        
        local selectionFrame = CreateFrame("Frame", "ShadowSelectionFrame", UIParent)
        selectionFrame:SetSize(300, 100 + (#matches * 30))
        selectionFrame:SetPoint("CENTER")
        selectionFrame:SetFrameStrata("DIALOG")
        
        selectionFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        selectionFrame:SetBackdropColor(0, 0, 0, 1)
        
        local title = selectionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", 0, -20)
        title:SetText("Which shadow do you add this strategy to?")
        
        for i, name in ipairs(matches) do
            local btn = CreateFrame("Button", nil, selectionFrame)
            btn:SetSize(260, 25)
            btn:SetPoint("TOP", 0, -50 - ((i-1) * 30))
            
            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            btn.text:SetPoint("CENTER")
            btn.text:SetText(name)
            
            btn:SetScript("OnClick", function()
                callback(name)
                selectionFrame:Hide()
            end)
            
            btn:SetScript("OnEnter", function(self)
                self.text:SetTextColor(1, 1, 1)
            end)
            
            btn:SetScript("OnLeave", function(self)
                self.text:SetTextColor(1, 0.82, 0)
            end)
        end
        
        local exitButton = CreateFrame("Button", nil, selectionFrame, "UIPanelCloseButton")
        exitButton:SetPoint("TOPRIGHT", 2, 0)
        exitButton:SetScript("OnClick", function()
            selectionFrame:Hide()
        end)
        
        tinsert(UISpecialFrames, "ShadowSelectionFrame")
        selectionFrame:Show()
    end

    local activeClassFrame = nil

    function ShowPaladinSettings()
        if activeClassFrame then
            activeClassFrame:Hide()
        end
        
        if paladinFrame then
            paladinFrame:Show()
            activeClassFrame = paladinFrame
            return
        end
        
        paladinFrame = CreateFrame("Frame", "ShadowPaladinSettingsFrame", UIParent)
        paladinFrame:SetSize(600, 550)
        paladinFrame:SetPoint("CENTER")
        paladinFrame:SetFrameStrata("FULLSCREEN")

        paladinFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        paladinFrame:SetBackdropColor(0, 0, 0, 1)

        local title = paladinFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -12)
        title:SetText("Paladin Settings")

        paladinFrame:SetMovable(true)
        paladinFrame:EnableMouse(true)
        paladinFrame:RegisterForDrag("LeftButton")
        paladinFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        paladinFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

        local exitButton = CreateFrame("Button", nil, paladinFrame, "UIPanelCloseButton")
        exitButton:SetPoint("TOPRIGHT", 2, 0)
        exitButton:SetScript("OnClick", function()
            paladinFrame:Hide()
            activeClassFrame = nil
        end)

        local function CenterColumn(buttons, xOffset, frameWidth)
            local colWidth = 280
            local startX = xOffset + (colWidth - buttons[1]:GetWidth()) / 2
            for i, btn in ipairs(buttons) do
                btn:ClearAllPoints()
                btn:SetPoint("TOPLEFT", startX, -60 - ((i-1) * 70))
            end
        end

        local blessingsLabel = paladinFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
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
            local btn = CreateFrame("Button", nil, paladinFrame)
            btn:SetSize(120, 60)
            btn:SetPoint("TOPLEFT", 30, -60 - ((i-1) * 70))

            btn.icon = btn:CreateTexture(nil, "ARTWORK")
            btn.icon:SetSize(32, 32)
            btn.icon:SetPoint("TOP", 0, -5)
            btn.icon:SetTexture("Interface\\Icons\\"..blessing.icon)

            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            btn.text:SetPoint("TOP", btn.icon, "BOTTOM", 0, -5)
            btn.text:SetText(blessing.name)

            btn:SetScript("OnClick", function()
                if not HasShadowClass("PALADIN") then print("No paladin shadow found.") return end
                
                PromptShadowSelection("PALADIN", function(targetName)
                    local cmd = "co +" .. blessing.strategy
                    for _, other in ipairs(blessing.others) do
                        cmd = cmd .. ",-" .. other
                    end
                    SendThrottledChatMessage(cmd, "WHISPER", nil, targetName)
                    print("Shadow " .. targetName .. " has enabled " .. blessing.name)
                end)
            end)

            btn:SetScript("OnEnter", function(self)
                self.text:SetTextColor(1, 1, 1)
            end)

            btn:SetScript("OnLeave", function(self)
                self.text:SetTextColor(1, 0.82, 0)
            end)

            table.insert(blessingButtons, btn)
        end

        CenterColumn(blessingButtons, 10, 280)

        local aurasLabel = paladinFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
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
            local btn = CreateFrame("Button", nil, paladinFrame)
            btn:SetSize(140, 60)
            btn:SetPoint("TOPLEFT", 310, -60 - ((i-1) * 70))

            btn.icon = btn:CreateTexture(nil, "ARTWORK")
            btn.icon:SetSize(32, 32)
            btn.icon:SetPoint("TOP", 0, -5)
            btn.icon:SetTexture("Interface\\Icons\\"..aura.icon)

            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            btn.text:SetPoint("TOP", btn.icon, "BOTTOM", 0, -5)
            btn.text:SetText(aura.name)

            btn:SetScript("OnClick", function()
                if not HasShadowClass("PALADIN") then print("No paladin shadow found.") return end
                
                PromptShadowSelection("PALADIN", function(targetName)
                    local cmd = "+" .. aura.strategy
                    for _, other in ipairs(aura.others) do
                        cmd = cmd .. ",-" .. other
                    end
                    SendThrottledChatMessage("co " .. cmd, "WHISPER", nil, targetName)
                    SendThrottledChatMessage("nc " .. cmd, "WHISPER", nil, targetName)
                    print("Shadow " .. targetName .. " has enabled " .. aura.name)
                end)
            end)

            btn:SetScript("OnEnter", function(self)
                self.text:SetTextColor(1, 1, 1)
            end)

            btn:SetScript("OnLeave", function(self)
                self.text:SetTextColor(1, 0.82, 0)
            end)

            table.insert(auraButtons, btn)
        end

        CenterColumn(auraButtons, 300, 280)

        tinsert(UISpecialFrames, "ShadowPaladinSettingsFrame")
        activeClassFrame = paladinFrame
        paladinFrame:Show()
    end

    function ShowHunterSettings()
        if activeClassFrame then
            activeClassFrame:Hide()
        end
        
        if hunterFrame then
            hunterFrame:Show()
            activeClassFrame = hunterFrame
            return
        end
        
        hunterFrame = CreateFrame("Frame", "ShadowHunterSettingsFrame", UIParent)
        hunterFrame:SetSize(400, 350)
        hunterFrame:SetPoint("CENTER")
        hunterFrame:SetFrameStrata("FULLSCREEN")

        hunterFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        hunterFrame:SetBackdropColor(0, 0, 0, 1)

        local title = hunterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -12)
        title:SetText("Hunter Aspect Settings")

        hunterFrame:SetMovable(true)
        hunterFrame:EnableMouse(true)
        hunterFrame:RegisterForDrag("LeftButton")
        hunterFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        hunterFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

        local exitButton = CreateFrame("Button", nil, hunterFrame, "UIPanelCloseButton")
        exitButton:SetPoint("TOPRIGHT", 2, 0)
        exitButton:SetScript("OnClick", function()
            hunterFrame:Hide()
            activeClassFrame = nil
        end)

        local aspectsLabel = hunterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        aspectsLabel:SetPoint("TOP", 0, -40)
        aspectsLabel:SetText("Aspect Strategies:")

        local aspects = {
            {name = "Hawk/Dragonhawk", strategy = "bdps", others = {"bspeed", "bmana", "rnature"}, icon = "ability_hunter_pet_dragonhawk"},
            {name = "Pack", strategy = "bspeed", others = {"bdps", "bmana", "rnature"}, icon = "Ability_Mount_WhiteTiger"},
            {name = "Viper", strategy = "bmana", others = {"bdps", "bspeed", "rnature"}, icon = "Ability_Hunter_AspectOfTheViper"},
            {name = "Wild", strategy = "rnature", others = {"bdps", "bspeed", "bmana"}, icon = "Spell_Nature_ProtectionformNature"},
        }

        local function CenterButtons(buttons, frameWidth)
            local colWidth = frameWidth - 40
            for i, btn in ipairs(buttons) do
                local startX = (frameWidth - btn:GetWidth()) / 2
                btn:ClearAllPoints()
                btn:SetPoint("TOPLEFT", startX, -70 - ((i-1) * 70))
            end
        end

        local aspectButtons = {}
        for i, aspect in ipairs(aspects) do
            local btn = CreateFrame("Button", nil, hunterFrame)
            btn:SetSize(180, 60)
            btn:SetPoint("TOPLEFT", 30, -70 - ((i-1) * 70))

            btn.icon = btn:CreateTexture(nil, "ARTWORK")
            btn.icon:SetSize(32, 32)
            btn.icon:SetPoint("TOP", 0, -5)
            btn.icon:SetTexture("Interface\\Icons\\"..aspect.icon)

            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            btn.text:SetPoint("TOP", btn.icon, "BOTTOM", 0, -5)
            btn.text:SetText(aspect.name)

            btn:SetScript("OnClick", function()
                if not HasShadowClass("HUNTER") then print("No hunter shadow found.") return end
                
                PromptShadowSelection("HUNTER", function(targetName)
                    local cmd = "co +" .. aspect.strategy
                    for _, other in ipairs(aspect.others) do
                        cmd = cmd .. ",-" .. other
                    end
                    SendThrottledChatMessage(cmd, "WHISPER", nil, targetName)
                    print("Shadow " .. targetName .. " has enabled " .. aspect.name)
                end)
            end)

            btn:SetScript("OnEnter", function(self)
                self.text:SetTextColor(1, 1, 1)
            end)

            btn:SetScript("OnLeave", function(self)
                self.text:SetTextColor(1, 0.82, 0)
            end)

            table.insert(aspectButtons, btn)
        end

        CenterButtons(aspectButtons, 400)

        tinsert(UISpecialFrames, "ShadowHunterSettingsFrame")
        activeClassFrame = hunterFrame
        hunterFrame:Show()
    end

    function ShowWarlockSettings()
        if activeClassFrame then
            activeClassFrame:Hide()
        end
        
        if warlockFrame then
            warlockFrame:Show()
            activeClassFrame = warlockFrame
            return
        end
        
        warlockFrame = CreateFrame("Frame", "ShadowWarlockSettingsFrame", UIParent)
        warlockFrame:SetSize(450, 450)
        warlockFrame:SetPoint("CENTER")
        warlockFrame:SetFrameStrata("FULLSCREEN")

        warlockFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        warlockFrame:SetBackdropColor(0, 0, 0, 1)

        local title = warlockFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -12)
        title:SetText("Warlock Pet Settings")

        warlockFrame:SetMovable(true)
        warlockFrame:EnableMouse(true)
        warlockFrame:RegisterForDrag("LeftButton")
        warlockFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        warlockFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

        local exitButton = CreateFrame("Button", nil, warlockFrame, "UIPanelCloseButton")
        exitButton:SetPoint("TOPRIGHT", 2, 0)
        exitButton:SetScript("OnClick", function()
            warlockFrame:Hide()
            activeClassFrame = nil
        end)

        local petsLabel = warlockFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        petsLabel:SetPoint("TOP", 0, -40)
        petsLabel:SetText("Pet Strategies:")
        
        local noteLabel = warlockFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        noteLabel:SetPoint("TOP", 0, -55)
        noteLabel:SetText("(Defaults: Affliction=Felhunter, Demonology=Felguard, Destruction=Imp)")
        noteLabel:SetTextColor(0.7, 0.7, 0.7)

        local pets = {
            {name = "Imp", spellId = 688, icon = "Spell_Shadow_Summonimp"},
            {name = "Voidwalker", spellId = 697, icon = "Spell_Shadow_SummonVoidWalker"},
            {name = "Succubus", spellId = 712, icon = "Spell_Shadow_SummonSuccubus"},
            {name = "Felhunter", spellId = 691, icon = "Spell_Shadow_SummonFelHunter"},
            {name = "Felguard", spellId = 30146, icon = "Spell_Shadow_SummonFelGuard"},
        }

        local function CenterButtons(buttons, frameWidth)
            for i, btn in ipairs(buttons) do
                local startX = (frameWidth - btn:GetWidth()) / 2
                btn:ClearAllPoints()
                btn:SetPoint("TOPLEFT", startX, -75 - ((i-1) * 70))
            end
        end

        local petButtons = {}
        for i, pet in ipairs(pets) do
            local btn = CreateFrame("Button", nil, warlockFrame)
            btn:SetSize(150, 60)
            btn:SetPoint("TOPLEFT", 30, -75 - ((i-1) * 70))

            btn.icon = btn:CreateTexture(nil, "ARTWORK")
            btn.icon:SetSize(32, 32)
            btn.icon:SetPoint("TOP", 0, -5)
            btn.icon:SetTexture("Interface\\Icons\\"..pet.icon)

            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            btn.text:SetPoint("TOP", btn.icon, "BOTTOM", 0, -5)
            btn.text:SetText(pet.name)

            btn:SetScript("OnClick", function()
                if not HasShadowClass("WARLOCK") then print("No warlock shadow found.") return end
                
                PromptShadowSelection("WARLOCK", function(targetName)
                    local unitId = nil
                    if UnitName("player") == targetName then
                        unitId = "player"
                    else
                        for j = 1, 4 do
                            if UnitName("party"..j) == targetName then
                                unitId = "party"..j
                                break
                            end
                        end
                        if not unitId then
                            for j = 1, 40 do
                                if UnitName("raid"..j) == targetName then
                                    unitId = "raid"..j
                                    break
                                end
                            end
                        end
                    end
                    
                    local hasMasterDemo = false
                    if unitId then
                        local masterDemoIds = {23785, 23822, 23823, 23824, 23825}
                        for k = 1, 40 do
                            local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellId = UnitAura(unitId, k, "HELPFUL")
                            if not name then break end
                            for _, buffId in ipairs(masterDemoIds) do
                                if spellId == buffId then
                                    hasMasterDemo = true
                                    break
                                end
                            end
                            if hasMasterDemo then break end
                        end
                    end
                    
                    local excludeFelguard = (pet.strategy == "felguard" and not hasMasterDemo)
                    if excludeFelguard then
                        print("This shadow cannot summon Felguard.")
                        return
                    end
                    
                    local cmd = "co +" .. pet.strategy
                    for _, other in ipairs(pet.others) do
                        if other == "felguard" and not hasMasterDemo then
                        else
                            cmd = cmd .. ",-" .. other
                        end
                    end
                    SendThrottledChatMessage(cmd, "WHISPER", nil, targetName)
                    print("Shadow " .. targetName .. " has enabled " .. pet.name)
                end)
            end)

            btn:SetScript("OnEnter", function(self)
                self.text:SetTextColor(1, 1, 1)
            end)

            btn:SetScript("OnLeave", function(self)
                self.text:SetTextColor(1, 0.82, 0)
            end)

            table.insert(petButtons, btn)
        end

        CenterButtons(petButtons, 450)

        tinsert(UISpecialFrames, "ShadowWarlockSettingsFrame")
        activeClassFrame = warlockFrame
        warlockFrame:Show()
    end

    local priestShadowProtEnabled = false

    function ShowPriestSettings()
        if activeClassFrame then
            activeClassFrame:Hide()
        end
        
        if priestFrame then
            priestFrame:Show()
            activeClassFrame = priestFrame
            return
        end
        
        priestFrame = CreateFrame("Frame", "ShadowPriestSettingsFrame", UIParent)
        priestFrame:SetSize(400, 200)
        priestFrame:SetPoint("CENTER")
        priestFrame:SetFrameStrata("FULLSCREEN")

        priestFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        priestFrame:SetBackdropColor(0, 0, 0, 1)

        local title = priestFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -12)
        title:SetText("Priest Buff Settings")

        priestFrame:SetMovable(true)
        priestFrame:EnableMouse(true)
        priestFrame:RegisterForDrag("LeftButton")
        priestFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        priestFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

        local exitButton = CreateFrame("Button", nil, priestFrame, "UIPanelCloseButton")
        exitButton:SetPoint("TOPRIGHT", 2, 0)
        exitButton:SetScript("OnClick", function()
            priestFrame:Hide()
            activeClassFrame = nil
        end)

        local buffsLabel = priestFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        buffsLabel:SetPoint("TOP", 0, -40)
        buffsLabel:SetText("Buff Strategies:")

        local btn = CreateFrame("Button", nil, priestFrame)
        btn:SetSize(150, 60)
        btn:SetPoint("TOP", 0, -80)

        btn.icon = btn:CreateTexture(nil, "ARTWORK")
        btn.icon:SetSize(32, 32)
        btn.icon:SetPoint("TOP", 0, -5)
        btn.icon:SetTexture("Interface\\Icons\\Spell_Shadow_AntiShadow")

        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.text:SetPoint("TOP", btn.icon, "BOTTOM", 0, -5)
        btn.text:SetText("Shadow Protection")

        btn.status = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.status:SetPoint("TOP", btn.text, "BOTTOM", 0, -5)
        btn.status:SetTextColor(1, 0, 0)
        btn.status:SetText("OFF")

        btn:SetScript("OnClick", function()
            if not HasShadowClass("PRIEST") then print("No priest shadow found.") return end
            
            PromptShadowSelection("PRIEST", function(targetName)
                if priestShadowProtEnabled then
                    SendThrottledChatMessage("co -rshadow", "WHISPER", nil, targetName)
                    priestShadowProtEnabled = false
                    btn.status:SetTextColor(1, 0, 0)
                    btn.status:SetText("OFF")
                    print("Shadow " .. targetName .. " has disabled Shadow Protection")
                else
                    SendThrottledChatMessage("co +rshadow", "WHISPER", nil, targetName)
                    priestShadowProtEnabled = true
                    btn.status:SetTextColor(0, 1, 0)
                    btn.status:SetText("ON")
                    print("Shadow " .. targetName .. " has enabled Shadow Protection")
                end
            end)
        end)

        btn:SetScript("OnEnter", function(self)
            self.text:SetTextColor(1, 1, 1)
        end)

        btn:SetScript("OnLeave", function(self)
            self.text:SetTextColor(1, 0.82, 0)
        end)

        tinsert(UISpecialFrames, "ShadowPriestSettingsFrame")
        activeClassFrame = priestFrame
        priestFrame:Show()
    end

    function ShowShamanSettings()
        if activeClassFrame then
            activeClassFrame:Hide()
        end
        
        if shamanFrame then
            shamanFrame:Show()
            activeClassFrame = shamanFrame
            return
        end
        
        shamanFrame = CreateFrame("Frame", "ShadowShamanSettingsFrame", UIParent)
        shamanFrame:SetSize(800, 430)
        shamanFrame:SetPoint("CENTER")
        shamanFrame:SetFrameStrata("FULLSCREEN")

        shamanFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        shamanFrame:SetBackdropColor(0, 0, 0, 1)

        local title = shamanFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -12)
        title:SetText("Shaman Totem Settings")

        shamanFrame:SetMovable(true)
        shamanFrame:EnableMouse(true)
        shamanFrame:RegisterForDrag("LeftButton")
        shamanFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        shamanFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

        local exitButton = CreateFrame("Button", nil, shamanFrame, "UIPanelCloseButton")
        exitButton:SetPoint("TOPRIGHT", 2, 0)
        exitButton:SetScript("OnClick", function()
            shamanFrame:Hide()
            activeClassFrame = nil
        end)

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
            }
        }

        local categories = {
            {name = "Water", type = "water", xOffset = 20},
            {name = "Earth", type = "earth", xOffset = 220},
            {name = "Fire", type = "fire", xOffset = 420},
            {name = "Air", type = "air", xOffset = 620}
        }

        for catIndex, category in ipairs(categories) do
            local label = shamanFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetPoint("TOP", shamanFrame, "TOPLEFT", category.xOffset + 75, -40)
            label:SetText(category.name .. ":")

            for i, totem in ipairs(totems[category.type]) do
                local btn = CreateFrame("Button", nil, shamanFrame)
                btn:SetSize(140, 60)
                btn:SetPoint("TOPLEFT", category.xOffset, -70 - ((i-1) * 70))

                btn.icon = btn:CreateTexture(nil, "ARTWORK")
                btn.icon:SetSize(32, 32)
                btn.icon:SetPoint("TOP", 0, -5)
                btn.icon:SetTexture("Interface\\Icons\\"..totem.icon)

                btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                btn.text:SetPoint("TOP", btn.icon, "BOTTOM", 0, -5)
                btn.text:SetText(totem.name)

                btn:SetScript("OnClick", function()
                    if not HasShadowClass("SHAMAN") then print("No shaman shadow found.") return end
                    
                    PromptShadowSelection("SHAMAN", function(targetName)
                        local cmd = "co +" .. totem.strategy
                        for _, other in ipairs(totem.others) do
                            cmd = cmd .. ",-" .. other
                        end
                        SendThrottledChatMessage(cmd, "WHISPER", nil, targetName)
                        print("Shadow " .. targetName .. " has enabled Totem: " .. totem.name)
                    end)
                end)

                btn:SetScript("OnEnter", function(self)
                    self.text:SetTextColor(1, 1, 1)
                end)

                btn:SetScript("OnLeave", function(self)
                    self.text:SetTextColor(1, 0.82, 0)
                end)
            end
        end

        tinsert(UISpecialFrames, "ShadowShamanSettingsFrame")
        activeClassFrame = shamanFrame
        shamanFrame:Show()
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
                for i, btnInfo in ipairs(frame.buttons) do
                    local button = _G["BotControlBarButton"..i]
                    if button and button.state then
                        if btnInfo.toggle then
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

    resetDetectionFrame:SetScript("OnEvent", function(self, event, msg, sender)
        if msg and msg:lower():match("ai was reset to defaults") and not self.waitingForReset then
            self.waitingForReset = true
            
            if not self.throttleFrame then
                self.throttleFrame = CreateFrame("Frame")
            end
            
            self.throttleFrame:SetScript("OnUpdate", function(frame, elapsed)
                frame.elapsed = (frame.elapsed or 0) + elapsed
                
                if frame.elapsed >= 2 then
                    ReapplyShadowSettings()
                    resetDetectionFrame.waitingForReset = false
                    frame.elapsed = 0
                    frame:SetScript("OnUpdate", nil)
                end
            end)
        end
    end)

    return frame
end

CreateBotControlBar()

BotControlBar:Hide()

---------------------------------------------------
-- Shadows bar keyboard shortcuts
---------------------------------------------------

ShadowShortcuts = {}

function ShowShadowsShortcutsMenu()
    if not ShadowShortcuts.configFrame then
        ShadowShortcuts.configFrame = ShadowShortcuts.CreateConfigWindow()
    end
    ShadowShortcuts.configFrame:Show()
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
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
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
        {text = "Button 10", buttonName = "BotControlBarButton10", action = "BOTCONTROLBAR_BUTTON10"}
    }

    ShadowShortcuts.configButtons = {}

    local lastButton
    for index, buttonInfo in ipairs(ShadowShortcuts.buttons) do
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
    tinsert(UISpecialFrames, "ShadowShortcutsConfig")
    
    return frame
end

function ShadowShortcuts.UpdateKeyTexts()
    for _, buttonInfo in ipairs(ShadowShortcuts.buttons) do
        local configButton = ShadowShortcuts.configButtons[buttonInfo.action]
        if configButton then
            local clickBinding = "CLICK "..buttonInfo.buttonName..":LeftButton"
            local foundKey = GetBindingKey(clickBinding)
            configButton.keyText:SetText(foundKey or "Not bound")
        end
    end
end

SLASH_SHADOWSHORTCUTS1 = "/shadowshortcuts"
SlashCmdList["SHADOWSHORTCUTS"] = function()
    ShowShadowsShortcutsMenu()
end

SLASH_SHADOW1 = "/shadow"
SlashCmdList["SHADOW"] = function()
   SendChatMessage(".shadowsmenu", "GUILD")
end

SLASH_SHADOW1 = "/shadowsmenu"
SlashCmdList["SHADOW"] = function()
   SendChatMessage(".shadowsmenu", "GUILD")
end

SLASH_SHADOWS2 = "/shadows"
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
            -- Close the dialog when ESC key is pressed
            if key == "ESCAPE" then
                StaticPopup_Hide("SHADOWSHORTCUTS_KEYBIND")
                return
            end
            
            -- Ignore certain modifier keys
            if key == "LSHIFT" or key == "RSHIFT" or key == "LCTRL" or key == "RCTRL" or key == "LALT" or key == "RALT" then
                return
            end
            
            local keyPressed = key
            if IsShiftKeyDown() then keyPressed = "SHIFT-"..keyPressed end
            if IsControlKeyDown() then keyPressed = "CTRL-"..keyPressed end
            if IsAltKeyDown() then keyPressed = "ALT-"..keyPressed end
            
            self.keyPressed = keyPressed
            local currentCommand = GetBindingAction(keyPressed)
            if currentCommand ~= "" then
                self.currentButton = currentCommand
            else
                self.currentButton = nil
            end
            
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
    OnAlt = function(self)  -- This handles button3 ("Set keybind")
        if not self.data then return end
        if self.keyPressed then
            -- Find and remove existing keys bound to this button
            local clickBinding = "CLICK "..self.data.buttonName..":LeftButton"
            local existingKey = GetBindingKey(clickBinding)
            
            if existingKey then
                SetBinding(existingKey, nil)
            end
            
            -- Remove the new key from any existing binding
            SetBinding(self.keyPressed, nil)
            
            -- Create new binding for this button
            SetBindingClick(self.keyPressed, self.data.buttonName)
            SaveBindings(GetCurrentBindingSet())
            ShadowShortcuts.UpdateKeyTexts()
            print(string.format("Bound |cFF00FF00%s|r to |cFFFFFF00%s|r", self.keyPressed, self.data.buttonName))
        end
    end,
    OnCancel = function(self)  -- This handles button2 ("Remove keybind")
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
    OnAccept = function(self)  -- This handles button1 ("Cancel")
        if not self.data then return end
        StaticPopup_Hide("SHADOWSHORTCUTS_KEYBIND")
    end,
    timeout = 0,
    exclusive = 1,
    whileDead = 1,
    hideOnEscape = 1,
    multipleButtons = true
}

for _, keyId in ipairs({
    "TOGGLE", "MODE", "BUTTON1", "BUTTON2", "BUTTON3", "BUTTON4", 
    "BUTTON5", "BUTTON6", "BUTTON7", "BUTTON8", "BUTTON9", "BUTTON10"
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

CreateBindingButton("TOGGLE")
CreateBindingButton("MODE")
for i = 1, 10 do
    CreateBindingButton("BUTTON"..i)
end

------------------------------------------------------
-- Server communication
------------------------------------------------------

cachedNames = {}

AIO.Handle("ShadowsCache", "RequestCache")

local chatFrame = CreateFrame("Frame")
chatFrame:RegisterEvent("CHAT_MSG_SYSTEM")
chatFrame:SetScript("OnEvent", function(self, event, msg)
    local name = msg:match("add: (.+) %- Login successful%.")
    if name and name ~= UnitName("player") and not cachedNames[name] then
        local class = GetClassByName(name)
        if class then
            cachedNames[name] = class
        end
    end
    local name = msg:match("remove: (.+) %- Logout successful%.")
    if name and cachedNames[name] then
        cachedNames[name] = nil
    end
end)

local ShadowsCacheHandlers = AIO.AddHandlers("ShadowsCache", {})
function ShadowsCacheHandlers.LoadCache(player, data)
    cachedNames = {}
    for name, class in pairs(data) do
        cachedNames[name] = class
        -- print("Cached ", name, " as class ", class)
    end
    -- print("Done caching shadows names and classes.")
end

function GetClassByName(name)
    if UnitName("player") == name then
        local _, class = UnitClass("player")
        return class
    end
    
    for i = 1, 4 do
        if UnitName("party"..i) == name then
            local _, class = UnitClass("party"..i)
            return class
        end
    end
    
    for i = 1, 40 do
        if UnitName("raid"..i) == name then
            local _, class = UnitClass("raid"..i)
            return class
        end
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
		if BotControlBar and (ShadowsBarToggleStatus == "ENABLED" or ShadowsBarToggleStatus  == "OPEN") then
			BotControlBar:Show()
		end
	end
end

SendChatMessage(".shadowsbarstatus", "GUILD")

local ShadowsBarAddonMsg = CreateFrame("Frame")
ShadowsBarAddonMsg:RegisterEvent("CHAT_MSG_ADDON")
ShadowsBarAddonMsg:SetScript("OnEvent", onShadowsBarAddonMessage)

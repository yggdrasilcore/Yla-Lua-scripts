local AIO = AIO or require("AIO")
if AIO.AddAddon() then
    return
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
        {text = "Aggressive", icon = "ability_racial_bloodrage", command = "grind"},
        {text = "Defensive", icon = "Ability_Warrior_DefensiveStance", command = "co -passive"},
        {text = "Passive", icon = "ability_seal", command = "flee"},
    }

    local toggleButtons = {
        {text = "Toggle Burst Mode", icon = "Ability_Shaman_Heroism", command = "boost", toggle = true, default = true},
        {text = "Toggle Food Between Fights", icon = "INV_Misc_Food_10", command = "food", toggle = true, default = true},
        {text = "Toggle Healer DPS", icon = "Spell_Holy_HolySmite", command = "healer dps", toggle = true, default = true},
        {text = "Toggle Shadows Menu", icon = "Spell_Shadow_AntiShadow", command = ".shadowsmenu", guild = true},
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
            elseif button.state then
                GameTooltip:AddLine("|cFF00FF00Active|r", 1, 1, 1)
            end
            GameTooltip:Show()
        end
    end

    local function IsShadowsMenuOpen()
        if GossipFrame:IsShown() then
            for i = 1, 5 do
                local button = _G["GossipTitleButton"..i]
                if not button then break end

                if button:IsVisible() and button:GetText() then
                    local text = button:GetText():lower()
                    if string.find(text, "how to use shadows") 
					or string.find(text, "available shadows") 
					or string.find(text, "active shadows") 
					or string.find(text, "how to use shadows") 
					or string.find(text, " commands") 
					then
                        return true
                    end
                end
            end
        end
        return false
    end

    local shadowsMenuButton

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
            
            if self.info.text == "Toggle Shadows Menu" then
                if IsShadowsMenuOpen() then
                    CloseGossip()
                    self.state = false
                    self.border:SetAlpha(0)
                else
                    if self.info.guild then
                        SendChatMessage(self.info.command, "GUILD")
                    else
                        local channel = GetNumRaidMembers() > 0 and "RAID" or GetNumPartyMembers() > 0 and "PARTY" or nil
                        SendChatMessage(self.info.command, channel)
                    end
                    self.state = true
                    self.border:SetAlpha(1)
                end
                UpdateButtonTooltip(self)
                return
            end

            if self.info.guild then
                SendChatMessage(self.info.command, "GUILD")
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
                        local passiveBtn = _G["BotControlBarButton9"]
                        local defensiveBtn = _G["BotControlBarButton10"]
                        
                        if passiveBtn and defensiveBtn then
                            passiveBtn.state = false
                            passiveBtn.border:SetAlpha(0)
                            
                            defensiveBtn.state = true
                            defensiveBtn.border:SetAlpha(1)
                            
                            UpdateButtonTooltip(passiveBtn)
                            UpdateButtonTooltip(defensiveBtn)
                        end
                        SendChatMessage("follow", channel)
                        local delayFrame = CreateFrame("Frame")
                        delayFrame.timeElapsed = 0
                        delayFrame:SetScript("OnUpdate", function(self, elapsed)
                            self.timeElapsed = self.timeElapsed + elapsed
                            if self.timeElapsed >= 0.5 then
                                self:SetScript("OnUpdate", nil)
                                self:Hide()
                                SendChatMessage("attack", channel)
                                local passiveBtn = _G["BotControlBarButton9"]
                                local defensiveBtn = _G["BotControlBarButton10"]
                                if passiveBtn and defensiveBtn then
                                    passiveBtn.state = false
                                    passiveBtn.border:SetAlpha(0)
                                    
                                    defensiveBtn.state = true
                                    defensiveBtn.border:SetAlpha(1)
                                    
                                    UpdateButtonTooltip(passiveBtn)
                                    UpdateButtonTooltip(defensiveBtn)
                                end
                            end
                        end)
                    end
                    return
                end
                SendChatMessage(self.info.command, channel)
                
                for _, btn in ipairs(movementGroup) do
                    local otherBtn = _G["BotControlBarButton"..(tIndexOf(buttons, btn))]
                    if otherBtn then
                        otherBtn.state = (otherBtn == self)
                        otherBtn.border:SetAlpha(otherBtn.state and 1 or 0)
                        UpdateButtonTooltip(otherBtn)
                    end
                end
                
                return
            end

            if tContains(movementGroup, self.info) then
                local followBtn = _G["BotControlBarButton"..(tIndexOf(buttons, {text = "Follow", icon = "Ability_Tracking", command = "follow"}))]
                local stayBtn = _G["BotControlBarButton"..(tIndexOf(buttons, {text = "Stay", icon = "spell_nature_timestop", command = "stay"}))]
                local attackBtn = _G["BotControlBarButton"..(tIndexOf(buttons, {text = "Attack", icon = "ability_ghoulfrenzy", command = "attack"}))]

                if self.info.text == "Attack" then
                    if not UnitExists("target") then
                        UIErrorsFrame:AddMessage("You don't have a target.", 1.0, 1.0, 0.0, 1.0, 6)
                    else
                        SendChatMessage(self.info.command, channel)
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
                if self.info.text == "Defensive" then
                    if isPassiveActive then
                        SendChatMessage("co -passive", channel)
                        SendChatMessage("nc -passive", channel)
                        isPassiveActive = false
                    else
                        SendChatMessage("nc -grind", channel)
                    end
                else
                    SendChatMessage(self.info.command, channel)
                end
                UpdateButtonTooltip(self)
                return
            end

            if self.info.toggle then
                self.state = not self.state

				if self.info.command == "boost" then
					if self.state then
						SendChatMessage("co +boost", channel)
						SendChatMessage("ns -2825", channel)
						SendChatMessage("ss -32182", channel)
					else
						SendChatMessage("co -boost", channel)
						SendChatMessage("ns +2825", channel)
						SendChatMessage("ss +32182", channel)
					end
                elseif self.info.command == "food" then
                    local cmd = self.state and "nc +food" or "nc -food"
                    SendChatMessage(cmd, channel)
                elseif self.info.command == "healer dps" then
                    local cmd = self.state and "co +healer dps" or "co -healer dps"
                    SendChatMessage(cmd, channel)
                end

                self.border:SetAlpha(self.state and 1 or 0)
                UpdateButtonTooltip(self)
            else
                if channel then
                    for cmd in string.gmatch(self.info.command, "[^\n]+") do
                        SendChatMessage(cmd, channel)
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

        if btnInfo.text == "Toggle Shadows Menu" then
            shadowsMenuButton = button
        end

        SetCombatButtonClickHandler(button)
    end

    frame:SetScript("OnUpdate", function(self, elapsed)
        if shadowsMenuButton then
            local isOpen = IsShadowsMenuOpen()
            if isOpen ~= shadowsMenuButton.state then
                shadowsMenuButton.state = isOpen
                shadowsMenuButton.border:SetAlpha(isOpen and 1 or 0)
                UpdateButtonTooltip(shadowsMenuButton)
            end
        end

        if self.delayedCommand then
            self.delayTimer = self.delayTimer - elapsed
            if self.delayTimer <= 0 then
                SendChatMessage(self.delayedCommand.command, self.delayedCommand.channel)

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
            text = "Repair",
            icon = "Trade_BlackSmithing",
            command = "repair"
        },
        {
            text = "Talk to NPC",
            icon = "achievement_character_human_male",
            command = "talk"
        },
        {
            text = "Train",
            icon = "Spell_Holy_ReviveChampion",
            command = "trainer learn"
        },
        {
            text = "Quest",
            icon = "INV_Letter_11",
            dropdown = {
                {text = "Show quest progress", command = "quests all"},
                {text = "Accept quests", command = "accept *"}
            }
        },
        {
            text = "Inventory",
            icon = "inv_misc_bag_07_black",
            command = "inv"
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

    local function HandleUtilityButtonAction(button)
        if button.info.text == "Use Objects" then
            local channel = GetNumRaidMembers() > 0 and "RAID" or GetNumPartyMembers() > 0 and "PARTY" or nil
            SendChatMessage("los", channel)
            
            local frame = CreateFrame("Frame")
            frame:RegisterEvent("CHAT_MSG_WHISPER")
            frame:SetScript("OnEvent", function(self, event, msg, sender)
                if msg:lower():match("spell") or msg:lower():match("item") then return end
                local itemName = msg:match("%[(.-)%]")
                if itemName then
                    if not itemCache[itemName] then
                        itemCache[itemName] = true
                        lastUpdate = GetTime()
                    end
                end
            end)

            local timer = CreateFrame("Frame")
            timer:SetScript("OnUpdate", function(self, elapsed)
                if lastUpdate > 0 and (GetTime() - lastUpdate) >= 1 and next(itemCache) then
                    ShowItemList()
                    lastUpdate = 0
                    frame:UnregisterEvent("CHAT_MSG_WHISPER")
                end
            end)
        elseif button.info.text == "Train" then
            if not UnitExists("target") then
                UIErrorsFrame:AddMessage("You must have a trainer targeted.", 1.0, 1.0, 0.0, 1.0, 6)
                return
            end
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
                        elseif item.text == "Accept quests" then
                            if not UnitExists("target") then
                                UIErrorsFrame:AddMessage("You must have a quest giver targeted.", 1.0, 1.0, 0.0, 1.0, 6)
                                skip = true
                            end
                        end
                        if not skip then
                            SendChatMessage(item.command, channel)
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
            SendChatMessage(button.info.command, channel)
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
                end

                button:SetScript("OnClick", function(self)
                    if isFleeActive then
                        local channel = GetNumRaidMembers() > 0 and "RAID" or GetNumPartyMembers() > 0 and "PARTY" or nil
                        SendChatMessage("reset botAI", channel)
						
                        local fleeTimer = CreateFrame("Frame")
                        fleeTimer.timeElapsed = 0
                        fleeTimer:SetScript("OnUpdate", function(self, elapsed)
                            self.timeElapsed = self.timeElapsed + elapsed
                            if self.timeElapsed >= 1 then
                                HandleUtilityButtonAction(self.buttonRef)
                                isFleeActive = false
                                isPassiveActive = false
                                resetCombatButtons = true
                                self:SetScript("OnUpdate", nil)
                            end
                        end)
                        fleeTimer.buttonRef = self
                    else
                        HandleUtilityButtonAction(self)
                    end
                end)
            end

            for i = #utilityButtons + 1, #frame.originalButtons do
                local button = _G["BotControlBarButton"..i]
                if button then button:Hide() end
            end

            AdjustButtons(frame)
        else
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
				SendChatMessage("u "..link, channel)
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

    SLASH_BOTCONTROLBAR1 = "/botbar"
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

    return frame
end

CreateBotControlBar()

BotControlBar:Hide()

---------------------------------------------------
-- Shadows bar keyboard shortcuts
---------------------------------------------------

local ShadowShortcuts = {}

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
    if not ShadowShortcuts.configFrame then
        ShadowShortcuts.configFrame = ShadowShortcuts.CreateConfigWindow()
    end
    ShadowShortcuts.configFrame:Show()
end

SLASH_SHADOW1 = "/shadow"
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
		checkBox:SetPoint("TOPLEFT", 16, -40)  -- Adjusted position to make room for header
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

		frame.name = "Shadows"
	else
		local frame = _G["ShadowsSettingsFrame"]
		frame:Show()
		
		local checkBox = _G["ShadowsBarCheckbox"]
		local keyBindButton = _G["ShadowsKeybindButton"]
		local resetButton = _G["ShadowsResetButton"]
		local header	= _G["headerText"]
		
		if checkBox and not checkBox:IsVisible() then checkBox:Show() end
		if keyBindButton and not keyBindButton:IsVisible()  then keyBindButton:Show() end
		if resetButton and not resetButton:IsVisible()  then resetButton:Show() end
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
    local header = _G["headerText"]
    
    -- Ensure shadowButton is accessible and unlock it
    if shadowButton then
        shadowButton:UnlockHighlight()  -- Unlock highlight
    end
    
    if checkBox and keyBindButton and resetButton and header then
        checkBox:Hide()
        keyBindButton:Hide()
        resetButton:Hide()
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
                local header = _G["headerText"]
                
                -- Ensure shadowButton is accessible, unlock and hide it
                if shadowButton then
                    shadowButton:UnlockHighlight()
                end
               
                if checkBox and keyBindButton and resetButton and header then
                    checkBox:Hide()
                    keyBindButton:Hide()
                    resetButton:Hide()
                    header:Hide()
                end
            end
            button:LockHighlight()  -- Lock the highlight for the clicked button
        end)
    end
end

------------------------------------------------------
-- Server communication
------------------------------------------------------

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


local AIO = AIO or require("AIO")

if AIO.AddAddon() then
   return
end

local UIHandlers = AIO.AddHandlers("UIFix", {})

local FeathersSpell = 29118
-------------------------------------------
-- Correction for AH deposit price
-------------------------------------------

local lastGold = 0
local lastSilver = 0
local lastCopper = 0
local isOnUpdateActive = false

local function CalculateNewPrice(gold, silver, copper)
    -- Convert the total price to copper
    local totalCopper = (gold * 10000) + (silver * 100) + copper
    -- Calculate 20% of the total price
    local newTotalCopper = math.floor(totalCopper * 0.2)
    -- Split the new total price back into gold, silver, and copper
    local newGold = math.floor(newTotalCopper / 10000)
    newTotalCopper = newTotalCopper % 10000
    local newSilver = math.floor(newTotalCopper / 100)
    local newCopper = newTotalCopper % 100
    return newGold, newSilver, newCopper
end

local function ModifyDeposit()
    local gold = 0
    local silver = 0
    local copper = 0

    -- Check if the deposit frame and its elements exist
    if AuctionsDepositMoneyFrame then
        -- Read GoldButton
        if AuctionsDepositMoneyFrameGoldButton and AuctionsDepositMoneyFrameGoldButton:IsVisible() then
            gold = tonumber(AuctionsDepositMoneyFrameGoldButton:GetText()) or 0
        end

        -- Read SilverButton
        if AuctionsDepositMoneyFrameSilverButton and AuctionsDepositMoneyFrameSilverButton:IsVisible() then
            silver = tonumber(AuctionsDepositMoneyFrameSilverButton:GetText()) or 0
        end

        -- Read CopperButton
        if AuctionsDepositMoneyFrameCopperButton and AuctionsDepositMoneyFrameCopperButton:IsVisible() then
            copper = tonumber(AuctionsDepositMoneyFrameCopperButton:GetText()) or 0
        end

        -- Check if the price has changed
        if gold ~= lastGold or silver ~= lastSilver or copper ~= lastCopper then
            -- Calculate the new price
            local newGold, newSilver, newCopper = CalculateNewPrice(gold, silver, copper)

            -- Set the new values
            if AuctionsDepositMoneyFrameGoldButton and AuctionsDepositMoneyFrameGoldButton:IsVisible() then
                AuctionsDepositMoneyFrameGoldButton:SetText(newGold)
            end

            if AuctionsDepositMoneyFrameSilverButton and AuctionsDepositMoneyFrameSilverButton:IsVisible() then
                AuctionsDepositMoneyFrameSilverButton:SetText(newSilver)
            end

            if AuctionsDepositMoneyFrameCopperButton and AuctionsDepositMoneyFrameCopperButton:IsVisible() then
                AuctionsDepositMoneyFrameCopperButton:SetText(newCopper)
            end

            -- Update the last known values
            lastGold = newGold
            lastSilver = newSilver
            lastCopper = newCopper

            -- Print the new total cost
            --print("New Price: " .. newGold .. " gold, " .. newSilver .. " silver, " .. newCopper .. " copper.")
        end
    end
end

local function ModifyDuration()
    if DurationDropDownText and DurationDropDownText:GetText() == "12 Hours" then DurationDropDownText:SetText("42 Hours") end
    if DurationDropDownText and DurationDropDownText:GetText() == "24 Hours" then DurationDropDownText:SetText("84 Hours") end
    if DurationDropDownText and DurationDropDownText:GetText() == "48 Hours" then DurationDropDownText:SetText("7 Days") end
    if DropDownList1Button1 and DropDownList1Button1:GetText() == "12 Hours" then DropDownList1Button1:SetText("42 Hours") end
    if DropDownList1Button2 and DropDownList1Button2:GetText() == "24 Hours" then DropDownList1Button2:SetText("84 Hours") end
    if DropDownList1Button3 and DropDownList1Button3:GetText() == "48 Hours" then DropDownList1Button3:SetText("7 Days") end
end

local function MonitorDepositChanges()
    if AuctionsDepositMoneyFrame and not isOnUpdateActive then
        AuctionsDepositMoneyFrame:SetScript("OnUpdate", ModifyDeposit)
        DurationDropDown:SetScript("OnUpdate", ModifyDuration)
        isOnUpdateActive = true
    end
end

local function StopMonitoringDepositChanges()
    if AuctionsDepositMoneyFrame and isOnUpdateActive then
        AuctionsDepositMoneyFrame:SetScript("OnUpdate", nil)
        DurationDropDown:SetScript("OnUpdate", nil)
        isOnUpdateActive = false
    end
end

-------------------------------------
-- Crossfaction unit menu start
-------------------------------------

CrossFactionMenu = {};
CrossFactionMenu.Macros = {};

function CrossFactionMenu.Macros.onLoad()
    CrossFactionMenu.Macros.menuItems = {};

    UnitPopupButtons["CrossFactionMenu_Invite"] = { text = "Invite", dist = 0 };
    table.insert(CrossFactionMenu.Macros.menuItems, "Invite");

    UnitPopupButtons["CrossFactionMenu_Whisper"] = { text = "Whisper", dist = 0 };
    table.insert(CrossFactionMenu.Macros.menuItems, "Whisper");

    UnitPopupButtons["CrossFactionMenu_Follow"] = { text = "Follow", dist = 0 };
    table.insert(CrossFactionMenu.Macros.menuItems, "Follow");

    UnitPopupButtons["CrossFactionMenu_Trade"] = { text = "Trade", dist = 0 };
    table.insert(CrossFactionMenu.Macros.menuItems, "Trade");

    hooksecurefunc("UnitPopup_OnClick", CrossFactionMenu.Macros.contextMenuClick);
end

function CrossFactionMenu.Macros.contextMenuClick(self)
    local dropdownFrame = UIDROPDOWNMENU_INIT_MENU;
    local button = self.value;
    local name = dropdownFrame.name;
    local startPos = string.find(button, "CrossFactionMenu_");

    --print("Context menu clicked for button: " .. button);

    if (startPos == 1) then
        -- Adjusted to extract correctly
        button = string.sub(button, startPos + #("CrossFactionMenu_"));  -- Get the substring correctly
        --print("Action identified: " .. button);

        if button == "Invite" then
            CrossFactionMenu.Macros.invite(name);
        elseif button == "Follow" then
            CrossFactionMenu.Macros.follow(name);
        elseif button == "Trade" then
            CrossFactionMenu.Macros.trade(name);
        elseif button == "Whisper" then
            CrossFactionMenu.Macros.whisper(name);
        end
    end

    CloseDropDownMenus();
end

local lastInteractTime = 0

function CrossFactionMenu.Macros.invite(name)
    local currentTime = GetTime()
    if currentTime - lastInteractTime >= 0.1 then
        --print("Inviting: " .. name);
        InviteUnit(name);
        lastInteractTime = currentTime
    end
end

function CrossFactionMenu.Macros.whisper(name)
    if name and name ~= "" then
        local editBox = ChatEdit_ChooseBoxForSend()
        ChatEdit_ActivateChat(editBox)
        editBox:SetText("/w " .. name .. " ")
        editBox:HighlightText()
    end
end

function CrossFactionMenu.Macros.follow(name)
    local currentTime = GetTime()
    if currentTime - lastInteractTime >= 0.1 then
        UIErrorsFrame:AddMessage("You need to be in a group with this player to follow them.", 1.0, 0.1, 0.1, 1.0);
        lastInteractTime = currentTime
    end
end

function CrossFactionMenu.Macros.trade(name)
    local currentTime = GetTime()
    if currentTime - lastInteractTime >= 0.1 then
        UIErrorsFrame:AddMessage("You need to be in a group with this player to trade them.", 1.0, 0.1, 0.1, 1.0);
        lastInteractTime = currentTime
    end
end

function CrossFactionMenu.Macros.updateMenu()
    local targetName = UnitName("target")
    local playerFaction = UnitFactionGroup("player")
    local targetFaction = UnitFactionGroup("target")
    local isInGroup = UnitInParty("target") or UnitInRaid("target")

    -- First, clean up existing menu items
    for _, menu in pairs(UnitPopupMenus) do
        for i = #menu, 1, -1 do
            if string.find(menu[i], "CrossFactionMenu_") then
                table.remove(menu, i)
            end
        end
    end

    local dropdownFrame = UIDROPDOWNMENU_INIT_MENU
    if dropdownFrame and dropdownFrame.which == "CHAT" then
        return
    end

    if targetName and playerFaction and targetFaction and 
       playerFaction ~= targetFaction and 
       not isInGroup then
        -- Add non-whisper buttons
        for _, button in ipairs(CrossFactionMenu.Macros.menuItems) do
            if button ~= "Whisper" then
                table.insert(UnitPopupMenus["PLAYER"], #UnitPopupMenus["PLAYER"] - 1, "CrossFactionMenu_" .. button);
                table.insert(UnitPopupMenus["FRIEND"], #UnitPopupMenus["FRIEND"] - 1, "CrossFactionMenu_" .. button);
                table.insert(UnitPopupMenus["PARTY"], #UnitPopupMenus["PARTY"] - 1, "CrossFactionMenu_" .. button);
                table.insert(UnitPopupMenus["RAID_PLAYER"], #UnitPopupMenus["RAID_PLAYER"] - 1, "CrossFactionMenu_" .. button);
                table.insert(UnitPopupMenus["TEAM"], #UnitPopupMenus["TEAM"] - 1, "CrossFactionMenu_" .. button);
                table.insert(UnitPopupMenus["CHAT_ROSTER"], #UnitPopupMenus["CHAT_ROSTER"] - 1, "CrossFactionMenu_" .. button);
            end
        end

        -- Add whisper button
        table.insert(UnitPopupMenus["PLAYER"], 2, "CrossFactionMenu_Whisper");
        table.insert(UnitPopupMenus["FRIEND"], 2, "CrossFactionMenu_Whisper");
        table.insert(UnitPopupMenus["PARTY"], 2, "CrossFactionMenu_Whisper");
        table.insert(UnitPopupMenus["RAID_PLAYER"], 2, "CrossFactionMenu_Whisper");
        table.insert(UnitPopupMenus["TEAM"], 2, "CrossFactionMenu_Whisper");
    end
end

-- Spell description/tooltip corrections

local function ApplyTwiggyTooltip(tooltip)
   tooltip:ClearLines()
   tooltip:AddLine("|cffffffffTwiggy|r")
   tooltip:AddLine("|cffffffffInstant|r")
   tooltip:AddLine("Right Click to summon and dismiss")
   tooltip:AddLine("Twiggy, your personal branch and")
   tooltip:AddLine("assistant of Yggdrasil.")
   tooltip:Show()
end

local function ApplyChromaticMountTooltip(tooltip)
   tooltip:ClearLines()
   tooltip:AddLine("|cffffffffChromatic Mount|r")
   tooltip:AddLine("|cffffffff1.5 sec cast|r")
   tooltip:AddLine("Summons and dismisses a rideable")
   tooltip:AddLine("Chromatic Drake. This is a very fast")
   tooltip:AddLine("mount with permanent slow fall.")
   tooltip:Show()
end

local function ApplyWeaksauceTooltip(tooltip)
   tooltip:ClearLines()
   tooltip:AddLine("|cffffffffOld Crappy McWeakSauce|r")
   tooltip:AddLine("|cffffffff1.5 sec cast|r")
   tooltip:AddLine("Summons and dismisses a crappy")
   tooltip:AddLine("rideable wyvern mount. This is an")
   tooltip:AddLine("unbearably slow mount. Not usable")
   tooltip:AddLine("while flagged for PVP.")
   tooltip:Show()
end

local function ApplyMonasteryTPTooltip(tooltip)
   tooltip:ClearLines()
   tooltip:AddLine("|cffffffffTeleport Monastery|r")
   tooltip:AddLine("|cffffffff2 sec cast|r")
   tooltip:AddLine("Teleports you to the entrance of")
   tooltip:AddLine("Scarlet Monastery.")
   tooltip:Show()
end

local function ApplyWorgenFormTooltip(tooltip)
   tooltip:ClearLines()
   tooltip:AddLine("|cffffffffWorgen From|r")
   tooltip:AddLine("|cffffffffInstant|r")
   tooltip:AddLine("Temporarily transforms you into")
   tooltip:AddLine("the form of a Worgen.")
   tooltip:Show()
end

local function ApplyFoATooltip(tooltip)
   tooltip:ClearLines()
   tooltip:AddLine("|cffffffffFeather Burst|r")
   tooltip:AddLine("The Feathers of Azeroth burst")
   tooltip:AddLine("around the wings of your flying")
   tooltip:AddLine("mounts, permitting their use in")
   tooltip:AddLine("in old world areas.")
   tooltip:Show()
end

local function ApplyFrogFormTooltip(tooltip)
   tooltip:ClearLines()
   tooltip:AddLine("|cffffffffFrog From|r")
   tooltip:AddLine("|cffffffffInstant|r")
   tooltip:AddLine("Transforms you into the form")
   tooltip:AddLine("of a frog for 60 seconds.")
   tooltip:Show()
end

local function ModifySpellTooltip(tooltip)
   local name, _, spellId = GameTooltip:GetSpell()
   if spellId == 40405 then
       ApplyTwiggyTooltip(tooltip)
   end
   if spellId == 24576 then
       ApplyChromaticMountTooltip(tooltip)
   end
   if spellId == 32420 then
       ApplyWeaksauceTooltip(tooltip)
   end
   if spellId == 427 then
       ApplyMonasteryTPTooltip(tooltip)
   end
   if spellId == 32819 then
       ApplyWorgenFormTooltip(tooltip)
   end
   if spellId == FeathersSpell then
       ApplyFoATooltip(tooltip)
   end
   if spellId == 3329 then
       ApplyFrogFormTooltip(tooltip)
   end
end

-- Hook the spell link insertion
local oldChatEdit_InsertLink = ChatEdit_InsertLink
function ChatEdit_InsertLink(text, ...)
   if text and text:find("spell:40405") then
       text = text:gsub("Lucky", "Twiggy")
   end
   return oldChatEdit_InsertLink(text, ...)
end

-- Function that handles the AFK toggle event
local function OnPlayerAFKChanged(self, event, arg1)
    if arg1 == "player" then
        if UnitIsAFK("player") then
            -- Start the timer if it's not already running
            if not self.afkTimer then
                self.afkTimer = 0
                self:SetScript("OnUpdate", function(self, elapsed)
                    self.afkTimer = self.afkTimer + elapsed
                    if self.afkTimer >= 120 then -- 120 seconds = 2 minutes
                        self.afkTimer = 0
                        SendChatMessage(".afk", "SAY")
                    end
                end)
            end
        else
            -- Stop the timer if the player is no longer AFK
            if self.afkTimer then
                self.afkTimer = nil
                self:SetScript("OnUpdate", nil)
            end
        end
    end
end


---------------- Event registrations

-- Register event for AFK status change
local z = CreateFrame("Frame")
z:RegisterEvent("PLAYER_FLAGS_CHANGED")
z:SetScript("OnEvent", OnPlayerAFKChanged)

-- Crossfaction Menus
CrossFactionMenu.Macros.onLoad();
local f = CreateFrame("Frame")
f:RegisterEvent("RAID_MEMBERS_CHANGED")
f:RegisterEvent("PLAYER_TARGET_CHANGED")
f:RegisterEvent("PARTY_MEMBERS_CHANGED")
f:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_TARGET_CHANGED" then
        CrossFactionMenu.Macros.updateMenu();
    else
        local targetName = UnitName("target")
        if not targetName then return end
        
        -- Create timer frame
        local timerFrame = CreateFrame("Frame")
        timerFrame.elapsed = 0
        timerFrame:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = self.elapsed + elapsed
            if self.elapsed >= 0.05 then -- 50ms
                local isInGroup = UnitInParty("target") or UnitInRaid("target")
                local playerFaction = UnitFactionGroup("player")
                local targetFaction = UnitFactionGroup("target")
                
                if playerFaction ~= targetFaction then
                    if isInGroup then
                        for _, menu in pairs(UnitPopupMenus) do
                            for i = #menu, 1, -1 do
                                if string.find(menu[i], "CrossFactionMenu_") then
                                    table.remove(menu, i)
                                end
                            end
                        end
                    else
                        CrossFactionMenu.Macros.updateMenu()
                    end
                else
                    CrossFactionMenu.Macros.updateMenu()
                end
                self:SetScript("OnUpdate", nil) -- Clean up timer
            end
        end)
    end
end)

-- AH Price corrections
local depositframe = CreateFrame("Frame")
depositframe:RegisterEvent("AUCTION_HOUSE_SHOW")
depositframe:RegisterEvent("AUCTION_HOUSE_CLOSED")
depositframe:SetScript("OnEvent", function(self, event, ...)
    if event == "AUCTION_HOUSE_SHOW" then
        if AuctionsDepositMoneyFrame then
            AuctionsDepositMoneyFrame:HookScript("OnShow", MonitorDepositChanges)
        end
    elseif event == "AUCTION_HOUSE_CLOSED" then
        StopMonitoringDepositChanges()
    end
end)

------------------------------------------------------------------- 
-- TWIGGY TOOLTIP 
-------------------------------------------------------------------

GameTooltip:HookScript("OnTooltipSetSpell", ModifySpellTooltip)

-- Function to modify the tooltip contents
local function ModifyCustomStoreTooltip(tooltip)
    for i = 1, tooltip:NumLines() do
        local line = _G[tooltip:GetName() .. "TextLeft" .. i]
        if line and line:GetText() then
            if line:GetText():find("Chromatic Mount") then
                ApplyChromaticMountTooltip(tooltip)
                return
            end
            if line:GetText():find("Old Crappy McWeakSauce") then
                ApplyWeaksauceTooltip(tooltip)
                return
            end
            if line:GetText():find("Teleport Monastery") then
                ApplyMonasteryTPTooltip(tooltip)
                return
            end
            if line:GetText():find("Worgen Form") then
                ApplyWorgenFormTooltip(tooltip)
                return
            end
            if line:GetText():find("Feather Burst") then
                ApplyFoATooltip(tooltip)
                return
            end
            if line:GetText():find("Frog Form") then
                ApplyFrogFormTooltip(tooltip)
                return
            end
        end
    end
end

-- Override the SetHyperlink method for CustomStoreTooltip
local originalSetHyperlink = CustomStoreTooltip.SetHyperlink
CustomStoreTooltip.SetHyperlink = function(self, link, ...)
    originalSetHyperlink(self, link, ...)
    ModifyCustomStoreTooltip(self)
end

-- Hook clicked links OK
local oldSetItemRef = SetItemRef
function SetItemRef(link, text, button, chatFrame)
    oldSetItemRef(link, text, button, chatFrame)
    if link:find("spell:40405") then
        ApplyTwiggyTooltip(ItemRefTooltip)
    end
    if link:find("spell:24576") then
        ApplyChromaticMountTooltip(ItemRefTooltip)
    end
    if link:find("spell:32420") then
        ApplyWeaksauceTooltip(ItemRefTooltip)
    end
    if link:find("spell:427%f[%d]") then
        ApplyMonasteryTPTooltip(ItemRefTooltip)
    end
    if link:find("spell:32819") then
        ApplyWorgenFormTooltip(ItemRefTooltip)
    end
    if link:find("spell:"..FeathersSpell) then
        ApplyFoATooltip(ItemRefTooltip)
    end
    if link:find("spell:3329%f[%d]") then
        ApplyFrogFormTooltip(ItemRefTooltip)
    end
end

local function filterFunc(_, _, msg, ...)
    if msg and msg:find("spell:40405") then
        local newMsg = msg:gsub("Lucky", "Twiggy")
        return false, newMsg, ...
    end
    return false
end

local oldSendChatMessage = SendChatMessage
function SendChatMessage(msg, ...)
    if msg and msg:find("spell:40405") then
        msg = msg:gsub("Lucky", "Twiggy")
    end
    oldSendChatMessage(msg, ...)
end

-- Register all chat filters
ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", filterFunc)


-- Spell Flight stuff

local BUFFIDS = {
    3363, 8153, 32235, 32239, 32240,
    32242, 32243, 32244, 32245, 32246, 32289, 32290, 32292, 32295, 32296, 32297, 32345,
    33943, 37015, 39798, 39800, 39801, 39802, 39803, 39910, 40120, 40192,
    40212, 41513, 41514, 41515, 41516, 41517, 41518, 42667, 42668, 42673, 42679, 43810,
    43927, 44151, 44153, 44317, 44655, 44744, 44824, 44825, 44827, 46197, 46199,
    47037, 48023, 49193, 51617, 51960, 54726, 54727, 54729, 54903, 58615,
    59567, 59568, 59569, 59570, 59571, 59650, 59961, 59976, 59996, 60002, 60021, 60024, 60025,
    60099, 61229, 61230, 61289, 61294, 61309, 61442, 61444, 61446, 61451,
    61996, 61997, 62048, 63796, 63844, 63956, 63963, 64927, 65439, 66087,
    66088, 67336, 69395, 71346, 71347, 71810, 72283, 72284, 72807, 72808, 74854, 74855,
    75596, 75617, 75618, 76153, 75973
}

-- Create a name-to-id lookup table
local spellNameToID = {}
for _, id in pairs(BUFFIDS) do
    local name = GetSpellInfo(id)
    if name then
        spellNameToID[name] = id
    end
end

local spellCastFrame = CreateFrame("Frame")

local lastSendTime = 0

local function OnEvent(self, event, unit, spellName, spellRank, lineID)
    if not IsSpellKnown(FeathersSpell) then return end
    if InCombatLockdown() then return end
    if UnitUsingVehicle("player") then return end
    if not (
    --GetRealZoneText() == "Azshara Crater" or -- mall flight disabled
    GetCurrentMapContinent() == 1 or GetCurrentMapContinent() == 2 or GetCurrentMapContinent() == 3) then return end
    if event == "UNIT_SPELLCAST_FAILED" and unit == "player" then
        if IsFlying() then
            return
        end
        local spellID = spellNameToID[spellName]
        if spellID and spellID > 0 then 

            local isInstance, _ =  IsInInstance()
            if not isInstance and (GetTime() - lastSendTime) >= 0.1 then
                if IsMounted() then
                    Dismount()
                end
                SendChatMessage("." .. spellID, "SAY")
                UIErrorsFrame:Clear()
                lastSendTime = GetTime()
            end
        end
    end
end

spellCastFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
spellCastFrame:SetScript("OnEvent", OnEvent)

-- Define the UpdateAllButtons function
function UpdateAllButtons(toggle)
    -- Check if we're in an outdoor area or instance
    if IsSpellKnown(FeathersSpell) then
        local isInstance, _ = IsInInstance()
        local isIndoors = IsIndoors()

        -- Loop through all possible action buttons, including action bar and pet bar buttons
        for i = 1, 120 do
        
            local button
            
            if IsAddOnLoaded("ElvUI") then
                if i <= 12 then
                    button = _G['ElvUI_Bar1Button' .. i]
                elseif i <= 24 then
                    button = _G['ElvUI_Bar2Button' .. (i - 12)]
                elseif i <= 36 then
                    button = _G['ElvUI_Bar3Button' .. (i-24)]
                elseif i <= 48 then
                    button = _G['ElvUI_Bar4Button' .. (i-36)]
                elseif i <= 60 then
                    button = _G['ElvUI_Bar5Button' .. (i-48)]
                elseif i <= 72 then
                    button = _G['ElvUI_Bar6Button' .. (i-60)]
                else
                    return
                end
            elseif IsAddOnLoaded("Bartender4") then
                button = _G["BT4Button" .. i]
            elseif IsAddOnLoaded("Dominos") then
                button = _G["DominosActionButton" .. i]
            else -- No addon, hook normal action buttons
                if i <= 12 then
                    button = _G['ActionButton' .. i]
                elseif i <= 24 then
                    button = _G['BonusActionButton' .. (i - 12)]
                elseif i <= 36 then
                    button = _G['MultiBarRightButton' .. (i-24)]
                elseif i <= 48 then
                    button = _G['MultiBarLeftButton' .. (i-36)]
                elseif i <= 60 then
                    button = _G['MultiBarBottomRightButton' .. (i-48)]
                elseif i <= 72 then
                    button = _G['MultiBarBottomLeftButton' .. (i-60)]
                else
                    return -- Stock UI doesn't have more than 72 buttons
                end
            end
            
            if button then
            
                -- Get the action type and check if it's usable
                local actionType, id, subType, spellID = GetActionInfo(i)
                
                local isUsable, notEnoughMana = IsUsableAction(i)
                local isDisabled = not isUsable or not button:IsEnabled()

                -- Check for mount or companion action types
                if spellID and actionType == "companion" and subType == "MOUNT" then
                    local buttonWidth, buttonHeight = button:GetSize()

                    -- Check if spellID is in BUFFIDS
                    for _, id in pairs(BUFFIDS) do
                        if spellID == id then
                            -- Create or get a custom texture for the button only outside or in instances
                            if not button.customTexture then
                                -- Create the custom texture
                                local customTexture = button:CreateTexture(nil, "ARTWORK")
                                customTexture:SetAllPoints(button)  -- Make the custom texture fill the button
                                button.customTexture = customTexture  -- Store the reference to the custom texture
                            end

                            local map = GetCurrentMapContinent()

                            -- Set texture and ensure size when outside or not in an instance
                            if not isIndoors and not isInstance and not InCombatLockdown()
                            and (
                            -- (GetRealZoneText() == "Azshara Crater") or -- mall flight disabled
                            map == 1 or map == 2 or map == 3) and not (toggle == "off") then
                                local texture = GetActionTexture(i)  -- Get the mount texture
                                button.customTexture:SetTexture(texture)  -- Apply the mount texture
                                button:SetSize(buttonWidth, buttonHeight)  -- Ensure the button size is retained
                            elseif button.customTexture then
                                button.customTexture:Hide()  -- Hide the custom texture when indoors
                                button.customTexture = nil  -- Clean up the reference to the custom texture
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Create the frame for event handling
local worldEnterFrame = CreateFrame("Frame")
local updateScheduled = false
local elapsedTime = 0

-- Register the events to trigger when the player enters the world, changes zones, or enters/leaves combat
worldEnterFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
worldEnterFrame:RegisterEvent("ZONE_CHANGED")
worldEnterFrame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Enter combat
worldEnterFrame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- Leave combat
worldEnterFrame:RegisterEvent("SPELLS_CHANGED")

worldEnterFrame:SetScript("OnEvent", function(self, event, ...)
    if (event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED") then
        if not updateScheduled then
            updateScheduled = true
            elapsedTime = 0  -- Reset elapsed time
            self:SetScript("OnUpdate", function(_, elapsed)
                elapsedTime = elapsedTime + elapsed
                if elapsedTime >= 1 then
                    UpdateAllButtons()
                    updateScheduled = false
                    self:SetScript("OnUpdate", nil)  -- Stop the OnUpdate loop
                end
            end)
        end
    elseif event == "PLAYER_REGEN_ENABLED" or ("SPELLS_CHANGED") then
        UpdateAllButtons()
    elseif event == "PLAYER_REGEN_DISABLED" then
        local toggle = "off"
        UpdateAllButtons(toggle)
    end
end)

-- Hook into ActionButton_UpdateUsable to call UpdateAllButtons
hooksecurefunc("ActionButton_UpdateUsable", function(button)
    UpdateAllButtons()
end)

UpdateAllButtons()


local function OnSpellCastSucceed(_, _, _, name)
    if name == "Worgen Form" then
        SendChatMessage(".32819", "SAY")  -- Send a message in "say" chat
    end
end

-- Register the event when a spell is cast
local spellSucceed = CreateFrame("Frame")
spellSucceed:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
spellSucceed:SetScript("OnEvent", OnSpellCastSucceed)
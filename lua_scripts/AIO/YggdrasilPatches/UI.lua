local AIO = AIO or require("AIO")

if AIO.AddAddon() then
   return
end

local UIHandlers = AIO.AddHandlers("UIFix", {})

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
            --Add anti AFK functionality here
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
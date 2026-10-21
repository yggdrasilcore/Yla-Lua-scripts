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

local function ModifyTooltip(tooltip)
    local itemName, itemLink = tooltip:GetItem()
    
    if itemLink then
        local itemID = itemLink:match("item:(%d+)")
        
        for i = 1, tooltip:NumLines() do
            local line = _G[tooltip:GetName().."TextLeft"..i]
            if line and line:GetText() then
                local text = line:GetText()
                
                if itemID == "45900" then
                    local newText = text:gsub("15%%", "25%%")
                    line:SetText(newText)
                    tooltip:Show()
                end
                
                if itemID == "42491" and text:find("The Banshee Queen shall have her revenge") then
                    line:SetText("|cff00ff00Equip: Generates magical arrows when drawn. Does not use ammo.|r\n" .. text)
                    tooltip:Show()
                end
            end
        end
    end
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
GameTooltip:HookScript("OnTooltipSetItem", ModifyTooltip)
ItemRefTooltip:HookScript("OnTooltipSetItem", ModifyTooltip)

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

local Mounts = {
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
for _, id in pairs(Mounts) do
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
    if IsSwimming() then return end -- Should this be here?
    if UnitUsingVehicle("player") then return end
    if not (
    --GetRealZoneText() == "Azshara Crater" or -- mall flight disabled
    GetSubZoneText() == "Krasus' Landing" or
    GetCurrentMapContinent() == 1 or GetCurrentMapContinent() == 2 or GetCurrentMapContinent() == 3
	)
	then return end
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
				
                local map = GetCurrentMapContinent()
				local x, y = GetPlayerMapPosition("player")
				
				local KrasusCanFly
				local subzone = GetSubZoneText()
				local canColdWeather = IsSpellKnown(54197)
				
				if map == 4 and subzone == "Krasus' Landing" and canColdWeather and x < 0.655 then
					return
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

-- Helper function to get the correct button based on slot and UI addon
function GetActionButton(slot)    
    if IsAddOnLoaded("Bartender4") then
        return _G["BT4Button" .. slot]
	elseif IsAddOnLoaded("ElvUI") then
        if slot <= 12 then
            return _G['ElvUI_Bar1Button' .. slot]
        elseif slot <= 24 then
            return _G['ElvUI_Bar2Button' .. (slot - 12)]
        elseif slot <= 36 then
            return _G['ElvUI_Bar3Button' .. (slot - 24)]
        elseif slot <= 48 then
            return _G['ElvUI_Bar4Button' .. (slot - 36)]
        elseif slot <= 60 then
            return _G['ElvUI_Bar5Button' .. (slot - 48)]
        elseif slot <= 72 then
            return _G['ElvUI_Bar6Button' .. (slot - 60)]
        end
    elseif IsAddOnLoaded("Dominos") then
        return _G["DominosActionButton" .. slot]
    else -- No addon, hook normal action buttons
        if slot <= 12 then
            return _G['ActionButton' .. slot]
        elseif slot <= 24 then
            return _G['BonusActionButton' .. (slot - 12)]
        elseif slot <= 36 then
            return _G['MultiBarRightButton' .. (slot - 24)]
        elseif slot <= 48 then
            return _G['MultiBarLeftButton' .. (slot - 36)]
        elseif slot <= 60 then
            return _G['MultiBarBottomRightButton' .. (slot - 48)]
        elseif slot <= 72 then
            return _G['MultiBarBottomLeftButton' .. (slot - 60)]
        end
    end
    return nil
end

function HandleButtonTexture(i, toggle)
    local class, classFileName = UnitClass("player")
    local button

	
    if i >= 121 and i <= 127 and class == "Druid" then
        button = _G['ShapeshiftButton' .. (i - 120)]  -- Get the ShapeshiftButton
    elseif i < 120 then
        button = GetActionButton(i)  -- For regular action buttons (1-120)
    end

    if not button then
        return
    end
    
    -- Get the action type and check if it's usable
    local actionType, id, subType, spellID = GetActionInfo(i)
    local isUsable, notEnoughMana = IsUsableAction(i)
    local isDisabled = not isUsable or not button:IsEnabled()
	
	local flightShapeButton
	local disabled
	
	if class == "Druid" and i >= 121 and i <= 127 then
		local dtex, name, isActive, isCastable = GetShapeshiftFormInfo(i-120)
		if dtex == "Interface\\Icons\\Ability_Druid_FlightForm" and not isActive then
			texture = "Interface\\Icons\\Ability_Druid_FlightForm"
			spellID = 40120
			flightShapeButton = true
		end
    else
        texture = GetActionTexture(i)  -- For action buttons, get the action texture
    end
	
    -- Check if the button's icon is the flight form icon (applies to action buttons)
    local isFlightForm = texture == "Interface\\Icons\\Ability_Druid_FlightForm"
	
    -- Check for mount or companion action types, or if the icon is flight form
    if spellID and (actionType == "companion" and subType == "MOUNT" or isFlightForm) 
	or (spellID == 40120 and flightShapeButton)
	then
        local buttonWidth, buttonHeight = button:GetSize()

		if spellID == 40120 then
			local name, rank, icon, powerCost, isFunnel, powerType
			if IsSpellKnown(40120) then
				name, rank, icon, powerCost, isFunnel, powerType = GetSpellInfo(40120)
			elseif IsSpellKnown(33943) then
				name, rank, icon, powerCost, isFunnel, powerType = GetSpellInfo(33943)
			end
			local currMana = UnitPower("player", 0)
			if currMana < powerCost then
				disabled = true
				-- print("Not enough mana to cast, setting to disabled")
			end
		end
		
        -- Check if spellID is in Mounts
        for _, id in pairs(Mounts) do
            if spellID == id then
	
                -- If no custom texture, create one
                if not button.customTexture then
                    local customTexture = button:CreateTexture(nil, "ARTWORK")
                    customTexture:SetAllPoints(button)
                    button.customTexture = customTexture
                end

                local map = GetCurrentMapContinent()
				local x, y = GetPlayerMapPosition("player")
				
				local KrasusCanFly
				local subzone = GetSubZoneText()
				local canColdWeather = IsSpellKnown(54197)

				if map == 4 and subzone == "Krasus' Landing" and canColdWeather and x > 0.655 then
					KrasusCanFly = true
				else
					KrasusCanFly = false
				end
				
                -- Add the custom texture if conditions are met
				if toggle == "off" then
					if button.customTexture then
						button.customTexture:Hide()
						button.customTexture = nil
					end
					return
				end
				
				if not IsIndoors() and not IsInInstance() and not InCombatLockdown()
				and ((map == 1 or map == 2 or map == 3 or KrasusCanFly)
				or toggle == "KrasusLanding")
				and not disabled then
					button.customTexture:SetTexture(texture)
					button:SetSize(buttonWidth, buttonHeight)
					button:SetFrameStrata("HIGH")
				else
					if button.customTexture then
						button.customTexture:Hide()
						button.customTexture = nil
					end
				end
            end
        end
    end
	
    -- Check if the player is currently in a shapeshift form
    if class == "Druid" then
        local shapeshiftForm = GetShapeshiftForm()  -- Get the current shapeshift form (returns 0 if not in a shapeshift)

        -- If the player is in a shapeshift form (e.g., flight form)
        if shapeshiftForm and shapeshiftForm > 0 then
            -- Check all buttons and remove any custom textures related to flight form
            if button.customTexture then
                button.customTexture:Hide()
                button.customTexture = nil
            end
			
			if texture == "Interface\\Icons\\Spell_Nature_WispSplode" then
				local buttonWidth, buttonHeight = button:GetSize()
                if not button.customTexture then
                    local customTexture = button:CreateTexture(nil, "ARTWORK")
                    customTexture:SetAllPoints(button)
                    button.customTexture = customTexture
                end
				local texture = GetActionTexture(i)
				button.customTexture:SetTexture(texture)
				button:SetSize(buttonWidth, buttonHeight)
			end
        end
    end
end

local lastUpdateTime = 0
local updateCooldown = 0.001  -- 1 milliseconds

function UpdateAllButtons(toggle)
    -- Get the current time
    local currentTime = GetTime()
	
	if toggle == "shapeshiftOff" then updateCooldown = 1 end
	
    -- If it's been less than 10ms since the last update, don't run the function again
	if currentTime - lastUpdateTime < updateCooldown then
		return
	end

	local map = GetCurrentMapContinent()
	local x, y = GetPlayerMapPosition("player")
	
	local KrasusCanFly
	local subzone = GetSubZoneText()
	local canColdWeather = IsSpellKnown(54197)
	
	if map == 4 and subzone == "Krasus' Landing" and canColdWeather and x < 0.655 then
		toggle = "off"
	end

    -- Update the timestamp to the current time
    lastUpdateTime = currentTime

    if IsSpellKnown(FeathersSpell) then
        for i = 1, 127 do
            HandleButtonTexture(i, toggle)
        end
    end
end

-- Event handling frame setup remains the same
local worldEnterFrame = CreateFrame("Frame")
local updateScheduled = false
local elapsedTime = 0

worldEnterFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
worldEnterFrame:RegisterEvent("ZONE_CHANGED")
worldEnterFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
worldEnterFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
worldEnterFrame:RegisterEvent("SPELLS_CHANGED")
worldEnterFrame:RegisterEvent("SPELL_UPDATE_USABLE")
worldEnterFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

local class, classFileName = UnitClass("player")
if class == "Druid" then
	worldEnterFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    worldEnterFrame:RegisterEvent("UNIT_MANA")
end

local shapeshiftActive = false
local updateScheduled = false
local KrasusLanding
local elapsedTime = 0

worldEnterFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "UPDATE_SHAPESHIFT_FORM" then
        if GetShapeshiftForm() and GetShapeshiftForm() > 0 and not shapeshiftActive then
            shapeshiftActive = true
            UpdateAllButtons()
        elseif GetShapeshiftForm() and GetShapeshiftForm() < 1 and shapeshiftActive then
            shapeshiftActive = false
            UpdateAllButtons("shapeshiftOff")
        end
    elseif event == "UNIT_MANA" and class == "Druid" then
        local unit = ...
        if unit == "player" then
            UpdateAllButtons()
        end
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED" then
		if not (GetSubZoneText() == "Krasus' Landing") then
			KrasusLanding = nil
		end
        if not updateScheduled then
            updateScheduled = true
            elapsedTime = 0
            self:SetScript("OnUpdate", function(_, elapsed)
                elapsedTime = elapsedTime + elapsed
                if elapsedTime >= 1 then
                    UpdateAllButtons()
                    updateScheduled = false
                    self:SetScript("OnUpdate", nil)
                end
            end)
        end
    elseif event == "PLAYER_REGEN_ENABLED" or event == "SPELLS_CHANGED" then
        UpdateAllButtons()
    elseif event == "PLAYER_REGEN_DISABLED" then
        UpdateAllButtons("off")
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp, subevent, _, _, _, _, name, _, spellID, _, _, _ = ...
        if name == (GetUnitName("player", false)) and subevent == "SPELL_AURA_APPLIED" and spellID == 58600 then
            UpdateAllButtons("off")
        end
    end
end)

hooksecurefunc("ActionButton_UpdateUsable", function(button)
    UpdateAllButtons()
end)

-- Hook into PickupAction
hooksecurefunc("PickupAction", function(slot)
    local button = GetActionButton(slot)
    if button and button.customTexture then
        button.customTexture:Hide()
        button.customTexture = nil
    end
    UpdateAllButtons()
end)

-- Hook into PlaceAction
hooksecurefunc("PlaceAction", function(slot)
    local button = GetActionButton(slot)
    if button and button.customTexture then
        button.customTexture:Hide()
        button.customTexture = nil
    end
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

-- Kaldorei medallion
local class, classFileName = UnitClass("player")
if class == "Druid" then
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("UNIT_AURA")
    local trinketSpellIDs = {
        71561, -- Trinket 1
        71484, -- Trinket 2
        71560, -- Trinket 3
        71556, -- Trinket 4
        71485, -- Trinket 5
        71492  -- Trinket 6
    }
    
    -- Get icons for our spell IDs
    local spellIcons = {}
    for _, spellID in pairs(trinketSpellIDs) do
        local _, _, icon = GetSpellInfo(spellID)
        spellIcons[icon] = spellID
    end
    
    local activeBuffs = {}
    
    local function CheckBuffs(self, event, unit)
        if unit and unit ~= "player" then return end
        
        local currentActive = {}
        
        -- Scan buffs
        for i = 1, 40 do
            local _, _, icon = UnitBuff("player", i)
            if not icon then 
                break 
            end
            
            if spellIcons[icon] then
                currentActive[icon] = true
            end
        end
        
        -- Check for removals
        for icon, spellID in pairs(spellIcons) do
            if activeBuffs[icon] and not currentActive[icon] then
                SendChatMessage(".dbmmorph", "SAY")
            end
        end
        
        activeBuffs = currentActive
    end
    
    frame:SetScript("OnEvent", CheckBuffs)
    
    -- Do initial check immediately
    CheckBuffs()
end

--------------------------------------
-- LVL Rewards Toggle
--------------------------------------

local LvlRewardsDisabled

local function onAddonMessage(self, event, prefix, message, channel, sender)
	if prefix == "CheckMounts" then
        if message and message:find("ENABLED") then
			KrasusLanding = true
            UpdateAllButtons("KrasusLanding")
		end
    elseif prefix == "LvlRewardsDisabled" then
        if message and message:find("DISABLED") then
            LvlRewardsDisabled = 1
        elseif message and message:find("ENABLED") then
            LvlRewardsDisabled = 0
        end
		if InterfaceOptionsFeaturesPanel:IsShown() then
			InterfaceOptionsFeaturesPanel:Hide()
			InterfaceOptionsFeaturesPanel:Show()
		end
	end
end

local chatmsgaddon = CreateFrame("Frame")
chatmsgaddon:RegisterEvent("CHAT_MSG_ADDON")
chatmsgaddon:SetScript("OnEvent", onAddonMessage)
SendChatMessage(".lvlrewardsstatus", "GUILD") -- Sends a request for the current level-up rewards status

InterfaceOptionsFeaturesPanel:HookScript("OnShow", function(self)
    if not DisableLevelUpRewardsCheckbox and LvlRewardsDisabled then
        local checkbox = CreateFrame("CheckButton", "DisableLevelUpRewardsCheckbox", InterfaceOptionsFeaturesPanel, "InterfaceOptionsCheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", InterfaceOptionsFeaturesPanelPreviewTalentChanges, "BOTTOMLEFT", 0, -45)
		
		if LvlRewardsDisabled == 0 then 
			checkbox:SetChecked(true)
		else
			checkbox:SetChecked(false)
		end
			
        local text = checkbox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        text:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
        text:SetText("Receive Level-Up Rewards")

        local function OnCheckboxClick(self)
            if self:GetChecked() then
                SendChatMessage(".lvlrewardson", "GUILD")  -- Send message to enable rewards
            else
                SendChatMessage(".lvlrewardsoff", "GUILD") -- Send message to disable rewards
            end
        end

        checkbox:SetScript("OnClick", OnCheckboxClick)

        local description = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        description:SetPoint("TOPLEFT", checkbox, "BOTTOMLEFT", 35, -5)
        description:SetText("If disabled, you will not receive gold and vanity rewards\non every 10 levels. If you pass a reward level with this\nfeature disabled, the reward cannot be claimed later.")
        description:SetTextColor(1, 1, 1)  -- Set text color to white
        description:SetJustifyH("LEFT")    -- Align text to the left

        local background = checkbox:CreateTexture(nil, "BACKGROUND")
        background:SetPoint("TOPLEFT", description, "TOPLEFT", -5, 5)
        background:SetPoint("BOTTOMRIGHT", description, "BOTTOMRIGHT", 5, -5)
		
	end
end)
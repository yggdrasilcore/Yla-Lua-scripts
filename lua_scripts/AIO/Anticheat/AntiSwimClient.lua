local AIO = AIO or require("AIO")
if AIO.AddAddon() then
	return
end
local AntiWater = CreateFrame("Frame", "AntiWater")
AntiWater.timer = 0
AntiWater.serverInWater = nil
AntiWater.failCount = 0

local function onWaterMessage(self, event, prefix, message, channel, sender)
    if prefix == "AIO_AntiCheat_Water" then
        self.serverInWater = (message == "true")
    end
end

AntiWater:RegisterEvent("CHAT_MSG_ADDON")
AntiWater:SetScript("OnEvent", onWaterMessage)
AntiWater:SetScript("OnUpdate", function(self, elapsed)
    self.timer = self.timer + elapsed
    if self.timer > 1 then
        self.timer = 0
        
        if UnitOnTaxi("player") or UnitUsingVehicle("player") or UnitIsCharmed("player") or UnitIsControlling("player") then
            self.failCount = 0
            return
        end
        
        if self.serverInWater ~= nil then
            local clientSwimming = IsSwimming() == 1
            
            local serverInWater = self.serverInWater and "YES" or "NO"
            local clientSwim = clientSwimming and "YES" or "NO"
            
            if self.serverInWater and not clientSwimming then
                self.failCount = self.failCount + 1
                if self.failCount >= 3 then
					SendChatMessage(".AntiCheatAlert WaterWalkHack", "GUILD")
                    self.failCount = 0
                end
            else
                self.failCount = 0
            end
        end
    end
end)
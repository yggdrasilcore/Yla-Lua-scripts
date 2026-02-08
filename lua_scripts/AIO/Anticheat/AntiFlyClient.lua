local AIO = AIO or require("AIO")
if AIO.AddAddon() then
	return
end

local AntiFlyInstance = CreateFrame("Frame", "AntiFlyInstance")
AntiFlyInstance.lastFlyState = false
AntiFlyInstance.timer = 0
AntiFlyInstance:SetScript("OnUpdate", function(self, elapsed)
    self.timer = self.timer + elapsed
    if self.timer > 0.5 then
        self.timer = 0
        local isFlying = IsFlying() == 1
        if isFlying ~= self.lastFlyState then
            local _, instanceType = IsInInstance()
            local clientFlying = isFlying and "YES" or "NO"
            if isFlying and instanceType == "pvp" then
                SendAddonMessage("AIO_AntiCheat", "FlyHackInInstance", "GUILD")
                    --SendChatMessage(".anticheat_kick", "GUILD")
            end
            self.lastFlyState = isFlying
        end
    end
end)

local AntiFlyWorld = CreateFrame("Frame", "AntiFlyWorld")
AntiFlyWorld.timer = 0
AntiFlyWorld.serverFlyState = nil
AntiFlyWorld.failCount = 0

local function onServerMessage(self, event, prefix, message, channel, sender)
    if prefix == "AIO_AntiCheat" then
        self.serverFlyState = (message == "true")
        local serverFlying = self.serverFlyState and "YES" or "NO"
    end
end

AntiFlyWorld:RegisterEvent("CHAT_MSG_ADDON")
AntiFlyWorld:SetScript("OnEvent", onServerMessage)
AntiFlyWorld:SetScript("OnUpdate", function(self, elapsed)
    self.timer = self.timer + elapsed
    if self.timer > 1 then
        self.timer = 0
        
        local clientIsFlying = IsFlying() == 1
        local _, instanceType = IsInInstance()
        
        local clientFlying = clientIsFlying and "YES" or "NO"
        local serverFlying = self.serverFlyState == nil and "WAITING" or (self.serverFlyState and "YES" or "NO")
        
        if instanceType ~= "pvp" and self.serverFlyState ~= nil then
            if clientIsFlying ~= self.serverFlyState then
                self.failCount = self.failCount + 1
                if self.failCount >= 3 then
                    SendAddonMessage("AIO_AntiCheat", "FlyHackInWorld", "GUILD")
                    self.failCount = 0
                end
            else
                self.failCount = 0
            end
        end
    end
end)
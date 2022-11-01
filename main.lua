
----------------------
-- Addon inspired in LagBar --
----------------------

local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame")
end
addon = _G[ADDON_NAME]

----------------------
-- Interval constants  --
----------------------
local MAX_INTERVAL = 5
local UPDATE_INTERVAL = 0

----------------------
-- Latency tolerance constants  --
----------------------
local HOME_LATENCY_TOLERANCE = 95
local WORLD_LATENCY_TOLERANCE = 100

----------------------
-- Texts colors contants  --
----------------------
local WARNING_TEXT_COLOR = "|cffff6060"
local TIME_TEXT_COLOR = "|cff00ccff"
local PING_TEXT_COLOR = "|cffffcc00"
local REGULAR_TEXT_COLOR = "|cffffffff"

----------------------
-- UI events contants  --
----------------------
local ADDON_LOADED_EVENT = "ADDON_LOADED"
local PLAYER_LOGIN_EVENT = "PLAYER_LOGIN"

----------------------
-- Strings contants  --
----------------------
local START_MESSAGE = "|cFF99CC33 SimpleLagCheck initialized."
local WARNING_TEXT = "WARNING!!!"
local HOME_LATENCY_TEXT = "Home latency:"
local WORLD_LATENCY_TEXT = "World latency:"

addon:RegisterEvent(ADDON_LOADED_EVENT)

addon:SetScript("OnEvent", function(self, event, ...)
	if event == ADDON_LOADED_EVENT or event == PLAYER_LOGIN_EVENT then
		if event == ADDON_LOADED_EVENT then
			local arg1 = ...
			if arg1 and arg1 == ADDON_NAME then
				self:UnregisterEvent(ADDON_LOADED_EVENT)
				self:RegisterEvent(PLAYER_LOGIN_EVENT)
			end
			return
		end
		if IsLoggedIn() then
			self:StartAddon(event, ...)
			self:UnregisterEvent(PLAYER_LOGIN_EVENT)
		end
		return
	end
	if self[event] then
		return self[event](self, event, ...)
	end
end)

function addon:StartAddon() 
    print(START_MESSAGE)
    self:MonitorPing()
end

function addon:Format12HrDateTime(dateTime)
    return date("%H:%M:%S", dateTime)
end

function addon:CheckLagStatusAndPrintIfNeeded()
    local latencyHome = select(3, GetNetStats())
    local latencyWorld = select(4, GetNetStats())
    local currentDate = addon:Format12HrDateTime(GetTime())

    if (latencyHome > HOME_LATENCY_TOLERANCE) then
        
        local text = string.format(
            "%s %s %s %s %s %s %s %s", 
            TIME_TEXT_COLOR, 
            currentDate, 
            WARNING_TEXT_COLOR,
            WARNING_TEXT,
            REGULAR_TEXT_COLOR,
            HOME_LATENCY_TEXT, 
            PING_TEXT_COLOR, 
            latencyHome
        )

        print(text)
    end

    if (latencyWorld > WORLD_LATENCY_TOLERANCE) then
        local text = string.format(
            "%s %s %s %s %s %s %s %s", 
            TIME_TEXT_COLOR, 
            currentDate, 
            WARNING_TEXT_COLOR,
            WARNING_TEXT,
            REGULAR_TEXT_COLOR,
            WORLD_LATENCY_TEXT, 
            PING_TEXT_COLOR, 
            latencyWorld
        )

        print(text)
    end
end

function addon:MonitorPing()

	addon:SetScript("OnUpdate", function(self, arg1)
		
		if (UPDATE_INTERVAL > 0) then
			UPDATE_INTERVAL = UPDATE_INTERVAL - arg1
		else
			UPDATE_INTERVAL = MAX_INTERVAL
			self:CheckLagStatusAndPrintIfNeeded()
		end

	end)
	
	addon:Show()
end
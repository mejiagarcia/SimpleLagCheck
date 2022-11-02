
----------------------
-- Addon inspired in LagBar --
----------------------

local ADDON_NAME, addon = ...

if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame")
    _G[ADDON_NAME].hidden = true
end

addon = _G[ADDON_NAME]

local DEBUG_MODE = false

----------------------
-- Interval variables  --
----------------------

local lastMinuteHomeLatencySum = 0
local lastMinuteHomeLatencyAverage = 0

local lastMinuteWorldLatencySum = 0
local lastMinuteWorldLatencyAverage = 0

local minutesPassed = 0
local updateInterval = 0

----------------------
-- Interval constants  --
----------------------
local MAX_INTERVAL = 1

local MAX_SECONDS_TO_WAIT_WORLD = 60

local HOME_LATENCY_TOLERANCE = 3
local WORLD_LATENCY_TOLERANCE = 3

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
local AVERAGE_PING_TEXT = "|cFF99CC33 SimpleLagCheck: |cffffcc00 Last minute latency average -> home:|cFF99CC33 %s |cffffcc00| world:|cFF99CC33 %s" 
local INVALID_COMMAND_TEXT = "SimpleLagCheck: invalid command"

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

    lastMinuteHomeLatencySum = lastMinuteHomeLatencySum + latencyHome
    lastMinuteWorldLatencySum = lastMinuteWorldLatencySum + latencyWorld

    if (minutesPassed >= MAX_SECONDS_TO_WAIT_WORLD) then
        lastMinuteHomeLatencyAverage = math.floor(lastMinuteHomeLatencySum / MAX_SECONDS_TO_WAIT_WORLD)
        lastMinuteWorldLatencyAverage = math.floor(lastMinuteWorldLatencySum / MAX_SECONDS_TO_WAIT_WORLD)
        lastMinuteHomeLatencySum = 0
        lastMinuteWorldLatencySum = 0
        minutesPassed = 0

        print(string.format(AVERAGE_PING_TEXT, lastMinuteHomeLatencyAverage, lastMinuteWorldLatencyAverage))
    end

    local hasHomeLag = lastMinuteHomeLatencyAverage > 0 and latencyHome > (lastMinuteHomeLatencyAverage + HOME_LATENCY_TOLERANCE)

    if (hasHomeLag) then
        
        local text = string.format(
            "%s %s %s %s %s %s %s %s", 
            TIME_TEXT_COLOR, 
            addon:Format12HrDateTime(GetTime()), 
            WARNING_TEXT_COLOR,
            WARNING_TEXT,
            REGULAR_TEXT_COLOR,
            HOME_LATENCY_TEXT, 
            PING_TEXT_COLOR, 
            latencyHome
        )

        lastMinuteHomeLatencyAverage = 0

        print(text)
    end

    local hasWorldLag = lastMinuteWorldLatencyAverage > 0 and latencyWorld > (lastMinuteWorldLatencyAverage + WORLD_LATENCY_TOLERANCE)

    if (hasWorldLag) then
        local text = string.format(
            "%s %s %s %s %s %s %s %s", 
            TIME_TEXT_COLOR, 
            addon:Format12HrDateTime(GetTime()), 
            WARNING_TEXT_COLOR,
            WARNING_TEXT,
            REGULAR_TEXT_COLOR,
            WORLD_LATENCY_TEXT, 
            PING_TEXT_COLOR, 
            latencyWorld
        )

        lastMinuteWorldLatencyAverage = 0

        print(text)
    end
end

function addon:MonitorPing()

	addon:SetScript("OnUpdate", function(self, arg1)
		
		if (updateInterval > 0) then
			updateInterval = updateInterval - arg1
		else
			updateInterval = MAX_INTERVAL
            minutesPassed = minutesPassed + 1

			self:CheckLagStatusAndPrintIfNeeded()

            if (DEBUG_MODE) then
                self:PrintDebugInfo()
            end

		end

	end)
	
	addon:Show()
end

function addon:PrintDebugInfo()
    print(string.format("home | sum: %s | seconds: %s", lastMinuteHomeLatencySum, minutesPassed))
    print(string.format("world | sum: %s | seconds: %s", lastMinuteWorldLatencySum, minutesPassed))
end

-- TODO: Use single command for both instructions --

SLASH_SIMPLELAGCHECKDEBUGON1 = "/slc-debug-on"

SlashCmdList.SIMPLELAGCHECKDEBUGON = function(msg, editBox)
    DEBUG_MODE = true
    print("debug mode on")
end

SLASH_SIMPLELAGCHECKDEBUGOFF1 = "/slc-debug-off"

SlashCmdList.SIMPLELAGCHECKDEBUGOFF = function(msg, editBox)
    DEBUG_MODE = false
    print("debug mode off")
end
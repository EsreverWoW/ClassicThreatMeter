local A, C, L, _ = unpack(select(2, ...))

-----------------------------
-- VARIABLES
-----------------------------
-- upvalues
local wipe = wipe
local select = select
local tinsert = tinsert
local sort = sort
local floor = floor
local format = format
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local FACTION_BAR_COLORS = FACTION_BAR_COLORS

-- other
local bars = {}
local threatData = {}
local testMode = false
local oldTime = 0
local playerGUID = UnitGUID("player")

-----------------------------
-- Check if Classic
-----------------------------
function A:IsClassic()
	-- return _G.WOW_PROJECT_ID ~= _G.WOW_PROJECT_CLASSIC -- for testing in retail
	return _G.WOW_PROJECT_ID == _G.WOW_PROJECT_CLASSIC
end

-----------------------------
-- ThreatClassic-1.0
-----------------------------
local ThreatLib = A:IsClassic() and LibStub:GetLibrary("ThreatClassic-1.0")

local UnitDetailedThreatSituation = A:IsClassic() and function(unit, mob)
	return ThreatLib:UnitDetailedThreatSituation(unit, mob)
end or _G.UnitDetailedThreatSituation

-----------------------------
-- FUNCTIONS
-----------------------------
-- Create Backdrop
local function CreateBackdrop(parent, cfg)
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetPoint("TOPLEFT", parent, "TOPLEFT", -cfg.inset, cfg.inset)
	frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", cfg.inset, -cfg.inset)
	-- Backdrop Settings
	local backdrop = {
		bgFile = cfg.bgFile,
		edgeFile = cfg.edgeFile,
		tile = cfg.tile,
		tileSize = cfg.tileSize,
		edgeSize = cfg.edgeSize,
		insets = {
			left = cfg.inset,
			right = cfg.inset,
			top = cfg.inset,
			bottom = cfg.inset,
		},
	}
	frame:SetBackdrop(backdrop)
	frame:SetBackdropColor(cfg.bgColor.r, cfg.bgColor.g, cfg.bgColor.b, cfg.bgColor.a)
	frame:SetBackdropBorderColor(cfg.edgeColor.r, cfg.edgeColor.g, cfg.edgeColor.b, cfg.edgeColor.a)

	parent.backdrop = frame
end

local function CreateFS(parent)
	local fs = parent:CreateFontString(nil, "ARTWORK")
	fs:SetFont(C.font.family, C.font.size, C.font.style)
	fs:SetVertexColor(C.font.color.r, C.font.color.g, C.font.color.b, C.font.color.a)
	fs:SetShadowOffset(C.font.shadow and 1 or 0, C.font.shadow and -1 or 0)
	return fs
end

local function CreateStatusBar(parent, header)
	-- StatusBar
	local bar = CreateFrame("StatusBar", nil, parent)
	bar:SetSize(C.bar.width + 2, C.bar.height)
	bar:SetStatusBarTexture(C.bar.texture)
	bar:SetMinMaxValues(0, 100)
	CreateBackdrop(bar, C.backdrop)

	if not header then
		-- BG
		bar.bg = bar:CreateTexture(nil, "BACKGROUND", nil, -6)
		bar.bg:SetTexture(C.bar.texture)
		bar.bg:SetAllPoints(bar)
		-- Name
		bar.name = CreateFS(bar)
		bar.name:SetPoint("LEFT", bar, 2, 0)
		bar.name:SetJustifyH("LEFT")
		-- Perc
		bar.perc = CreateFS(bar)
		bar.perc:SetPoint("RIGHT", bar, -2, 0)
		bar.perc:SetJustifyH("RIGHT")
		-- Value
		bar.val = CreateFS(bar)
		bar.val:SetPoint("RIGHT", bar, -40, 0)
		bar.val:SetJustifyH("RIGHT")
		bar.name:SetPoint("RIGHT", bar.val, "LEFT", -10, 0) -- right point of name is left point of value

		bar:Hide()
	end
	return bar
end

-- Update Threat Data
local function UpdateThreatData(unit)
	if not UnitExists(unit) then return end
	-- check target of target if currently targeting a friend
	local target = UnitIsFriend("player", "target") and "targettarget" or "target"
	local _, _, scaledPercent, _, threatValue = UnitDetailedThreatSituation(unit, target)
	if threatValue and threatValue < 0 then
		threatValue = threatValue + 410065408
	end
	tinsert(threatData, {
		unit			= unit,
		scaledPercent	= scaledPercent or 0,
		threatValue		= threatValue or 0,
	})
end

-- Get Color
local function GetColor(unit)
	if UnitIsPlayer(unit) then
		return RAID_CLASS_COLORS[select(2, UnitClass(unit))]
	else
		return FACTION_BAR_COLORS[UnitReaction(unit, "player")]
	end
end

-- Number Format
local function NumFormat(v)
	if v > 1e10 then
		return (floor(v / 1e9)).."b"
	elseif v > 1e9 then
		return (floor((v / 1e9) * 10) / 10).."b"
	elseif v > 1e7 then
		return (floor(v / 1e6)).."m"
	elseif v > 1e6 then
		return (floor((v / 1e6) * 10) / 10).."m"
	elseif v > 1e4 then
		return (floor(v / 1e3)).."k"
	elseif v > 1e3 then
		return (floor((v / 1e3) * 10) / 10).."k"
	else
		return v
	end
end

-- Compare Values
local function Compare(a, b)
	return a.scaledPercent > b.scaledPercent
end

-- Update Threat Bars
local function UpdateThreatBars(self)
	-- sort the threat table
	sort(threatData, Compare)

	-- update view
	for i = 1, C.bar.count do
		-- get values out of table
		local data = threatData[i]
		local bar = self.bars[i]
		if data and data.threatValue > 0 then
			bar.name:SetText(UnitName(data.unit) or UNKNOWN)
			bar.val:SetText(NumFormat(data.threatValue))
			bar.perc:SetText(floor(data.scaledPercent).."%")
			bar:SetValue(data.scaledPercent)
			local color = GetColor(data.unit) or {r = 0.8, g = 0, b = 0.8}
			if C.bar.marker and UnitGUID(data.unit) == playerGUID then
				color = {r = 0.8, g = 0, b = 0}
			end
			bar:SetStatusBarColor(color.r, color.g, color.b, C.bar.alpha)
			bar.bg:SetVertexColor(color.r * C.bar.colorMod, color.g * C.bar.colorMod, color.b * C.bar.colorMod, C.bar.alpha)
			bar.backdrop:SetBackdropColor(C.backdrop.bgColor.r, C.backdrop.bgColor.g, C.backdrop.bgColor.b, C.backdrop.bgColor.a)
			bar.backdrop:SetBackdropBorderColor(C.backdrop.edgeColor.r, C.backdrop.edgeColor.g, C.backdrop.edgeColor.b, C.backdrop.edgeColor.a)

			bar:Show()
		else
			bar:Hide()
		end
	end
end

-- Check Status
local function CheckStatus(self, event)
	if event == "CLASSIC_THREAT_UPDATE" and testMode then return else testMode = false end

	local instanceType = select(2, GetInstanceInfo())
	if (C.general.hideOOC and not InCombatLockdown()) or (C.hideSolo and GetNumGroupMembers() == 0) or (C.general.hideInPVP and (instanceType == "arena" or instanceType == "pvp")) then
		self:Hide()
		return
	end

	local target = UnitIsFriend("player", "target") and "targettarget" or "target"

	if UnitExists(target) and UnitAffectingCombat(target) then
		self:Show()
		local now = GetTime()
		if now - oldTime > C.general.update then
			-- wipe
			wipe(threatData)
			local numGroupMembers = GetNumGroupMembers()
			local inRaid = IsInRaid()
			-- group
			if numGroupMembers > 0 then
				local unit = inRaid and "raid" or "party"
				for i = 1, inRaid and numGroupMembers or 4 do
					UpdateThreatData(unit..i)
					UpdateThreatData(unit.."pet"..i)
				end
				-- party excludes player/pet
				if not inRaid then
					UpdateThreatData("player")
					UpdateThreatData("pet")
				end
			-- solo
			else
				UpdateThreatData("player")
				UpdateThreatData("pet")
			end
			UpdateThreatBars(self)
			oldTime = now
		end
		-- set header unit name
		local targetName = UnitExists(target) and (": " .. UnitName(target)) or ""
		self.headerText:SetText(format("%s%s", L.gui.threat, targetName))
		
	else
		-- clear header text of unit name
		self.headerText:SetText(format("%s%s", L.gui.threat, ""))
		-- hide bars when no target
		for i = 1, C.bar.count do
			bars[i]:Hide()
		end
		oldTime = 0
	end
end

-- Test Bars
local function TestBars()
	if InCombatLockdown() then return end

	testMode = true
	for i = 1, C.bar.count do
		threatData[i] = {
			unit = UnitName("player"),
			scaledPercent = i / C.bar.count * 100,
			threatValue = i * 1e4,
		}
		tinsert(bars, i)
	end
	UpdateThreatBars(frame)
end

-----------------------------
-- INIT
-----------------------------
local OnLogon = CreateFrame("Frame")
OnLogon:RegisterEvent("PLAYER_ENTERING_WORLD")
OnLogon:SetScript("OnEvent", function(self, event)
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")

	-- handle SavedVariables
	if CTM_Options == nil then
		CTM_Options = {}
	end

	for i = 1, #C do
		if CTM_Options[C[i]] == nil then
			CTM_Options[C[i]] = C[C[i]]
		end
	end

	-- Minimum of 1 Row
	if not C.bar.count or C.bar.count < 1 then
		C.bar.count = 1
	end

	-- C = CTM_Options

	if C.general.welcome then
		print("|c00FFAA00"..A.addonName.." v"..A.version.." - "..L.welcome.."|r")
	end
end)

-- First create a frame frame to gather all the objects (make that dragable later)
local frame = CreateFrame("Frame", A.addonName.."BarFrame", UIParent)
frame:SetSize(C.bar.width + 2, (C.bar.height * C.bar.count + (C.bar.padding) * C.bar.count - (C.bar.padding)) + 2)
frame:SetFrameStrata("BACKGROUND")
frame:SetFrameLevel(1)
frame:SetPoint(C.frame.position.a1, C.frame.position.af, C.frame.position.a2, C.frame.position.x, C.frame.position.y)
frame:SetScale(C.general.scale)
frame.bars = bars

-- Background
frame.bg = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
frame.bg:SetTexture(1, 1, 1)
frame.bg:SetAllPoints()
frame.bg:SetVertexColor(C.frame.bgColor.r, C.frame.bgColor.g, C.frame.bgColor.b, C.frame.bgShow and C.frame.bgColor.a or 0)

-- Header
if C.frame.headerShow then
	local color = C.frame.headerColor

	frame.header = CreateStatusBar(frame, true)
	frame.header:SetPoint("TOPLEFT", frame, 0, C.bar.height)
	frame.header:SetStatusBarColor(color.r, color.g, color.b, color.a)

	frame.headerText = CreateFS(frame.header)
	frame.headerText:SetPoint("LEFT", frame.header, 2, 0)
	frame.headerText:SetJustifyH("LEFT")
	frame.headerText:SetText(format("%s%s", L.gui.threat, ""))
end

CreateBackdrop(frame, C.backdrop)

-- Create StatusBars
for i = 1, C.bar.count do
	bars[i] = CreateStatusBar(frame)
	if i == 1 then
		bars[i]:SetPoint("TOP", 0, 0)
	else
		bars[i]:SetPoint("TOP", bars[i - 1], "BOTTOM", 0, -C.bar.padding + 1)
	end
end

-- Callback Handler
local function CheckStatusFromCallback()
	CheckStatus(frame, "CLASSIC_THREAT_UPDATE")
end

-- Events
frame:SetScript("OnEvent", CheckStatus)
if A:IsClassic() then
	ThreatLib:RegisterCallback("Activate", CheckStatusFromCallback)
	ThreatLib:RegisterCallback("ThreatUpdated", CheckStatusFromCallback)
	ThreatLib:RequestActiveOnSolo(true)
else
	frame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
end
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")

-- Drag Frame
A:CreateDragFrame(frame, A.dragFrames, -2, true)

-- Create Slash Commands
A:CreateSlashCmd(A.addonName, A.addonShortcut, A.dragFrames, A.addonColor)
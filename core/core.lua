local A, C, L, _ = unpack(select(2, ...))

-----------------------------
-- VARIABLES
-----------------------------
-- upvalues
local _G		= _G
local select	= _G.select
local unpack	= _G.unpack
local tonumber	= _G.tonumber
local type		= _G.type
local floor		= _G.math.floor
local byte		= _G.string.byte
local format	= _G.string.format
local len		= _G.string.len
local sub		= _G.string.sub

local ipairs	= _G.ipairs
local pairs		= _G.pairs
local tinsert	= _G.table.insert
local sort		= _G.table.sort
local wipe		= _G.table.wipe

local GetNumGroupMembers	= _G.GetNumGroupMembers
local GetTime				= _G.GetTime
local GetInstanceInfo		= _G.GetInstanceInfo
local InCombatLockdown		= _G.InCombatLockdown
local UnitAffectingCombat	= _G.UnitAffectingCombat
local UnitClass				= _G.UnitClass
local UnitExists			= _G.UnitExists
local UnitIsFriend			= _G.UnitIsFriend
local UnitName				= _G.UnitName
local UnitReaction			= _G.UnitReaction
local UnitGUID				= _G.UnitGUID

local FACTION_BAR_COLORS	= _G.FACTION_BAR_COLORS
local RAID_CLASS_COLORS		= _G.RAID_CLASS_COLORS

-- other
local loaded = false
local bars = {}
local threatData = {}
local threatColors = {}
local oldTime = 0
local playerName = ""
local playerGUID = ""

-----------------------------
-- WOW CLASSIC
-----------------------------
-- A.classic = _G.WOW_PROJECT_ID ~= _G.WOW_PROJECT_CLASSIC -- for testing in retail
A.classic = _G.WOW_PROJECT_ID == _G.WOW_PROJECT_CLASSIC

local ThreatLib = A.classic and LibStub:GetLibrary("ThreatClassic-1.0")

local UnitThreatSituation = A.classic and function(unit, mob)
	return ThreatLib:UnitThreatSituation(unit, mob)
end or _G.UnitThreatSituation

local UnitDetailedThreatSituation = A.classic and function(unit, mob)
	return ThreatLib:UnitDetailedThreatSituation(unit, mob)
end or _G.UnitDetailedThreatSituation

-----------------------------
-- INIT
-----------------------------
local CTM = CreateFrame("Frame", A.addonName.."BarFrame", UIParent)

-----------------------------
-- FUNCTIONS
-----------------------------
local function CopyDefaults(t1, t2)
	if type(t1) ~= "table" then return {} end
	if type(t2) ~= "table" then t2 = {} end

	for k, v in pairs(t1) do
		if type(v) == "table" then
			t2[k] = CopyDefaults(v, t2[k])
		elseif type(v) ~= type(t2[k]) then
			t2[k] = v
		end
	end

	return t2
end

local backdrop = {}
local function CreateBackdrop(parent, cfg)
	local f = CreateFrame("Frame", nil, parent)
	f:SetPoint("TOPLEFT", parent, "TOPLEFT", -cfg.inset, cfg.inset)
	f:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", cfg.inset, -cfg.inset)
	-- Backdrop Settings
	backdrop = {
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
	f:SetBackdrop(backdrop)
	f:SetBackdropColor(unpack(cfg.bgColor))
	f:SetBackdropBorderColor(unpack(cfg.edgeColor))

	parent.backdrop = f
end

local function CreateFS(parent)
	local fs = parent:CreateFontString(nil, "ARTWORK")
	fs:SetFont(C.font.family, C.font.size, C.font.style)
	return fs
end

local function CreateStatusBar(parent, header)
	-- StatusBar
	local bar = CreateFrame("StatusBar", nil, parent)
	bar:SetMinMaxValues(0, 100)
	-- Backdrop
	CreateBackdrop(bar, C.backdrop)

	if not header then
		-- BG
		bar.bg = bar:CreateTexture(nil, "BACKGROUND", nil, -6)
		bar.bg:SetAllPoints(bar)
		-- Name
		bar.name = CreateFS(bar)
		bar.name:SetJustifyH("LEFT")
		-- Perc
		bar.perc = CreateFS(bar)
		bar.perc:SetJustifyH("RIGHT")
		-- Value
		bar.val = CreateFS(bar)
		bar.val:SetJustifyH("RIGHT")

		bar:Hide()
	end
	return bar
end

local function Compare(a, b)
	return a.scaledPercent > b.scaledPercent
end

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

local function ShortenString(str, i, ellipsis)
	if not str then return end
	local bytes = len(str)
	if bytes <= i then
		return str
	else
		local length, pos = 0, 1
		while (pos <= bytes) do
			length = length + 1
			local c = byte(str, pos)
			if c > 0 and c <= 127 then
				pos = pos + 1
			elseif c >= 192 and c <= 223 then
				pos = pos + 2
			elseif c >= 224 and c <= 239 then
				pos = pos + 3
			elseif c >= 240 and c <= 247 then
				pos = pos + 4
			end
			if length == i then break end
		end
		if length == i and pos <= bytes then
			return sub(str, 1, pos - 1) .. (ellipsis and "..." or "")
		else
			return str
		end
	end
end

local colorUnit = {}
local colorFallback = {}
local colorMarker = {}

local function GetColor(unit)
	if unit then
		if C.bar.marker and UnitGUID(unit) == playerGUID then
			return colorMarker
		elseif UnitIsPlayer(unit) then
			colorUnit = RAID_CLASS_COLORS[select(2, UnitClass(unit))]
		else
			colorUnit = FACTION_BAR_COLORS[UnitReaction(unit, "player")]
		end
		colorUnit = {colorUnit.r, colorUnit.g, colorUnit.b, C.bar.alpha}
		return colorUnit
	else
		return colorFallback
	end
end

local function UpdateThreatBars()
	-- sort the threat table
	sort(threatData, Compare)

	-- update view
	for i = 1, C.bar.count do
		-- get values out of table
		local data = threatData[i]
		local bar = CTM.bars[i]
		if data and data.threatValue > 0 then
			bar.name:SetText(UnitName(data.unit) or UNKNOWN)
			bar.val:SetText(NumFormat(data.threatValue))
			bar.perc:SetText(floor(data.scaledPercent).."%")
			bar:SetValue(data.scaledPercent)
			local color = GetColor(data.unit)
			bar:SetStatusBarColor(unpack(color))
			bar.bg:SetVertexColor(color[1] * C.bar.colorMod, color[2] * C.bar.colorMod, color[3] * C.bar.colorMod, C.bar.alpha)
			bar.backdrop:SetBackdropColor(unpack(C.backdrop.bgColor))
			bar.backdrop:SetBackdropBorderColor(unpack(C.backdrop.edgeColor))

			bar:Show()
		else
			bar:Hide()
		end
	end
end

local function CheckVisibility()
	local instanceType = select(2, GetInstanceInfo())
	local show = (C.general.hideOOC and not InCombatLockdown()) or (C.general.hideSolo and GetNumGroupMembers() == 0) or (C.general.hideInPVP and (instanceType == "arena" or instanceType == "pvp"))

	--[[
	if A.classic then
		if show then
			ThreatLib:RequestActiveOnSolo(true)
		else
			ThreatLib:RequestActiveOnSolo(false)
		end
	end
	--]]

	return show
end

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

local function CheckStatus()
	if not loaded then return end
	if C.frame.test then return end

	local hideFrame = CheckVisibility()

	if hideFrame then
		return CTM:Hide()
	else
		CTM:Show()
	end

	local target = UnitIsFriend("player", "target") and "targettarget" or "target"

	if UnitExists(target) then -- and UnitAffectingCombat(target) then
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
					UpdateThreatData(unit .. i)
					UpdateThreatData(unit .. "pet" .. i)
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
			UpdateThreatBars()
			oldTime = now
		end
		-- set header unit name
		local targetName = UnitExists(target) and (": " .. UnitName(target)) or ""
		targetName = ShortenString(targetName, floor(CTM.header:GetWidth() / (C.font.size * 0.75)), true)
		CTM.headerText:SetText(format("%s%s", L.gui_threat, targetName))
	else
		-- clear header text of unit name
		CTM.headerText:SetText(format("%s%s", L.gui_threat, ""))
		-- hide bars when no target
		for i = 1, C.bar.count do
			bars[i]:Hide()
		end
		oldTime = 0
	end
end

if A.classic then
	ThreatLib:RegisterCallback("Activate", CheckStatus)
	ThreatLib:RegisterCallback("Deactivate", CheckStatus)
	ThreatLib:RegisterCallback("ThreatUpdated", CheckStatus)
	ThreatLib:RequestActiveOnSolo(true)
end

-----------------------------
-- UPDATE FRAME
-----------------------------
local function SetPosition(f)
	local a1, _, a2, x, y = f:GetPoint()
	C.frame.position = {a1, "UIParent", a2, x, y}
end

local function OnDragStart(f)
	f:StartMoving()
end

local function OnDragStop(f)
	f:StopMovingOrSizing()
	SetPosition(f)
end

local function UpdateFont(fs)
	fs:SetFont(C.font.family, C.font.size, C.font.style)
	fs:SetVertexColor(unpack(C.font.color))
	fs:SetShadowOffset(C.font.shadow and 1 or 0, C.font.shadow and -1 or 0)
end

function CTM:UpdateFrame()
	self:SetSize(C.frame.width + 2, ((C.bar.height + C.bar.padding - 1) * C.bar.count) - C.bar.padding)
	self:ClearAllPoints()
	self:SetPoint(unpack(C.frame.position))
	self:SetScale(C.frame.scale)

	if not C.frame.locked then
		self:EnableMouse(true)
		self:SetMovable(true)
		self:SetClampedToScreen(true)
		self:RegisterForDrag("LeftButton")
		self:SetScript("OnDragStart", OnDragStart)
		self:SetScript("OnDragStop", OnDragStop)
	else
		self:EnableMouse(false)
		self:SetMovable(false)
	end

	-- Background
	self.bg:SetAllPoints()
	self.bg:SetVertexColor(unpack(C.frame.color))

	-- Header
	if C.frame.headerShow then
		self.header:SetSize(C.frame.width + 4, C.bar.height)
		self.header:SetStatusBarTexture(C.bar.texture)

		self.header:SetPoint("TOPLEFT", self, -1, C.bar.height - 1)
		self.header:SetStatusBarColor(unpack(C.frame.headerColor))

		self.header.backdrop:SetBackdropColor(0, 0, 0, 0) -- ugly, but okay for now
		self.header.backdrop:SetBackdropBorderColor(0, 0, 0, C.frame.headerColor[4]) -- adjust alpha for border

		self.headerText:SetText(format("%s%s", L.gui_threat, ""))

		UpdateFont(self.headerText)

		self.header:Show()
	else
		self.header:Hide()
	end

	-- Create StatusBars
	-- for i = 1, C.bar.count do
	for i = 1, 40 do
		if not bars[i] then
			bars[i] = CreateStatusBar(self)
		end

		local bar = bars[i]

		if i == 1 then
			bar:SetPoint("TOP", 0, 0)
		else
			bar:SetPoint("TOP", bars[i - 1], "BOTTOM", 0, -C.bar.padding + 1)
		end
		bar:SetSize(C.frame.width + 4, C.bar.height)
		bar:SetStatusBarTexture(C.bar.texture)

		-- BG
		bar.bg:SetTexture(C.bar.texture)
		-- Name
		bar.name:SetPoint("LEFT", bar, 4, 0)
		UpdateFont(bar.name)
		-- Perc
		bar.perc:SetPoint("RIGHT", bar, -2, 0)
		UpdateFont(bar.perc)
		-- Value
		-- bar.val:SetPoint("RIGHT", bar, -40, 0)
		bar.val:SetPoint("RIGHT", bar, -(C.font.size * 3.5), 0)
		UpdateFont(bar.val)

		-- Adjust Name
		bar.name:SetPoint("RIGHT", bar.val, "LEFT", -10, 0) -- right point of name is left point of value
	end
end

-----------------------------
-- TEST MODE
-----------------------------
local function TestMode()
	if InCombatLockdown() then return end

	C.frame.test = true
	for i = 1, C.bar.count do
		threatData[i] = {
			unit = playerName,
			scaledPercent = i / C.bar.count * 100,
			threatValue = i * 1e4,
		}
		tinsert(bars, i)
	end
	UpdateThreatBars()
end

-----------------------------
-- NAMEPLATES
-----------------------------
local function UpdateNameplateThreat(self)
	if not InCombatLockdown() or not C.general.nameplateThreat then return end
	local unit = self.unit
	if not unit then return end
	if not unit:match("nameplate%d?$") then return end
	local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
	if not nameplate then return end
	local status = UnitThreatSituation("player", unit)
	if status then
		if C.general.invertColors then
			if status == 3 then
				status = 0
			elseif status == 0 then
				status = 3
			end
		end
		self.healthBar:SetStatusBarColor(unpack(threatColors[status]))
	end
end

if A.classic then
	-- since UNIT_THREAT_LIST_UPDATE isn't a thing in Classic, health color doesn't update nearly as frequently
	-- we'll instead hook the range check since it is OnUpdate - gross, but it works for now
	hooksecurefunc("CompactUnitFrame_UpdateInRange", UpdateNameplateThreat)
else
	hooksecurefunc("CompactUnitFrame_UpdateHealthColor", UpdateNameplateThreat)
	hooksecurefunc("CompactUnitFrame_UpdateAggroFlash", UpdateNameplateThreat)
end

-----------------------------
-- VERSION CHECK
-----------------------------
local group = {}
local groupSort = {}

local function CheckVersion(onlyOutdated)
	if onlyOutdated then
		print(L.version_list_outdated)
	else
		print(L.version_list)
	end
	local latestRevision = ThreatLib.latestSeenRevision
	local revisions = ThreatLib.partyMemberRevisions
	local agents = ThreatLib.partyMemberAgents
	for k, v in pairs(group) do
		group[k] = nil
	end
	local numGroupMembers = GetNumGroupMembers()
	local inRaid = IsInRaid()
	if numGroupMembers > 0 then
		local unit = inRaid and "raid" or "party"
		for i = 1, inRaid and numGroupMembers or 4 do
			local name = UnitName(unit .. i)
			if name then
				group[name] = true
			end
		end
		for i = 1, #groupSort do
			tremove(groupSort)
		end
		for k, _ in pairs(group) do
			tinsert(groupSort, k)
		end
		table.sort(groupSort)
		print(L.version_divider)
		for _, v in ipairs(groupSort) do
			if not onlyOutdated or (not revisions[v] or revisions[v] < (latestRevision or 0)) then
				print(("%s: %s / %s %s"):format(v, agents[v] or ("|cff666666" .. UNKNOWN .. "|r"), revisions[v] or ("|cff666666" .. UNKNOWN .. "|r"), ThreatLib:IsCompatible(v) and "" or " - |cffff0000" .. L.version_incompatible))
			end
		end
	end
end

local function NotifyOldClients()
	if not ThreatLib:IsGroupOfficer("player") then
		print(L.message_leader)
		return
	end
	local latestRevision = ThreatLib.latestSeenRevision
	local revisions = ThreatLib.partyMemberRevisions
	local agents = ThreatLib.partyMemberAgents
	local numGroupMembers = GetNumGroupMembers()
	local inRaid = IsInRaid()
	if numGroupMembers > 0 then
		local unit = inRaid and "raid" or "party"
		for i = 1, inRaid and numGroupMembers or 4 do
			local name = UnitName(unit .. i)
			if name then
				if ThreatLib:IsCompatible(name) then
					if revisions[name] and revisions[name] < latestRevision then
						SendChatMessage(L.message_outdated, "WHISPER", nil, name)
					end
				else
					SendChatMessage(L.message_incompatible, "WHISPER", nil, name)
				end
			end
		end
	end
end

--[[
local function CheckVersionOLD(self, event, prefix, msg, channel, sender)
	if event == "CHAT_MSG_ADDON" then
		if prefix ~= "CTMVer" or sender == playerName then return end
		if tonumber(msg) ~= nil and tonumber(msg) > tonumber(A.version) then
			print("|cffff0000"..L.outdated.."|r")
			self:UnregisterEvent("CHAT_MSG_ADDON")
		end
	else
		if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
			C_ChatInfo.SendAddonMessage("CTMVer", tonumber(A.version), "INSTANCE_CHAT")
		elseif IsInRaid(LE_PARTY_CATEGORY_HOME) then
			C_ChatInfo.SendAddonMessage("CTMVer", tonumber(A.version), "RAID")
		elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
			C_ChatInfo.SendAddonMessage("CTMVer", tonumber(A.version), "PARTY")
		elseif IsInGuild() then
			C_ChatInfo.SendAddonMessage("CTMVer", tonumber(A.version), "GUILD")
		end
	end
end
--]]

-----------------------------
-- EVENTS
-----------------------------
CTM:RegisterEvent("PLAYER_LOGIN")
CTM:SetScript("OnEvent", function(self, event, ...)
	return self[event](self, event, ...)
end)

function CTM:PLAYER_ENTERING_WORLD(...)
	playerName = UnitName("player")
	playerGUID = UnitGUID("player")
	-- CheckVersionOLD(self, ...)
	CheckStatus()
end

function CTM:PLAYER_TARGET_CHANGED(...)
	C.frame.test = false
	CheckStatus()
end

function CTM:GROUP_ROSTER_UPDATE(...)
	-- CheckVersionOLD(self, ...)
	CheckStatus()
end

function CTM:PLAYER_REGEN_DISABLED(...)
	C.frame.test = false
	CheckStatus()
end

function CTM:PLAYER_REGEN_ENABLED(...)
	collectgarbage()
	C.frame.test = false
	CheckStatus()
end

function CTM:UNIT_THREAT_LIST_UPDATE(...)
	C.frame.test = false
	CheckStatus()
end

function CTM:PLAYER_LOGIN()
	C_ChatInfo.RegisterAddonMessagePrefix("CTMVer")

	CTM_Options = CTM_Options or {}
	C = CopyDefaults(A.defaultConfig, CTM_Options)

	-- Minimum of 1 Row
	if not C.bar.count or C.bar.count < 1 then
		C.bar.count = 1
	end

	-- Adjust fonts for CJK
	if A.locale == "koKR" or A.locale == "zhCN" or A.locale == "zhTW" then
		C.font.family = _G.STANDARD_TEXT_FONT
	end

	-- Setup Menu
	CTM.Menu = CreateFrame("Frame", A.addonName.."MenuFrame", UIParent, "UIDropDownMenuTemplate")
	self:UpdateMenu()

	-- Setup frame
	self:SetFrameStrata("BACKGROUND")
	self:SetFrameLevel(1)
	self:ClearAllPoints()
	self:SetPoint(unpack(C.frame.position))

	self.bg = self:CreateTexture(nil, "BACKGROUND", nil, -8)
	self.bg:SetColorTexture(1, 1, 1, 1)

	self.header = CreateStatusBar(self, true)
	self.header:SetScript("OnMouseUp", function(self, button)
		if button == "RightButton" then
			EasyMenu(CTM.menuTable, CTM.Menu, "cursor", 0, 0, "MENU")
		end
	end)

	self.headerText = CreateFS(self.header)
	self.headerText:SetPoint("LEFT", self.header, 4, -1)
	self.headerText:SetJustifyH("LEFT")

	self.bars = bars

	self:UpdateFrame()

	-- Get Colors
	colorUnit = {}
	colorFallback = {0.8, 0, 0.8, C.bar.alpha}
	colorMarker = {0.8, 0, 0, C.bar.alpha}

	threatColors = {
		[0] = C.general.threatColors.good,
		[1] = C.general.threatColors.neutral,
		[2] = C.general.threatColors.neutral,
		[3] = C.general.threatColors.bad
	}

	-- Test Mode
	C.frame.test = false

	if C.general.welcome then
		print("|c00FFAA00"..A.addonName.." v"..A.version.." - "..L.message_welcome.."|r")
	end

	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	-- self:RegisterEvent("CHAT_MSG_ADDON")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")

	if not A.classic then
		self:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
	end

	self:SetupConfig()

	loaded = true

	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end

-----------------------------
-- CONFIG
-----------------------------
function CTM:UpdateMenu()
	CTM.menuTable = {
		{text = L.frame_lock, notCheckable = false, checked = function() return C.frame.locked end, func = function()
			C.frame.locked = not C.frame.locked
			CTM:UpdateFrame()
		end},
		{text = L.frame_test, notCheckable = false, checked = function() return C.frame.test end, func = function()
			C.frame.test = not C.frame.test
			if C.frame.test then
				TestMode()
			else
				CheckStatus()
			end
		end},
		{text = L.version_check_all, notCheckable = true, func = function()
			CheckVersion()
		end},
		{text = L.version_check, notCheckable = true, func = function()
			CheckVersion(true)
		end},
		{text = L.gui_config, notCheckable = true, func = function()
			LibStub("AceConfigDialog-3.0"):Open("ClassicThreatMeter")
		end},
	}
end

function CTM:SetupConfig()
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(A.addonName, self.configTable)

	local ACD = LibStub("AceConfigDialog-3.0")
	self.config = {}
	self.config.general = ACD:AddToBlizOptions(A.addonName, A.addonName, nil, "general")
	self.config.appearance = ACD:AddToBlizOptions(A.addonName, L.appearance, A.addonName, "appearance")
	-- self.config.warnings = ACD:AddToBlizOptions(A.addonName, L.warnings, A.addonName, "warnings")
	self.config.version = ACD:AddToBlizOptions(A.addonName, L.version, A.addonName, "version")
end

CTM.configTable = {
	type = "group",
	name = A.addonName,
	get = function(info)
		return C[info[1]][info[2]]
	end,
	set = function(info, value) C[info[1]][info[2]] = value end,
	args = {
		general = {
			order = 1,
			type = "group",
			name = L.general,
			args = {
				general = {
					order = 1,
					name = L.general,
					type = "header",
				},
				welcome = {
					order = 2,
					name = L.general_welcome,
					type = "toggle",
					width = "full",
				},
				--[[
				minimap = {
					order = 3,
					name = L.general_test,
					type = "toggle",
					width = "full",
				},
				--]]
				--[[
				ignorePets = {
					order = 4,
					name = L.general_ignorePets,
					type = "toggle",
					width = "full",
				},
				--]]
				visibility = {
					order = 5,
					name = L.visibility,
					type = "header",
				},
				hideOOC = {
					order = 6,
					name = L.visibility_hideOOC,
					type = "toggle",
					width = "full",
					set = function(info, value)
						C[info[1]][info[2]] = value
						CheckStatus()
					end,
				},
				hideSolo = {
					order = 7,
					name = L.visibility_hideSolo,
					type = "toggle",
					width = "full",
					set = function(info, value)
						C[info[1]][info[2]] = value
						CheckStatus()
					end,
				},
				hideInPVP = {
					order = 8,
					name = L.visibility_hideInPvP,
					type = "toggle",
					width = "full",
					set = function(info, value)
						C[info[1]][info[2]] = value
						CheckStatus()
					end,
				},
				nameplates = {
					order = 9,
					name = L.nameplates,
					type = "header",
				},
				nameplateThreat = {
					order = 10,
					name = L.nameplates_enable,
					type = "toggle",
					width = "full",
				},
				invertColors = {
					order = 11,
					name = L.nameplates_invert,
					type = "toggle",
					width = "full",
				},
				threatColors = {
					order = 12,
					name = L.nameplate_colors,
					type = "group",
					inline = true,
					get = function(info)
						return unpack(C[info[1]][info[2]][info[3]])
					end,
					set = function(info, r, g, b)
						local cfg = C[info[1]][info[2]][info[3]]
						cfg[1] = r
						cfg[2] = g
						cfg[3] = b
					end,

					args = {
						good = {
							order = 1,
							name = L.color_good,
							type = "color",
							hasAlpha = false,
						},
						neutral = {
							order = 2,
							name = L.color_neutral,
							type = "color",
							hasAlpha = false,
						},
						bad = {
							order = 3,
							name = L.color_bad,
							type = "color",
							hasAlpha = false,
						},
					},
				},
			},
		},
		appearance = {
			order = 2,
			type = "group",
			name = L.appearance,
			get = function(info)
				return C[info[2]][info[3]]
			end,
			set = function(info, value)
				C[info[2]][info[3]] = value
				CTM:UpdateFrame()
			end,
			args = {
				frame = {
					order = 1,
					name = L.frame,
					type = "group",
					inline = true,
					args = {
						test = {
							order = 1,
							name = L.frame_test,
							type = "execute",
							func = function(info, value)
								C.frame.test = not C.frame.test
								if C.frame.test then
									TestMode()
								else
									CheckStatus()
								end
							end,
						},
						locked = {
							order = 2,
							name = L.frame_lock,
							type = "toggle",
						},
						scale = {
							order = 3,
							name = L.frame_scale,
							type = "range",
							min = 50,
							max = 300,
							step = 1,
							bigStep = 10,
							get = function(info)
								return C[info[2]][info[3]] * 100
							end,
							set = function(info, value)
								C[info[2]][info[3]] = value / 100
								CTM:UpdateFrame()
							end,
						},
						-- width here
						headerShow = {
							order = 4,
							name = L.frame_headerShow,
							type = "toggle",
						},
						frameColors = {
							order = 5,
							name = L.color,
							type = "group",
							inline = true,
							get = function(info)
								return unpack(C[info[2]][info[4]])
							end,
							set = function(info, r, g, b, a)
								local cfg = C[info[2]][info[4]]
								cfg[1] = r
								cfg[2] = g
								cfg[3] = b
								cfg[4] = a
								CTM:UpdateFrame()
							end,

							args = {
								color = {
									order = 1,
									name = L.frame_bg,
									type = "color",
									hasAlpha = true,
								},
								headerColor = {
									order = 2,
									name = L.frame_header,
									type = "color",
									hasAlpha = true,
								},
							},
						},
					},
				},
				bar = {
					order = 2,
					name = L.bar,
					type = "group",
					inline = true,
					args = {
						count = {
							order = 1,
							name = L.bar_count,
							type = "range",
							min = 1,
							max = 40,
							step = 1,
							set = function(info, value)
								local prev = C[info[2]][info[3]]
								C[info[2]][info[3]] = value
								if prev > value then
									for i = value + 1, prev do
										CTM.bars[i]:Hide()
									end
								end
								CTM:UpdateFrame()
							end,
						},
						-- growth direction
						height = {
							order = 3,
							name = L.bar_height,
							type = "range",
							min = 6,
							max = 64,
							step = 1,
						},
						padding = {
							order = 4,
							name = L.bar_padding,
							type = "range",
							min = 0,
							max = 16,
							step = 1,
						},
						-- marker
						-- texture
						-- custom color / class color
						-- alpha (for when using class colors)
						-- color / colormod
					},
				},
				font = {
					order = 3,
					name = L.font,
					type = "group",
					inline = true,
					args = {
						-- name
						size = {
							order = 2,
							name = L.font_size,
							type = "range",
							min = 6,
							max = 64,
							step = 1,
						},
						style = {
							order = 3,
							name = L.font_style,
							type = "select",
							values = {
								[""] = "NONE",
								["OUTLINE"] = "OUTLINE",
								["THICKOUTLINE"] = "THICKOUTLINE",
							},
							style = "dropdown",
						},
						shadow = {
							order = 4,
							name = L.font_shadow,
							type = "toggle",
							width = "full",
						},
					},
				},
				reset = {
					order = 4,
					name = L.reset,
					type = "execute",
					func = function(info, value)
						CTM_Options = {}
						C = CopyDefaults(A.defaultConfig, CTM_Options)
						CTM:UpdateFrame()
					end,
				},
			},
		},
		--[[
		warnings = {
			order = 3,
			type = "group",
			name = L.warnings,
			args = {
				visual = {
					order = 1,
					name = L.warnings_visual,
					type = "toggle",
					width = "full",
				},
				sounds = {
					order = 2,
					name = L.warnings_sounds,
					type = "toggle",
					width = "full",
				},
				threshold = {
					order = 3,
					name = L.warnings_threshold,
					type = "range",
					min = 50,
					max = 100,
					step = 1,
					bigStep = 10,
					-- get / set
				},
				warningFile = {
					order = 4,
					name = L.sound_warningFile,
					type = "toggle",
					width = "full",
				},
				pulledFile = {
					order = 5,
					name = L.sound_pulledFile,
					type = "toggle",
					width = "full",
				},
			},
		},
		--]]
		version = {
			order = 4,
			type = "group",
			name = L.version,
			args = {
				version = {
					order = 1,
					name = L.version,
					type = "header",
				},
				version_check = {
					order = 2,
					name = L.version_check,
					type = "execute",
					func = function(info, value)
						CheckVersion()
					end,
				},
				version_check_all = {
					order = 3,
					name = L.version_check_all,
					type = "execute",
					func = function(info, value)
						CheckVersion(true)
					end,
				},
				version_notify = {
					order = 4,
					name = L.version_notify,
					type = "execute",
					func = function(info, value)
						NotifyOldClients()
					end,
				},
			},
		},
	},
}

SLASH_CLASSICTHREATMETER1 = "/ctm"
SLASH_CLASSICTHREATMETER2 = "/threat"
SLASH_CLASSICTHREATMETER3 = "/classicthreatmeter"
SlashCmdList["CLASSICTHREATMETER"] = function()
	LibStub("AceConfigDialog-3.0"):Open("ClassicThreatMeter")
end

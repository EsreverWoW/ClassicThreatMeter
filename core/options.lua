local parent, A, C, L, _ = ..., unpack(select(2, ...))

-----------------------------
-- VARIABLES
-----------------------------
-- addon info
A.addonName		= parent
A.addonColor	= "00FFAA00"
A.addonShortcut	= "ctm"
A.version		= GetAddOnMetadata(parent, "Version")

-- drag frames
A.dragFrames	= {}

-----------------------------
-- FUNCTIONS
-----------------------------
-- A:GetPoint
function A:GetPoint(frame)
	if not frame then return end
	local point = {}
	point.a1, point.af, point.a2, point.x, point.y = frame:GetPoint()
	if point.af and point.af:GetName() then
		point.af = point.af:GetName()
	end
	return point
end

local function OnDragStart(self, button)
	if IsShiftKeyDown() then
		if button == "LeftButton" then
			self:GetParent():StartMoving()
		end
	end
end

-- A:ResetPoint
function A:ResetPoint(frame)
	if not frame then return end
	if not frame.defaultPoint then return end
	if InCombatLockdown() then return end
	local point = frame.defaultPoint
	frame:ClearAllPoints()
	if point.af and point.a2 then
		frame:SetPoint(point.a1 or "CENTER", point.af, point.a2, point.x or 0, point.y or 0)
	elseif point.af then
		frame:SetPoint(point.a1 or "CENTER", point.af, point.x or 0, point.y or 0)
	else
		frame:SetPoint(point.a1 or "CENTER", point.x or 0, point.y or 0)
	end
end

-- A:UnlockFrame
function A:UnlockFrame(frame)
	if not frame then return end
	if not frame:IsUserPlaced() then return end
	if frame.frameVisibility then
	if frame.frameVisibilityFunc then
		UnregisterStateDriver(frame, frame.frameVisibilityFunc)
	end
	RegisterStateDriver(frame, "visibility", "show")
	end
	frame.dragFrame:Show()
end

-- A:LockFrame
function A:LockFrame(frame)
	if not frame then return end
	if not frame:IsUserPlaced() then return end
	if frame.frameVisibility then
		if frame.frameVisibilityFunc then
			UnregisterStateDriver(frame, "visibility")
			-- hack to make it refresh properly, otherwise if you had state n (no vehicle exit button) it would not update properly because the state n is still in place
			RegisterStateDriver(frame, frame.frameVisibilityFunc, "blizzfix")
			RegisterStateDriver(frame, frame.frameVisibilityFunc, frame.frameVisibility)
		else
			RegisterStateDriver(frame, "visibility", frame.frameVisibility)
		end
	end
	frame.dragFrame:Hide()
end

-- A:UnlockFrames
function A:UnlockFrames(frames, str)
	if not frames then return end
	for idx, frame in next, frames do
		self:UnlockFrame(frame)
	end
	print(str)
end

-- A:LockFrames
function A:LockFrames(frames, str)
	if not frames then return end
	for idx, frame in next, frames do
		self:LockFrame(frame)
	end
	print(str)
end

-- A:ResetFrames
function A:ResetFrames(frames, str)
	if not frames then return end
	if InCombatLockdown() then
		print("|c00FF0000ERROR:|r "..str.." not allowed while in combat!")
		return
	end
	for idx, frame in next, frames do
		self:ResetPoint(frame)
	end
	print(str)
end

local function OnDragStop(self)
	self:GetParent():StopMovingOrSizing()
end

local function OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_TOP")
	GameTooltip:AddLine(self:GetParent():GetName(), 0, 1, 0.5, 1, 1, 1)
	GameTooltip:AddLine("Hold SHIFT + LeftButton to drag.", 1, 1, 1, 1, 1, 1)
	GameTooltip:Show()
end

local function OnLeave(self)
	GameTooltip:Hide()
end

-- A:CreateDragFrame
function A:CreateDragFrame(frame, frames, inset, clamp)
	if not frame or not frames then return end
	-- save the default position for later
	frame.defaultPoint = self:GetPoint(frame)
	table.insert(frames, frame) --add frame object to the list
	-- anchor a dragable frame on frame
	local df = CreateFrame("Frame", nil, frame)
	df:SetAllPoints(frame)
	df:SetFrameStrata("HIGH")
	df:SetHitRectInsets(inset or 0, inset or 0, inset or 0, inset or 0)
	df:EnableMouse(true)
	df:RegisterForDrag("LeftButton")
	df:SetScript("OnDragStart", OnDragStart)
	df:SetScript("OnDragStop", OnDragStop)
	df:SetScript("OnEnter", OnEnter)
	df:SetScript("OnLeave", OnLeave)
	df:Hide()
	-- overlay texture
	local t = df:CreateTexture(nil, "OVERLAY", nil, 6)
	t:SetAllPoints(df)
	t:SetColorTexture(1, 1, 1)
	t:SetVertexColor(0, 1, 0)
	t:SetAlpha(0.3)
	df.texture = t
	-- frame stuff
	frame.dragFrame = df
	frame:SetClampedToScreen(clamp or false)
	frame:SetMovable(true)
	frame:SetUserPlaced(true)
end

-- A:CreateSlashCmd
function A:CreateSlashCmd(addonName, shortcut, frames, color)
	if not addonName or not shortcut or not frames then return end
		SlashCmdList[shortcut] = function(cmd)
		if (cmd:match("unlock")) then
			self:UnlockFrames(frames, "|c"..(color or defaultColor)..addonName.."|r frames unlocked")
		elseif (cmd:match("lock")) then
			self:LockFrames(frames, "|c"..(color or defaultColor)..addonName.."|r frames locked")
		elseif (cmd:match("reset")) then
			self:ResetFrames(frames, "|c"..(color or defaultColor)..addonName.."|r frames reset")
		else
			print("|c"..(color or defaultColor)..addonName.." command list:|r")
			print("|c"..(color or defaultColor).."\/"..shortcut.." lock|r, to lock all frames")
			print("|c"..(color or defaultColor).."\/"..shortcut.." unlock|r, to unlock all frames")
			print("|c"..(color or defaultColor).."\/"..shortcut.." reset|r, to reset all frames")
		end
	end
	_G["SLASH_"..shortcut.."1"] = "/"..shortcut
end

local A, C, L, _ = unpack(select(2, ...))

-----------------------------
-- Default Config
-----------------------------
local defaultTexture	= [[Interface\ChatFrame\ChatFrameBackground]]
local defaultFont		= [[Interface\AddOns\ClassicThreatMeter\media\NotoSans-SemiCondensedBold.ttf]] or STANDARD_TEXT_FONT

-- general
C.general = {
	welcome				= true,									-- display welcome message
	update				= 0.25,									-- time (in seconds) between updates
	scale				= 1,									-- global scale
	hideOOC				= false,								-- hide frame when out of combat
	hideSolo			= false,								-- hide frame when not in a group
	hideInPVP			= true,									-- hide frame when in battlegrounds
}

C.frame = {
	position			= {										-- frame position (movable in game via "/ctm")
							a1 = "LEFT",
							af = UIParent,
							a2 = "LEFT",
							x = 50,
							y = 0
						},
	headerShow			= true,									-- show frame header
	headerColor			= {r = 0, g = 0, b = 0, a = 0.8},		-- frame header color
	bgShow				= true,									-- show frame background
	bgColor				= {r = 0, g = 0, b = 0, a = 0.35},		-- frame background color
}

-- backdrop settings
C.backdrop = {
	bgFile				= defaultTexture,						-- backdrop file location
	bgColor				= {r = 1, g = 1, b = 1, a = 0.1},		-- backdrop color
	edgeFile			= defaultTexture,						-- backdrop edge file location
	edgeColor			= {r = 0, g = 0, b = 0, a = 1 },		-- backdrop edge color
	tile				= false,								-- backdrop texture tiling
	tileSize			= 0,									-- backdrop tile size
	edgeSize			= 1,									-- backdrop edge size
	inset				= 0,									-- backdrop inset value
}

-- threat bar settings
C.bar = {
	count				= 7,									-- maximum amount of bars to show
	descend				= true,									-- sort bars descending / ascending
	width				= 217,									-- bar width
	height				= 15,									-- bar height
	padding				= 0,									-- padding between bars
	marker				= false,								-- mark your statusbar in red
	texture				= defaultTexture,						-- texture file location
	classColor			= true,									-- use class color
	defaultColor		= {r = 0.8, g = 0, b = 0.8},			-- color to use when classColor is false
	alpha				= 1,									-- statusbar alpha
	colorMod			= 0,									-- color modifier
}

C.font = {
	family				= defaultFont,							-- font file location
	size				= 11,									-- font size
	style				= "OUTLINE",							-- font style
	color				= {r = 1, g = 1, b = 1, a = 1},			-- font color
	shadow				= false,								-- font dropshadow
}

C.visual = {
	enable				= true,									-- enable screen flash
}

C.sound = {
	enable				= true,									-- enable sounds
	threshold			= 80,									-- warning sound threshold (threat percentage)
	warningFile			= [[Sound\Interface\Aggro_Enter_Warning_State.ogg]],
	pulledFile			= [[Sound\Interface\Aggro_Pulled_Aggro.ogg]],
}
local A, C, L, _ = unpack(select(2, ...))

-----------------------------
--	enUS and enGB clients
-----------------------------
-- welcome message
L.welcome			= "Type /ctm for options."

-- version check
L.outdated			= "New version of CTM available! Please download the latest version."
L.incompatible		= "CTM is out of date and is incompatible with someone in your group. Please upgrade immediately."

-- main frame
L.gui.threat		= "Threat"

-- config frame
L.general.welcome	= "Display welcome message when logging in."
L.general.update	= "Time (in seconds) between updates."
L.general.scale		= "Global scale modifier."
L.general.hideOOC	= "Hide frame when out of combat."
L.general.hideSolo	= "Hide frame when not in a group."
L.general.hideInPvP	= "Hide frame when in battlegrounds."

L.frame.position	= "Toggle frame movement for repositioning."
L.frame.headerShow	= "Show the frame header."
L.frame.headerColor	= "Color for the threat frame header."
L.frame.bgShow		= "Show the frame background."
L.frame.bgColor		= "Color for the threat frame background."

L.bar.count			= "Maximum number or bars to show."
L.bar.descend		= "Change bar sorting."
L.bar.width			= "Bar width."
L.bar.height		= "Bar height."
L.bar.padding		= "Padding between bars."
L.bar.marker		= "Mark your own threat bar in red."
L.bar.texture		= "Bar texture file."
L.bar.classColor	= "Use class color for bars."
L.bar.defaultColor	= "Color used if class color is disabled."
L.bar.alpha			= "Bar alpha."
L.bar.colorMod		= "Color value modifer."

L.font.family		= "Font file."
L.font.size			= "Font size."
L.font.style		= "Font style."
L.font.color		= "Font color."
L.font.shadow		= "Font dropshadow."

L.visual.enable		= "Enable visual screen alerts."

L.sound.enable		= "Enable sounds."
L.sound.threshold	= "Warning threshold."
L.sound.warningFile	= "Warning sound file."
L.sound.pulledFile	= "Pulled aggro sound file."
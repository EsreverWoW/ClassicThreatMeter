-----------------------------
--	Init ClassicThreatMeter
-----------------------------
local parent, ns = ...
ns[1] = {} -- A, Functions
ns[2] = {} -- C, Config
ns[3] = {} -- L, Localization

-----------------------------
--	Locale Tables
-----------------------------
local sections = {
	"gui",
	"general",
	"frame",
	"bar",
	"font",
	"visual",
	"sound",
}

for i = 1, #sections do
	ns[3][sections[i]] = {}
end
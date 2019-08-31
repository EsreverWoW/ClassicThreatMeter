﻿local MAJOR_VERSION = "ThreatClassic-1.0"
local MINOR_VERSION = 3

if MINOR_VERSION > _G.ThreatLib_MINOR_VERSION then _G.ThreatLib_MINOR_VERSION = MINOR_VERSION end

ThreatLib_funcs[#ThreatLib_funcs + 1] = function()
	local ThreatLib = _G.ThreatLib
	local NEFARIAN_ID = 11583

	ThreatLib:GetModule("NPCCore"):RegisterModule(NEFARIAN_ID, function(Nefarian)
		Nefarian:RegisterTranslation("enUS", function() return {
			["BURN! You wretches! BURN!"] = "BURN! You wretches! BURN!"
		} end)

		Nefarian:RegisterTranslation("deDE", function() return {
			["BURN! You wretches! BURN!"] = "BRENNT! Ihr Elenden! BRENNT!"
		} end)

		Nefarian:RegisterTranslation("frFR", function() return {
			["BURN! You wretches! BURN!"] = nil
		} end)

		Nefarian:RegisterTranslation("koKR", function() return {
			["BURN! You wretches! BURN!"] = "불타라! 활활! 불타라!"
		} end)

		Nefarian:RegisterTranslation("zhTW", function() return {
			["BURN! You wretches! BURN!"] = "燃燒吧！你這個不幸的人！燃燒吧！"
		} end)

		Nefarian:RegisterTranslation("zhCN", function() return {
			["BURN! You wretches! BURN!"] = "燃烧吧！你这个"
		} end)

		local phaseTwo = Nefarian:GetTranslation("BURN! You wretches! BURN!")
		Nefarian:UnregisterTranslations()

		function Nefarian:Init()
			self:RegisterCombatant(NEFARIAN_ID, true)
			self:RegisterChatEvent("yell", phaseTwo, self.phaseTwo)
		end

		function Nefarian:phaseTwo()
			self:WipeRaidThreatOnMob(NEFARIAN_ID)
		end
	end)
end

local MAJOR_VERSION = "ThreatClassic-1.0"
local MINOR_VERSION = 1

if MINOR_VERSION > _G.ThreatLib_MINOR_VERSION then _G.ThreatLib_MINOR_VERSION = MINOR_VERSION end
if select(2, _G.UnitClass("player")) ~= "WARRIOR" then return end

ThreatLib_funcs[#ThreatLib_funcs + 1] = function()
	local _G = _G
	local select = _G.select
	local GetTalentInfo = _G.GetTalentInfo
	local GetShapeshiftForm = _G.GetShapeshiftForm
	local GetSpellInfo = _G.GetSpellInfo
	local pairs, ipairs = _G.pairs, _G.ipairs
	local GetTime = _G.GetTime
	local UnitDebuff = _G.UnitDebuff

	local ThreatLib = _G.ThreatLib

	local Warrior = ThreatLib:GetOrCreateModule("Player")

	local threatValues = {
		sunder = {
			[7386] = 100, -- 47? https://github.com/magey/classic-warrior/wiki/Threat-Mechanics
			[7405] = 140,
			[8380] = 180,
			[11596] = 220,
			[11597] = 260
		},
		shieldBash = {
			[72] = 180, -- 43? https://github.com/magey/classic-warrior/wiki/Threat-Mechanics
			[1671] = 180,
			[1672] = 180
		},
		revenge = {
			[6572] = 155, -- 83? https://github.com/magey/classic-warrior/wiki/Threat-Mechanics
			[6574] = 195,
			[7379] = 235,
			[11600] = 275,
			[11601] = 315,
			[25288] = 355
		},
		heroicStrike = {
			[78] = 20,
			[284] = 39, -- 31? https://github.com/magey/classic-warrior/wiki/Threat-Mechanics
			[285] = 59,
			[1608] = 78,
			[11564] = 98,
			[11565] = 118,
			[11566] = 137,
			[11567] = 145,
			[25286] = 175 -- 173?
		},
		shieldSlam = {
			[23922] = 160,
			[23923] = 190,
			[23924] = 220,
			[23925] = 250
		},
		cleave = {
			[845] = 10,
			[7369] = 40,
			[11608] = 60,
			[11609] = 70,
			[20569] = 100
		},
		hamstring = {
			[1715] = 61, -- 22? https://github.com/magey/classic-warrior/wiki/Threat-Mechanics
			[7372] = 101,
			[7373] = 141,
		},
		--[[
		mockingBlow = {
			[694] = mockingBlowFactor * 16,
			[7400] = mockingBlowFactor * 26,
			[7402] = mockingBlowFactor * 36,
			[20559] = mockingBlowFactor * 46,
			[20560] = mockingBlowFactor * 56
		},
		--]]
		battleShout = {
			[6673] = 5, -- 1? https://github.com/magey/classic-warrior/wiki/Threat-Mechanics
			[5242] = 11, -- 12? https://github.com/magey/classic-warrior/wiki/Threat-Mechanics
			[6192] = 17,
			[11549] = 26,
			[11550] = 39,
			[11551] = 55,
			[25289] = 70
		},
		demoShout = {
			[1160] = 11, -- https://github.com/magey/classic-warrior/wiki/Threat-Mechanics
			[6190] = 17,
			[11554] = 21,
			[11555] = 32,
			[11556] = 43
		},
		thunderclap = {
			[6343] = 17, -- 13? https://github.com/magey/classic-warrior/wiki/Threat-Mechanics
			[8198] = 40,
			[8204] = 64,
			[8205] = 96,
			[11580] = 143,
			[11581] = 180
		},
		execute = {
			[5308] = true,
			[20658] = true,
			[20660] = true,
			[20661] = true,
			[20662] = true
		},
		disarm = {
			[676] = 104
		}
	}

	local function init(self, t, f)
		local func = function(self, spellID, target)
			self:AddTargetThreat(target, f(self, spellID))
		end
		for k, v in pairs(t) do
			self.CastLandedHandlers[k] = func
		end
	end

	function Warrior:ClassInit()
		-- Taunt
		self.CastLandedHandlers[355] = self.Taunt

		-- Non-transactional abilities		
		init(self, threatValues.heroicStrike, self.HeroicStrike)
		init(self, threatValues.shieldBash, self.ShieldBash)
		init(self, threatValues.shieldSlam, self.ShieldSlam)
		init(self, threatValues.revenge, self.Revenge)
		-- init(self, threatValues.mockingBlow, self.MockingBlow)
		init(self, threatValues.hamstring, self.Hamstring)
		init(self, threatValues.thunderclap, self.Thunderclap)
		init(self, threatValues.disarm, self.Disarm)

		-- Transactional stuff
		-- Sunder Armor
		local func = function(self, spellID, target)
			self:AddTargetThreatTransactional(target, spellID, self:SunderArmor(spellID))
		end
		for k, v in pairs(threatValues.sunder) do
			self.CastHandlers[k] = func
			self.MobDebuffHandlers[k] = self.GetSunder
		end

		-- Ability damage modifiers
		for k, v in pairs(threatValues.execute) do
			self.AbilityHandlers[v] = self.Execute
		end

		-- Shouts
		-- Battle Shout
		local bShout = function(self, spellID, target)
			self:AddThreat(threatValues.battleShout[spellID] * self:threatMods())
		end
		for k, v in pairs(threatValues.battleShout) do
			self.CastHandlers[k] = bShout
		end

		-- Demoralizing Shout
		local demoShout = function(self, spellID, target)
			self:AddThreat(threatValues.demoShout[spellID] * self:threatMods())
		end
		for k, v in pairs(threatValues.demoShout) do
			self.CastHandlers[k] = demoShout
		end

		local demoShoutMiss = function(self, spellID, target)
			self:rollbackTransaction(target, spellID)
		end
		for k, v in pairs(threatValues.demoShout) do
			self.CastMissHandlers[k] = demoShoutMiss
		end

		-- Set names don't need to be localized.
		self.itemSets = {
			["Might"] = { 16866, 16867, 16868, 16862, 16864, 16861, 16865, 16863 }
		}
	end

	function Warrior:ClassEnable()
		self:GetStanceThreatMod()
		self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", "GetStanceThreatMod" )
	end

	function Warrior:ScanTalents()
		-- Defiance
		if ThreatLib.Classic then
			local rank = _G.select(5, GetTalentInfo(3, 9))
			self.defianceMod = 1 + (0.05 * rank)
		else
			self.defianceMod = 1 -- for when testing in retail
		end
	end

	function Warrior:GetStanceThreatMod()
		self.isTanking = false
		if GetShapeshiftForm() == 2 then
			self.passiveThreatModifiers = 1.3 * self.defianceMod
			self.isTanking = true
		elseif GetShapeshiftForm() == 3 then
			self.passiveThreatModifiers = 0.8
		else
			self.passiveThreatModifiers = 0.8
		end
		self.totalThreatMods = nil -- Needed to recalc total mods
	end

	function Warrior:SunderArmor(spellID)
		local sunderMod = 1
		if self:getWornSetPieces("Might") >= 8 then
			sunderMod = 1.15
		end
		local threat = threatValues.sunder[spellID]
		return threat * sunderMod * self:threatMods()
	end

	function Warrior:Taunt(spellID, target)
		local targetThreat = ThreatLib:GetThreat(UnitGUID("targettarget"), target)
		local myThreat = ThreatLib:GetThreat(UnitGUID("player"), target)
		if targetThreat > 0 and targetThreat > myThreat then
			pendingTauntTarget = target
			pendingTauntOffset = targetThreat-myThreat
		elseif targetThreat == 0 then
			local maxThreat = ThreatLib:GetMaxThreatOnTarget(target)
			pendingTauntTarget = target
			pendingTauntOffset = maxThreat-myThreat
		end
		self.nextEventHook = self.TauntNextHook
	end

	function Warrior:TauntNextHook(timestamp, subEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID)
		if pendingTauntTarget and (subEvent ~= "SPELL_MISSED" or spellID ~= 355) then
			self:AddTargetThreat(pendingTauntTarget, pendingTauntOffset)
			ThreatLib:PublishThreat()
		end
		pendingTauntTarget = nil
		pendingTauntOffset = nil
	end

	function Warrior:HeroicStrike(spellID)
		return threatValues.heroicStrike[spellID] * self:threatMods()
	end

	function Warrior:ShieldBash(spellID)
		return threatValues.shieldBash[spellID] * self:threatMods()
	end

	function Warrior:ShieldSlam(spellID)
		return threatValues.shieldSlam[spellID] * self:threatMods()
	end

	function Warrior:Revenge(spellID)
		return threatValues.revenge[spellID] * self:threatMods()
	end

	--[[
	function Warrior:MockingBlow(spellID)
		return threatValues.mockingBlow[spellID] * self:threatMods()
	end
	--]]

	function Warrior:Hamstring(spellID)
		return threatValues.hamstring[spellID] * self:threatMods()
	end

	function Warrior:Thunderclap(spellID)
		return threatValues.thunderclap[spellID] * self:threatMods()
	end

	function Warrior:Execute(amount)
		return amount * 1.25
	end

	function Warrior:Disarm(spellID)
		return threatValues.disarm[spellID] * self:threatMods()
	end

	function Warrior:GetSunder(spellID, target)
		self:AddTargetThreat(target, self:SunderArmor(spellID))
	end
end

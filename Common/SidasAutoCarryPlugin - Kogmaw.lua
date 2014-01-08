--[[
 
        Auto Carry Plugin - Kogmaw Reborn PROdiction Edition
		Author: Kain
		Version: See version variable below.
		Copyright 2013

		Dependency: Sida's Auto Carry
 
		How to install:
			Make sure you already have AutoCarry installed.
			Name the script EXACTLY "SidasAutoCarryPlugin - Kogmaw.lua" without the quotes.
			Place the plugin in BoL/Scripts/Common folder.

		Features:

		
		Download: https://bitbucket.org/KainBoL/bol/raw/master/Common/SidasAutoCarryPlugin%20-%20Kogmaw.lua

		Version History:
			Version: 1.01
				Release

		To Do: Known issue: The Big One missile tracking can become out of sync in Reborn if script is started after missiles have been accrued, due to lack of Buff function support in Reborn. Revamped works great.
--]]

function Vars()
	curVersion = "1.01"

	if AutoCarry.Skills then IsSACReborn = true else IsSACReborn = false end

	-- Disable SAC Reborn's skills. Ours are better.
	if IsSACReborn then
		AutoCarry.Skills:DisableAll()
	end

	QRange, WRange, ERange, RRange = 625, 625, 850, 1700
	QSpeed, WSpeed, ESpeed, RSpeed = 1.3, 1.3, 1.3, math.huge
	QDelay, WDelay, EDelay, RDelay = 260, 260, 260, 1000
	QWidth, WWidth, EWidth, RWidth = 200, 200, 200, 200

	if IsSACReborn then
		SkillQ = AutoCarry.Skills:NewSkill(true, _Q, QRange, "Caustic Spittle", AutoCarry.SPELL_LINEAR, 0, false, false, QSpeed, QDelay, QWidth, false)
		SkillW = AutoCarry.Skills:NewSkill(true, _W, WRange, "Bio-Arcane Barrage", AutoCarry.SPELL_LINEAR, 0, false, false, WSpeed, WDelay, WWidth, false)
		SkillE = AutoCarry.Skills:NewSkill(true, _E, ERange, "Void Ooze", AutoCarry.SPELL_LINEAR, 0, false, false, ESpeed, EDelay, EWidth, false)
		SkillR = AutoCarry.Skills:NewSkill(true, _R, RRange, "Living Artillery", AutoCarry.SPELL_LINEAR, 0, false, false, RSpeed, RDelay, RWidth, false)
	else
		SkillQ = {spellKey = _Q, range = QRange, speed = QSpeed, delay = QDelay, width = QWidth, minions = false }
		SkillW = {spellKey = _W, range = WRange, speed = WSpeed, delay = WDelay, width = WWidth, minions = false }
		SkillE = {spellKey = _E, range = ERange, speed = ESpeed, delay = EDelay, width = EWidth, minions = false }
		SkillR = {spellKey = _R, range = RRange, speed = RSpeed, delay = RDelay, width = RWidth, minions = false }
	end

	QReady, WReady, EReady, RReady = false, false, false, false

	stacks, timer = 0, 0

	Target = nil

	-- Check to see if user failed to read the forum...
	if VIP_USER then
		if FileExist(SCRIPT_PATH..'Common/Collision.lua') then
			require "Collision"

			if type(Collision) ~= "userdata" then
				PrintChat("Your version of Collision.lua is incorrect. Please install v1.1.1 or later in Common folder.")
				return
			else
				assert(type(Collision.GetMinionCollision) == "function")
			end
		else
			PrintChat("Please install Collision.lua v1.1.1 or later in Common folder.")
			return
		end

		if FileExist(SCRIPT_PATH..'Common/2DGeometry.lua') then
			PrintChat("Please delete 2DGeometry.lua from your Common folder.")
		end
	end

	if VIP_USER then
		if IsSACReborn then
			PrintChat("<font color='#CCCCCC'> >> Kain's Kog'Maw - PROdiction 2.0 <</font>")
		else
			PrintChat("<font color='#CCCCCC'> >> Kain's Kog'Maw - VIP Prediction <</font>")
		end
	else
		PrintChat("<font color='#CCCCCC'> >> Kain's Kog'Maw - Free Prediction <</font>")
	end
end

function Menu()
	AutoCarry.PluginMenu:addParam("sep", "----- Kog'Maw by Kain: v"..curVersion.." -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("sep", "----- [ Combo ] -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("ComboQ", "Use Caustic Spittle", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("ComboW", "Use Bio-Arcane Barrage", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("ComboE", "Use Void Ooze", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("ComboR", "Use Living Artillery", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("sep", "----- [ Stacks ] -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("Max6", "Max Stacks At 6", SCRIPT_PARAM_SLICE, 2, 0, 6, 0)
	AutoCarry.PluginMenu:addParam("Max12", "Max Stacks At 12", SCRIPT_PARAM_SLICE, 3, 0, 6, 0)
	AutoCarry.PluginMenu:addParam("Max18", "Max Stacks At 18", SCRIPT_PARAM_SLICE, 4, 0, 6, 0)
	AutoCarry.PluginMenu:addParam("sep", "----- [ Killsteal ] -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("KillstealQ", "Use Caustic Spittle", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("KillstealE", "Use Void Ooze", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("KillstealR", "Use Living Artillery", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("sep", "----- [ Misc ] -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("MinMana", "Minimum Mana % After Cast", SCRIPT_PARAM_SLICE, 40, 0, 100, 0)
end

function PluginOnLoad()
	Vars()
	Menu()
end

function PluginOnTick()
	Target = AutoCarry.GetAttackTarget()
	SpellCheck()

	if GetTickCount() > timer + 6500 then stacks = 0 end
	Killsteal()

	if Target and not Target.dead and AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.MixedMode then
		if AutoCarry.PluginMenu.ComboQ then CastQ() end
		if AutoCarry.PluginMenu.ComboW then CastW() end
		if AutoCarry.PluginMenu.ComboE then CastE() end
	end

	if AutoCarry.PluginMenu.ComboR and ValidTarget(AutoCarry.GetAttackTarget(), GetRRange()) and (AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.MixedMode) then
		if (myHero.level > 5 and myHero.level < 12 and stacks < AutoCarry.PluginMenu.Max6)
		or (myHero.level > 11 and myHero.level < 18 and stacks < AutoCarry.PluginMenu.Max12)
		or (myHero.level > 17 and stacks < AutoCarry.PluginMenu.Max18) then
			if myHero.mana - GetMana() > (myHero.maxMana / 100) * AutoCarry.PluginMenu.MinMana then
				CastR(AutoCarry.GetAttackTarget())
			end
		end
	end
end

function SpellCheck()
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)
	AutoCarry.SkillsCrosshair.range = GetLongestRange()
end

function PluginOnProcessSpell(unit, spell)
	if unit.isMe and spell.name:lower():find("kogmawlivingartillery") then
		stacks = stacks + 1
		timer = GetTickCount()
	end
end

function CastQ(enemy)
	if not enemy then enemy = Target end

	if QReady and IsValid(enemy, QRange) then
		CastSpell(_Q, enemy)
	end
end

function CastW(enemy)
	if not enemy then enemy = Target end

	if WReady and IsValid(enemy, WRange) then
		CastSpell(_W)
	end
end

function CastE(enemy)
	if not enemy then enemy = Target end

	if EReady and IsValid(enemy, ERange) then
		if IsSACReborn then
			SkillE:ForceCast(enemy)
		else
			AutoCarry.CastSkillshot(SkillE, enemy)
		end
	end
end

function CastR(enemy)
	if not enemy then enemy = Target end

	if RReady and IsValid(enemy, RRange) then
		if IsSACReborn then
			SkillR:ForceCast(enemy)
		else
			AutoCarry.CastSkillshot(SkillR, enemy)
		end
	end
end

function IsValid(enemy, dist)
	if enemy and enemy.valid and not enemy.dead and enemy.bTargetable and ValidTarget(enemy, dist) then
		return true
	else
		return false
	end
end

function GetMana()
	local mana = 40 + (40 * stacks)
	return mana < 401 and mana or 400
end

function GetRRange()
	if myHero:GetSpellData(_R).level == 1 then
		return 1400
	elseif myHero:GetSpellData(_R).level == 2 then
		return 1700
	elseif myHero:GetSpellData(_R).level == 3 then
		return 2200
	end
end

function GetLongestRange()
	local range = GetRRange()
	if range and range > ERange then
		return range
	else
		return ERange
	end
end
function Killsteal()
	for i, enemy in ipairs(GetEnemyHeroes()) do
		local enemyDistance = GetDistance(enemy)
		local QDmg = getDmg("Q", enemy, myHero)
		local EDmg = getDmg("E", enemy, myHero)
		local RDmg = getDmg("R", enemy, myHero)
		local AADmg = getDmg("AD", enemy, myHero)

		if enemy and not enemy.dead and enemy.health > AADmg or (enemy.health < AADmg and enemyDistance > GetTrueRange()) then
			if AutoCarry.PluginMenu.KillstealR and RReady and enemy.health <= RDmg and enemyDistance < RRange then
				CastR(enemy)
			elseif AutoCarry.PluginMenu.KillstealQ and QReady and enemy.health <= QDmg and enemyDistance < QRange then
				CastQ(enemy)
			elseif AutoCarry.PluginMenu.KillstealE and EReady and enemy.health <= EDmg and enemyDistance < ERange then
				CastE(enemy)
			elseif AutoCarry.PluginMenu.KillstealQ and AutoCarry.PluginMenu.KillstealR and QReady and RReady and enemy.health <= (QDmg + RDmg) and enemyDistance < QRange then
				CastQ(enemy)
				CastR(enemy)
			elseif AutoCarry.PluginMenu.KillstealE and AutoCarry.PluginMenu.KillstealR and EReady and RReady and enemy.health <= (EDmg + RDmg) and enemyDistance < ERange then
				CastQ(enemy)
				CastR(enemy)
			elseif AutoCarry.PluginMenu.KillstealQ and AutoCarry.PluginMenu.KillstealE and QReady and EReady and enemy.health <= (QDmg + EDmg) and enemyDistance < ERange then
				CastE(enemy)
				CastQ(enemy)
			elseif AutoCarry.PluginMenu.KillstealQ and AutoCarry.PluginMenu.KillstealE and AutoCarry.PluginMenu.KillstealR and QReady and EReady and RReady and
				enemy.health <= (QDmg + EDmg + RDmg) and enemyDistance < QRange then
				CastQ(enemy)
				CastE(enemy)
				CastR(enemy)
			end
		end
	end
end

function GetTrueRange()
	return myHero.range + GetDistance(myHero.minBBox)
end

--UPDATEURL=
--HASH=B15D36BE2E1C58B5F86BE7236AD20E6C

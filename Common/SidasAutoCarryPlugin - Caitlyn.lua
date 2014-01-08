--[[
 
        Auto Carry Plugin - Caitlyn Reborn PROdiction Edition
		Author: Kain
		Version: See version variable below.
		Copyright 2013

		Dependency: Sida's Auto Carry
 
		How to install:
			Make sure you already have AutoCarry installed.
			Name the script EXACTLY "SidasAutoCarryPlugin - Caitlyn.lua" without the quotes.
			Place the plugin in BoL/Scripts/Common folder.

		Features:
		
		Download: https://bitbucket.org/KainBoL/bol/raw/master/Common/SidasAutoCarryPlugin%20-%20Caitlyn.lua

		Version History:
			Version 1.12:
				Auto AA's best target if Headshot passive is available and enabled in menu.
				Alerts user if Headshot passive is available.

			Version: 1.0
				Release

		To Do: Known issue: The Big One missile tracking can become out of sync in Reborn if script is started after missiles have been accrued, due to lack of Buff function support in Reborn. Revamped works great.
--]]

if myHero.charName ~= "Caitlyn" then return end

function Vars()
	curVersion = 1.12

	if AutoCarry.Skills then IsSACReborn = true else IsSACReborn = false end

	-- Disable SAC Reborn's skills. Ours are better.
	if IsSACReborn then
		-- AutoCarry.Skills:DisableAll()
		AutoCarry.Skills:GetSkill(_Q).Enabled = false
	end

	KeyQ = string.byte("Q")
	KeyW = string.byte("W")
	KeyE = string.byte("E")
	KeyR = string.byte("R")

	QRange, WRange, ERange, RRange = 1250, 800, 1000, 2000
	EKnockbackRange = 400
	QSpeed, ESpeed = 2.1, 1.6
	QDelay, EDelay = 625, 250
	QWidth, EWidth = 100, 0

	if IsSACReborn then
		SkillQ = AutoCarry.Skills:NewSkill(true, _Q, QRange, "Piltover Peacemaker", AutoCarry.SPELL_LINEAR, 0, false, false, QSpeed, QDelay, QWidth, true)
		SkillQEscape = AutoCarry.Skills:NewSkill(true, _Q, QRange + EKnockbackRange, "Piltover Peacemaker", AutoCarry.SPELL_LINEAR, 0, false, false, QSpeed, QDelay, QWidth, true)
		SkillE = AutoCarry.Skills:NewSkill(true, _E, ERange, "90 Caliber Net", AutoCarry.SPELL_LINEAR, 0, false, false, ESpeed, EDelay, EWidth, false)
	else
		SkillQ = {spellKey = _Q, range = QRange, speed = QSpeed, delay = QDelay, width = QWidth, minions = true }
		SkillQEscape = {spellKey = _Q, range = QRange + EKnockbackRange, speed = QSpeed, delay = QDelay, width = QWidth, minions = true }
		SkillE = {spellKey = _E, range = ERange, speed = ESpeed, delay = EDelay, width = EWidth, minions = false }
	end

	-- Items
	ignite = nil
	DFGSlot, HXGSlot, BWCSlot, SheenSlot, TrinitySlot, LichBaneSlot = nil, nil, nil, nil, nil, nil
	QReady, WReady, EReady, RReady, DFGReady, HXGReady, BWCReady, IReady, FReady = false, false, false, false, false, false, false, false, false
	flashEscape = false

	if (myHero:GetSpellData(SUMMONER_1).name:find("SummonerFlash") == nil) and (myHero:GetSpellData(SUMMONER_2).name:find("SummonerFlash") == nil) then Flash = nil
	elseif myHero:GetSpellData(SUMMONER_1).name:find("SummonerFlash") then Flash = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerFlash") then Flash = SUMMONER_2 end

	BuffHeadshot = "caitlynheadshot"
	isHeadshot = false

	if VIP_USER then
		if IsSACReborn then
			PrintChat("<font color='#CCCCCC'> >> Kain's Caitlyn - PROdiction 2.0 <</font>")
		else
			PrintChat("<font color='#CCCCCC'> >> Kain's Caitlyn - VIP Prediction <</font>")
		end
	else
		PrintChat("<font color='#CCCCCC'> >> Kain's Caitlyn - Free Prediction <</font>")
	end
end

function Menu()
	AutoCarry.PluginMenu:addParam("sep", "----- Caitlyn by Kain: v"..curVersion.." -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("alt", "Alternate", SCRIPT_PARAM_ONKEYDOWN, false, 17)  
	AutoCarry.PluginMenu:addParam("Dash", "Dash", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("Z"))
	AutoCarry.PluginMenu:addParam("AAHeadshot", "Auto AA if Headshot up", SCRIPT_PARAM_ONOFF, true)

	AutoCarry.PluginMenu:addParam("sep", "----- [ Killsteal ] -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("KillstealQ", "Killshot with Q", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("KillstealE", "Killshot with E", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("KillstealRManual", "Manual Killshot with R", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("R"))
	AutoCarry.PluginMenu:addParam("KillstealR", "Killshot with R", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("sep", "----- [ Combo ] -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("toggleQ", "Toggle Q Cast", SCRIPT_PARAM_ONOFF, false)
	AutoCarry.PluginMenu:addParam("CastQ", "Fire Q", SCRIPT_PARAM_ONOFF, false)
	AutoCarry.PluginMenu:addParam("CastW", "Drop Trap", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("sep", "-- Draw Options --", SCRIPT_PARAM_INFO, "")  
	AutoCarry.PluginMenu:addParam("DisableDrawCircles", "Disable Draw", SCRIPT_PARAM_ONOFF, false)
	AutoCarry.PluginMenu:addParam("DrawQ", "Draw - Peacemaker", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("DrawR", "Draw - Ace in the Hole", SCRIPT_PARAM_ONOFF, true)
end

function PluginOnLoad()
	Vars()
	Menu()
end

function PluginOnTick()
	SpellCheck()

	if Target and AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.MixedMode then
		Killsteal()
	end

	if not AutoCarry.PluginMenu.toggleQ then
		if AutoCarry.PluginMenu.alt then
			AutoCarry.PluginMenu.CastQ = true
			flashEscape = true
		elseif not AutoCarry.PluginMenu.alt then
			AutoCarry.PluginMenu.CastQ = false
			flashEscape = false
		end
	elseif AutoCarry.PluginMenu.toggleQ then
		AutoCarry.PluginMenu.CastQ = true
	end


	if AutoCarry.PluginMenu.Dash then    
		Dash()
	end

	if AutoCarry.PluginMenu.CastQ and QReady then
		AutoCarry.SkillsCrosshair.range = 1300
	else
		AutoCarry.SkillsCrosshair.range = GetTrueRange()
	end

	-- Notify user when headshot passive is available.
	if isHeadshot then
		PrintFloatText(myHero, 0, "Headshot Available!")
		if AutoCarry.PluginMenu.AAHeadshot and Target and GetDistance(Target) < GetTrueRange() then
			myHero:Attack(Target)
		end
	end

	if Target then
		if AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.MixedMode then
			local closestEnemy = FindClosestEnemy()
			-- or (myHero.health < (myHero.maxHealth * .30) and )
			if EReady and GetDistance(closestEnemy) < 300 then
				CastE(closestEnemy)
				CastQEscape(closestEnemy)
			end
		
			if QReady and GetDistance(Target) > GetTrueRange() then
				if AutoCarry.PluginMenu.CastQ then
					if GetDistance(Target) < QRange then
						CastQ(Target)
					end
				end
			end
		end    
	end
end

function OnGainBuff(unit, buff)
	if buff and buff.type ~= nil and unit.name == myHero.name and unit.team == myHero.team then
		if buff.name == BuffHeadshot then
			isHeadshot = true
		end
	end 
end

function OnLoseBuff(unit, buff)
	if buff and buff.type ~= nil and unit.name == myHero.name and unit.team == myHero.team then
		if buff.name == BuffHeadshot then
			isHeadshot = false
		end
	end 
end

function OnAttacked()
	if Target then
		if AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.MixedMode then
			if QReady then
				if AutoCarry.PluginMenu.CastQ then
					if GetDistance(Target) < QRange then
						CastQ(Target)
						myHero:Attack(Target)
					end
				end
			end
		end
	end
end
 
function PluginOnDraw()
	if not AutoCarry.PluginMenu.DisableDrawCircles and not myHero.dead then
		if QReady and AutoCarry.PluginMenu.DrawQ then
			DrawCircle(myHero.x, myHero.y, myHero.z, QRange, 0x00FFFF)
		end

		if RReady and AutoCarry.PluginMenu.DrawR then
			DrawCircle(myHero.x, myHero.y, myHero.z, RRange, 0x00FF00)
		end
	end
end

function CastQ(enemy)
	if not enemy then enemy = Target end

	if QReady and IsValid(enemy, SkillQ.Range) then
		if IsSACReborn then
			SkillQ:ForceCast(enemy)
		else
			AutoCarry.CastSkillshot(SkillQ, enemy)
		end
	end
end

function CastQEscape(enemy)
	if not enemy then enemy = Target end

	if QReady and IsValid(enemy, SkillQEscape.Range) then
		if IsSACReborn then
			SkillQEscape:ForceCast(enemy)
		else
			AutoCarry.CastSkillshot(SkillQEscape, enemy)
		end
	end
end

function CastE(enemy)
	if not enemy then enemy = Target end

	if EReady and IsValid(enemy, SkillE.Range) then
		if IsSACReborn then
			SkillE:ForceCast(enemy)
		else
			AutoCarry.CastSkillshot(SkillE, enemy)
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

function Dash()
	myHero:MoveTo(mousePos.x,mousePos.z)

	if not flashEscape then
		if WReady and AutoCarry.PluginMenu.CastW then 
			for i, enemy in ipairs(GetEnemyHeroes()) do
				if enemy and GetDistance(enemy) < 400 then
					CastSpell(_W, myHero.x, myHero.z)
				end
			end
		end

		if EReady then
			MPos = Vector(mousePos.x, mousePos.y, mousePos.z)
			HeroPos = Vector(myHero.x, myHero.y, myHero.z)
			DashPos = HeroPos + ( HeroPos - MPos ) * (500 / GetDistance(mousePos))
			myHero:MoveTo(mousePos.x, mousePos.z)
			CastSpell(_E, DashPos.x, DashPos.z)
			myHero:MoveTo(mousePos.x, mousePos.z)
		end
	end

	if flashEscape then
		if WReady and AutoCarry.PluginMenu.CastW then  
			for i, enemy in ipairs(GetEnemyHeroes()) do
				if enemy and GetDistance(enemy) < 400 then
					CastSpell(_W, myHero.x, myHero.z)
				end
			end
		end

		if FReady then
			myHero:MoveTo(mousePos.x, mousePos.z)
			CastSpell(Flash, mousePos.x, mousePos.z)
			myHero:MoveTo(mousePos.x, mousePos.z)
		end
	end
end

function Killsteal()
	local closestEnemy = FindClosestEnemy()

	for i, enemy in ipairs(GetEnemyHeroes()) do
		local enemyDistance = GetDistance(enemy)
		local QDmg = getDmg("Q", enemy, myHero)
		local EDmg = getDmg("E", enemy, myHero)
		local RDmg = getDmg("R", enemy, myHero)
		local AADmg = getDmg("AD", enemy, myHero)

		if enemy and not enemy.dead and (enemy.health > AADmg or (enemy.health < AADmg and enemyDistance > GetTrueRange())) then
			if AutoCarry.PluginMenu.KillstealE and EReady and enemy.health <= EDmg and enemyDistance < ERange then
				CastE(enemy)
			elseif AutoCarry.PluginMenu.KillstealQ and QReady and enemy.health <= QDmg and enemyDistance < QRange then
				CastQ(enemy)
			elseif AutoCarry.PluginMenu.KillstealQ and AutoCarry.PluginMenu.KillstealE and QReady and EReady and enemy.health <= (QDmg + EDmg) and enemyDistance < ERange then
				CastE(enemy)
				CastQ(enemy)
			end

			if RReady and enemy.health <= RDmg and enemyDistance < RRange then
				-- PrintChat("D "..enemyDistance.." ! "..QRange.."!"..ERange.." ! "..enemy.name.."!"..closestEnemy.name.."!"..closestEnemy.team.."!"..enemy.team)
				if AutoCarry.PluginMenu.KillstealR and (enemyDistance > QRange or (not QReady and enemyDistance > ERange) or (not EReady and enemyDistance > GetTrueRange())) and enemy.name == closestEnemy.name and enemy.team == closestEnemy.team then
					PrintFloatText(myHero, 0, "Ace in the Hole!")
					CastSpell(_R, enemy)
				else
					PrintFloatText(myHero, 0, "Press R For Killshot")
					if AutoCarry.PluginMenu.KillstealRManual then
						CastSpell(_R, enemy)
					end
				end
			end
		end
	end
end

function FindClosestEnemy()
	local closestEnemy = nil

	for _, enemy in pairs(AutoCarry.EnemyTable) do
		if enemy and enemy.valid and not enemy.dead then
			if not closestEnemy or GetDistance(enemy) < GetDistance(closestEnemy) then
				closestEnemy = enemy
			end
		end
	end

	return closestEnemy
end

function SpellCheck()
	Target = AutoCarry.GetAttackTarget()
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)
	FReady = (Flash ~= nil and myHero:CanUseSpell(Flash) == READY)

	if player:GetSpellData(_R).level < 1 then RRange = 1300
	elseif player:GetSpellData(_R).level == 1 then RRange = 2000
	elseif player:GetSpellData(_R).level == 2 then RRange = 2500
	elseif player:GetSpellData(_R).level == 3 then RRange = 3000
	end
end

function FindClosestEnemy()
	local closestEnemy = nil

	for _, enemy in pairs(AutoCarry.EnemyTable) do
		if enemy and enemy.valid and not enemy.dead then
			if not closestEnemy or GetDistance(enemy) < GetDistance(closestEnemy) then
				closestEnemy = enemy
			end
		end
	end

	return closestEnemy
end

function GetTrueRange()
	return myHero.range + GetDistance(myHero.minBBox)
end

--UPDATEURL=
--HASH=F9BE395779CE53083FB28ED0E25A8469

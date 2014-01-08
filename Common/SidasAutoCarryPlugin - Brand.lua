--[[
 
        Auto Carry Plugin - Brand Free Edition
                Author: Chancity & Kain
                Version: See version variable below.
                Copyright 2013

                Dependency: Sida's Auto Carry
 
                How to install:
                        Make sure you already have AutoCarry installed.
                        Name the script EXACTLY "SidasAutoCarryPlugin - Brand.lua" without the quotes.
                        Place the plugin in BoL/Scripts/Common folder.

                Features:
					Smart Combos (Checks for mana, ability damage, and cool downs), can be disabled
					Draw text for smart combo is shown on target
					Fully customizable ability options in Mixed Mode (Q, W, E)
					Mixed Mode Harass with mana management
					Optional use Q return while using Mixed Mode
					Draws Skill Ranges based on what skills are ready
				
                
                Download: 

                Version History:
                        Version: 1.0
                            Release         
--]]

if myHero.charName ~= "Brand" then return end

function Variables()
	curVersion = 1.0
	
	AdvancedCallback:bind('OnGainBuff', function(unit, buff) OnGainBuff(unit, buff) end)
	AdvancedCallback:bind('OnLoseBuff', function(unit, buff) OnLoseBuff(unit, buff) end)
	
	QRange, QSpeed, QDelay, QWidth = 1100, 1.60, 625, 50
	WRange, WSpeed, WDelay, WWidth = 1100, .9, 250, 200
	ERange, ESpeed, EDelay, EWidth = 920, 1.55, 240, 80
	RRange, RSpeed, RDelay, RWidth = 750, math.huge, 100, 100
	QReady, WReady, EReady, RReady, DFGReady, IReady = false, false, false, false, false, false
	DFGSlot = nil


	if AutoCarry.Skills then IsSACReborn = true else IsSACReborn = false end

    if IsSACReborn then
		AutoCarry.Skills:DisableAll()
    end
	
	QRange, QSpeed, QDelay, QWidth = 1100, 1.60, 625, 50
	WRange, WSpeed, WDelay, WWidth = 1100, .9, 250, 200
	ERange, ESpeed, EDelay, EWidth = 920, 1.55, 240, 80
	RRange, RSpeed, RDelay, RWidth = 750, math.huge, 100, 100
	QReady, WReady, EReady, RReady, DFGReady, IReady = false, false, false, false, false, false
	DFGSlot = nil

	if IsSACReborn then
		SkillQ = AutoCarry.Skills:NewSkill(false, _Q, QRange, "Sear", AutoCarry.SPELL_LINEAR_COL, 0, false, false, QSpeed, QDelay, QWidth, true)
		SkillW = AutoCarry.Skills:NewSkill(false, _W, WRange, "Pillar of Flame", AutoCarry.SPELL_CIRCLE, 0, false, false, WSpeed, WDelay, WWidth, false)
		SkillE = AutoCarry.Skills:NewSkill(false, _E, ERange, "Conflagration", AutoCarry.SPELL_TARGETED, 0, false, false, ESpeed, EDelay, EWidth, false)
		SkillR = AutoCarry.Skills:NewSkill(false, _R, RRange, "Pyroclasm", AutoCarry.SPELL_TARGETED, 0, false, false, RSpeed, RDelay, RWidth, false)
	else
		SkillQ = {spellKey = _Q, range = QRange, speed = QSpeed, delay = QDelay, width = QWidth, configName = "sear", displayName = "Q (Orb of Deception)", enabled = true, skillShot = true, minions = false, reset = false, reqTarget = false }
		SkillW = {spellKey = _W, range = WRange, speed = WSpeed, delay = WDelay, width = WWidth, configName = "pillarofflame", displayName = "W (Fox-Fire)", enabled = true, skillShot = false, minions = false, reset = false, reqTarget = false }
		SkillE = {spellKey = _E, range = ERange, speed = ESpeed, delay = EDelay, width = EWidth, configName = "conflagration", displayName = "E (Charm)", enabled = true, skillShot = true, minions = true, reset = false, reqTarget = false }
		SkillR = {spellKey = _R, range = RRange, speed = RSpeed, delay = RDelay, width = RWidth, configName = "pyroclasm", displayName = "R (Spirit Rush)", enabled = true, skillShot = false, minions = false, reset = false, reqTarget = false }
	end
		
	ignite = nil
	useIgnite = true
	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then
		ignite = SUMMONER_1
    elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
		ignite = SUMMONER_2
	end
	
	enemyHeros = {}
	enemyHerosCount = 0
	for i = 1, heroManager.iCount do
		local hero = heroManager:GetHero(i)
		if hero.team ~= player.team then
			local enemyCount = enemyHerosCount + 1
			enemyHeros[enemyCount] = {object = hero, q = 0, w = 0, e = 0, r = 0, dfg = 0, ig = 0, myDamage = 0, manaCombo = 0, ablaze = 0}
			enemyHerosCount = enemyCount
		end
	end
end

function BrandMenu()
	Menu = AutoCarry.PluginMenu
		Menu:addSubMenu("["..myHero.charName.." Auto Carry: Auto Carry]", "autocarry")
			Menu.autocarry:addParam("SmartCombo","Use Smart Combo", SCRIPT_PARAM_ONOFF, true)
			Menu.autocarry:addParam("CastR","Use Pyroclasm (Z)", SCRIPT_PARAM_ONKEYTOGGLE, true, string.byte("Z"))
			Menu.autocarry:addParam("RequireBlaze","Require Blze (X)", SCRIPT_PARAM_ONKEYTOGGLE, true, string.byte("X"))
			Menu.autocarry:permaShow("CastR")
			Menu.autocarry:permaShow("RequireBlaze")
			
		Menu:addSubMenu("["..myHero.charName.." Auto Carry: Mixed Mode]", "mixedmode")		
			Menu.mixedmode:addParam("MixedUseQ","Use Sear", SCRIPT_PARAM_ONOFF, true)
			Menu.mixedmode:addParam("MixedUseW","Pillar of Flame", SCRIPT_PARAM_ONOFF, false)
			Menu.mixedmode:addParam("MixedUseE","Conflagration", SCRIPT_PARAM_ONOFF, true)
			Menu.mixedmode:addParam("MixedMinMana","Mana Manager %", SCRIPT_PARAM_SLICE, 40, 0, 100, 0)
		
								
		Menu:addSubMenu("["..myHero.charName.." Auto Carry: Other]", "other")
			Menu.other:addParam("Ignite","Use Ignite", SCRIPT_PARAM_ONOFF, true)
			Menu.other:addParam("DrawKillable","Draw Killable", SCRIPT_PARAM_ONOFF, true)
			Menu.other:addParam("DrawKillableTextSize","Draw Killable Text Size", SCRIPT_PARAM_SLICE, 15, 0, 40, 0)
			Menu.other:addParam("DrawTextTargetColor","Target Color", SCRIPT_PARAM_COLOR, {255,255,0,0})
			Menu.other:addParam("DrawTextUnitColor","Unit Color", SCRIPT_PARAM_COLOR, { 255, 255, 50, 50 })
			Menu.other:addParam("DrawRange","Draw Skill Range", SCRIPT_PARAM_ONOFF, true)
		
		Menu:addSubMenu("["..myHero.charName.." Auto Carry: Info]", "scriptinfo")
			Menu.scriptinfo:addParam("sep","["..myHero.charName.." Auto Carry: Version "..curVersion.."]", SCRIPT_PARAM_INFO, "")
			Menu.scriptinfo:addParam("sep1","Created By: Chancity, Please Enjoy!!", SCRIPT_PARAM_INFO, "")		
end

function PluginOnLoad()
	Variables()
	BrandMenu()
	AutoCarry.SkillsCrosshair.range = ERange
end

function PluginOnTick()	
	CheckSpells()
	damageCalculation()
	
	if Target ~= nil and  AutoCarry.MainMenu.AutoCarry then
		FullCombo()
	end
	
	if Target ~= nil and AutoCarry.MainMenu.MixedMode and CheckMana() then
		HarassCombo()
	end
	
	if Menu.other.Ignite and ignite and IReady then doIgnite() end
end

function PluginOnDraw()
	if Menu.other.DrawRange and EReady then
		DrawCircle(myHero.x, myHero.y, myHero.z, ERange, 0xe066a3)
	elseif Menu.other.DrawRange and QReady then
		DrawCircle(myHero.x, myHero.y, myHero.z, QRange, 0xe066a3)
	elseif Menu.other.DrawRange and WReady then
		DrawCircle(myHero.x, myHero.y, myHero.z, WRange, 0xe066a3)
	end
	
	if Menu.other.DrawKillable then
		for i = 1, enemyHerosCount do
			local Unit = enemyHeros[i].object
			local q = enemyHeros[i].q
			local w = enemyHeros[i].w
			local e = enemyHeros[i].e
			local r = enemyHeros[i].r
			local dfg = enemyHeros[i].dfg
			local ig = enemyHeros[i].ig
			local myDamage = enemyHeros[i].myDamage
			local manaCombo = enemyHeros[i].manaCombo
			local comboMessage = ""
			local a = Menu.other.DrawTextTargetColor
			local b = Menu.other.DrawTextUnitColor
			if ValidTarget(Unit) then
				if myDamage >= Unit.health and manaCombo <= myHero.mana and not myHero.dead then
					if e == 1 then
						comboMessage = comboMessage.." E"
					end
					if q == 1 then
						comboMessage = comboMessage.." Q"
					end
					if w == 1 then
						comboMessage = comboMessage.." W"
					end
					if r == 1 then
						comboMessage = comboMessage.." R"
					end
					if dfg == 1 then
						comboMessage = comboMessage.." DFG"
					end
					if ig == 1 then
						comboMessage = comboMessage.." IG"
					end
					if Unit == Target then
						DrawText3D("Killable"..comboMessage,Unit.x,Unit.y, Unit.z,Menu.other.DrawKillableTextSize,ARGB(a[1],a[2],a[3],a[4]), true)
					else
						DrawText3D("Killable"..comboMessage,Unit.x,Unit.y, Unit.z,Menu.other.DrawKillableTextSize,ARGB(b[1],b[2],b[3],b[4]), true)
					end
				elseif myDamage < Unit.health and QReady or WReady or EReady then
					if Unit == Target then
						DrawText3D("Harass"..comboMessage,Unit.x,Unit.y, Unit.z,Menu.other.DrawKillableTextSize,ARGB(a[1],a[2],a[3],a[4]), true)
					else
						DrawText3D("Harass"..comboMessage,Unit.x,Unit.y, Unit.z,Menu.other.DrawKillableTextSize,ARGB(b[1],b[2],b[3],b[4]), true)
					end
				elseif not myHero.dead then
					if Unit == Target then
						DrawText3D("Not Killable"..comboMessage,Unit.x,Unit.y, Unit.z,Menu.other.DrawKillableTextSize,ARGB(a[1],a[2],a[3],a[4]), true)
					else
						DrawText3D("Not Killable"..comboMessage,Unit.x,Unit.y, Unit.z,Menu.other.DrawKillableTextSize,ARGB(b[1],b[2],b[3],b[4]), true)
					end
				end
			end
		end 
	end
end

function FullCombo()
	if Menu.autocarry.SmartCombo then
		for i = 1, enemyHerosCount do
			local Unit = enemyHeros[i].object
			local q = enemyHeros[i].q
			local w = enemyHeros[i].w
			local e = enemyHeros[i].e
			local r = enemyHeros[i].r
			local dfg = enemyHeros[i].dfg
			local myDamage = enemyHeros[i].myDamage
			if Unit.name == Target.name and myDamage >= Target.health then
				
				if ig == 0 then 
					useIgnite = false 
				else
					useIgnite = true
				end
				
				if dfg == 1 then
					if DFGReady then CastSpell(DFGSlot, Target) end
				end
				
				if w == 1 then CastW() end
				if q == 1 then CastQ() end
				if e == 1 then CastE() end
				if r == 1 and Menu.autocarry.CastR then CastR() end
			elseif myDamage < Target.health then
				CastW()
				CastQ()
				CastE()
			end
		end
	else
		CastW()
		CastQ()
		CastE()
	end
end

function HarassCombo()
	if Menu.mixedmode.MixedUseW and WReady and CheckMana() and ValidTarget(Target, WRange) then 
		CastW()
	end
	
	if Menu.mixedmode.MixedUseQ and QReady and CheckMana() and ValidTarget(Target, QRange) then
		CastQ()
	end
	
	if Menu.mixedmode.MixedUseE and EReady and CheckMana() and GetDistance(Target) <= ERange then CastE() end 
end

function CastE()
	if EReady and GetDistance(Target) <= ERange then CastSpell(_E, Target) end 
end

function CastQ()
	if QReady and ValidTarget(Target, QRange) then
		if Menu.autocarry.RequireBlaze and getDmg("Q", Target, myHero) < Target.health then
			for i = 1, enemyHerosCount do
				if enemyHeros[i].object == Target then
					if enemyHeros[i].ablaze == 1 then
						if IsSACReborn then
							SkillQ:Cast(Target)
						else
							AutoCarry.CastSkillshot(SkillQ, Target)
						end
					end
				end
			end
		else
			if IsSACReborn then
				SkillQ:Cast(Target)
			else
				AutoCarry.CastSkillshot(SkillQ, Target)
			end
		end
	end
end

function CastW()	
	if WReady and ValidTarget(Target, WRange) then 
		if IsSACReborn then
			SkillW:Cast(Target)
		else
			AutoCarry.CastSkillshot(SkillW, Target)
		end
	end
end

function CastR()
	if RReady and ValidTarget(Target, RRange) then 
		if IsSACReborn then
			SkillR:Cast(Target)
		else
			AutoCarry.CastSkillshot(SkillR, Target)
		end
	end
end

function doIgnite()
    for _, enemy in pairs(GetEnemyHeroes()) do
		if ValidTarget(enemy, 600) and useIgnite and enemy.health <= 50 + (20 * player.level) and not IsIgnited(enemy) then
        	CastSpell(ignite, enemy)
        end
    end
end

function IsIgnited(target)
	if TargetHaveBuff("SummonerDot", target) then
		igniteTick = GetTickCount()
		return true
	elseif igniteTick == nil or GetTickCount()-igniteTick>500 then
		return false
	end
end

function CheckMana()
	if myHero.mana >= myHero.maxMana*(Menu.mixedmode.MixedMinMana/100) then
		return true
	else
		return false
	end	
end

function OnGainBuff(unit, buff)
	if buff.name == "brandablaze" then
		for i = 1, enemyHerosCount do
			if enemyHeros[i].object == unit then
				enemyHeros[i].ablaze = 1
			end
		end
	end
end

function OnLoseBuff(unit, buff)
	if buff.name == "brandablaze" then
		for i = 1, enemyHerosCount do
			if enemyHeros[i].object == unit then
				enemyHeros[i].ablaze = 0
			end
		end
	end
end

function CheckSpells()
	Target = AutoCarry.GetAttackTarget()
	DFGSlot = GetInventorySlotItem(3128)

	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)

	DFGReady = (DFGSlot ~= nil and myHero:CanUseSpell(DFGSlot) == READY)
	IReady = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
end

function damageCalculation()
	for i = 1, enemyHerosCount do
		local Unit = enemyHeros[i].object
		if ValidTarget(Unit) then
			dfgdamage, ignitedamage = 0, 0
			manaCombo, myDamage, QDamage, EDamage, WDamage, RDamage = 0, getDmg("P", Unit, myHero), getDmg("Q", Unit, myHero), getDmg("E", Unit, myHero), getDmg("W", Unit, myHero), getDmg("R", Unit, myHero)
			dfgdamage = (DFGSlot and getDmg("DFG",Unit,myHero) or 0)
			ignitedamage = (ignite and getDmg("IGNITE",Unit,myHero) or 0)
			
			if EReady then
				if myHero.mana >= myHero:GetSpellData(_E).mana and myHero.mana >= manaCombo then
					manaCombo = manaCombo + myHero:GetSpellData(_E).mana
					myDamage = myDamage + EDamage
					enemyHeros[i].e = 1
				else
					enemyHeros[i].e = 0
				end
			else
				enemyHeros[i].e = 0
			end
			
			if QReady then
				if myHero.mana >= myHero:GetSpellData(_Q).mana and myHero.mana >= manaCombo and myDamage < Unit.health then
					manaCombo = manaCombo + myHero:GetSpellData(_Q).mana
					myDamage = myDamage + QDamage
					enemyHeros[i].q = 1
				else
					enemyHeros[i].q = 0
				end
			else
				enemyHeros[i].q = 0
			end
			
			if WReady then
				if myHero.mana >= myHero:GetSpellData(_W).mana and myHero.mana >= manaCombo and myDamage < Unit.health then
					manaCombo = manaCombo + myHero:GetSpellData(_W).mana
					myDamage = myDamage + WDamage
					enemyHeros[i].w = 1
				else
					enemyHeros[i].w = 0
				end
			else
				enemyHeros[i].w = 0
			end
			
			if RReady then
				if myHero.mana >= myHero:GetSpellData(_R).mana and myHero.mana >= manaCombo and myDamage < Unit.health then
					manaCombo = manaCombo + myHero:GetSpellData(_R).mana
					myDamage = myDamage + RDamage
					enemyHeros[i].r = 1
				else
					enemyHeros[i].r = 0
				end
			else
				enemyHeros[i].r = 0
			end
			
			if DFGReady and myDamage < Unit.health then
				myDamage = myDamage * 1.2
				myDamage = myDamage + dfgdamage
				enemyHeros[i].dfg = 1
			else
				enemyHeros[i].dfg = 0
			end
			
			if IReady and myDamage < Unit.health then
				myDamage = myDamage + ignitedamage
				enemyHeros[i].ig = 1
			else
				enemyHeros[i].ig = 0
			end
			
			enemyHeros[i].manaCombo = manaCombo
			enemyHeros[i].myDamage = myDamage
		end
	end
end
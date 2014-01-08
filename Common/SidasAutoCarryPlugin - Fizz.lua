--[[
 
        Auto Carry Plugin - Fizz Prodiction Edition
                Author: Chancity & Kain
                Version: See version variable below.
                Copyright 2013

                Dependency: Sida's Auto Carry
 
                How to install:
                        Make sure you already have AutoCarry installed.
                        Name the script EXACTLY "SidasAutoCarryPlugin - Fizz.lua" without the quotes.
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

if myHero.charName ~= "Fizz" then return end

local Prodict = ProdictManager.GetInstance()

function Variables()
	curVersion = 1.0
	
	QRange, QSpeed, QDelay, QWidth = 550, nil, nil, nil
	ERange, ESpeed, EDelay, EWidth = 650, 1, 240, 75
	RRange, RSpeed, RDelay, RWidth = 1250, 1.36, 250, 60
	QReady, WReady, EReady, RReady, SHEENReady, LICHReady, DFGReady, IReady = false, false, false, false, false, false, false, false
	DFGSlot, SHEENSlot, LICHSlot = nil, nil, nil

	SkillQ = AutoCarry.Skills:NewSkill(false, _Q, QRange, "Urchin Strike", AutoCarry.SPELL_TARGETED, 0, false, false, QSpeed, QDelay, QWidth, false)
	SkillE = AutoCarry.Skills:NewSkill(false, _E, ERange, "Playful/Trickster", AutoCarry.SPELL_TARGETED, 0, false, false, ESpeed, EDelay, EWidth, true)
	
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
			enemyHeros[enemyCount] = {object = hero, sheen = 0, lich = 0, q = 0, w = 0, e = 0, r = 0, dfg = 0, ig = 0, myDamage = 0, manaCombo = 0}
			enemyHerosCount = enemyCount
		end
	end
end

function FizzMenu()
	Menu = AutoCarry.PluginMenu
		Menu:addSubMenu(""..myHero.charName.." Auto Carry: Auto Carry", "autocarry")
			Menu.autocarry:addParam("SmartCombo","Use Smart Combo", SCRIPT_PARAM_ONOFF, true)
			Menu.autocarry:addParam("CastR","Chum the Waters (Z)", SCRIPT_PARAM_ONKEYTOGGLE, true, string.byte("Z"))
			Menu.autocarry:permaShow("CastR")
			
		Menu:addSubMenu(""..myHero.charName.." Auto Carry: Mixed Mode", "mixedmode")	
			Menu.mixedmode:addParam("MixedUseQ","Urchin Strike", SCRIPT_PARAM_ONOFF, true)
			Menu.mixedmode:addParam("MixedUseW","Seastone Trident", SCRIPT_PARAM_ONOFF, false)
			Menu.mixedmode:addParam("MixedMinMana","Mana Manager %", SCRIPT_PARAM_SLICE, 40, 0, 100, 0)
					
		
		Menu:addSubMenu(""..myHero.charName.." Auto Carry: Draw", "draw")
			Menu.draw:addParam("DrawKillable","Draw Killable", SCRIPT_PARAM_ONOFF, true)
			Menu.draw:addParam("DrawKillableTextSize","Draw Killable Text Size", SCRIPT_PARAM_SLICE, 25, 0, 40, 0)
			Menu.draw:addParam("DrawTextTargetColor","Target Color", SCRIPT_PARAM_COLOR, {255,0,238,0})
			Menu.draw:addParam("DrawTextUnitColor","Unit Color", SCRIPT_PARAM_COLOR, { 255, 255, 50, 50 })
			Menu.draw:addParam("DrawRange","Draw Skill Range", SCRIPT_PARAM_ONOFF, true)
			
		Menu:addSubMenu(""..myHero.charName.." Auto Carry: Extras", "extras")
			Menu.extras:addParam("Ignite","Use Ignite", SCRIPT_PARAM_ONOFF, true)
			Menu.extras:addParam("CastE","Playful and Trickster (X)", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("X"))
			Menu.extras:permaShow("CastE")
end

local function CastR(unit, pos, spell)
	if RReady then
		if ValidTarget(unit, RRange) then
			HeroPos = Vector(myHero.x,0,myHero.z)
			EnemyPos = Vector(pos.x, 0, pos.z)                      
			LeadingPos = EnemyPos + (EnemyPos - HeroPos ):normalized()*(-0.05)
			CastSpell(_R, LeadingPos.x,LeadingPos.z)
		end
	end
end

function PluginOnLoad()
	Variables()
	FizzMenu()
	ProdictR = Prodict:AddProdictionObject(_R, RRange, RSpeed, RDlay, RWidth, myHero, CastR)
end

function PluginOnTick()	
	if myHero.dead then return end
	
	CheckSpells()
	damageCalculation()
	
	if Target ~= nil and  AutoCarry.MainMenu.AutoCarry then
		FullCombo()
	end
	
	if Target ~= nil and AutoCarry.MainMenu.MixedMode and CheckMana() then
		HarassCombo()
	end
	
	if Menu.extras.Ignite and ignite and IReady then doIgnite() end
end

function PluginOnDraw()
	if myHero.dead then return end
	
	if Menu.draw.DrawRange and RReady then
		DrawCircle(myHero.x, myHero.y, myHero.z, RRange, 0xe066a3)
		AutoCarry.SkillsCrosshair.range = RRange
	end
	
	if Menu.draw.DrawRange and QReady then
		DrawCircle(myHero.x, myHero.y, myHero.z, QRange, 0xe066a3)
		if not RReady then AutoCarry.SkillsCrosshair.range = QRange end
	end
	
	if Menu.draw.DrawKillable then
		for i = 1, enemyHerosCount do
			local Unit = enemyHeros[i].object
			local sheen = enemyHeros[i].sheen
			local lich = enemyHeros[i].lich
			local q = enemyHeros[i].q
			local w = enemyHeros[i].w
			local e = enemyHeros[i].e
			local r = enemyHeros[i].r
			local dfg = enemyHeros[i].dfg
			local ig = enemyHeros[i].ig
			local myDamage = enemyHeros[i].myDamage
			local manaCombo = enemyHeros[i].manaCombo
			local comboMessage = ""
			local a = Menu.draw.DrawTextTargetColor
			local b = Menu.draw.DrawTextUnitColor
			if ValidTarget(Unit) then
				if myDamage >= Unit.health and manaCombo <= myHero.mana then
					if r >= 1 then
						comboMessage = comboMessage.." R"
					end
					if q == 1 then
						comboMessage = comboMessage.." Q"
					end
					if w == 1 then
						comboMessage = comboMessage.." W"
					end
					if e == 1 then
						comboMessage = comboMessage.." E"
					end
					if sheen == 1 then
						comboMessage = comboMessage.." SHN"
					end
					if lich == 1 then
						comboMessage = comboMessage.." LCH"
					end
					if dfg == 1 then
						comboMessage = comboMessage.." DFG"
					end
					if ig == 1 then
						comboMessage = comboMessage.." IG"
					end
					if Unit == Target then
						DrawText3D("Killable"..comboMessage,Unit.x,Unit.y, Unit.z,Menu.draw.DrawKillableTextSize,ARGB(a[1],a[2],a[3],a[4]), true)
					else
						DrawText3D("Killable"..comboMessage,Unit.x,Unit.y, Unit.z,Menu.draw.DrawKillableTextSize,ARGB(b[1],b[2],b[3],b[4]), true)
					end
				elseif myDamage < Unit.health and QReady or WReady or EReady then
					if Unit == Target then
						DrawText3D("Harass"..comboMessage,Unit.x,Unit.y, Unit.z,Menu.draw.DrawKillableTextSize,ARGB(a[1],a[2],a[3],a[4]), true)
					else
						DrawText3D("Harass"..comboMessage,Unit.x,Unit.y, Unit.z,Menu.draw.DrawKillableTextSize,ARGB(b[1],b[2],b[3],b[4]), true)
					end
				elseif not myHero.dead then
					if Unit == Target then
						DrawText3D("Not Killable"..comboMessage,Unit.x,Unit.y, Unit.z,Menu.draw.DrawKillableTextSize,ARGB(a[1],a[2],a[3],a[4]), true)
					else
						DrawText3D("Not Killable"..comboMessage,Unit.x,Unit.y, Unit.z,Menu.draw.DrawKillableTextSize,ARGB(b[1],b[2],b[3],b[4]), true)
					end
				end
			end
		end 
	end
end

function FullCombo()
		if Menu.autocarry.CastR then ProdictR:EnableTarget(Target, true) end
		CastQ()
		CastW()
		CastE()
end

function HarassCombo()
	if Menu.mixedmode.MixedUseQ and QReady and CheckMana() and ValidTarget(Target, QRange) then CastQ() end
	if Menu.mixedmode.MixedUseW and WReady and CheckMana() then CastW() end 
	if Menu.mixedmode.MixedUseE and EReady and CheckMana() and ValidTarget(Target, ERange) then CastE() end
end

function CastE()
	if EReady and ValidTarget(Target, ERange) and Menu.extras.CastE then 
		SkillE:Cast(Target)
	end
end

function CastQ()
	if QReady and ValidTarget(Target, QRange) then 
		SkillQ:Cast(Target)
	end
end

function CastW()	
	if WReady and GetDistance(Target) <= 175 then CastSpell(_W, Target) end 
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

function CheckSpells()
	Target = AutoCarry.GetAttackTarget()
	DFGSlot = GetInventorySlotItem(3128)
	LICHSlot = GetInventorySlotItem(3100)
	SHEENSlot = GetInventorySlotItem(3057)

	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)

	DFGReady = (DFGSlot ~= nil and myHero:CanUseSpell(DFGSlot) == READY)
	LICHReady = (LICHSlot ~= nil and myHero:CanUseSpell(LICHSlot) == READY)
	SHEENReady = (SHEENSlot ~= nil and myHero:CanUseSpell(SHEENSlot) == READY)
	IReady = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
end

function damageCalculation()
	for i = 1, enemyHerosCount do
		local Unit = enemyHeros[i].object
		if ValidTarget(Unit) then
			dfgdamage, ignitedamage = 0, 0
			manaCombo, myDamage, QDamage, EDamage, WDamage, RDamage = 0, 0, getDmg("Q", Unit, myHero), getDmg("E", Unit, myHero), getDmg("W", Unit, myHero), getDmg("R", Unit, myHero)
			sheendamage = (SHEENSlot and getDmg("SHEEN",Unit,myHero) or 0)
			lichdamage = (LICHSlot and getDmg("LICHBANE",Unit,myHero) or 0)
			dfgdamage = (DFGSlot and getDmg("DFG",Unit,myHero) or 0)
			ignitedamage = (ignite and getDmg("IGNITE",Unit,myHero) or 0)
			
			if sheendamage > 0 and myDamage < Unit.health then
				myDamage = myDamage + sheendamage
				enemyHeros[i].sheen = 1
			else
				enemyHeros[i].sheen = 0
			end
			
			if lichdamage > 0 and myDamage < Unit.health then
				myDamage = myDamage + lichdamage
				enemyHeros[i].lich = 1
			else
				enemyHeros[i].lich = 0
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
					myDamage = myDamage + (WDamage + WDamage)
					enemyHeros[i].w = 1
				else
					enemyHeros[i].w = 0
				end
			else
				enemyHeros[i].w = 0
			end
			
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

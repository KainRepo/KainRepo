--[[

        Auto Carry Plugin - Viktor Prodiction Edition
                Author: Notanyoneknows with help from Kain and Chancity
                Version: See version variable below.
                Copyright 2013

                Dependency: Sida's Auto Carry

                How to install:
                        Make sure you already have AutoCarry installed.
                        Name the script EXACTLY "SidasAutoCarryPlugin - Viktor.lua" without the quotes.
                        Place the plugin in BoL/Scripts/Common folder.

				Update: Now using AoE_Skillshot_Position for Gravity Field
				Update: Adjusted skill ranges and widths

--]]

if myHero.charName ~= "Viktor" then return end


local curVersion = .22
local enemyHeros = {}
local enemyHerosCount = 0
local useIgnite = true

local Prodict = ProdictManager.GetInstance()

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

function Vars()

    if AutoCarry.Skills then IsSACReborn = true else IsSACReborn = false end

    if IsSACReborn then
		AutoCarry.Skills:DisableAll()
    end

	QRange, QSpeed, QDelay, QWidth = 600, nil, nil, nil
	WRange, WSpeed, WDelay, WWidth = 625, math.huge, .25, 315
	ERange, ESpeed, EDelay, EWidth = 1225, 1200, .25, 25
	RRange, RSpeed, RDelay, RWidth = 700, 1000, .25, 250
	QReady, WReady, EReady, RReady = false, false, false, false

	WRadius = 160

	ignite = nil
	DFGSlot, SheenSlot, LichBaneSlot = nil, nil, nil
	DFGReady, IReady =  false, false

	if IsSACReborn then
		SkillQ = AutoCarry.Skills:NewSkill(false, _Q, QRange, "Power Transfer", AutoCarry.SPELL_TARGETED, 0, false, false, QSpeed, QDelay, QWidth, false)
		SkillW = AutoCarry.Skills:NewSkill(false, _W, WRange, "Gravity Field", AutoCarry.SPELL_CIRCLE, 0, false, false, WSpeed, WDelay, WWidth, false)
		SkillR = AutoCarry.Skills:NewSkill(false, _R, RRange, "Chaos Storm", AutoCarry.SPELL_LINEAR, 0, false, false, RSpeed, RDelay, RWidth, false)
	else
		SkillQ = {spellKey = _Q, range = QRange, speed = QSpeed, delay = QDelay, width = QWidth, configName = "powertransfer", displayName = "Q (Power Transfer)", enabled = true, skillShot = false, minions = false, reset = false, reqTarget = true }
		SkillW = {spellKey = _W, range = WRange, speed = WSpeed, delay = WDelay, width = WWidth, configName = "gravityfield", displayName = "W (Gravity Field)", enabled = true, skillShot = true, minions = false, reset = false, reqTarget = false }
		SkillR = {spellKey = _R, range = RRange, speed = RSpeed, delay = RDelay, width = RWidth, configName = "chaosstorm", displayName = "R (Chaos Storm)", enabled = true, skillShot = true, minions = false, reset = false, reqTarget = false }
	end

	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then
		ignite = SUMMONER_1
    	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
		ignite = SUMMONER_2
	end

	PrintChat("<font color='#e066a3'> >> Viktor Auto Carry Plugin:</font> <font color='#f4cce0'> Running Version "..curVersion.."</font>")
	PrintChat("<font color='#e066a3'> >> Viktor Auto Carry Plugin:</font> <font color='#f4cce0'> Join the Glorious Evolution</font>")
	PrintChat("<font color='#e066a3'> >> Viktor Auto Carry Plugin:</font> <font color='#f4cce0'> Created By: Notanyoneknows with help from Kain and Chancity </font>")
end

function ViktorMenu()
	Menu = AutoCarry.PluginMenu
		Menu:addSubMenu("["..myHero.charName.." Auto Carry: Auto Carry]", "autocarry")
			Menu.autocarry:addParam("SmartCombo","Use Smart Combo", SCRIPT_PARAM_ONOFF, true)
			Menu.autocarry:addParam("CastR","Use Chaos Storm", SCRIPT_PARAM_ONOFF, true)
			Menu.autocarry:addParam("CastW","Use Gravity Field (Z)", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("Z"))
			Menu.autocarry:permaShow("CastW")

		Menu:addSubMenu("["..myHero.charName.." Auto Carry: Mixed Mode]", "mixedmode")
			Menu.mixedmode:addParam("MixedUseQ","Use Power Transfer", SCRIPT_PARAM_ONOFF, false)
			Menu.mixedmode:addParam("MixedUseE","Use Death Ray", SCRIPT_PARAM_ONOFF, true)
			Menu.mixedmode:addParam("MixedMinMana","Mana Manager %", SCRIPT_PARAM_SLICE, 40, 0, 100, 0)
		Menu:addSubMenu("["..myHero.charName.." Auto Carry: Other]", "other")
			Menu.other:addParam("OtherIgnite","Use Ignite", SCRIPT_PARAM_ONOFF, true)
			Menu.other:addParam("DrawKillable","Draw Killable", SCRIPT_PARAM_ONOFF, true)
			Menu.other:addParam("DrawKillableTextSize","Draw Killable Text Size", SCRIPT_PARAM_SLICE, 15, 0, 40, 0)
			Menu.other:addParam("DrawTextTargetColor","Target Color", SCRIPT_PARAM_COLOR, {255,255,0,0})
			Menu.other:addParam("DrawTextUnitColor","Unit Color", SCRIPT_PARAM_COLOR, { 255, 255, 50, 50 })
			Menu.other:addParam("DrawRange","Draw Skill Range", SCRIPT_PARAM_ONOFF, true)

		Menu:addSubMenu("["..myHero.charName.." Auto Carry: Info]", "scriptinfo")
			Menu.scriptinfo:addParam("sep","["..myHero.charName.." Auto Carry: Version "..curVersion.."]", SCRIPT_PARAM_INFO, "")
			Menu.scriptinfo:addParam("sep1","Created By: Notanyoneknows, Evolution!", SCRIPT_PARAM_INFO, "")
end

local function CastE(unit, pos, spell)
	if EReady then
		if ValidTarget(unit) then
			if GetDistance(unit) <= ERange and GetDistance(unit)<=550 then
				EnemyPos = {x = unit.x, y = unit.y, z = unit.z}
				HeroPos = Vector(myHero.x, myHero.y, myHero.z)
				EMinRange = HeroPos +(HeroPos -EnemyPos)*(-50/GetDistance(unit))
				Packet('S_CAST', { spellId = _E, fromX = EMinRange.x, fromY = EMinRange.z, toX = unit.x, toY = unit.z }):send()
			elseif GetDistance(unit) <= ERange then
				EnemyPos = {x = unit.x, y = unit.y, z = unit.z}
				HeroPos = Vector(myHero.x, myHero.y, myHero.z)
				EMinRange = HeroPos +(HeroPos -EnemyPos)*(-550/GetDistance(unit))
				Packet('S_CAST', { spellId = _E, fromX = EMinRange.x, fromY = EMinRange.z, toX = unit.x, toY = unit.z }):send()
			end
		else
			return
		end
	end
end

function PluginOnLoad()
	LoadEnemies()
	ViktorMenu()
	Vars()
	AutoCarry.SkillsCrosshair.range = ERange
	ProdictE = Prodict:AddProdictionObject(_E, ERange, ESpeed, EDlay, EWidth, myHero, CastE)
end

function PluginOnTick()
	SpellCheck()

	damageCalculation()


	if Target ~= nil and  AutoCarry.MainMenu.AutoCarry then
		FullCombo()
	end

	if Target ~= nil and AutoCarry.MainMenu.MixedMode and CheckMana() then
		HarassCombo()
	end

	if Menu.other.OtherIgnite and ignite and IReady then doIgnite() end
end

function FullCombo()
	if Menu.autocarry.SmartCombo then
		for i = 1, enemyHerosCount do
			local Unit = enemyHeros[i].object
			local q = enemyHeros[i].q
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
				if Menu.autocarry.CastW then CastW() end
				if r >= 1 and Menu.autocarry.CastR then CastR() end
				if e == 1 then CastEE(Target) end
				if q == 1 then CastQ() end
			elseif myDamage < Target.health then
				if Menu.autocarry.CastW then CastW() end
				CastEE(Target)
				CastQ()
			end
		end
	else
		if Menu.autocarry.CastW then CastW() end
		CastEE(Target)
		CastQ()
	end
end

function CastR()
	if RReady and IsValid(Target, SkillR.Range) then
		SkillR:Cast(Target)
	end
end

function CastW()
	if WReady and IsValid(Target, SkillW.Range) then
		spellPos = GetAoESpellPosition(WRadius, Target)
		CastSpell(_W, spellPos.x, spellPos.z)
	end
end

function CastQ()
	if QReady and GetDistance(Target) <= QRange then CastSpell(_Q, Target) end
end

function CastEE(Target)
	ProdictE:EnableTarget(Target, true)
end

function HarassCombo()
	if Menu.mixedmode.MixedUseQ and QReady and CheckMana() and GetDistance(Target) <= QRange then CastSpell(_Q, Target) end

	if Menu.mixedmode.MixedUseE and EReady and CheckMana() and IsValid(Target, ERange) then
		CastEE(Target)
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

function IsValid(enemy, dist)
	if enemy and enemy.valid and not enemy.dead and enemy.bTargetable and ValidTarget(enemy, dist) then
		return true
	else
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

function SpellCheck()
	Target = AutoCarry.GetAttackTarget()
	DFGSlot = GetInventorySlotItem(3128)

	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)

	DFGReady = (DFGSlot ~= nil and myHero:CanUseSpell(DFGSlot) == READY)
	IReady = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
end

function LoadEnemies()
	for i = 1, heroManager.iCount do
		local hero = heroManager:GetHero(i)
		if hero.team ~= player.team then
			local enemyCount = enemyHerosCount + 1
			enemyHeros[enemyCount] = {object = hero, q = 0, e = 0, r = 0, dfg = 0, ig = 0, myDamage = 0, manaCombo = 0}
			enemyHerosCount = enemyCount
		end
	end
end

function damageCalculation()
	for i = 1, enemyHerosCount do
		local Unit = enemyHeros[i].object
		if ValidTarget(Unit) then
			dfgdamage, ignitedamage = 0, 0
			manaCombo, myDamage, QDamage, EDamage, RDamage = 0, 0, getDmg("Q", Unit, myHero), getDmg("E", Unit, myHero), getDmg("R", Unit, myHero)
			dfgdamage = (DFGSlot and getDmg("DFG",Unit,myHero) or 0)
			ignitedamage = (ignite and getDmg("IGNITE",Unit,myHero) or 0)

			if QReady then
				if myHero.mana >= myHero:GetSpellData(_Q).mana and myHero.mana >= manaCombo then
					manaCombo = manaCombo + myHero:GetSpellData(_Q).mana
					myDamage = myDamage + QDamage
					enemyHeros[i].q = 1
				else
					enemyHeros[i].q = 0
				end
			else
				enemyHeros[i].q = 0
			end

			if EReady then
				if myHero.mana >= myHero:GetSpellData(_E).mana and myHero.mana >= manaCombo and myDamage < Unit.health then
					manaCombo = manaCombo + myHero:GetSpellData(_E).mana
					myDamage = myDamage + EDamage
					enemyHeros[i].e = 1
				else
					enemyHeros[i].e = 0
				end
			else
				enemyHeros[i].e = 0
			end

			if RReady then
				if myHero.mana >= myHero:GetSpellData(_R).mana and myHero.mana >= manaCombo and myDamage < Unit.health then
					manaCombo = manaCombo + myHero:GetSpellData(_R).mana
					if myHero:GetSpellData(_R).level == 1 then
						myDamage = myDamage + (RDamage * 2.86)
					elseif myHero:GetSpellData(_R).level == 2 then
						myDamage = myDamage + (RDamage * 2.68)
					elseif myHero:GetSpellData(_R).level == 3 then
						myDamage = myDamage + (RDamage * 2.6)
					end
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
					if q == 1 then
						comboMessage = comboMessage.." Q"
					end
					if e == 1 then
						comboMessage = comboMessage.." E"
					end
					if r >= 1 then
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

--[[
        AoE_Skillshot_Position 2.0 by monogato

        GetAoESpellPosition(radius, main_target, [delay]) returns best position in order to catch as many enemies as possible with your AoE skillshot, making sure you get the main target.
        Note: You can optionally add delay in ms for prediction (VIP if avaliable, normal else).
]]

function GetCenter(points)
        local sum_x = 0
        local sum_z = 0

        for i = 1, #points do
                sum_x = sum_x + points[i].x
                sum_z = sum_z + points[i].z
        end

        local center = {x = sum_x / #points, y = 0, z = sum_z / #points}

        return center
end

function ContainsThemAll(circle, points)
        local radius_sqr = circle.radius*circle.radius
        local contains_them_all = true
        local i = 1

        while contains_them_all and i <= #points do
                contains_them_all = GetDistanceSqr(points[i], circle.center) <= radius_sqr
                i = i + 1
        end

        return contains_them_all
end

-- The first element (which is gonna be main_target) is untouchable.
function FarthestFromPositionIndex(points, position)
        local index = 2
        local actual_dist_sqr
        local max_dist_sqr = GetDistanceSqr(points[index], position)

        for i = 3, #points do
                actual_dist_sqr = GetDistanceSqr(points[i], position)
                if actual_dist_sqr > max_dist_sqr then
                        index = i
                        max_dist_sqr = actual_dist_sqr
                end
        end

        return index
end

function RemoveWorst(targets, position)
        local worst_target = FarthestFromPositionIndex(targets, position)

        table.remove(targets, worst_target)

        return targets
end

function GetInitialTargets(radius, main_target)
        local targets = {main_target}
        local diameter_sqr = 4 * radius * radius

        for i=1, heroManager.iCount do
                target = heroManager:GetHero(i)
                if target.networkID ~= main_target.networkID and ValidTarget(target) and GetDistanceSqr(main_target, target) < diameter_sqr then table.insert(targets, target) end
        end

        return targets
end

function GetPredictedInitialTargets(radius, main_target, delay)
        if VIP_USER and not vip_target_predictor then vip_target_predictor = TargetPredictionVIP(nil, nil, delay/1000) end
        local predicted_main_target = VIP_USER and vip_target_predictor:GetPrediction(main_target) or GetPredictionPos(main_target, delay)
        local predicted_targets = {predicted_main_target}
        local diameter_sqr = 4 * radius * radius

        for i=1, heroManager.iCount do
                target = heroManager:GetHero(i)
                if ValidTarget(target) then
                        predicted_target = VIP_USER and vip_target_predictor:GetPrediction(target) or GetPredictionPos(target, delay)
                        if target.networkID ~= main_target.networkID and GetDistanceSqr(predicted_main_target, predicted_target) < diameter_sqr then table.insert(predicted_targets, predicted_target) end
                end
        end

        return predicted_targets
end

-- I don�t need range since main_target is gonna be close enough. You can add it if you do.
function GetAoESpellPosition(radius, main_target, delay)
        local targets = delay and GetPredictedInitialTargets(radius, main_target, delay) or GetInitialTargets(radius, main_target)
        local position = GetCenter(targets)
        local best_pos_found = true
        local circle = Circle(position, radius)
        circle.center = position

        if #targets > 2 then best_pos_found = ContainsThemAll(circle, targets) end

        while not best_pos_found do
                targets = RemoveWorst(targets, position)
                position = GetCenter(targets)
                circle.center = position
                best_pos_found = ContainsThemAll(circle, targets)
        end

        return position
end

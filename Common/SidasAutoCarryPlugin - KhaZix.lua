--[[
 
        Auto Carry Plugin - KhaZix PROdiction Edition
		Author: Kain & hellking298
		Version: See version variable below.
		Copyright 2013

		Dependency: Sida's Auto Carry
 
		How to install:
			Make sure you already have AutoCarry installed.
			Name the script EXACTLY "SidasAutoCarryPlugin - KhaZix.lua" without the quotes.
			Place the plugin in BoL/Scripts/Common folder.

		Features:

		Download: https://bitbucket.org/KainBoL/bol/raw/master/Common/SidasAutoCarryPlugin%20-%20KhaZix.lua

		Version History:
			Version: 1.0:
				Release

		To Do:

--]]

if myHero.charName ~= "Khazix" then return end

function Vars()
	curVersion = 1.0
	
	if AutoCarry.Skills then IsSACReborn = true else IsSACReborn = false end

	-- Disable SAC Reborn's skills. Ours are better.
	if IsSACReborn then
		AutoCarry.Skills:DisableAll()
	end

	KeyQ = string.byte("Q")
	KeyW = string.byte("W")
	KeyE = string.byte("E")
	KeyR = string.byte("R")

	QRange, WRange, ERange,RRange = 375, 1000, 900, math.huge
	QSpeed, WSpeed, ESpeed = 1.45, 1.85, math.huge
	QDelay, WDelay, EDelay = 250, 0.225, 0
	QWidth, WWidth, EWidth = 200, 110, 100
  

	if IsSACReborn then
		SkillQ = AutoCarry.Skills:NewSkill(false, _Q, QRange, "KhazixQ", AutoCarry.SPELL_LINEAR, 0, false, false, QSpeed, QDelay, QWidth, false)
		SkillW = AutoCarry.Skills:NewSkill(false, _W, WRange, "KhazixW", AutoCarry.SPELL_LINEAR_COL, 0, false, false, WSpeed, WDelay, WWidth, true)
		SkillE = AutoCarry.Skills:NewSkill(false, _E, ERange, "KhazixE", AutoCarry.SPELL_CIRCLE, 0, false, false, ESpeed, EDelay, EWidth, false)
	else
		SkillQ = {spellKey = _Q, range = QRange, speed = QSpeed, delay = QDelay, width = QWidth, minions = false }
		SkillW = {spellKey = _W, range = WRange, speed = WSpeed, delay = WDelay, width = WWidth, minions = true }
		SkillE = {spellKey = _E, range = ERange, speed = ESpeed, delay = EDelay, width = EWidth, minions = false }
	end

	-- Items
	ignite = nil
	DFGSlot, HXGSlot, BWCSlot, SheenSlot, TrinitySlot, LichBaneSlot = nil, nil, nil, nil, nil, nil
	QReady, WReady, EReady, RReady, DFGReady, HXGReady, BWCReady, IGNITEReady, BARRIERReady, CLEANSEReady, FReady = false, false, false, false, false, false, false, false, false, false, false
	flashEscape = false

	IGNITESlot = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") and SUMMONER_2) or nil)
	BARRIERSlot = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerBarrier") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerBarrier") and SUMMONER_2) or nil)
	CLEANSESlot = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerCleanse") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerCleanse") and SUMMONER_2) or nil)

	floattext = {"Harass him","Fight him","Kill him","Murder him"} -- text assigned to enemys

	killable = {} -- our enemy array where stored if people are killable
	waittxt = {} -- prevents UI lags, all credits to Dekaron

	for i=1, heroManager.iCount do waittxt[i] = i*3 end -- All credits to Dekaron

	standRange = 205 -- range to check for mouse

	tick = 0

	Target = nil

	debugMode = false

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
		PrintChat("<font color='#CCCCCC'> >> Kain & hellking298's KhaZix - PROdiction 2.0 <</font>")
	else
		PrintChat("<font color='#CCCCCC'> >> Kain & hellking298's KhaZix - Free Prediction <</font>")
	end

items =
	{
		BRK = {id=3153, range = 500, reqTarget = true, slot = nil },
		BWC = {id=3144, range = 400, reqTarget = true, slot = nil },
		DFG = {id=3128, range = 750, reqTarget = true, slot = nil },
		HGB = {id=3146, range = 400, reqTarget = true, slot = nil },
		RSH = {id=3074, range = 350, reqTarget = false, slot = nil},
		STD = {id=3131, range = 350, reqTarget = false, slot = nil},
		TMT = {id=3077, range = 350, reqTarget = false, slot = nil},
		YGB = {id=3142, range = 350, reqTarget = false, slot = nil}
	}
end

function Menu()
	AutoCarry.PluginMenu:addParam("sep", "----- "..myHero.charName.." by Kain: v"..curVersion.." -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("sep", "----- [ Combo ] -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("ComboQ", "Use Taste Their Fear", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("ComboW", "Use KhazixW", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("ComboE", "Use KhazixE", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("EnemyLockOn", "Lock Onto Enemy", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("S"))
	AutoCarry.PluginMenu:addParam("EnemyPermLockOn", "Lock Onto Enemy Always", SCRIPT_PARAM_ONOFF, false)
	AutoCarry.PluginMenu:addParam("AutoIgnite", "Auto Ignite Killable Enemy", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("UseItems", "Use items", SCRIPT_PARAM_ONOFF, true)

	ExtraConfig = scriptConfig("Sida's Auto Carry Plugin: "..myHero.charName..": Extras", myHero.charName)
	ExtraConfig:addParam("sep", "----- [ Draw ] -----", SCRIPT_PARAM_INFO, "")
	ExtraConfig:addParam("DrawKillable", "Draw Killable Enemies", SCRIPT_PARAM_ONOFF, true)
	ExtraConfig:addParam("DisableDrawCircles", "Disable Draw", SCRIPT_PARAM_ONOFF, false)
	ExtraConfig:addParam("DrawFurthest", "Draw Furthest Spell Available", SCRIPT_PARAM_ONOFF, true)
	ExtraConfig:addParam("DrawTargetArrow", "Draw Arrow to Target", SCRIPT_PARAM_ONOFF, false)
	ExtraConfig:addParam("DrawQ", "Draw Taste Their Fear", SCRIPT_PARAM_ONOFF, true)
  ExtraConfig:addParam("DrawE", "Draw KhazixE", SCRIPT_PARAM_ONOFF, true)
	ExtraConfig:addParam("DrawW", "Draw KhazixW", SCRIPT_PARAM_ONOFF, true)
end

function PluginOnLoad()
	Vars()
	Menu()

	if IsSACReborn then
		AutoCarry.Crosshair:SetSkillCrosshairRange(1000)
	else
		AutoCarry.SkillsCrosshair.range = 1000
	end

	-- if ExtraConfig.AutoLevelSkills then -- setup the skill autolevel
	--	autoLevelSetSequence(levelSequence)
	-- end
end

function PluginOnTick()
	tick = GetTickCount()
	Target = GetTarget()
	CheckEvolution()
  SpellCheck()

	if Target then
		if AutoCarry.MainMenu.AutoCarry then
			Combo()

			if AutoCarry.PluginMenu.UseItems then
				UseItems(Target)
			end
		end

		if AutoCarry.PluginMenu.EnemyPermLockOn or AutoCarry.PluginMenu.EnemyLockOn then
			if GetDistanceFromMouse(myHero) < 400 and GetDistance(Target) < 400 and GetDistance(Target) > (GetTrueRange() - 30) then
				if AutoCarry.GetNextAttackTime() > tick then
					MoveHero(Target.x, Target.z)
				else
					myHero:Attack(Target)
				end
			end
		end
		  
		if AutoCarry.PluginMenu.AutoIgnite then
			Ignite()
		end
	end
end

function inStandRange()
	return (GetDistanceFromMouse(myHero) < standRange)
end

function MoveHero(x, z)
	if IsSACReborn then
		AutoCarry.MyHero:MovementEnabled(false)
		myHero:MoveTo(x, z)
		AutoCarry.MyHero:MovementEnabled(true)
	else
		AutoCarry.CanMove = false
		myHero:MoveTo(x, z)
		AutoCarry.CanMove = true
	end
end

function GetTarget()
	if IsSACReborn then
		return AutoCarry.Crosshair:GetTarget()
	else
		return AutoCarry.GetAttackTarget()
	end
end

function Combo()
 	if Target then
		if AutoCarry.PluginMenu.ComboQ and QReady and GetDistance(Target) <= QRange then
			CastQ(Target)
		end
		if AutoCarry.PluginMenu.ComboW and WReady and GetDistance(Target) <= WRange then
			CastW(Target)
		end
		if AutoCarry.PluginMenu.ComboE and EReady and GetDistance(Target) <= ERange then
			CastE(Target)
		end
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
		if IsSACReborn then
			SkillW:Cast(enemy)
		else
			AutoCarry.CastSkill(SkillW, enemy)
		end
	end
end

function CastE(enemy)
	if not enemy then enemy = Target end

	if EReady and IsValid(enemy, ERange) then
		if IsSACReborn then
			SkillE:Cast(enemy)
		else
			AutoCarry.CastSkill(SkillE, enemy)
		end
	end
end

-- Item useage by Sida
function UseItems(enemy)
	if enemy == nil then return end
	for _,item in pairs(items) do
		item.slot = GetInventorySlotItem(item.id)
		if item.slot ~= nil then
			if item.reqTarget and GetDistance(enemy) < item.range then
				CastSpell(item.slot, enemy)
			elseif not item.reqTarget then
				if (GetDistance(enemy) - getHitBoxRadius(myHero) - getHitBoxRadius(enemy)) < 50 then
					CastSpell(item.slot)
				end
			end
		end
	end
end

function Ignite()
	IGNITEReady = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
	if IGNITEReady then
		local ignitedmg = 0
		for j = 1, heroManager.iCount, 1 do
			local enemyhero = heroManager:getHero(j)
			if ValidTarget(enemyhero,600) then
				ignitedmg = 50 + 20 * myHero.level
				if enemyhero.health <= ignitedmg then
					CastSpell(ignite, enemyhero)
				end
			end
		end
	end
end

function PluginOnDraw()
	if Target and not Target.dead and ExtraConfig.DrawTargetArrow and (AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.MixedMode) then
		DrawArrowsToPos(myHero, Target)
	end

	if IsTickReady(75) then DMGCalculation() end
	DrawKillable()
	DrawRanges()

	if ExtraConfig.DrawTargetInUltimateRange and RReady then
		local currentRRange = GetRRange()
		for _, enemy in pairs(GetEnemyHeroes()) do
			if enemy and not enemy.dead and currentRRange and GetDistance(enemy) < currentRRange then
				for j=0, 20 do
					DrawCircle(enemy.x, enemy.y, enemy.z, 30 + j*1.5, 0x0099CC) -- Blue
				end
			end
		end
	end
end

function DrawKillable()
	if ExtraConfig.DrawKillable and not myHero.dead then
		for i=1, heroManager.iCount do
			local Unit = heroManager:GetHero(i)
			if ValidTarget(Unit) then -- we draw our circles
				 if killable[i] == 1 then
				 	DrawCircle(Unit.x, Unit.y, Unit.z, 100, 0xFFFFFF00)
				 end

				 if killable[i] == 2 then
				 	DrawCircle(Unit.x, Unit.y, Unit.z, 100, 0xFFFFFF00)
				 end

				 if killable[i] == 3 then
				 	for j=0, 10 do
				 		DrawCircle(Unit.x, Unit.y, Unit.z, 100+j*0.8, 0x099B2299)
				 	end
				 end

				 if killable[i] == 4 then
				 	for j=0, 10 do
				 		DrawCircle(Unit.x, Unit.y, Unit.z, 100+j*0.8, 0x099B2299)
				 	end
				 end

				 if waittxt[i] == 1 and killable[i] ~= nil and killable[i] ~= 0 and killable[i] ~= 1 then
				 	PrintFloatText(Unit,0,floattext[killable[i]])
				 end
			end

			if waittxt[i] == 1 then
				waittxt[i] = 30
			else
				waittxt[i] = waittxt[i]-1
			end
		end
	end
end

function DrawRanges()
	if not ExtraConfig.DisableDrawCircles and not myHero.dead then
		local farSpell = FindFurthestReadySpell()

		-- DrawCircle(myHero.x, myHero.y, myHero.z, getTrueRange(), 0x808080) -- Gray

		if ExtraConfig.DrawQ and QReady and ((ExtraConfig.DrawFurthest and farSpell and farSpell == QRange) or not ExtraConfig.DrawFurthest) then
			DrawCircle(myHero.x, myHero.y, myHero.z, QRange, 0x0099CC) -- Blue
		end
    		if ExtraConfig.DrawW and WReady and ((ExtraConfig.DrawFurthest and farSpell and farSpell == WRange) or not ExtraConfig.DrawFurthest) then
			DrawCircle(myHero.x, myHero.y, myHero.z, WRange, 0x0099CC) -- Blue
		end
    
		if ExtraConfig.DrawE and EReady and ((ExtraConfig.DrawFurthest and farSpell and farSpell == ERange) or not ExtraConfig.DrawFurthest) then
			DrawCircle(myHero.x, myHero.y, myHero.z, ERange, 0x00FF00) -- Green
		end

		Target = GetTarget()
		if Target ~= nil then
			for j=0, 10 do
				DrawCircle(Target.x, Target.y, Target.z, 40 + j*1.5, 0x00FF00) -- Green
			end
		end
	end
end

function DMGCalculation()
	for i=1, heroManager.iCount do
        local Unit = heroManager:GetHero(i)
        if ValidTarget(Unit) then
        	local RUINEDKINGDamage, IGNITEDamage, BWCDamage = 0, 0, 0

        	local QDamage = getDmg("Q", Unit, myHero)
			local WDamage = getDmg("W", Unit, myHero)
			local EDamage = getDmg("E", Unit, myHero)
			local HITDamage = getDmg("AD", Unit, myHero)

			local IGNITEDamage = (IGNITESlot and getDmg("IGNITE", Unit, myHero) or 0)
			local BWCDamage = (BWCSlot and getDmg("BWC", Unit, myHero) or 0)
			local RUINEDKINGDamage = (RUINEDKINGSlot and getDmg("RUINEDKING", Unit, myHero) or 0)
			local combo1 = HITDamage
			local combo2 = HITDamage
			local combo3 = HITDamage
			local mana = 0

			if QReady then
				combo1 = combo1 + QDamage
				combo2 = combo2 + QDamage
				combo3 = combo3 + QDamage
				mana = mana + myHero:GetSpellData(_Q).mana
			end

			if WReady then
				combo1 = combo1 + WDamage
				combo2 = combo2 + WDamage
				combo3 = combo3 + WDamage
				mana = mana + myHero:GetSpellData(_W).mana
			end

			if EReady then
				combo1 = combo1 + EDamage
				combo2 = combo2 + EDamage
				combo3 = combo3 + EDamage
				mana = mana + myHero:GetSpellData(_E).mana
			end

			if BWCReady then
				combo2 = combo2 + BWCDamage
				combo3 = combo3 + BWCDamage
			end

			if RUINEDKINGReady then
				combo2 = combo2 + RUINEDKINGDamage
				combo3 = combo3 + RUINEDKINGDamage
			end

			if IGNITEReady then
				combo3 = combo3 + IGNITEDamage
			end

			killable[i] = 1 -- the default value = harass

			if combo3 >= Unit.health and myHero.mana >= mana then -- all cooldowns needed
				killable[i] = 2
			end

			if combo2 >= Unit.health and myHero.mana >= mana then -- only spells + ulti and items needed
				killable[i] = 3
			end

			if combo1 >= Unit.health and myHero.mana >= mana then -- only spells but no ulti needed
				killable[i] = 4
			end
		end
	end
end

function FindFurthestReadySpell()
	local farSpell = nil

	if ExtraConfig.DrawQ and QReady then farSpell = QRange end
	if ExtraConfig.DrawE and EReady and (not farSpell or ERange > farSpell) then farSpell = ERange end
	if ExtraConfig.DrawW and WReady and (not farSpell or WRange > farSpell) then farSpell = WRange end

	return farSpell
end

function DrawArrowsToPos(pos1, pos2)
	if pos1 and pos2 then
		startVector = D3DXVECTOR3(pos1.x, pos1.y, pos1.z)
		endVector = D3DXVECTOR3(pos2.x, pos2.y, pos2.z)
		DrawArrows(startVector, endVector, 60, 0xE97FA5, 100)
	end
end

function IsValid(enemy, dist)
	if enemy and enemy.valid and not enemy.dead and enemy.bTargetable and ValidTarget(enemy, dist) then
		return true
	else
		return false
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

function FindLowestHealthEnemy(range)
	local lowHealthEnemy = nil

	for _, enemy in pairs(AutoCarry.EnemyTable) do
		if enemy and enemy.valid and not enemy.dead then
			if not lowHealthEnemy or (GetDistance(enemy) <= range and enemy.health < lowHealthEnemy.health) then
				lowHealthEnemy = enemy
			end
		end
	end

	return closestEnemy
end

function EnemyCount(point, range)
	local count = 0

	for _, enemy in pairs(GetEnemyHeroes()) do
		if enemy and not enemy.dead and GetDistance(point, enemy) <= range then
			count = count + 1
		end
	end            

	return count
end

function IsMyManaLow()
	if myHero.mana < (myHero.maxMana * ( ExtraConfig.ManaManager / 100)) then
		return true
	else
		return false
	end
end

function IsTickReady(tickFrequency)
	-- Improves FPS
	-- Disabled for now.
	if 1 == 1 then return true end

	if tick ~= nil and math.fmod(tick, tickFrequency) == 0 then
		return true
	else
		return false
	end
end

function CheckEvolution()
		if myHero:GetSpellData(_E).name == "khazixelong" then
	  		SkillE.range = 900
	 	end 
	 	if myHero:GetSpellData(_Q).name == "khazixqlong" then
	  		SkillQ.range = 375
	 	end 
end 

function GetTrueRange()
	return myHero.range + GetDistance(myHero.minBBox)
end

function SpellCheck()
	DFGSlot, HXGSlot, BWCSlot, SheenSlot, TrinitySlot, LichBaneSlot = GetInventorySlotItem(3128),
	GetInventorySlotItem(3146), GetInventorySlotItem(3144), GetInventorySlotItem(3057),
	GetInventorySlotItem(3078), GetInventorySlotItem(3100)

	RUINEDKINGSlot, QUICKSILVERSlot, RANDUINSSlot, BWCSlot = GetInventorySlotItem(3153), GetInventorySlotItem(3140), GetInventorySlotItem(3143)

	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)

	RUINEDKINGReady = (RUINEDKINGSlot ~= nil and myHero:CanUseSpell(RUINEDKINGSlot) == READY)
	QUICKSILVERReady = (QUICKSILVERSlot ~= nil and myHero:CanUseSpell(QUICKSILVERSlot) == READY)
	RANDUINSReady = (RANDUINSSlot ~= nil and myHero:CanUseSpell(RANDUINSSlot) == READY)

	DFGReady = (DFGSlot ~= nil and myHero:CanUseSpell(DFGSlot) == READY)
	HXGReady = (HXGSlot ~= nil and myHero:CanUseSpell(HXGSlot) == READY)
	BWCReady = (BWCSlot ~= nil and myHero:CanUseSpell(BWCSlot) == READY)

	IGNITEReady = (IGNITESlot ~= nil and myHero:CanUseSpell(IGNITESlot) == READY)
	BARRIERReady = (BARRIERSlot ~= nil and myHero:CanUseSpell(BARRIERSlot) == READY)
	CLEANSEReady = (CLEANSESlot ~= nil and myHero:CanUseSpell(CLEANSESlot) == READY)
end
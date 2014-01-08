--[[
 
        Auto Carry Plugin - Ezreal Reborn PROdiction Edition
		Author: Kain
		Version: See version variable below.
		Copyright 2013

		Dependency: Sida's Auto Carry
 
		How to install:
			Make sure you already have AutoCarry installed.
			Name the script EXACTLY "SidasAutoCarryPlugin - Ezreal.lua" without the quotes.
			Place the plugin in BoL/Scripts/Common folder.

		Features:

		
		Download: https://bitbucket.org/KainBoL/bol/raw/master/Common/SidasAutoCarryPlugin%20-%20Ezreal.lua

		Version History:
			Version: 1.14:
				Random fixes.
			Version: 1.1b:
				Added E to mouse position.
				Improved logic on R killsteal.
				Fixed random bugs.
			Version: 1.0:
				Release

		To Do: Known issue: The Big One missile tracking can become out of sync in Reborn if script is started after missiles have been accrued, due to lack of Buff function support in Reborn. Revamped works great.
--]]

if myHero.charName ~= "Ezreal" then return end

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

function Vars()
	curVersion = 1.14

	if AutoCarry.Skills then IsSACReborn = true else IsSACReborn = false end

	-- Disable SAC Reborn's skills. Ours are better.
	if IsSACReborn then
		AutoCarry.Skills:DisableAll()
	end

	KeyQ = string.byte("Q")
	KeyW = string.byte("W")
	KeyE = string.byte("E")
	KeyR = string.byte("R")

	QRange, WRange, ERange, RRange = 1100, 1050, 475, 10000
	QSpeed, WSpeed, ESpeed, RSpeed = 2.0, 1.6, 1.6, 1.7
	QDelay, WDelay, EDelay, RDelay = 250, 250, 250, 250
	QWidth, WWidth, EWidth, RWidth = 70, 90, 0, 100

	if IsSACReborn then
		SkillQ = AutoCarry.Skills:NewSkill(true, _Q, QRange, "Mystic Shot", AutoCarry.SPELL_LINEAR_COL, 0, false, false, QSpeed, QDelay, QWidth, true)
		SkillW = AutoCarry.Skills:NewSkill(true, _W, WRange, "Essence Flux", AutoCarry.SPELL_LINEAR, 0, false, false, WSpeed, WDelay, WWidth, false)
		SkillE = AutoCarry.Skills:NewSkill(true, _E, ERange, "Arcane Shift", AutoCarry.SPELL_LINEAR, 0, false, false, ESpeed, EDelay, EWidth, false)
		SkillR = AutoCarry.Skills:NewSkill(true, _R, RRange, "Trueshot Barrage", AutoCarry.SPELL_LINEAR, 0, false, false, RSpeed, RDelay, RWidth, false)
	else
		SkillQ = {spellKey = _Q, range = QRange, speed = QSpeed, delay = QDelay, width = QWidth, minions = true }
		SkillW = {spellKey = _W, range = WRange, speed = WSpeed, delay = WDelay, width = WWidth, minions = false }
		SkillE = {spellKey = _E, range = ERange, speed = ESpeed, delay = EDelay, width = EWidth, minions = false }
		SkillR = {spellKey = _R, range = RRange, speed = RSpeed, delay = RDelay, width = RWidth, minions = false }
	end

	-- Items
	ignite = nil
	DFGSlot, HXGSlot, BWCSlot, SheenSlot, TrinitySlot, LichBaneSlot = nil, nil, nil, nil, nil, nil
	QReady, WReady, EReady, RReady, DFGReady, HXGReady, BWCReady, IReady = false, false, false, false, false, false, false, false

	qTimer = 0
	wTimer = 0
	rTimer = 0
	mainTimer = 0 -- delay between spells
			
	floattext = {"Harass him","Fight him","Kill him","Murder him"} -- text assigned to enemys

	killable = {} -- our enemy array where stored if people are killable
	waittxt = {} -- prevents UI lags, all credits to Dekaron

	for i=1, heroManager.iCount do waittxt[i] = i*3 end -- All credits to Dekaron

	tick = nil

	Target = nil

	debugMode = false

	-- AutoUpdate
--[[
	hasUpdated = true
	GetVersionURL = "https://dl.dropboxusercontent.com/s/mpi5vjhdgeoc7ve/Version.ini"
	newDownloadURL = nil
	newVersion = nil
	newMessage = nil
	SCRIPT_FILE = SCRIPT_PATH.."Common\\SidasAutoCarryPlugin - "..myHero.charName..".lua"
	VER_PATH = os.getenv("APPDATA").."\\"..myHero.charName.."Version.ini"
	UpdateChat = {}
	DownloadFile(GetVersionURL, VER_PATH, function() end)
--]]

	if VIP_USER then
		if IsSACReborn then
			PrintChat("<font color='#CCCCCC'> >> Kain's Ezreal - PROdiction 2.0 <</font>")
		else
			PrintChat("<font color='#CCCCCC'> >> Kain's Ezreal - VIP Prediction <</font>")
		end
	else
		PrintChat("<font color='#CCCCCC'> >> Kain's Ezreal - Free Prediction <</font>")
	end
end

function Menu()
	AutoCarry.PluginMenu:addParam("sep", "----- "..myHero.charName.." by Kain: v"..curVersion.." -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("space", "", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("sep", "----- [ Combo ] -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("ComboQ", "Use Q (Mystic Shot)", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("ComboW", "Use W (Essence Flux)", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("ComboR", "Use R for Killsteal (Trueshot Barrage)", SCRIPT_PARAM_ONOFF, false)
	AutoCarry.PluginMenu:addParam("RMaxDistance", "Max Distance to Auto R", SCRIPT_PARAM_SLICE, 2000, 100, 10000, 0)
	AutoCarry.PluginMenu:addParam("sep", "----- [ Harass ] -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("HarassQ", "Use Q (Mystic Shot)", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("HarassW", "Use W (Essence Flux)", SCRIPT_PARAM_ONOFF, true)
--[[
	-- Farming
	AutoCarry.PluginMenu:addParam("sep", "----- [ Farming ] -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("FarmUseQ", "Use Q (Mystic Shot)", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("FarmMinMana", "Farm if my mana > %", SCRIPT_PARAM_SLICE, 35, 0, 100, 0)
	AutoCarry.PluginMenu:addParam("sep", "", SCRIPT_PARAM_INFO, "")
	
	-- Draw Death Timer
	AutoCarry.PluginMenu:addParam("sep", "["..myHero.charName.." Auto Carry: Draw]", SCRIPT_PARAM_INFO, "")
    AutoCarry.PluginMenu:addParam("DrawText", "Draw Text", SCRIPT_PARAM_ONOFF, true)
--]]
	-- Extras Menu
	ExtraConfig = scriptConfig("Sida's Auto Carry Plugin: "..myHero.charName..": Extras", myHero.charName)
	ExtraConfig:addParam("sep", "----- [ Misc ] -----", SCRIPT_PARAM_INFO, "")
	ExtraConfig:addParam("ProMode", "Use Auto QWER Keys", SCRIPT_PARAM_ONOFF, true)
	ExtraConfig:addParam("SmartE", "E to Mouse Pos.", SCRIPT_PARAM_ONOFF, true)
	ExtraConfig:addParam("ManaManager", "Mana Manager %", SCRIPT_PARAM_SLICE, 40, 0, 100, 2)
	ExtraConfig:addParam("sep", "----- [ Draw ] -----", SCRIPT_PARAM_INFO, "")
	ExtraConfig:addParam("DrawKillable", "Draw Killable Enemies", SCRIPT_PARAM_ONOFF, true)
	ExtraConfig:addParam("DrawTargetArrow", "Draw Arrow to Target", SCRIPT_PARAM_ONOFF, false)
	ExtraConfig:addParam("DisableDrawCircles", "Disable Draw", SCRIPT_PARAM_ONOFF, false)
	ExtraConfig:addParam("DrawFurthest", "Draw Furthest Spell Available", SCRIPT_PARAM_ONOFF, true)
	ExtraConfig:addParam("DrawQ", "Draw Mystic Shot", SCRIPT_PARAM_ONOFF, true)
	ExtraConfig:addParam("DrawW", "Draw Essence Flux", SCRIPT_PARAM_ONOFF, true)
	ExtraConfig:addParam("DrawE", "Draw Arcane Shift", SCRIPT_PARAM_ONOFF, true)
end

function PluginOnLoad()
	AutoCarry.SkillsCrosshair.Range = 1200

	Vars()
	Menu()
end

function PluginOnTick()
	if hasUpdated then 
		if FileExist(VER_PATH) then
			AutoUpdate() 
		end 
	end
	
	Target = AutoCarry.GetAttackTarget()
	tick = GetTickCount()

	SpellCheck()

	if Target then
		if AutoCarry.MainMenu.AutoCarry then
			Combo()
		end

		if (AutoCarry.MainMenu.MixedMode or AutoCarry.MainMenu.LaneClear) and not IsMyManaLow() then
			if AutoCarry.PluginMenu.HarassQ then CastQ() end
			if AutoCarry.PluginMenu.HarassW then CastW() end
		end
	end

	if not Target and (AutoCarry.MainMenu.MixedMode or  AutoCarry.MainMenu.LaneClear) then
		if AutoCarry.PluginMenu.FarmUseQ then FarmWithQ() end
	end
end

function Combo()
	local calcenemy = 1

	if not Target or not ValidTarget(Target) then return true end

	for i=1, heroManager.iCount do
    	local Unit = heroManager:GetHero(i)
    	if Unit.charName == Target.charName then
    		calcenemy = i
    	end
   	end
   	
	if IGNITEReady and killable[calcenemy] == 3 then CastSpell(IGNITESlot, Target) end

	if AutoCarry.PluginMenu.UseItems then
		if BWCReady and (killable[calcenemy] == 2 or killable[calcenemy] == 3) then CastSpell(BWCSlot, Target) end
		if RUINEDKINGReady and (killable[calcenemy] == 2 or killable[calcenemy] == 3) then CastSpell(RUINEDKINGSlot, Target) end
		if RANDUINSReady then CastSpell(RANDUINSSlot) end
	end

	if AutoCarry.PluginMenu.ComboQ then CastQ() end
	if AutoCarry.PluginMenu.ComboW then CastW() end

	if RReady and AutoCarry.PluginMenu.ComboR and GetDistance(Target) <= AutoCarry.PluginMenu.RMaxDistance and ((getDmg("R", Target, myHero) >= Target.health + 20) or killable[calcenemy] == 2 or killable[calcenemy] == 3) then
		CastR()
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

function CastW(enemy)
	if not enemy then enemy = Target end

	if WReady and IsValid(enemy, SkillW.Range) then
		if IsSACReborn then
			SkillW:ForceCast(enemy)
		else
			AutoCarry.CastSkillshot(SkillW, enemy)
		end
	end
end

function CastE()
	if ExtraConfig.SmartE then
		local dashSqr = math.sqrt((mousePos.x - myHero.x)^2+(mousePos.z - myHero.z)^2)
		local dashX = myHero.x + ERange*((mousePos.x - myHero.x)/dashSqr)
		local dashZ = myHero.z + ERange*((mousePos.z - myHero.z)/dashSqr)

		CastSpell(_E, dashX, dashZ)
	end
end

function CastR(enemy)
	if not enemy then enemy = Target end

	if RReady and IsValid(enemy, SkillR.Range) then
		if IsSACReborn then
			SkillR:ForceCast(enemy)
		else
			AutoCarry.CastSkillshot(SkillR, enemy)
		end
	end
end

function FarmWithQ()
end

function IsValid(enemy, dist)
	if enemy and enemy.valid and not enemy.dead and enemy.bTargetable and ValidTarget(enemy, dist) then
		return true
	else
		return false
	end
end

function PluginOnDraw()
-- if 1 == 1 then return end
	if Target and not Target.dead and ExtraConfig.DrawTargetArrow and (AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.MixedMode) then
		DrawArrowsToPos(myHero, Target)
	end

	if IsTickReady(75) then DMGCalculation() end
	DrawKillable()
	DrawRanges()
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

		if ExtraConfig.DrawQ and QReady and ((ExtraConfig.DrawFurthest and farSpell and farSpell == SkillQ.Range) or not ExtraConfig.DrawFurthest) then
			DrawCircle(myHero.x, myHero.y, myHero.z, SkillQ.Range, 0x0099CC) -- Blue
		end

		if ExtraConfig.DrawW and WReady and ((ExtraConfig.DrawFurthest and farSpell and farSpell == SkillW.Range) or not ExtraConfig.DrawFurthest) then
			DrawCircle(myHero.x, myHero.y, myHero.z, SkillW.Range, 0xFFFF00) -- Yellow
		end

		if ExtraConfig.DrawE and EReady and ((ExtraConfig.DrawFurthest and farSpell and farSpell == SkillE.Range) or not ExtraConfig.DrawFurthest) then
			DrawCircle(myHero.x, myHero.y, myHero.z, SkillE.Range, 0x00FF00) -- Green
		end

		Target = AutoCarry.GetAttackTarget()
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
			local RDamage = getDmg("R", Unit, myHero)
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

			if RReady then
				combo2 = combo2 + RDamage
				combo3 = combo3 + RDamage
				mana = mana + myHero:GetSpellData(_R).mana
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

	if ExtraConfig.DrawQ and QReady then farSpell = SkillQ.Range end
	if ExtraConfig.DrawW and WReady and (not farSpell or SkillW.Range > farSpell) then farSpell = SkillW.Range end
	if ExtraConfig.DrawE and EReady and (not farSpell or SkillE.Range > farSpell) then farSpell = SkillE.Range end

	return farSpell
end

function DrawArrowsToPos(pos1, pos2)
	if pos1 and pos2 then
		startVector = D3DXVECTOR3(pos1.x, pos1.y, pos1.z)
		endVector = D3DXVECTOR3(pos2.x, pos2.y, pos2.z)
		DrawArrows(startVector, endVector, 60, 0xE97FA5, 100)
	end
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
	IReady = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
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

function GetTrueRange()
	return myHero.range + GetDistance(myHero.minBBox)
end

function IsTickReady(tickFrequency)
	-- Improves FPS
	if tick ~= nil and math.fmod(tick, tickFrequency) == 0 then
		return true
	else
		return false
	end
end

function PluginOnWndMsg(msg,key)
	Target = AutoCarry.GetAttackTarget(true)
	if Target ~= nil and ExtraConfig.ProMode then
		if msg == KEY_DOWN and key == KeyQ then CastQ() end
		if msg == KEY_DOWN and key == KeyW then CastW() end
		if msg == KEY_DOWN and key == KeyE then
			if ExtraConfig.SmartE then
				CastE()
			end
		end
		if msg == KEY_DOWN and key == KeyR then CastR() end
	end
end

-- Auto Updater

--[[
function NewIniReader()
	local reader = {};
	function reader:Read(fName)
		self.root = {};
		self.reading_section = "";
		for line in io.lines(fName) do
			if startsWith(line, "[") then
				local section = string.sub(line,2,-2);
				self.root[section] = {};
				self.reading_section = section;
			elseif not startsWith(line, ";") then
				if self.reading_section then
					local var,val = line:usplit("=");
					local var,val = var:utrim(), val:utrim();
					if string.find(val, ";") then
						val,comment = val:usplit(";");
						val = val:utrim();
					end
					self.root[self.reading_section] = self.root[self.reading_section] or {};
					self.root[self.reading_section][var] = val;
				else
					return error("No element set for setting");
				end
			end
		end
	end
	function reader:GetValue(Section, Key)
		return self.root[Section][Key];
	end
	function reader:GetKeys(Section)
		return self.root[Section];
	end
	return reader;
end

function startsWith(text,prefix)
	return string.sub(text, 1, string.len(prefix)) == prefix
end

function string:usplit(sep)
	return self:match("([^" .. sep .. "]+)[" .. sep .. "]+(.+)")
end

function string:utrim()
	return self:match("^%s*(.-)%s*$")
end

function AutoUpdate()
	
	reader = NewIniReader();
	
	if FileExist(VER_PATH) then 
		reader:Read(VER_PATH);
	
		newDownloadURL = reader:GetValue("Version", "Download")
		newVersion = reader:GetValue("Version", "Version")
		newMessage = reader:GetValue("Version", "Message")
		
		UpdateChat = {
			"<font color='#98ff00'> >> "..myHero.charName.." Auto Carry Plugin:</font> <font color='#5b9900'> Checking for update... </font>",
			"<font color='#98ff00'> >> "..myHero.charName.." Auto Carry Plugin:</font> <font color='#5b9900'> Running Version "..curVersion.."</font>",
			"<font color='#98ff00'> >> "..myHero.charName.." Auto Carry Plugin:</font> <font color='#5b9900'> New Version Released "..newVersion.."</font>",
			"<font color='#98ff00'> >> "..myHero.charName.." Auto Carry Plugin:</font> <font color='#5b9900'> Updated to version "..newVersion.." press F9 two times to use updated script. </font>",
			"<font color='#98ff00'> >> "..myHero.charName.." Auto Carry Plugin:</font> <font color='#5b9900'> Script is Up-To-Date </font>",
			"<font color='#98ff00'> >> "..myHero.charName.." Auto Carry Plugin:</font> <font color='#5b9900'> Update Message ("..newVersion.."): "..newMessage.."</font>",
			"<font color='#98ff00'> >> "..myHero.charName.." Auto Carry Plugin:</font> <font color='#5b9900'> Failed to check for update, press F9 two times if first run </font>"
					}
		
		local results, reason = os.remove(VER_PATH)
		
		if tonumber(newVersion) > tonumber(curVersion) then
			DownloadFile(newDownloadURL, SCRIPT_PATH, function()
			if FileExist(SCRIPT_PATH) then
			ChatUpdate("update")
            end
			end)
		else
		ChatUpdate("uptodate")
		end	
	else 
		ChatUpdate("failed")
	end 
	hasUpdated = false
end

function ChatUpdate(stats)
		PrintChat(UpdateChat[1])
		PrintChat(UpdateChat[2])
	if stats == "update" then
		PrintChat(UpdateChat[3])
		PrintChat(UpdateChat[4])
		PrintChat(UpdateChat[6])
	elseif stats == "uptodate" then
		PrintChat(UpdateChat[5])
		PrintChat(UpdateChat[6])
	else
		PrintChat(UpdateChat[7])
	end
end
--]]

--UPDATEURL=
--HASH=C407C88AC9587DADB17DCD25B35056DD

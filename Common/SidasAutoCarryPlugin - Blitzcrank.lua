-- Original by pqmailer. Converted by Kain and updated.
if myHero.charName ~= "Blitzcrank" or not VIP_USER then return end

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

	QReady, WReady, EReady, RReady, IGNITEReady = nil, nil, nil, nil, nil
	IGNITESlot = nil
	enemyHeroes = nil
	QPred = nil
	QCol = nil
	ToInterrupt = {}
	InterruptList = {
		{ charName = "Caitlyn", spellName = "CaitlynAceintheHole"},
		{ charName = "FiddleSticks", spellName = "Crowstorm"},
		{ charName = "FiddleSticks", spellName = "DrainChannel"},
		{ charName = "Galio", spellName = "GalioIdolOfDurand"},
		{ charName = "Karthus", spellName = "FallenOne"},
		{ charName = "Katarina", spellName = "KatarinaR"},
		{ charName = "Malzahar", spellName = "AlZaharNetherGrasp"},
		{ charName = "MissFortune", spellName = "MissFortuneBulletTime"},
		{ charName = "Nunu", spellName = "AbsoluteZero"},
		{ charName = "Pantheon", spellName = "Pantheon_GrandSkyfall_Jump"},
		{ charName = "Shen", spellName = "ShenStandUnited"},
		{ charName = "Urgot", spellName = "UrgotSwap2"},
		{ charName = "Varus", spellName = "VarusQ"},
		{ charName = "Warwick", spellName = "InfiniteDuress"}
	}

	QRange, WRange, ERange, RRange = 1050, 200, 200, 600
	QSpeed = 1.8
	QDelay = 250
	QWidth = 120

	RangeAD = 175

	if IsSACReborn then
		SkillQ = AutoCarry.Skills:NewSkill(false, _Q, QRange, "Rocket Grab", AutoCarry.SPELL_LINEAR_COL, 0, false, false, QSpeed, QDelay, QWidth, true)
	else
		SkillQ = {spellKey = _Q, range = QRange, speed = QSpeed, delay = QDelay, width = QWidth, minions = true }
	end

	IGNITESlot = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") and SUMMONER_2) or nil)

	enemyHeroes = GetEnemyHeroes()

	QPred = TargetPredictionVIP(QRange, QSpeed, QDelay, QWidth)
	QCol = Collision(QRange, QSpeed, QDelay, QWidth)

	for _, enemy in pairs(enemyHeroes) do
		for _, champ in pairs(InterruptList) do
			if enemy.charName == champ.charName then
				table.insert(ToInterrupt, champ.spellName)
			end
		end
	end

	tick = nil

	Target = nil

	debugMode = false
end

function Menu()
	AutoCarry.PluginMenu:addParam("sep", "----- "..myHero.charName.." by Kain: v"..curVersion.." -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	AutoCarry.PluginMenu:addParam("ksR", "KS with R", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("interrupt", "Interrupt with R", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("printInterrupt", "Print Interrupts", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("autoIGN", "Auto Ignite", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("drawCol", "Draw Collision", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("QHitChance", "Min. Q Hit Chance", SCRIPT_PARAM_SLICE, 70, 0, 100, 0)

	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, QRange, DAMAGE_MAGIC or DAMAGE_PHYSICAL)
	ts.name = "Blitzcrank"
	AutoCarry.PluginMenu:addTS(ts)
end

function PluginOnLoad()
	AutoCarry.SkillsCrosshair.Range = 1100

	Vars()
	Menu()
end

function PluginOnTick()
	ts:update()
	if ts ~= nil and ts.target ~= nil then Target = ts.target else Target = nil end

	SpellCheck()

	if AutoCarry.PluginMenu.autoIGN then AutoIgnite() end
	if AutoCarry.PluginMenu.ksR then KSR() end
	if AutoCarry.MainMenu.AutoCarry then Combo() end
end

function PluginOnDraw()
	if Target and AutoCarry.PluginMenu.drawCol then QCol:DrawCollision(myHero, Target) end
end

function PluginOnProcessSpell(unit, spell)
	if #ToInterrupt > 0 and AutoCarry.PluginMenu.interrupt and RReady then
		for _, ability in pairs(ToInterrupt) do
			if spell.name == ability and unit.team ~= myHero.team then
				if RRange >= GetDistance(unit) then
					CastSpell(_R)
					if AutoCarry.PluginMenu.printInterrupt then print("Tried to interrupt " .. spell.name) end
				end
			end
		end
	end
end

function SpellCheck()
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)
	IGNITEReady = (IGNITESlot ~= nil and myHero:CanUseSpell(IGNITESlot) == READY)
end

function AutoIgnite()
	if not IGNITEReady then return end

	for _, enemy in pairs(enemyHeroes) do
		if ValidTarget(enemy, 600) then
			if getDmg("IGNITE", enemy, myHero) >= enemy.health then
				CastSpell(IGNITESlot, enemy)
			end
		end
	end
end

function KSR()
	if not RReady then return end

	for _, enemy in pairs(enemyHeroes) do
		if ValidTarget(enemy, RRange) then
			if getDmg("R", enemy, myHero) >= enemy.health then
				CastSpell(_R)
			end
		end
	end
end

function Combo()
	if not Target then return end

	local Distance = GetDistance(Target)

	if Distance <= QRange and Distance > RangeAD then
		CastQ(Target)
	end

	if Distance <= RangeAD then
		if EReady and AutoCarry.PluginMenu.useE then CastSpell(_E, Target) end
		if WReady and AutoCarry.PluginMenu.useW then CastSpell(_W) end
		myHero:Attack(Target)
	end
end

function CastQ(enemy)
	if not enemy then enemy = Target end

	if QReady and IsValid(enemy, QRange) then
		local predic = QPred:GetPrediction(enemy)
		if not predic then return false end

		local isEnemyRetreating = IsEnemyRetreating(enemy, predic)
		if not isEnemyRetreating or (isEnemyRetreating and not IsNearRangeLimit(enemy, QRange)) then
			if IsSACReborn then
				SkillQ:Cast(enemy)
			else
				CastQVIP(enemy)
			end
		end
	end
end

function CastQVIP(enemy)
	local HitChance = QPred:GetHitChance(enemy)
	local Position = QPred:GetPrediction(enemy)
	local MinionCol = QCol:GetMinionCollision(myHero, enemy)

	if not MinionCol and HitChance >= AutoCarry.PluginMenu.QHitChance/100 then
		if Position and QRange >= GetDistance(Position) then
			CastSpell(_Q, Position.x, Position.z)
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

function IsNearRangeLimit(obj, range)
	if GetDistance(obj) >= (range * .95) then
		return true
	else
		return false
	end
end

function IsEnemyRetreating(target, predic)
	if GetDistance(predic) > GetDistance(target) then
		return true
	else
		return false
	end
end
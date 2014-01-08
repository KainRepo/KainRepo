if myHero.charName ~= "Thresh" then return end

--[[
	Kain's Thresh
	by: Kain
	
	To Do:
		Done? Fix draw autoattack range. Should not be autocarry reference.
		Fix VIP Prediction issues.
		On W, casts Shield to the wrong place.
		OnWndMsg Pro Mode Keys.
		Dynamic Range Circles.
		Add prediction for box.
	
	FAQ: Smart Cast messes with Q and E. Disable it to aim correctly.

		Download: https://bitbucket.org/KainBoL/bol-private/raw/master/Thresh%20-%20Kain%27s%20Chain%20Warden%20-%20Pred2.0.lua

		Version History:
			Version 1.3:
				Added PROdiction 2.0.
			Version 1.2b:
				Complete Rewrite.
			Version: 1.0:
				Release.
				

--]]

local version = "1.3"

local KeyQ = string.byte("Q")
local KeyW = string.byte("W")
local KeyE = string.byte("E")
local KeyR = string.byte("R")
	
local QRange = 1075
local WRange = 950
local ERange = 500
local RRange = 450

local QSpeed = 1.595
local ESpeed = .580

local QDelay = 493
local EDelay = 1.33

local RRadius = 450

local QWidth = 180
local EWidth = 180 -- unknown

local QMana = 80
local WMana = { 50, 55, 60, 65, 70}
local EMana = { 60, 65, 70, 75, 80}
local RMana = 100

local summoneRRange = 600
local enemyPos
local ts = TargetSelector(TARGET_LOW_HP, 1200, DAMAGE_PHYSICAL, true)
local QReady, EReady = false, false
local wLastTick = 0
local wLastHealth = 0

local useProdiction = false

local debugMode = false

--[[
	range, speed, delay, width

	spellName = threshqinternal
	projectileName = Thresh_Q_whip_beam.troy
	castDelay = 493.55 (468.00-546.00)
	projectileSpeed = 1595.05 (994.06-2033.73)
	range = 605.90 (124.26-1110.42)

	spellName = ThreshE
	projectileName = Thresh_E_mis.troy
	castDelay = 1.33 (0.00-16.00)
	projectileSpeed = 580.68 (509.73-1043.91)
	range = 556.99 (549.30-614.59)
--]]

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
	if FileExist(SCRIPT_PATH..'Common/Prodiction.lua') then
		require "Prodiction"

		LoadProtectedScript('RHBPFBArLzQEXCVlJgpXDxwMMRwSIlciJg0kFihaTEhGSWQ6QjIJbURmIhcqKCkORwYkFyweIwBLAik0JF04MRgjGiNaTEhGSWQ6LisdQHNPe2xIRklkOi0wFy4NLx0LZRMHQ2AuMQw9KRQ9ASwvNARcJW0aLAoyIRUgICxBEzkkFyocalIWNSklCR9rIRwhGD9eRTIlJBlbZ2UKIgw0EQBpbCMMXycnGC4SAAcLJjgpAl1iSHNEcE97FyA4NR9dazIJdzgiFjU3IyQEUD8sFiM2JBgAJjhoDlI4MSo9HCoeSWU+IQNULmlZPgkjFwFpbCQIXyo8VW0OLxYRLWBgHlw+NxooVWYRBCkgIgxQIAMMIxoyGworZU1nOkJMHCMdB592B270F4A40CDF7A461349D4F0212A')

		useProdiction = true

		InitPROdiction()

		Col = Collision(QRange, 1200, 0.5, QWidth)
		qp = SetupPROdiction(_Q, QRange, QSpeed*1000, QDelay/1000, QWidth, myHero,
			function(unit, pos, castSpell)
				if QReady and GetDistance(unit) < QRange then
					FireQ(unit, pos, castSpell)
				end
			end)
		qe = TargetPredictionVIP(ERange, ESpeed*1000, EDelay/1000, EWidth)

		PrintChat("<font color='#CCCCCC'> >> Kain's Thresh - Prediction 2.0 Loaded <<</font>")
	else
		PrintChat("<font color='#CCCCCC'> >> Please install Prodiction.lua in Common folder. <<</font>")
	end
-- else
	-- qp = TargetPredictionVIP(QRange, 1200, 0.5, QWidth)
--	qp = TargetPredictionVIP(QRange, QSpeed*1000, QDelay/1000, QWidth)
--	qe = TargetPredictionVIP(ERange, ESpeed*1000, EDelay/1000, EWidth)
--	PrintChat("<font color='#CCCCCC'> >> Kain's Thresh - VIP Prediction <<</font>")
--	end
else
	-- qp = TargetPrediction(QRange, 1.2, 500, QWidth)
	qp = TargetPrediction(QRange, QSpeed, QDelay, QWidth)
	qe = TargetPrediction(ERange, ESpeed, EDelay, EWidth)
	PrintChat("<font color='#CCCCCC'> >> Kain's Thresh - Free Prediction <<</font>")
end

function OnLoad()
	QReady, WReady, EReady, RReady = false, false, false, false

	MinionMarkerOnLoad()

	enemyMinions = minionManager(MINION_ENEMY, 1200, player)
    ThreshConfig = scriptConfig("Kain's Thresh: Main - v"..version, "Thresh")
	ThreshConfig:addParam("Combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
    ThreshConfig:addParam("Pull", "Pull with Flay", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("E"))
    ThreshConfig:addParam("Push", "Push with Flay", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("T"))
	ThreshConfig:addParam("Hook", "Pull with Chain", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("Q"))
	ThreshConfig:addParam("HooknPull", "HooknPull", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("G"))
	ThreshConfig:addParam("PullnPassage", "Pull n Passage", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("H"))
	ThreshConfig:addParam("Escape", "Box > Push Flay to Escape", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("A"))
	ThreshConfig:addParam("AExhaust", "Use Exhaust on Flay", SCRIPT_PARAM_ONOFF, false)
	ThreshConfig:addParam("sep", "----- [ Ultimate ] -----", SCRIPT_PARAM_INFO, "")
	ThreshConfig:addParam("Box", "Auto Ultimate", SCRIPT_PARAM_ONOFF, true)
	ThreshConfig:addParam("SmartUltKS", "Smart Ult Kill Secure", SCRIPT_PARAM_ONOFF, true)
	ThreshConfig:addParam("BoxCount", "Enemy Count before Using Ulti", SCRIPT_PARAM_SLICE, 3, 0, 5, 0)
	ThreshConfig:addParam("BoxRange", "Use Auto Ult at this range", SCRIPT_PARAM_SLICE, 400, 0, 450, 0)
	ThreshConfig:addParam("RMec", "Use MEC for R", SCRIPT_PARAM_ONOFF, true)

	ThreshExtraConfig = scriptConfig("Kain's Thresh: Extra", "Thresh")
	ThreshExtraConfig:addParam("sep", "----- [ Draw ] -----", SCRIPT_PARAM_INFO, "")
	ThreshExtraConfig:addParam("WRapid", "Use W when lost rapid amount of health", SCRIPT_PARAM_ONOFF, true)
	ThreshExtraConfig:addParam("WPercentage", "Percent of health to use W",SCRIPT_PARAM_SLICE, 0, 0, 100, 0)
	ThreshExtraConfig:addParam("WTime", "W tracking time",SCRIPT_PARAM_SLICE, 0, 2, 5, 0)
	ThreshExtraConfig:addParam("Ignite", "Auto Ignite", SCRIPT_PARAM_ONOFF, true)
	ThreshExtraConfig:addParam("Marker", "Minion Marker", SCRIPT_PARAM_ONOFF, false)
	ThreshExtraConfig:addParam("DoubleIgnite", "Don't Double Ignite", SCRIPT_PARAM_ONOFF, true)
	ThreshExtraConfig:addParam("ProMode", "Q and E Auto Aim", SCRIPT_PARAM_ONOFF, true)
	ThreshExtraConfig:addParam("sep", "----- [ Draw ] -----", SCRIPT_PARAM_INFO, "")
	ThreshExtraConfig:addParam("DisableDraw", "Disable Draw", SCRIPT_PARAM_ONOFF, false)
	ThreshExtraConfig:addParam("DrawFurthest", "Draw Furthest Spell Available", SCRIPT_PARAM_ONOFF, true)
	ThreshExtraConfig:addParam("DrawTargetArrow", "Draw Arrow to Target", SCRIPT_PARAM_ONOFF, false)
	ThreshExtraConfig:addParam("DrawAD", "Draw Auto Attack", SCRIPT_PARAM_ONOFF, true)
	ThreshExtraConfig:addParam("DrawQ", "Draw Death Sentence", SCRIPT_PARAM_ONOFF, true)
	ThreshExtraConfig:addParam("DrawW", "Draw Dark Passage", SCRIPT_PARAM_ONOFF, true)
	ThreshExtraConfig:addParam("DrawE", "Draw Flay", SCRIPT_PARAM_ONOFF, true)
	ThreshExtraConfig:addParam("DrawR", "Draw The Box", SCRIPT_PARAM_ONOFF, true)

	ThreshConfig:permaShow("Box")
	ThreshConfig:permaShow("AExhaust")
    ts.name = "Thresh"
    ThreshConfig:addTS(ts)
    PrintChat(">> Kain's Thresh - v"..version.." <<")

	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then ign = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then ign = SUMMONER_2
	else ign = nil
	end

	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerExhaust") then exhaust = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerExhaust") then exhaust = SUMMONER_2
	else exhaust = nil
	end
end

function willHitMinion(predic, width)
	local hitCount = 0
	for _, minionObjectQ in pairs(enemyMinions.objects) do
		 if minionObjectQ ~= nil and string.find(minionObjectQ.name,"Minion_") == 1 and minionObjectQ.team ~= player.team and minionObjectQ.dead == false then
			 if predic ~= nil and player:GetDistance(minionObjectQ) < QRange then
				 ex = player.x
				 ez = player.z
				 tx = predic.x
				 tz = predic.z
				 dx = ex - tx
				 dz = ez - tz
				 if dx ~= 0 then
				 m = dz/dx
				 c = ez - m*ex
				 end
				 mx = minionObjectQ.x
				 mz = minionObjectQ.z
				 dis = (math.abs(mz - m*mx - c))/(math.sqrt(m*m+1))
				 if dis < width and math.sqrt((tx - ex)*(tx - ex) + (tz - ez)*(tz - ez)) > math.sqrt((tx - mx)*(tx - mx) + (tz - mz)*(tz - mz)) then
					hitCount = hitCount + 1
					if hitCount > 1 then
						return true
					end
				 end
			 end
		 end
	 end
	 return false
end

function OnCreateObj(obj)
	if ThreshExtraConfig.Marker then
		MinionMarkerOnCreateObj(obj)
	end
end

function CanCast(Spell)
    return (player:CanUseSpell(Spell) == READY)
end

function IReady()
	if ign ~= nil then
		return (player:CanUseSpell(ign) == READY)
	end
end

function ExhaustReady()
	if exhaust ~= nil then
		return (player:CanUseSpell(exhaust) == READY)
	end
end

function OnTick()
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)

	ts:update()
	enemyMinions:update()

	if ts.target ~= nil then
		if ThreshConfig.Escape then BoxEscape() end

		if WReady and ThreshExtraConfig.WRapid and TakingRapidDamage() then
			local closestAlly = findClosestAlly()
			if closestAlly ~= nil and GetDistance(closestAlly) < WRange then
				CastSpell(_W, closestAlly.x, closestAlly.z)
			else
				CastSpell(_W, myHero.x, myHero.z)
			end
		end

		if ThreshConfig.Combo or ThreshConfig.HooknPull then HooknPull() end
		if ThreshConfig.PullnPassage then PullnPassage() end
		if ThreshConfig.Hook then Hook() end
		if ThreshConfig.Pull then FlayPull() end
		if ThreshConfig.Push then FlayPush() end
		if ThreshConfig.Combo or ThreshConfig.Box then AutoBox() end
		if ThreshExtraConfig.Ignite and ign ~= nil then AutoIgnite() end
	end
end

function OnDraw()
	if ThreshExtraConfig.DrawTargetArrow and ts ~= nil and ts.target ~= nil and not ts.target.dead and (AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.MixedMode) then
		DrawArrowsToPos(myHero, ts.target)
	end

	if not ThreshExtraConfig.DisableDraw and not myHero.dead then
		local farSpell = FindFurthestReadySpell()

		if ThreshExtraConfig.DrawAD then
			DrawCircle(myHero.x, myHero.y, myHero.z, getTrueRange(), 0x808080) -- Gray
		end

		if ThreshExtraConfig.DrawQ and QReady and ((ThreshExtraConfig.DrawFurthest and farSpell and farSpell == QRange) or not ThreshExtraConfig.DrawFurthest) then
			DrawCircle(myHero.x, myHero.y, myHero.z, QRange, 0x0099CC) -- Blue
		end

		if ThreshExtraConfig.DrawW and WReady and ((ThreshExtraConfig.DrawFurthest and farSpell and farSpell == WRange) or not ThreshExtraConfig.DrawFurthest) then
			DrawCircle(myHero.x, myHero.y, myHero.z, WRange, 0xFFFF00) -- Yellow
		end

		if ThreshExtraConfig.DrawE and EReady and ((ThreshExtraConfig.DrawFurthest and farSpell and farSpell == ERange) or not ThreshExtraConfig.DrawFurthest) then
			DrawCircle(myHero.x, myHero.y, myHero.z, ERange, 0x00FF00) -- Green
		end

		if ThreshExtraConfig.DrawR and RReady and ((ThreshExtraConfig.DrawFurthest and farSpell and farSpell == RRange) or not ThreshExtraConfig.DrawFurthest) then
			DrawCircle(myHero.x, myHero.y, myHero.z, RRange, 0xFF0000) -- Red
		end

		if ts ~= nil and ts.target ~= nil then
			for j=0, 10 do
				DrawCircle(ts.target.x, ts.target.y, ts.target.z, 40 + j*1.5, 0x00FF00) -- Green
			end
		end

		if ValidTarget(ts.target, QRange) and CanCast(_Q) then
			local enemyPos = ts.nextPosition
			if enemyPos ~= nil then
				local x1, y1, OnScreen1 = get2DFrom3D(myHero.x, myHero.y, myHero.z)
				local x2, y2, OnScreen2 = get2DFrom3D(enemyPos.x, enemyPos.y, enemyPos.z)
				DrawLine(x1, y1, x2, y2, 3, 0xFFFF0000)
			end
		end
	end

	if ThreshExtraConfig.Marker then
		MinionMarkerOnDraw()
	end
end

function FindFurthestReadySpell()
	local farSpell = nil

	if ThreshExtraConfig.DrawQ and QReady then farSpell = QRange end
	if ThreshExtraConfig.DrawW and WReady and (not farSpell or WRange > farSpell) then farSpell = WRange end
	if ThreshExtraConfig.DrawE and EReady and (not farSpell or ERange > farSpell) then farSpell = ERange end
	if ThreshExtraConfig.DrawR and RReady and (not farSpell or RRange > farSpell) then farSpell = RRange end

	return farSpell
end

function getTrueRange()
    return myHero.range + GetDistance(myHero.minBBox)
end

function DrawArrowsToPos(pos1, pos2)
	if pos1 and pos2 then
		startVector = D3DXVECTOR3(pos1.x, pos1.y, pos1.z)
		endVector = D3DXVECTOR3(pos2.x, pos2.y, pos2.z)
		DrawArrows(startVector, endVector, 60, 0xE97FA5, 100)
	end
end

--[[
	Combat
--]]

function getPred(speed, delay, target)
	if target == nil then return nil end
	local travelDuration = (delay + GetDistance(myHero, target)/speed)
	travelDuration = (delay + GetDistance(GetPredictionPos(target, travelDuration))/speed)
	travelDuration = (delay + GetDistance(GetPredictionPos(target, travelDuration))/speed)
	travelDuration = (delay + GetDistance(GetPredictionPos(target, travelDuration))/speed) 	
	return GetPredictionPos(target, travelDuration)
end

function CastR(p) 
	if ThreshConfig.RMec then
		if p and GetDistance(p) <= RRange then
			CastSpell(_R, p.x, p.z)
		end
	else
		CastSpell(_R, ts.target.x, ts.target.z)
	end
end

function Hook()
	if QReady and ValidTarget(ts.target, QRange + 500) then
		if useProdiction then
			predic = qp:EnableTarget(ts.target, true)
		else
			predic = qp:GetPrediction(ts.target)
			return FireQ(ts.target, predic, myHero:GetSpellData(_Q))
		end
	end

	return false
end

function FireQ(unit, predic, spell)
	if QReady and ValidTarget(unit, QRange) and predic and GetDistance(predic) < QRange and not unit.dead and ((not VIP_USER and not willHitMinion(predic, QWidth)) or (VIP_USER and not Col:GetMinionCollision(myHero, predic))) then
		local isEnemyRetreating = IsEnemyRetreating(unit, predic)
		if not isEnemyRetreating or (isEnemyRetreating and not IsNearRangeLimit(predic, QRange)) then
			CastSpell(_Q, predic.x, predic.z)
			return true
		end
	end

	return false
end

function HooknPull()
--	local predic = qp:GetPrediction(ts.target)
--	-- if predic and GetDistance(predic) < QRange and QReady then
--	if predic and ValidTarget(predic, QRange) and QReady then
--		if VIP_USER and not Col:GetMinionCollision(myHero, predic) then
--			CastSpell(_Q, predic.x, predic.z)
--		else CastSpell(_Q, predic.x, predic.z) end
--	end
	Hook()

--	if GetDistance(ts.target) < ERange and EReady then
--		xPos = myHero.x + (myHero.x - ts.target.x)
--		zPos = myHero.z + (myHero.z - ts.target.z)
--		CastSpell(_E, xPos, zPos)
--	end

	Pull()
end

function PullnPassage()
	-- local predic = qp:GetPrediction(ts.target)
	local castW, castQ = false, false

--[[
	if predic and GetDistance(predic) < QRange and QReady then
		if VIP_USER then
			if not Col:GetMinionCollision(myHero, predic) then
				CastSpell(_Q, predic.x, predic.z)
				castW = true
			end
		else 
			CastSpell(_Q, predic.x, predic.z)
			castW = true
		end
	end
--]]

	if QReady then
		Hook()
		if not QReady then castW = true end
	end

	local closestAlly = findClosestAlly()

	if closestAlly ~= nil and GetDistance(closestAlly) < WRange and WReady and castW then
		CastSpell(_W, closestAlly.x, closestAlly.z)
		castQ = true
		castW = false
	end
	if GetDistance(ts.target) < ERange and EReady then
		xPos = myHero.x + (myHero.x - ts.target.x)
		zPos = myHero.z + (myHero.z - ts.target.z)
		CastSpell(_E, xPos, zPos)
	end
end

function findClosestAlly()
	local closestAlly = nil
	local currentAlly = nil

	for i=1, heroManager.iCount do
		currentAlly = heroManager:GetHero(i)
		if currentAlly.team == myHero.team and not currentAlly.dead and currentAlly.charName ~= myHero.charName then
			if closestAlly == nil then
				closestAlly = currentAlly
			elseif GetDistance(currentAlly) < GetDistance(closestAlly) then
				closestAlly = currentAlly
			end
		end
	end
	return closestAlly
end

function TakingRapidDamage()
	if GetTickCount() - wLastTick > (ThreshExtraConfig.WTime * 1000) then
		--> Check amount of health lost
		if myHero.health - wLastHealth > myHero.maxHealth * (ThreshExtraConfig.WPercentage / 100) then
			return true
		else
			--> Reset counters
			wLastTick = GetTickCount()
			wLastHealth = myHero.health
		end
	end
end

function IsNearRangeLimit(obj, range)
	if GetDistance(obj) >= (range * .98) then
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

function FlayPull()
	if ThreshConfig.AExhaust then AutoExhaust() end
--	if ValidTarget(ts.target, ERange) and CanCast(_E) then
--		xPos = myHero.x + (myHero.x - ts.target.x)
--		zPos = myHero.z + (myHero.z - ts.target.z)
--		CastSpell(_E, xPos, zPos)
--	end
	Pull()
end

function Pull()
	if not ts.target or ts.target.dead then return end
	local predic = qe:GetPrediction(ts.target)

	-- if EReady and ValidTarget(ts.target, ERange) and predic and GetDistance(predic) < ERange and not ts.target.dead then
--	if EReady and ValidTarget(ts.target, ERange) and not ts.target.dead then
--		xPos = myHero.x + (myHero.x - ts.target.x)
--		zPos = myHero.z + (myHero.z - ts.target.z)
--		CastSpell(_E, xPos, zPos)
--	end
	castPos = nil

	if EReady then
		if predic and GetDistance(predic) < ERange and (not VIP_USER or (VIP_USER and not Col:GetMinionCollision(myHero, predic))) then
			if debugMode then PrintChat("E Pull: Prediction") end
			castPos = predic
		elseif ValidTarget(ts.target, ERange) then
			if debugMode then PrintChat("E Pull: No Prediction") end
			castPos = ts.target
		end

		if castPos ~= nil then
			xPos = myHero.x + (myHero.x - castPos.x)
			zPos = myHero.z + (myHero.z - castPos.z)
			CastSpell(_E, xPos, zPos)
			return true
		end
	end

	return false
end

function FlayPush()
	if not ts.target or ts.target.dead then return end
	local predic = qe:GetPrediction(ts.target)

	if EReady then
		if predic and GetDistance(predic) < ERange and (not VIP_USER or (VIP_USER and not Col:GetMinionCollision(myHero, predic))) then
			if debugMode then PrintChat("E Push: Prediction") end
			CastSpell(_E, predic.x, predic.z)
			return true
		elseif ValidTarget(ts.target, ERange) and CanCast(_E) then
			if debugMode then PrintChat("E Push: No Prediction") end
			CastSpell(_E, ts.target.x, ts.target.z)
			return true
		end
	end

	return false
end

function AutoBox()
	if ThreshConfig.Box then
		if debugMode then
			-- PrintChat("In box range: "..CountEnemyHeroInRange(ThreshConfig.BoxRange)..". Damage: "..CalculateDamage(ts.target)..", "..ts.target.health)
		end

		-- CountEnemies(p, RRange) >= 2
		if CanCast(_R) and (CountEnemyHeroInRange(ThreshConfig.BoxRange) >= ThreshConfig.BoxCount or isSmartUltKS(ts)) then
			if debugMode then PrintChat("Autoboxing") end
			--local predic = qe:GetPrediction(ts.target)
			local p = GetAoESpellPosition(RRadius, ts.target)
			-- local p = GetAoESpellPosition(RRadius, predic)
			CastR(p)
		end
	end
end

function isSmartUltKS(ts)
	if not ThreshConfig.SmartUltKS then return false end

	if CalculateDamage(ts.target) > ts.target.health and CountEnemyHeroInRange(ThreshConfig.BoxRange) >= CountAllyHeroInRange(ThreshConfig.BoxRange) then
		return true
	else
		return false
	end
end

function CountAllyHeroInRange(range)
	count = 0

	for _, ally in pairs(GetAllyHeroes()) do
		if ally.valid and GetDistance(ally) < range then
			count = count + 1
		end
	end

	return count
end

function BoxEscape()
	-- local qPred = getPred(1.2, 0.5, ts.target)
	if ValidTarget(ts.target, ThreshConfig.BoxRange) and CanCast(_R) then
		CastSpell(_R)
--		if ValidTarget(ts.target, ERange) and CanCast(_E) then
--			CastSpell(_E, ts.target.x, ts.target.z)
--		end
		FlayPush()
	end
end	

function AutoIgnite()
	local iDmg = 0		
	if IReady and not myHero.dead then
		for i = 1, heroManager.iCount, 1 do
			local target = heroManager:getHero(i)
			if ValidTarget(target) then
				iDmg = 50 + 20 * myHero.level
				if target ~= nil and target.team ~= myHero.team and not target.dead and target.visible and GetDistance(target) < summoneRRange and target.health < iDmg then
					if ThreshExtraConfig.DoubleIgnite and not TargetHaveBuff("SummonerDot", target) then
						CastSpell(ign, target)
						elseif not ThreshExtraConfig.DoubleIgnite then
							CastSpell(ign, target)
					end
				end
			end
		end
	end
end

function AutoExhaust()
	if ExhaustReady and exhaust ~= nil and not myHero.dead then
		if ValidTarget(ts.target, summoneRRange) then
			CastSpell(exhaust, ts.target)
		end
	end
end

function CalculateDamage(enemy)
	local totalDamage = 0
	local currentMana = myHero.mana 
	local qReady = QReady and currentMana >= QMana
	local wReady = WReady and currentMana >= WMana[myHero:GetSpellData(_W).level]
	local eReady = EReady and currentMana >= EMana[myHero:GetSpellData(_E).level]
	local rReady = RReady and currentMana >= RMana 
	if qReady then totalDamage = totalDamage + getDmg("Q", enemy, myHero) end
	if wReady then totalDamage = totalDamage + getDmg("W", enemy, myHero) end
	if eReady then totalDamage = totalDamage + getDmg("E", enemy, myHero) end
	if rReady then totalDamage = totalDamage + getDmg("R", enemy, myHero) end
	return totalDamage 
end 


function CountEnemies(point, range)
    local ChampCount = 0
    for j = 1, heroManager.iCount, 1 do
        local enemyhero = heroManager:getHero(j)
        if myHero.team ~= enemyhero.team and ValidTarget(enemyhero, RRange + 50) then
            if GetDistance(enemyhero, point) <= range then
                ChampCount = ChampCount + 1
            end
        end
    end            
    return ChampCount
end

--[[
	Simple Minion Marker
	by: Kilua
--]]

function MinionMarkerOnLoad()
	minionTable = {}
	for i = 0, objManager.maxObjects do
		local obj = objManager:GetObject(i)
		if obj ~= nil and obj.type ~= nil and obj.type == "obj_AI_Minion" then 
			table.insert(minionTable, obj) 
		end
	end
end

function MinionMarkerOnDraw() 
	for i,minionObject in ipairs(minionTable) do
		if minionObject.valid and (minionObject.dead == true or minionObject.team == myHero.team) then
			table.remove(minionTable, i)
			i = i - 1
		elseif minionObject.valid and minionObject ~= nil and myHero:GetDistance(minionObject) ~= nil and myHero:GetDistance(minionObject) < 1500 and minionObject.health ~= nil and minionObject.health <= myHero:CalcDamage(minionObject, myHero.addDamage+myHero.damage) and minionObject.visible ~= nil and minionObject.visible == true then
			for g = 0, 6 do
				DrawCircle(minionObject.x, minionObject.y, minionObject.z,80 + g,255255255)
			end
        end
    end
end

function MinionMarkerOnCreateObj(object)
	if object ~= nil and object.type ~= nil and object.type == "obj_AI_Minion" then table.insert(minionTable, object) end
end

function OnWndMsg(msg,key)
	if not ts.target or ts.target.dead then return end

	if Target ~= nil and ThreshExtraConfig.ProMode then
		if msg == KEY_DOWN and key == KeyQ then Hook() end
		-- if msg == KEY_DOWN and key == KeyW then CastW() end
		if msg == KEY_DOWN and key == KeyE then FlayPull() end
		-- if msg == KEY_DOWN and key == KeyR then CastR() end
	end
end

-- End of Thresh script

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

-- I don't need range since main_target is gonna be close enough. You can add it if you do.
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

--UPDATEURL=
--HASH=B9F4A8828A115B12FC93AFA80252E3D5

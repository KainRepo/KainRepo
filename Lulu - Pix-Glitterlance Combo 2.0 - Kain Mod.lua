--[[
	Lulu Pix-Glitterlance Combo 2.0
		by eXtragoZ

	Press spacebar to hit the enemy

	1º The script searches for TargetSelector target in range of E to do E -> Q
	2º The script searches for the closest enemy in range of Q from you or pix to do Q
	3º The script searches for the closest creep or ally to the enemy in the range of Q and in the range of E from you to do E (creep or ally) -> Q

	Features:
		- Full combo: E -> Q
		- The circle indicates the range of E
		- Draws the how the script will use the Q
		- PredictionVIP for Q (if you dont are VIP the script will use the current position of the enemy)
		- Pix position check
		- Target configuration (only when the enemy is in E range)
		- Press shift to configure
]]
--MissileSpeed	"1400.0000"
--Lulu_Q_Mis.troy
--delay 250 + 2 * latency
if myHero.charName ~= "Lulu" then return end
--[[		Config		]]
local HK = 32 -- C
--[[		Code		]]
local range = 2000
local qrange = 925
local erange = 650 + 25
--
local objminionTable = {}
local minionnearenemy = {}
local minionnearenemydist = {}
local PixObj = nil
local lessdistance = qrange
local Qtarget = nil
local Qcastedfrom = nil
-- Active
local QREADY, EREADY = false, false
local tsE
local qDelay = 250
local wayPointManager = WayPointManager()
local targetPrediction2 = TargetPredictionVIP(10000, nil, (qDelay + GetLatency()*2)/1000)

function OnLoad()
	LPGConfig = scriptConfig("Lulu Pix-Glitterlance Combo 2.0", "lulupixglitterlance")
	LPGConfig:addParam("scriptActive", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, HK)
	LPGConfig:addParam("ComboW", "Use W in Combo", SCRIPT_PARAM_ONOFF, true)
	LPGConfig:addParam("drawcircles", "Draw Circles", SCRIPT_PARAM_ONOFF, true)
	tsE = TargetSelector(TARGET_LOW_HP_PRIORITY,erange,DAMAGE_PHYSICAL)
	tsE.name = "Lulu"
	LPGConfig:addTS(tsE)
	LPGLoadMinions()
	PrintChat(" >> Lulu Pix-Glitterlance Combo 2.0 loaded!")
end
function OnTick()
	-- if not IsTickReady(10) then return false end

	tsE:update()
	QREADY = (myHero:CanUseSpell(_Q) == READY)
	WREADY = (myHero:CanUseSpell(_W) == READY)
	EREADY = (myHero:CanUseSpell(_E) == READY)
	
	if VIP_USER then
		targetPrediction2.Spell.Delay = (qDelay + GetLatency()*2)/1000
	end
	local qcast = false
	local ecast = false
	for e=1, heroManager.iCount do
		minionnearenemy[e] = nil
		minionnearenemydist[e] = qrange
	end
	lessdistance = qrange
	Qtarget = nil
	Qcastedfrom = nil
	if not myHero.dead then	
		for i,object in ipairs(objminionTable) do
			if object and not object.dead and object.name ~= "RobotBuddy" and GetDistance(object) <= erange then
				local edamage = getDmg("E",object,myHero)
				if myHero.team == object.team or object.health > edamage*1.1  then
					for e=1, heroManager.iCount do
						local enemy = heroManager:GetHero(e)
						if ValidTarget(enemy, range) then
							local distanceenemy = GetDistance(enemy,object)
							if distanceenemy <= minionnearenemydist[e] then
								minionnearenemy[e] = object
								minionnearenemydist[e] = distanceenemy
							end
						end
					end
				end
			end
		end
		for i=1, heroManager.iCount do
			local teammate = heroManager:GetHero(i)
			if ValidTarget(teammate, erange, false) then
				for e=1, heroManager.iCount do
					local enemy = heroManager:GetHero(e)
					if ValidTarget(enemy, range) then
						local distanceenemy = GetDistance(teammate,enemy)
						if distanceenemy <= minionnearenemydist[e] then
							minionnearenemy[e] = teammate
							minionnearenemydist[e] = distanceenemy
						end
					end
				end
			end
		end
		for i=1, heroManager.iCount do
			local enemy = heroManager:GetHero(i)
			if ValidTarget(enemy) then
				if PixObj then
					local distancePixenemy = GetDistance(PixObj,enemy)
					if distancePixenemy <= lessdistance then
						lessdistance = distancePixenemy
						Qtarget = enemy
						Qcastedfrom = PixObj
					end
				end
				local distanceenemy = GetDistance(enemy)
				if distanceenemy <= lessdistance then
					lessdistance = distanceenemy
					Qtarget = enemy
					Qcastedfrom = myHero
				end
			end
		end
		if LPGConfig.scriptActive then
			if tsE.target ~= nil and EREADY then
				CastSpell(_E, tsE.target)
				ecast = true
				if QREADY then
					if VIP_USER then
						local QPos, t = targetPrediction2:GetPrediction(tsE.target)
						if QPos then
							CastSpell(_Q, QPos.x, QPos.z)
							qcast = true
						end
					else
						CastSpell(_Q, tsE.target.x, tsE.target.z)
						qcast = true
					end
				end
			end
			if QREADY and not qcast and Qtarget then
				if VIP_USER then
					local QPos, t = targetPrediction2:GetPrediction(Qtarget)
					if QPos and GetDistance(Qcastedfrom,QPos) <= qrange then
						CastSpell(_Q, QPos.x, QPos.z)
						qcast = true
					end
				else
					CastSpell(_Q, Qtarget.x, Qtarget.z)
					qcast = true
				end
			end
			if QREADY and EREADY and not qcast and not ecast then
				for i=1, heroManager.iCount do
					local enemy = heroManager:GetHero(i)
					if minionnearenemy[i] and not qcast then
						if VIP_USER then
							local QPos, t = targetPrediction2:GetPrediction(enemy)
							if QPos then
								CastSpell(_E, minionnearenemy[i])
								CastSpell(_Q, QPos.x, QPos.z)
								qcast = true
							end
						else
							CastSpell(_E, minionnearenemy[i])
							CastSpell(_Q, enemy.x, enemy.z)
							qcast = true
						end
					end
				end
			end
		end

		if LPGConfig.ComboW and tsE and tsE.target ~= nil and WREADY then
			PrintChat("A")
			CastSpell(_W, tsE.target)
		end
	end
end

function IsTickReady(tickFrequency)
	-- Improves FPS
	if tick ~= nil and math.fmod(tick, tickFrequency) == 0 then
		return true
	else
		return false
	end
end

function OnDraw()
	if not IsTickReady(75) then return false end

	if LPGConfig.drawcircles and not myHero.dead then
		DrawCircle(myHero.x, myHero.y, myHero.z, erange, 0x992D3D)
		if QREADY then
			if Qcastedfrom then
				local maxdistposq = Qcastedfrom + (Vector(Qtarget) - Qcastedfrom):normalized()*qrange
				DrawArrows(Qcastedfrom, maxdistposq, 40, 0xFFFFFF, 0)
			elseif EREADY then
				for i=1, heroManager.iCount do
					local enemy = heroManager:GetHero(i)
					if minionnearenemy[i] then
						local maxdistposq = minionnearenemy[i] + (Vector(enemy) - minionnearenemy[i]):normalized()*qrange
						DrawArrows(minionnearenemy[i], maxdistposq, 40, 0xFFFFFF, 0)
					end
				end
			end
		end
	end
end
function OnCreateObj(object)
	if object and object.type == "obj_AI_Minion" then
		if object.name:find("T200") or object.name:find("Red") or object.name:find("T100") or object.name:find("Blue") then
			table.insert(objminionTable, object)
		end
	end
	if object and object.type == "obj_AI_Minion" and object.name == "RobotBuddy" then
		PixObj = object
	end
end
function OnDeleteObj(object)
	for i,v in ipairs(objminionTable) do
		if not v.valid or object.name:find(v.name) then
			table.remove(objminionTable,i)
		end
	end
	if object and object.type == "obj_AI_Minion" and object.name == "RobotBuddy" then
		PixObj = nil
	end
end
function LPGLoadMinions()
	for i=1, objManager.maxObjects do
		local object = objManager:getObject(i)
		if object and object.type == "obj_AI_Minion" and not object.dead then
			table.insert(objminionTable, object)
		end
		if object and object.type == "obj_AI_Minion" and object.name == "RobotBuddy" then
			PixObj = object
		end
	end
end
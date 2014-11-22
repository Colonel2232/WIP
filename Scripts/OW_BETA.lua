require("libs.ScriptConfig")
require("libs.Utils")
require("libs.HeroInfo")
require("libs.EasyHUD")
require("libs.TargetFind")
require("libs.Animations")

--[[
                         '''''''''''                               
                     ''''```````````'''''''''''.                   
                 ''''`````````````````````..../.                   
              '''``````````````````````.../////.                   
          ''''``````````````````````...////////.                   
        ''wwwwwwwwww````````````....///////////.                   
         weeeeeeeeeewwwwwwwwww..//////////////.                    
         weeeeeeeeeeeeeeeeeeeew///////////////.                    
          weeeeeeeeeeeeeeeeeeew///////////////.                    
           weeeeeeeeeeeeeeeeeew///////////////.                    
           weeeeeeeeeeeeeeeeeeew//////////////.                    
            weeeeeeeeeeeeeeeeeew/////////////.                     
             weeeeeeeeeeeeeeeeew/////////////.                     
             weeeeeeeeeeeeeeeeew/////////////.                     
              weeeeeeeeeeeeeeeew/////////////.                     
               weeeeeeeeeeeeeeeew////////////.                     
               weeeeeeeeeeeeeeeew///////////.                      
                weeeeeeeeeeeeeeew//////////.                       
                 weeeeeeeeeeeeeew////////..                        
                 weeeeeeeeeeeeeeew//////.                          
                  wweeeeeeeeeeeeew/////.                           
                    wwwweeeeeeeeew////.                              *           
                        wwwweeeeew//..                    *       *              
                            wwwwew/.            * *     **    **      *    
                                ww.             *      **    *     **          
                                                 *      **   * *****    * **   
                                                   *      ****** ** * *     ***
                                                      *** *********           *
        +-------------------------------------------------+   * *  *            
        |                                                 |    *  *** **        
        |           Orb Walker - Made by Moones           |    *   *    **      
        |           ^^^^^^^^^^^^^^^^^^^^^^^^^^^           |    *    *     **    
        +-------------------------------------------------+    *   **      **   
                                                                            *       
        =+=+=+=+=+=+=+=+=+ VERSION 2.1 +=+=+=+=+=+=+=+=+=+=
	 
        Description:
        ------------
	
             - Orb Walk when holding hotkey on mouse hovered hero or lowest hp enemy hero in attack range.
             - AutoAttack while Orb walk when holding hotkey.
             - Supports all ability Unique Attack Modifiers: Clinkz's Searing Arrows, Drow Ranger's Frost Arrows, Viper's Poison Attack, Huskar's Burning Spear, Silencer's Glaives of Wisdom, Jakiro's Liquid Fire, Outworld Devourer's Arcane Orb, Enchantress's Impetus (include range of it).
             - Also supports range of passives: Sniper's Aim and Templar Assassin's Psy Blades		 
	   
        Changelog:
        ----------
		
			 Update 2.1:
			 Fixed FPS drop
			 Fixed bug in Animations lib
		
             Update 2.0:
			 Now requires Animations library.
			 Fixed orbwalking for all heroes.
	
             Update 1.1:
             Added key for AutoAttacking while Orbwalking.

             Update 1.0b:
             First release. Bugs may appear, so feel free to report them.
]]--

local config = ScriptConfig.new()
config:SetParameter("CustomMove", "J", config.TYPE_HOTKEY)
config:SetParameter("Menu", "H", config.TYPE_HOTKEY)
config:SetParameter("ModifiersTogglekey", "A", config.TYPE_HOTKEY)
config:SetParameter("AutoAttackKey", "S", config.TYPE_HOTKEY)
config:SetParameter("Spaceformove", true)
config:SetParameter("DontOrbwalkWhenIdle", true)
config:SetParameter("ActiveFromStart", true)
config:SetParameter("ShowMenuAtStart", true)
config:SetParameter("EnableAttackModifiers", true)
config:SetParameter("ShowSign", true)
config:Load()
	
custommove = config.CustomMove
menu = config.Menu
modifhotkey = config.ModifiersTogglekey
noorbwalkidle = config.DontOrbwalkWhenIdle
spaceformove = config.Spaceformove
active = config.ActiveFromStart
showmenu = config.ShowMenuAtStart
enablemodifiers = config.EnableAttackModifiers
showSign = config.ShowSign
aakey = config.AutoAttackKey

sleep = 0

local reg = false local HUD = nil local myhero = nil local victim = nil local myId = nil local attack = 0 local move = 0 
local attack1 = 0 local move1 = 0
local onlybearorb = false

local monitor = client.screenSize.x/1600
local F14 = drawMgr:CreateFont("F14","Tahoma",14*monitor,550*monitor) 
local statusText = drawMgr:CreateText(10*monitor,580*monitor,-1,"",F14) statusText.visible = false

function activeCheck()	
	if PlayingGame() then
		if not active then
			active = true
		else
			active = false
		end
	end
end

function smCheck()
	if PlayingGame() then
		if not showmenu then
			showmenu = true
		else
			showmenu = nil
		end
	end
end

function owCheck()
	if PlayingGame() then
		if not noorbwalkidle then
			noorbwalkidle = true
		else
			noorbwalkidle = false
		end
	end
end

function modCheck()
	if PlayingGame() then
		if not enablemodifiers then
			enablemodifiers = true
		else
			enablemodifiers = false
		end
	end
end

function ssCheck()
	if PlayingGame() then
		if not showSign then
			showSign = true
		else
			showSign = false
		end
	end
end

function bearCheck()
	if PlayingGame() then
		if not onlybearorb then
			onlybearorb = true
		else
			onlybearorb = false
		end
	end
end

function Key(msg, code)
	if msg ~= KEY_UP or client.chat or client.console then return end
	if code == menu and HUD then 
		if HUD:IsClosed() then
			HUD:Open()
			statusText.visible = false
		else
			HUD:Close()
			if showSign then
				statusText.visible = true
			end
		end
	elseif code == modifhotkey then
		modCheck()
	end
end

function Main(tick)
	if not PlayingGame() then return end
	local me = entityList:GetMyHero() if not me then return end
	local ID = me.classId if ID ~= myId then Close() end
	
	if spaceformove then
		movetomouse = 0x20
	else
		movetomouse = custommove
	end
	
	if not HUD then 
		CreateHUD()
		if not showmenu then
			HUD:Close()
		end
	elseif HUD and HUD:IsClosed() and showSign then
		statusText.visible = true
	end
	
	if string.byte("A") <= menu and menu <= string.byte("Z") then
		statusText.text = "Orb Walker: Press " .. string.char(menu) .. " to open Menu"
	else 
		statusText.text = "Orb Walker: Press " .. menu .. " to open Menu"
	end
 
	if active then
		if not myhero then	
			myhero = MyHero(me)
		else			
			myhero.attackRange = myhero:GetAttackRange()
			local bear = nil
			if me.classId == CDOTA_Unit_Hero_LoneDruid then
				bear = entityList:GetEntities({classId=CDOTA_Unit_SpiritBear,visible=true,alive=true,team=me.team})[1]
			end
			if IsKeyDown(movetomouse) and not client.chat then	
				if (not victim or GetDistance2D(me,victim) > myhero.attackRange*2 or not victim.alive) and SleepCheck("victim") then
					local creeps = entityList:GetEntities(function (v) return (v.courier or (v.creep and v.spawned) or (v.classId == CDOTA_BaseNPC_Creep_Neutral and v.spawned) or v.classId == CDOTA_BaseNPC_Tower or v.classId == CDOTA_BaseNPC_Barracks or v.classId == CDOTA_BaseNPC_Building or v.classId == CDOTA_BaseNPC_Venomancer_PlagueWard or v.classId == CDOTA_BaseNPC_Warlock_Golem or (v.classId == CDOTA_BaseNPC_Creep_Lane and v.spawned) or (v.classId == CDOTA_BaseNPC_Creep_Siege and v.spawned) or v.classId == CDOTA_Unit_VisageFamiliar or v.classId == CDOTA_Unit_Undying_Zombie or v.classId == CDOTA_Unit_SpiritBear or v.classId == CDOTA_Unit_Broodmother_Spiderling or v.classId == CDOTA_Unit_Hero_Beastmaster_Boar or v.classId == CDOTA_BaseNPC_Invoker_Forged_Spirit or v.classId == CDOTA_BaseNPC_Creep) and v.team ~= me.team and v.alive and v.health > 0 and me:GetDistance2D(v) <= myhero.attackRange*2 + 50 end)
					table.sort(creeps, function (a,b) return a.health < b.health end)
					victim = targetFind:GetClosestToMouse(me,300) or targetFind:GetLowestEHP(myhero.attackRange*2 + 50, phys) or creeps[1]
					Sleep(250,"victim")
				end
				if ((me.classId == CDOTA_Unit_Hero_LoneDruid and not onlybearorb) or me.classId ~= CDOTA_Unit_Hero_LoneDruid) then
					if not Animations.CanMove(me) and victim and GetDistance2D(me,victim) <= myhero.attackRange*2 + 50 then
						if tick > attack then
							myhero:Hit(victim)
							attack = tick + 100
						end
					elseif tick > move then
						me:Move(client.mousePosition)
						move = tick + 100
					end
				end
				if bear and bear.alive then
					if not Animations.CanMove(bear) and victim and bear:CanAttack() and GetDistance2D(bear,victim) <= bear.attackRange*2 + 50 then
						if tick > attack1 then
							bear:Attack(victim)
							attack1 = tick + 100
						end
					elseif tick > move1 then
						bear:Move(client.mousePosition)
						move1 = tick + 100
					end
				end
			else
				victim = nil
			end 
		end
	end
end

class 'MyHero'

function MyHero:__init(heroEntity)
	self.heroEntity = heroEntity
	local name = heroEntity.name
	if not heroInfo[name] then
		return nil
	end
end

function MyHero:GetAttackRange()
	local bonus = 0
	if self.heroEntity.classId == CDOTA_Unit_Hero_TemplarAssassin then	
		local psy = self.heroEntity:GetAbility(3)
		if psy and psy.level > 0 then
			bonus = psy:GetSpecialData("bonus_attack_range",psy.level)			
		end
	elseif self.heroEntity.classId == CDOTA_Unit_Hero_Sniper then	
		local aim = self.heroEntity:GetAbility(3)
		if aim and aim.level > 0 then		
			bonus = aim:GetSpecialData("bonus_attack_range",aim.level)		
		end		
	elseif self.heroEntity.classId == CDOTA_Unit_Hero_Enchantress then
		if enablemodifiers then
			local impetus = self.heroEntity:GetAbility(4)
			if impetus.level > 0 and self.heroEntity:AghanimState() then
				bonus = impetus:GetSpecialData("bonus_attack_range_scepter",impetus.level)
			end
		end
	end
	return self.heroEntity.attackRange + bonus
end

function MyHero:Hit(target)
	if target and target.team ~= self.heroEntity.team then
		if target and enablemodifiers and not target:IsMagicImmune() then
			if self.heroEntity.classId == CDOTA_Unit_Hero_Clinkz then
				local searinga = self.heroEntity:GetAbility(2)
				if searinga.level > 0 and self.heroEntity.mana > 10 then
					self.heroEntity:SafeCastAbility(searinga, target)
				else self.heroEntity:Attack(target) end
			elseif self.heroEntity.classId == CDOTA_Unit_Hero_DrowRanger then
				local frost = self.heroEntity:GetAbility(1)
				if frost.level > 0 and self.heroEntity.mana > 12 then
					self.heroEntity:SafeCastAbility(frost, target)
				else self.heroEntity:Attack(target) end
			elseif self.heroEntity.classId == CDOTA_Unit_Hero_Viper then
				local poison = self.heroEntity:GetAbility(1)
				if poison.level > 0 and self.heroEntity.mana > 21 then
					self.heroEntity:SafeCastAbility(poison, target)
				else self.heroEntity:Attack(target) end  
			elseif self.heroEntity.classId == CDOTA_Unit_Hero_Huskar then
				local burning = self.heroEntity:GetAbility(2)
				if burning.level > 0 and self.heroEntity.health > 15 then
					self.heroEntity:SafeCastAbility(burning, target)
				else self.heroEntity:Attack(target) end
			elseif self.heroEntity.classId == CDOTA_Unit_Hero_Silencer then
				local glaives = self.heroEntity:GetAbility(2)
				if glaives.level > 0 and self.heroEntity.mana > 15 then
					self.heroEntity:SafeCastAbility(glaives, target)
				else self.heroEntity:Attack(target) end
			elseif self.heroEntity.classId == CDOTA_Unit_Hero_Jakiro then
				local liquid = self.heroEntity:GetAbility(3)
				if liquid.level > 0 and liquid.state == LuaEntityAbilty.STATE_READY then
					self.heroEntity:SafeCastAbility(liquid, target)
				else self.heroEntity:Attack(target) end
			elseif self.heroEntity.classId == CDOTA_Unit_Hero_Obsidian_Destroyer then
				local arcane = self.heroEntity:GetAbility(1)
				if arcane.level > 0 and self.heroEntity.mana > 100 then
					self.heroEntity:SafeCastAbility(arcane, target)
				else self.heroEntity:Attack(target) end
			elseif self.heroEntity.classId == CDOTA_Unit_Hero_Enchantress then
				local impetus = self.heroEntity:GetAbility(4)
				local impemana = {55,60,65}
				if impetus.level > 0 and self.heroEntity.mana > impemana[impetus.level] then
					self.heroEntity:SafeCastAbility(impetus, target)
				else self.heroEntity:Attack(target) end
			else
				self.heroEntity:Attack(target)
			end
		else
			self.heroEntity:Attack(target)
		end
	end
end

function CreateHUD()
	if not HUD then
		HUD = EasyHUD.new(5*monitor,100*monitor,250*monitor,300*monitor,"Orb Walker",0x111111C0,-1,true,true)
		if spaceformove then
			if string.byte("A") <= aakey and aakey <= string.byte("Z") then
				HUD:AddText(5*monitor,10*monitor,"Usage: Hold SPACE.(For AutoAttack hold "..string.char(aakey)..")")
			else
				HUD:AddText(5*monitor,10*monitor,"Usage: Hold SPACE.(For AutoAttack hold "..aakey..")")
			end
		else
			if string.byte("A") <= movetomouse and movetomouse <= string.byte("Z") and string.byte("A") <= aakey and aakey <= string.byte("Z") then
				HUD:AddText(5*monitor,10*monitor,"Usage: Hold "..string.char(movetomouse)..".(For AutoAttack hold "..string.char(aakey)..")")
			else
				HUD:AddText(5*monitor,10*monitor,"Usage: Hold "..movetomouse..".(For AutoAttack hold "..aakey..")")
			end
		end
		HUD:AddText(5*monitor,30*monitor,"Orb Walker Settings:")
		if string.byte("A") <= menu and menu <= string.byte("Z") then
			HUD:AddText(5*monitor,220*monitor,"Press " .. string.char(menu) .. " for Open / Close Menu")
		else
			HUD:AddText(5*monitor,220*monitor,"Press " .. menu .. " for Open / Close Menu")
		end
		HUD:AddCheckbox(5*monitor,50*monitor,35*monitor,20*monitor,"ENABLE SCRIPT",activeCheck,active)
		HUD:AddText(5*monitor,75*monitor,"Script Settings:")
		HUD:AddCheckbox(5*monitor,95*monitor,35*monitor,20*monitor,"SHOW MENU ON START",smCheck,showmenu)
		HUD:AddCheckbox(5*monitor,115*monitor,35*monitor,20*monitor,"NO OrbWalk on IDLE enemy",owCheck,noorbwalkidle)
		if string.byte("A") <= modifhotkey and modifhotkey <= string.byte("Z") then
			HUD:AddCheckbox(5*monitor,135*monitor,35*monitor,20*monitor,"ATTACK MODIFIERS - ToggleKey "..string.char(modifhotkey),modCheck,enablemodifiers)
		else
			HUD:AddCheckbox(5*monitor,135*monitor,35*monitor,20*monitor,"ATTACK MODIFIERS - ToggleKey "..modifhotkey,modCheck,enablemodifiers)
		end
		HUD:AddCheckbox(5*monitor,155*monitor,35*monitor,20*monitor,"Show Sign",ssCheck,showSign)
		if entityList:GetMyHero().classId == CDOTA_Unit_Hero_LoneDruid then
			HUD:AddCheckbox(5*monitor,175*monitor,35*monitor,20*monitor,"ONLY BEAR ORBWALK",bearCheck,onlybearorb)
		end
		HUD:AddButton(5*monitor,250*monitor,110*monitor,40*monitor, 0x60615FFF,"Save Settings",SaveSettings)
	end
end

function SaveSettings()
	local file = io.open(SCRIPT_PATH.."/config/Orb_Walker.txt", "w+")
	if file then
		if string.byte("A") <= custommove and custommove <= string.byte("Z") then
			file:write("CustomMove = "..string.char(custommove).."\n")
		else
			file:write("CustomMove = "..custommove.."\n")
		end
		if spaceformove then
			file:write("Spaceformove = true \n")
		else
			file:write("Spaceformove = false \n")
		end
		if showmenu then
			file:write("ShowMenuAtStart = true \n")
		else
			file:write("ShowMenuAtStart = false \n")
		end
		if active then
			file:write("ActiveFromStart = true \n")
		else
			file:write("ActiveFromStart = false \n")
		end
		if noorbwalkidle then
			file:write("DontOrbwalkWhenIdle = true \n")
		else
			file:write("DontOrbwalkWhenIdle = false \n")
		end
		if enablemodifiers then
			file:write("EnableAttackModifiers = true \n")
		else
			file:write("EnableAttackModifiers = false \n")
		end
		if showSign then
			file:write("ShowSign = true \n")
		else
			file:write("ShowSign = false \n")
		end
		if string.byte("A") <= menu and menu <= string.byte("Z") then
			file:write("Menu = "..string.char(menu))
		else
			file:write("Menu = "..menu)
		end
		if string.byte("A") <= aakey and aakey <= string.byte("Z") then
			file:write("AutoAttackKey = "..string.char(aakey))
		else
			file:write("AutoAttackKey = "..aakey)
		end
		if string.byte("A") <= modifhotkey and modifhotkey <= string.byte("Z") then
			file:write("ModifiersTogglekey = "..string.char(modifhotkey))
		else
			file:write("ModifiersTogglekey = "..modifhotkey)
		end
        file:close()
    end
end

function Load()
	if PlayingGame() then
		local me = entityList:GetMyHero()
		if not me then 
			script:Disable()
		else
			statusText.visible = false
			myhero = nil
			HUD = nil
			reg = true
			victim = nil
			myId = me.classId
			sleep = 0 
			myAttackTickTable = {}
			myAttackTickTable.attackRateTick = 0 
			myAttackTickTable.attackPointTick = nil
			script:RegisterEvent(EVENT_FRAME, Main)
			script:RegisterEvent(EVENT_KEY, Key)
			script:UnregisterEvent(Load)
		end
	end	
end

function Close()
	statusText.visible = false
	myhero = nil
	victim = nil
	myId = nil
	
	if HUD then
		HUD:Close()	
		HUD = nil
	end
	
	if reg then
		script:UnregisterEvent(Main)
		script:UnregisterEvent(Key)
		script:RegisterEvent(EVENT_TICK, Load)	
		reg = false
	end
end

script:RegisterEvent(EVENT_CLOSE, Close)
script:RegisterEvent(EVENT_TICK, Load)
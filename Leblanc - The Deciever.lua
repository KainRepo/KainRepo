--[[
        [Script] Leblanc - The Deceiver by Skeem & Kain
        
                Features:
                        - Prodiction for VIPs, NonVIP prediction
                        - Full Combo:
                                - Dynamic combo depending o enemy health/distance
                                - Gap closers for enemies that are too far away and can die
                                - Mana checks for all combos
                                - Orbwalking Toggle in combo menu
                        - Harass Settings:
                                - 2 Modes of Harass
                                1 - Will use W as a gapcloser and hit enemy with Q
                                2 - Will use Q to damage enemy then hit enemy with W (RECOMENDED)
                                - Option to return back with W
                        - Farming Settings:
                                - Toggle to farm with Q in menu
                                - Minimum mana to farm can be set in menu (50% default)
                        - Jungle Clear Settings:
                                - Toggle to use Q to clear jungle
                                - Toggle to use W to clear jungle (Off by default)
                                - Toggle to use E to clear jungle
                                - Toggle to orbwalk the jungle minions
                        - KillSteal Settings:
                                - Smart KillSteal with Overkill Checks
                                - Toggle for Auto Ignite
                        - Drawing Settings:
                                - Toggle to draw if enemy is killable
                                - Toggle to draw Q Range if available
                                - Toggle to draw W Range if available (Off by default)
                                - Toggle to draw E Range if available (Off by default)
                        - Misc Settings:
                                - Toggle for auto zhonyas/wooglets (needs more logic)
                                - Toggle for Auto Mana / Health Pots
                
                Credits & Mentions
                        - Kain because I've used some of his code and learned a lot from his scripts
                        - Bothappy, Entryway & Nalle for being my personal lovers
                        - Everyone at the KKK crew who tested this script and gave awesome suggestions!
                        
                Changelog:
                        1.0   - First Release!
                        
                TODO: W Smart Evade (Almost Done)
                      Clone usages (Almost Done)
                      More dynammic combos !
]]--
        

if myHero.charName ~= "Leblanc" then return end

if VIP_USER then
	require "Prodiction"
	require "Collision"
end 

LoadProtectedScript('
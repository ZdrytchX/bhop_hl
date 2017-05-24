Print("Bunny Hop Physics Enabled - Half Life Air Physics edition")
--core mixins
ModLoader.SetupFileHook( "lua/Mixins/GroundMoveMixin.lua", "lua/bhophl/core/GroundMoveMixin.lua", "post" )

--bhophl Speed Modifications
ModLoader.SetupFileHook( "lua/Gorge.lua", "lua/bhophl/Gorge.lua", "post" )
ModLoader.SetupFileHook( "lua/Onos.lua", "lua/bhophl/Onos.lua", "post" )
ModLoader.SetupFileHook( "lua/Skulk.lua", "lua/bhophl/Skulk.lua", "post" )
ModLoader.SetupFileHook( "lua/Fade.lua", "lua/bhophl/Fade.lua", "post" )
ModLoader.SetupFileHook( "lua/Marine.lua", "lua/bhophl/Marine.lua", "post" )
ModLoader.SetupFileHook( "lua/Player.lua", "lua/bhophl/Player.lua", "post" )
ModLoader.SetupFileHook( "lua/Exo.lua", "lua/bhophl/Exo.lua", "post" )
ModLoader.SetupFileHook( "lua/BalanceMisc.lua", "lua/bhophl/BalanceMisc.lua", "post" )

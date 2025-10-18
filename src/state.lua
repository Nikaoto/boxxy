function make_state_from_dir(dir)
   return {
      {
         id = 1,
         file = "main.lua",
         text_string =
            "function love.update(dt)\n" ..
            "   print(\"Hello!\")\n" ..
            "   timers.update(dt)\n" ..
            "   controls.update()\n" ..
            "end\n",

         --text_table = {...},
         line_count = 5,
         connections = {
            {line=3, char=20, fn_id=2},
            {line=4, char=20, fn_id=3},
         },
      },
      
      -- timers.update()
      {
         id = 2,
         file = "timers.lua",
         text_string =
            "function timers.update(dt)\n" ..
            "   global_timer = global_timer + dt\n"..
            "end\n",
         line_count = 3,
         connections = {},
      },
      
      -- controls.update()
      {
         id = 3,
         file = "controls.lua",
         text_string =
            "function controls.update()\n" ..
            "   whatever.dothing()\n" ..
            "end\n",
         line_count = 3,
         connections = {},
      }
   }
end

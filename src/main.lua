inspect = require("lib/inspect")
require("state")



function love.load()
   local state = make_state_from_dir(dir)
   print(inspect(state))
end

function love.update(dt)
end

function love.draw()
end

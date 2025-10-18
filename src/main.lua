require("lib/string")
require("lib/table")
require("lib/math")

inspect = require("lib/inspect")
require("state")


function love.load()
   local state = make_state_from_dir(dir)
end

function love.update(dt)
end

function love.draw()
end

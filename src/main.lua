Class = require("lib/Class")
require("lib/string")
require("lib/table")
require("lib/math")

inspect = require("lib/inspect")
require("state")

lg = love.graphics
font = lg.newFont('fixedsys.ttf', 24)

Box = require("Box")

boxes = {}

local world

function love.load()
   world = love.physics.newWorld(0, 0, true)

   local state = make_state_from_dir(dir)

   for i, box in ipairs(state) do
      local b = Box:new({
         x = (i - 1) * 100 + 50,
         y = i *100 + 50,
         phy_world = world,

         fn_id = box.id,
         file = box.file,
         connections = box.connections,
         text_string = box.text_string,
         line_count = box.line_count,
      })
      table.insert(boxes, b)
   end
   print(inspect(state))
end

function love.update(dt)
   world:update(dt)

   for _, box in ipairs(boxes) do
      -- box:update(dt)
   end
end

function love.draw()

   for _, box in ipairs(boxes) do
      box:draw()
   end
end


debugger = require("lib/debugger")
require("lib/print")

CHAR_W = 1.5
CHAR_H = 1.5
RENDER_WIDTH = 1920
RENDER_HEIGHT = 1080
MOUSE_MOVE_MARGIN = 100

OBJ_TYPES = {
   DEFAULT = 1,
   CURSOR = 2,
}

love.graphics.setDefaultFilter("nearest", "nearest")
inspect = require("lib/inspect")
colorlib = require("lib/colorlib")
physics = require("lib/physics")
require("lib/rand")
require("lib/string")
require("lib/table")
require("lib/math")

Class = require("lib/Class")
Vector = require("lib/Vector")
Camera = require("lib/Camera")
Colorhex = require("lib/colorhex")

require("state")

local colors_alpha = 0.7
colors = {
   background = Colorhex("#272822"),
   comments   = Colorhex("#75715E"),
   white      = Colorhex("#F8F8F2"),
   yellow     = Colorhex("#E6DB74"),
   green      = Colorhex("#A6E22E"),
   orange     = Colorhex("#FD971F"),
   purple     = Colorhex("#AE81FF"),
   pink       = Colorhex("#F92672"),
   blue       = Colorhex("#66D9EF"),

   a_yellow     = Colorhex("#E6DB74", colors_alpha),
   a_green      = Colorhex("#A6E22E", colors_alpha),
   a_orange     = Colorhex("#FD971F", colors_alpha),
   a_purple     = Colorhex("#AE81FF", colors_alpha),
   a_pink       = Colorhex("#F92672", colors_alpha),
   a_blue       = Colorhex("#66D9EF", colors_alpha),
}

colors.darkgreen = colorlib.mix({}, colors.background, colors.green, 0.5)

lg = love.graphics
lk = love.keyboard
lm = love.mouse
font = lg.newFont('fixedsys.ttf', 24)
tfont = lg.newFont('fixedsys.ttf', 128)

Box = require("Box")
Text = require("Text")
Connection = require("Connection")

cam = Camera:new({
   w = RENDER_WIDTH,
   h = RENDER_HEIGHT,
   move_speed = 15,
   dir = Vector:new(0,0),
   zoom = 0.2,
   zoom_speed = 0.01,
})

mouse_x, mouse_y = 0, 0
mouse_dy = 0

canvas = lg.newCanvas(400, 300)

cursor = require("cursor")
idle_cursor = lm.newCursor("img/hand_free.png", 64*0.33, 64*0.08)
point_cursor = lm.newCursor("img/hand_point.png", 64*0.33, 64*0.08)
click_cursor = lm.newCursor("img/hand_click.png", 64*0.33, 64*0.08)
grab_cursor = lm.newCursor("img/hand_grab.png", 64*0.33, 64*0.08)

objects = {}
conns_map = {}
boxes_by_id = {}

collision_manager = require("collision_manager")

function love.load()
   world = love.physics.newWorld(0, 0, true)
   world:setCallbacks(
      collision_manager.begin_contact,
      collision_manager.end_contact
   )
   lm.setCursor(idle_cursor)
   cursor:init(world)

   local state = make_state_from_dir(dir)

   -- Spawn all boxes
   for i, box in ipairs(state) do
      local b = Box:new({
         x = 0 + rand.int(-500, 500),
         y = 0 + rand.int(-5, 5),
         phy_world = world,

         fn_id = box.id,
         file = box.file,
         connections = box.connections,
         text_string = box.text_string,
         line_count = box.line_count,
      })
      table.insert(objects, b)
      boxes_by_id[box.id] = b
   end

   -- Make connections map
   for i, fun in ipairs(state) do
      for j, conn in ipairs(fun.connections) do
         if not conns_map[fun.id] then
            conns_map[fun.id] = {}
         end
         table.insert(conns_map[fun.id], conn.fn_id)
      end
   end

   -- Spawn connections
   for parent_id, child_ids in pairs(conns_map) do
      local parent = boxes_by_id[parent_id]
      local px, py = parent.body:getPosition()
      for i, child_id in ipairs(child_ids) do
         local child = boxes_by_id[child_id]
         local cx, cy = child.body:getPosition()
         local k = table.ifind_fn(parent.connections, function(v)
            return v.fn_id == child.fn_id
         end)
         if not k then break end
         local c = Connection:new({
            parent_obj = parent,
            child_obj = child,
            conn_data = parent.connections[k],
         })
         table.insert(objects, c)
      end
   end

   love.window.setMode(1920, 1080)
end

function love.wheelmoved(x, y)
   if y > 0 then
      mouse_dy = 1
   elseif y < 0 then
      mouse_dy = -1
   end
end

function love.keypressed(key)
   if key == "t" then
       local mx, my = cam:to_world(mouse_x, mouse_y)
       table.insert(objects, Text:new({
           spawn_x = mx,
           spawn_y = my,
           text = rand.choice({
               "Sample Text", "Renderer", "Ligma", "TransactionBuilderFactory"}),
       }))
   end

    if key == "0" then
        cam.zoom = 0.3
        cam.x = 0
        cam.y = 0
    end
end

function love.mousereleased(x, y, button, istouch, presses)
   cursor:mousereleased(x, y, button, istouch, presses)
end

function love.mousepressed(x, y, button, istouch, presses)
   cursor:mousepressed(x, y, button, istouch, presses)
end

function love.update(dt)
   lm.setCursor(idle_cursor)
   world:update(dt)
   cursor:update(dt)

   mouse_x, mouse_y = lm:getPosition()

   if lk.isDown("q") or lk.isDown("escape") then
      love.event.quit()
      return
   end

   if mouse_dy ~= 0 then
      cam:do_zoom(mouse_dy)
   end

   -- Camera movement
   cam.dir:set(0,0)
   if lk.isDown("right") or mouse_x > RENDER_WIDTH-MOUSE_MOVE_MARGIN then
      cam.dir.x = cam.dir.x + 1
   elseif lk.isDown("left") or mouse_x < MOUSE_MOVE_MARGIN then
      cam.dir.x = cam.dir.x - 1
   end
   if lk.isDown("up") or mouse_y < MOUSE_MOVE_MARGIN then
      cam.dir.y = cam.dir.y - 1
   elseif lk.isDown("down") or mouse_y > RENDER_HEIGHT-MOUSE_MOVE_MARGIN then
      cam.dir.y = cam.dir.y + 1
   end
   cam.dir:normalize()
   if not cam.dir:is_zero() then
      cam:do_move(cam.dir.x, cam.dir.y)
   end

   -- Camera zooming
   if lk.isDown("-") then
      cam:do_zoom(-2)
   elseif lk.isDown("=") then
      cam:do_zoom(2)
   end

   for _, obj in ipairs(objects) do
      obj:update(dt)
   end

   mouse_dy = 0
end

function drawGrid(cameraX, cameraY, zoom)
   local gridSize = 50  -- size of each grid cell
   local width, height = love.graphics.getDimensions()

   -- use zoom for consistent spacing
   local scaledGrid = gridSize * zoom

   -- offset so grid moves with camera
   local offsetX = (cameraX * zoom) % scaledGrid
   local offsetY = (cameraY * zoom) % scaledGrid

   love.graphics.setColor(0.2, 0.2, 0.2) -- grid color
   love.graphics.setLineWidth(1)

   -- vertical lines
   for x = -offsetX, width, scaledGrid do
      love.graphics.line(x, 0, x, height)
   end

   -- horizontal lines
   for y = -offsetY, height, scaledGrid do
      love.graphics.line(0, y, width, y)
   end
end

function love.draw()
   lg.setColor(colors.background)
   lg.clear()
   table.stable_sort(objects, function(a,b)
      return (a.z or 0) < (b.z or 0)
   end)

   --lg.setCanvas(canvas)
   lg.clear(0,0,0,0)
   local cw, ch = canvas:getDimensions()
   
   drawGrid(cam.x, cam.y, cam.zoom)

   cam:apply()
   lg.setColor(1,1,1,1)
   for _, box in ipairs(objects) do
      box:draw()
   end
   
   -- Center
   -- lg.setColor(1, 0, 0, 1)
   -- lg.circle("fill", 0, 0, 10)

   -- Mouse
   -- mouse_x, mouse_y = lm:getPosition()
   -- lg.setColor(0, 1, 0, 1)
   -- local mx, my = cam:to_world(mouse_x, mouse_y)
   -- lg.circle("fill", mx, my, 10)

   lg.setColor(1,1,1,1)
   lg.print(world:getJointCount())

   cam:revert()
   --lg.setCanvas()

   --lg.setColor(1,1,1,1)
   --local ww, wh = love.window.getDesktopDimensions()
   --lg.draw(canvas, ww/2, wh/2, 0, ww/cw, wh/ch, cw/2, ch/2)
end

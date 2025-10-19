local cursor = {
   obj_name = "cursor",
   spawn_x = 0,
   spawn_y = 0,
   obj_type = 2,
   collider_r = 10,
   collider_mass = 1000,
   collider_sensor = true,
   collider_gravity_scale = 0,

   -- Objects currently being manipulated by the cursor
   drag_objects = {},
   drag_count = 0,

   schedule = {}
}

local lp = love.physics

function cursor:init(world)
   physics.add_physics(self, world)
   self.body:setActive(false)
end

function cursor:start_dragging(obj)
   if not self.drag_objects[obj] then
      table.insert(self.schedule, function()
         local x, y = self.body:getPosition()
         local joint = lp.newDistanceJoint(
            self.body,
            obj.body,
            x, y,
            x, y,
            false
         )
         joint:setFrequency(80)
         joint:setDampingRatio(1)
         self.drag_objects[obj] = {
            inital_x = x,
            inital_y = y,
            joint = joint,
            obj = obj,
         }
         self.drag_count = self.drag_count + 1
      end)
   end
end

function cursor:stop_dragging(obj)
   if not self.drag_objects[obj] then
      return
   end

   table.insert(self.schedule, function()
      self.drag_objects[obj].joint:destroy()
      self.drag_objects[obj] = nil
      self.drag_count = self.drag_count - 1
   end)
end

function cursor:update(dt)
   if #self.schedule > 0 then
      for _, fn in pairs(self.schedule) do
         fn()
      end
      self.schedule = {}
   end

   local wx, wy = cam:to_world(lm.getPosition())

   if lm.isDown(1) then
      self.body:setPosition(wx, wy)
   end
end

function cursor:mousepressed(x, y, button, istouch, presses)
   if button == 1 then
      self.body:setActive(true)
      local wx, wy = cam:to_world(lm.getPosition())
      self.body:setPosition(wx, wy)
   end
end

function cursor:mousereleased(x, y, button, istouch, presses)
   if button == 1 then
      local keys = table.keys(self.drag_objects)
      for _, key_obj in pairs(keys) do
         self:stop_dragging(key_obj)
      end
      self.body:setActive(false)
   end
end

function cursor:draw()
end

return cursor

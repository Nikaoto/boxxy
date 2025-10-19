local Text = Class:new({
    obj_name = "text",
    obj_type = OBJ_TYPES.DEFAULT,
    spawn_x = 0,
    spawn_y = 0,
    collider_mass = 1,
    font = tfont,
})

function Text:init()
    self.color = rand.choice({
        colors.white,
        colors.yellow,
        colors.green,
        colors.orange,
        colors.purple,
        colors.blue,
    })

    self.tobj = lg.newText(self.font, self.text)
    self.collider_w = self.tobj:getWidth() + 2
    self.collider_h = self.tobj:getHeight() + 2
    physics.add_physics(self, world)
end

function Text:isMouseOver()
   local mx, my = love.mouse.getPosition()
   mx, my = cam:to_world(mx, my)

   local x, y = self.body:getPosition()

   local left   = x - self.collider_w / 2
   local right  = x + self.collider_w / 2
   local top    = y - self.collider_h / 2
   local bottom = y + self.collider_h / 2

   return mx >= left and mx <= right and my >= top and my <= bottom
end

function Text:update(dt)
   if self:isMouseOver() then
      if lm.getCursor() == idle_cursor then
         lm.setCursor(point_cursor)
      end

      if lm.isDown(1) then
         lm.setCursor(grab_cursor)
      end
   end
end

function Text:draw()
    lg.setColor(self.color)
    local x, y = self.body:getPosition()
    lg.draw(self.tobj, x, y, 0, 1, 1, self.collider_w/2, self.collider_h/2)
end

return Text

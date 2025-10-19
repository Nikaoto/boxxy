local Box = Class:extend({
   x = 0,
   y = 0,
   w = 100,
   h = 100,
   phy_world = nil,

   fn_id = 0,
   file = '',
   connections = {},
   text_string = '',
   line_count = 0,

   padding = 16,
   title_padding = 8,

   outline = 10,
})

function Box:init()
   self.body = love.physics.newBody(self.phy_world, self.x, self.y, "dynamic")
   self.shape = love.physics.newRectangleShape(self.w, self.h)
   self.fixture = love.physics.newFixture(self.body, self.shape, 1)

   self.text_obj = love.graphics.newText(font, self.text_string)
   self.title_obj = love.graphics.newText(font, self.file)
   
   self:resizeToText()
end

function Box:update(dt)

end

function Box:resizeToText()
   local tw, th = self.text_obj:getDimensions()
   local ttw, tth = self.title_obj:getDimensions()

   self.w = math.max(tw, ttw) + self.padding * 2
   self.h = th + self.padding * 2 + tth + self.padding

   self.shape:release()
   self.shape = love.physics.newRectangleShape(self.w, self.h)
   self.fixture:destroy()
   self.fixture = love.physics.newFixture(self.body, self.shape, 1)
end

function Box:draw_connection_points()

end

function Box:isMouseOver()
   local mx, my = love.mouse.getPosition()
   local x, y = self.body:getPosition()

   local left   = x - self.w / 2
   local right  = x + self.w / 2
   local top    = y - self.h / 2
   local bottom = y + self.h / 2

   return mx >= left and mx <= right and my >= top and my <= bottom
end

function Box:draw()
   
   if self:isMouseOver() then
      lg.setColor(1, 1, 1)
      lg.rectangle("fill", self.x - (self.w + self.outline) / 2, 
                  self.y - (self.h + self.outline) / 2, 
                  self.w + self.outline, self.h + self.outline)
   end

   local x, y = self.body:getPosition()

   -- draw box
   lg.setColor(0.2, 0.4, 0.8)
   lg.rectangle("fill", x - self.w / 2, y - self.h / 2, self.w, self.h)

   -- draw title
   lg.setColor(1, 1, 0.8)
   local title_x = x - self.w / 2 + self.title_padding
   local title_y = y - self.h / 2 + self.title_padding
   lg.draw(self.title_obj, math.floor(title_x, 0.5), math.floor(title_y, 0.5))

   -- draw line under title
   lg.setColor(1, 1, 1)
   local line_y = title_y + self.title_obj:getHeight() + self.title_padding / 2
   lg.setColor(0.9, 0.9, 0.9)
   lg.setLineWidth(2)
   lg.line(x - self.w / 2 + self.title_padding, line_y, x + self.w / 2 - self.title_padding, line_y)

   -- draw code 
   lg.setColor(1, 1, 1)
   local text_x = x - self.w / 2 + self.padding
   local text_y = y - self.h / 2 + self.padding + self.title_obj:getHeight() + self.padding
   lg.draw(self.text_obj, math.floor(text_x, 0.5), math.floor(text_y, 0.5))

end

return Box

local Connection = Class:extend({
   startpoint = Vector:new(0,0),
   endpoint = Vector:new(0,0),
   z = 2,
})

function Connection:init()
end

function Connection:update()
end

function Connection:draw()
   lg.setColor(1, 0, 0, 1)
   lg.setLineWidth(3)
   lg.line(
      self.startpoint.x, self.startpoint.y,
      self.endpoint.x,   self.endpoint.y
   )

   lg.setLineWidth(5)
   lg.circle("line", self.startpoint.x, self.startpoint.y, 4)
end

return Connection

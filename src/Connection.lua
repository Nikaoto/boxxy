local Connection = Class:extend({
   startpoint = Vector:new(0,0),
   endpoint = Vector:new(0,0),
   z = 2,
   parent_obj = nil,
   child_obj = nil,
   conn_data = nil,
})

function Connection:init()
end

function Connection:update()
end

function Connection:draw()
   lg.setColor(1, 0, 0, 1)
   lg.setLineWidth(10)

   local px, py = self.parent_obj.body:getPosition()
   local cx, cy = self.child_obj.body:getPosition()

   local sx = px + self.conn_data.char * CHAR_W - self.parent_obj.w/2
   local sy = 56 + 5 + py + self.conn_data.line * CHAR_H - self.parent_obj.h/2 -- 56 for box text paddings
   local ex = cx - self.child_obj.w/2
   local ey = cy - self.child_obj.h/2

   lg.line(sx, sy, ex, ey)

   lg.setLineWidth(4)
   lg.circle("line", sx, sy, 20)
end

return Connection

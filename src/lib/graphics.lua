-- Extra functions for 'love.graphics'

function love.graphics.mix_alpha(ma)
   local r, g, b, a = love.graphics.getColor()
   love.graphics.setColor(r, g, b, a*ma)
end

function love.graphics.mix_color(mr,mg,mb,ma,amount)
   if type(mr) == "table" then
      amount = mg or 0.5
      ma = mr[4]
      mb = mr[3]
      mg = mr[2]
      mr = mr[1]
   end

   local r, g, b, a = love.graphics.getColor()
   love.graphics.setColor(
      math.lerp(r, mr, amount),
      math.lerp(g, mg, amount),
      math.lerp(b, mb, amount),
      math.lerp(a, ma, amount)
   )
end

function love.graphics.dotted_circle(x, y, r)
   local pc = math.round(r + 5)
   for i=0, pc, 1 do
      local rot = i * (math.pi * 2 / pc)
      love.graphics.points(
         x + math.cos(rot) * r,
         y + math.sin(rot) * r
      )
   end
end

-- Includes line_height arg
function love.graphics.make_font(src, size, line_height)
   local font = love.graphics.newFont(src, size)
   font:setLineHeight(line_height or 1)
   return font
end

-- The border is on the inside. Like doing 'box-sizing: border-box' in css
function love.graphics.bordered_rectangle(x, y, w, h,
                                          thickness, color, border_color,
                                          border_radius)
   local t = thickness
   local r = border_radius
   -- Draw the border
   love.graphics.setLineWidth(1)
   love.graphics.setColor(border_color)
   for i=0, thickness, 1 do
      love.graphics.rectangle("line", x+i, y+i, w-i*2, h-i*2, r, r)
   end

   -- Draw the inside rectangle
   local t2 = t * 2
   love.graphics.setColor(color)
   love.graphics.rectangle(
      "fill",
      x + t,  y + t,
      w - t2, h - t2,
      r,      r
   )
end

-- The same as bordered_rectangle, but uses love's line width
function love.graphics.rectangle_ring(x, y, w, h,
                                      thickness, inside_color, border_color,
                                      border_radius)
   local r = border_radius

   -- Draw the inside rectangle
   love.graphics.setColor(inside_color)
   love.graphics.rectangle(
      "fill",
      x, y,
      w, h,
      r, r
   )

   -- Draw the border
   love.graphics.setColor(border_color)
   love.graphics.setLineWidth(thickness)
   love.graphics.rectangle("line", x, y, w, h, r, r)
end

function love.graphics.ring(x, y, r, border_th, inside_th, border_col, inside_col)
   -- Draw the inside of the ring
   love.graphics.setLineWidth(inside_th)
   love.graphics.setColor(inside_col)
   love.graphics.circle("line", x, y, r)

   -- Draw the borders of the ring
   love.graphics.setLineWidth(border_th)
   love.graphics.setColor(border_col)
   --- inner
   love.graphics.circle("line", x, y, r-inside_th)
   --- outer
   love.graphics.circle("line", x, y, r+inside_th)

   love.graphics.setLineWidth(1)
end

function love.graphics.progress_bar(
   x, y, w, h,
   fill_amount,
   bar_color,
   background_color,
   border_color,
   bar_radius,
   border_radius,
   border_thickness
)
   local t = border_thickness
   local t2 = border_thickness * 2
   local r = border_radius

   -- Draw the border
   love.graphics.setColor(border_color)
   for i=0, border_thickness, 1 do
      love.graphics.rectangle("line", x+i, y+i, w-i*2, h-i*2, r, r)
   end

   -- Draw the background
   love.graphics.setColor(background_color)
   love.graphics.rectangle(
      "fill",
      x + t,  y + t,
      w - t2, h - t2,
      r,      r
   )

   -- Draw the bar
   local a = clamp(fill_amount, 0, 1)
   if a == 0 then return end
   r = bar_radius
   love.graphics.setColor(bar_color)
   love.graphics.rectangle("fill",
      x + t,        y + t,
      (w - t2) * a, h - t2,
      r,            r
   )
end

function love.graphics.draw_body_no_color(body, fill_type)
   if not body then return end

   for _, f in pairs(body:getFixtures()) do
      local shape = f:getShape()
      if shape:getType() == "edge" then
         love.graphics.line(shape:getPoints())
      elseif shape:getType() == "circle" then
         love.graphics.circle(
            fill_type or (f:isSensor() and "line" or "fill"),
            body:getX(),
            body:getY(),
            shape:getRadius()
         )
      else
         love.graphics.polygon(
            fill_type or "fill",
            body:getWorldPoints(shape:getPoints())
         )
      end
   end
end

function love.graphics.draw_joint(joint, r, color1, color2)
   if not joint then return end

   local x1, y1, x2, y2 = joint:getAnchors()

   if color1 then love.graphics.setColor(color1) end
   love.graphics.circle( "fill", x1, y1, r )

   if color2 then love.graphics.setColor(color2) end
   love.graphics.circle( "fill", x2, y2, r )
end

local debug_colors = {
   ["active"] = {
      border = { 80/255, 110/255, 1, 0.8 },
      inside = { 80/255, 110/255, 1, 0.7 },
   },
   ["inactive"] = {
      border = { 0, 180/255, 0.5, 1 },
      inside = { 0, 180/255, 0.5, 0.7 },
   },
}
function love.graphics.draw_body(body, fill_type)
   if not body then return end

   local colors = debug_colors[body:isActive() and "active" or "inactive"]
   love.graphics.setColor(colors.inside)
   for _, f in pairs(body:getFixtures()) do
      local shape = f:getShape()
      if shape:getType() == "edge" then
         love.graphics.line(shape:getPoints())
      elseif shape:getType() == "circle" then
         love.graphics.circle(
            fill_type or (f:isSensor() and "line" or "fill"),
            body:getX(),
            body:getY(),
            shape:getRadius()
         )
      else
         love.graphics.polygon(
            fill_type or "fill",
            body:getWorldPoints(shape:getPoints())
         )
      end
   end
end

-- Ori - triangle orientation (pointing "up" or "down")
function love.graphics.tooltip_triangle(tip_x, tip_y, w, h, ori, bg_color, border_color, border_thickness)
   -- Draw triangle
   if ori == "up" then
      lg.setColor(bg_color)
      lg.polygon(
         "fill",
         tip_x - w/2, tip_y + border_thickness/2,
         tip_x,       tip_y + border_thickness/2 - h,
         tip_x + w/2, tip_y + border_thickness/2
      )
      lg.setLineWidth(border_thickness)
      lg.setColor(border_color)
      lg.line(
         tip_x - w/2, tip_y + border_thickness/2,
         tip_x,       tip_y + border_thickness/2 - h,
         tip_x + w/2, tip_y + border_thickness/2
      )
   else
      lg.setColor(bg_color)
      lg.polygon(
         "fill",
         tip_x - w/2, tip_y - border_thickness/2 - h,
         tip_x,       tip_y - border_thickness/2,
         tip_x + w/2, tip_y - border_thickness/2 - h
      )
      lg.setLineWidth(border_thickness)
      lg.setColor(border_color)
      lg.line(
         tip_x - w/2, tip_y - border_thickness/2 - h,
         tip_x,       tip_y - border_thickness/2,
         tip_x + w/2, tip_y - border_thickness/2 - h
      )      
   end
end

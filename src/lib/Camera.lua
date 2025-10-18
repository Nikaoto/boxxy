local Camera = Class:extend({
   x = 0, y = 0,
   w = 0, h = 0,
   zoom = 1,

   lerp_amount = 0.02 * 60,
   zoom_speed = 0.01,
   rel_zoom_move_mod = 0.05,
   min_zoom = 0.1,
   max_zoom = 2.5,
   move_speed = 1,
})

local function clamp(x, min, max)
   if x < min then return min end
   if x > max then return max end
   return x
end

local function lerp(from, to, amount)
   return from + (to - from) * amount
end

Camera.interp_fn = lerp

function Camera:init()
   self.shakes = {}
end

function Camera:shake(...)
   table.insert(self.shakes, Camera_Shake:new(...))
end

function Camera:clear_shakes()
   self.shakes = {}
end

function Camera:clamp_to(x1, y1, x2, y2)
   local cw, ch = self.w/self.zoom, self.h/self.zoom

   local min_x = x1 + cw/2
   local max_x = x2 - cw/2
   local min_y = y1 + ch/2
   local max_y = y2 - ch/2

   if min_x > max_x then
      self.x = (min_x+max_x)/2
   else
      self.x = math.clamp(self.x, min_x, max_x)
   end

   if min_y > max_y then
      self.y = (min_y+max_y)/2
   else
      self.y = math.clamp(self.y, min_y, max_y)
   end
end

function Camera:update(dt, target_x, target_y, clamp)
   if target_x then
      self.x = self.interp_fn(self.x, target_x, self.lerp_amount * dt)
   end

   if target_y then
      self.y = self.interp_fn(self.y, target_y, self.lerp_amount * dt)
   end

   -- Clamp to bounds
   if clamp then
      self:clamp_to(clamp.x1, clamp.y1, clamp.x2, clamp.y2)
   end

   -- Apply shakes (if any)
   for i=#self.shakes, 1, -1 do
      self.shakes[i]:update(dt)

      self.x = self.x + self.shakes[i].dx
      self.y = self.y + self.shakes[i].dy

      if self.shakes[i].timer.done then
         table.remove(self.shakes, i)
      end
   end
end

function Camera:do_move(dx, dy)
   self.x = self.x + dx * self.move_speed * 1/self.zoom
   self.y = self.y + dy * self.move_speed * 1/self.zoom
end

function Camera:do_zoom(val)
   self.zoom = clamp(
      self.zoom + val * self.zoom_speed,
      self.min_zoom,
      self.max_zoom
   )
end

-- Zoom out from or zoom into the given coordinates
function Camera:do_rel_zoom(val, x, y)
   local prev_zoom = self.zoom
   self:do_zoom(val * prev_zoom)

   -- Don't move if we didn't zoom
   if prev_zoom == self.zoom then return end

   -- Move the camera relative to the coordinates
   local sign = val < 0 and -1 or 1
   self:do_move(
      sign * (x - self.w/2) * self.rel_zoom_move_mod,
      sign * (y - self.h/2) * self.rel_zoom_move_mod
   )
end

function Camera:do_world_zoom(val, mx, my)
   local prev_zoom = self.zoom
   local wx = (mx - self.x ) / prev_zoom
   local wy = (my - self.y ) / prev_zoom
   self:do_zoom(val * prev_zoom)

   -- Don't move if we didn't zoom
   if prev_zoom == self.zoom then return end

   -- Move the camera relative to the coordinates
   self.x = mx - wx * self.zoom
   self.y = my - wy * self.zoom
end

function Camera:apply()
   lg.translate(
      -self.x * self.zoom + self.w/2,
      -self.y * self.zoom + self.h/2
   )
   lg.scale(self.zoom)
end

function Camera:revert()
   lg.scale(1/self.zoom)
   lg.translate(
      (-self.x * self.zoom + self.w/2) * -1,
      (-self.y * self.zoom + self.h/2) * -1
   )
end

function Camera:to_world(x, y)
   return self.x + (x - self.w / 2) / self.zoom,
          self.y + (y - self.h / 2) / self.zoom
end

function Camera:to_screen(x, y)
   return (x - self.x) * self.zoom + self.w/2,
          (y - self.y) * self.zoom + self.h/2
end

function Camera:get_rect()
   return self:get_rect_z(1/self.zoom)
end

-- Uses z (zoom) to scale returned rect size
function Camera:get_rect_z(z)
   return self.x - z * self.w/2, self.y - z * self.h/2,
          self.w * z,            self.h * z
end

function Camera:in_view(x, y, w, h)
   return self:in_view_mz(0, 1/self.zoom, x, y, w, h)
end

-- Uses margin
function Camera:in_view_m(margin, x, y, w, h, px, py)
   return self:in_view_mz(margin, 1/self.zoom, x, y, w, h, px, py)
end

-- Uses margin and zoom coefficient.
-- px and py are parallax x and y amounts.
function Camera:in_view_mz(m, z, x, y, w, h, px, py)
   z = z or 1/self.zoom
   m = m or 0
   px = px or 1
   py = py or px or 1

   if w < 0 then
      x, w = x + w, -w
   end
   if h < 0 then
      y, h = y + h, -h
   end

   if x + w < self.x * px - z * self.w/2 - m*z then
      return false
   end

   if self.x * px + z * self.w/2 + m*z < x then
      return false
   end

   if y + h < self.y * py - z * self.h/2 - m*z then
      return false
   end

   if self.y * py + z * self.h/2 + m*z < y then
      return false
   end

   return true
end

return Camera

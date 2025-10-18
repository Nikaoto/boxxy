local Spring = Class:extend({
   value = 0,
   target_value = 1,
   damping = 0.2,
   restitution = 0.2,
   deadzone = 0.0001,
   speed = 0,
})

function Spring:init()
   self.target_value = self.value
end

-- NOTE: This is framerate dependent! Only use with fixed timestep update.
function Spring:update()
   local diff = self.target_value - self.value
   if math.abs(diff) <= self.deadzone then
      self:finish()
      return
   end

   self.speed = self.speed * (1 - self.damping)
   self.speed = self.speed + diff * self.restitution
   self.value = self.value + self.speed
end

-- The version of :update() that works reasonably well with a variable timestep
function Spring:update_variable_timestep(delta_time)
   local diff = self.target_value - self.value
   if math.abs(diff) <= self.deadzone then
      self:finish()
      return
   end

   -- Adjust delta time so this update roughly matches the fixed update version
   -- when the latter is running at 60fps
   local dt = delta_time * 60

   self.speed = self.speed * (1 - math.pow(self.damping, dt))
   self.speed = self.speed + diff * self.restitution * dt
   self.value = self.value + self.speed * dt
end

function Spring:pull(new_value, new_restitution, new_damping)
   self.value = new_value
   self.restitution = new_restitution or self.restitution
   self.damping = new_damping or self.damping
end

function Spring:mold(new_target_value, rest, damp, dz)
   self.target_value = new_target_value
   self.restitution = rest or self.restitution
   self.damping = damp or self.damping
   self.deadzone = dz or self.deadzone

   return self
end

function Spring:set(new_target_value, rest, damp, dz)
   self.target_value = new_target_value
   self.restitution = rest or self.restitution
   self.damping = damp or self.damping
   self.deadzone = dz or self.deadzone

   -- Main difference between :mold() and :set()
   self.value = self.target_value

   return self
end

function Spring:tmp_set(field, value)
   if self[field] then
      if not self.tmp_saves then self.tmp_saves = {} end
      self.tmp_saves[field] = self[field]
      self[field] = value
   end

   return self
end

function Spring:finish()
   self.value = self.target_value
   self.speed = 0

   if self.on_stabilize_data then
      if self.on_stabilize_data.cb then
         self.on_stabilize_data.cb(self)
      end

      if self.on_stabilize_data.opts and self.on_stabilize_data.opts.oneshot then
         self.on_stabilize_data = nil
      end
   end

   -- Restore saved fields from most recent pull/mold
   if self.tmp_saves then
      for k, v in pairs(self.tmp_saves) do
         self[k] = v
      end
      self.tmp_saves = nil
   end

   return self
end

function Spring:is_stable(deadzone)
   deadzone = deadzone or 0
   return math.abs(self.value - self.target_value) <= deadzone
end

function Spring:on_stabilize(cb, opts)
   self.on_stabilize_data = {cb = cb, opts = opts}
end

function Spring.all_stable(obj)
   if not obj or not obj.springs then return true end

   for _, spr in pairs(obj.springs) do
      if not spr:is_stable() then return false end
   end
   return true
end

return Spring

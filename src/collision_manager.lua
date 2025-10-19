local collision_enter_callbacks = {
   [OBJ_TYPES.CURSOR] = {
      [OBJ_TYPES.DEFAULT] = function(cursor, default, contact)
         cursor:start_dragging(default)
      end,
   },
}

local collision_exit_callbacks = {
   [OBJ_TYPES.CURSOR] = {
      [OBJ_TYPES.DEFAULT] = function(cursor, default, contact)
      end,
   },
}

local function begin_contact(fixture1, fixture2, contact)
   local obj1 = fixture1:getUserData()
   local obj2 = fixture2:getUserData()
   if not obj1 then return end
   if not obj2 then return end

   local obj1_callbacks = collision_enter_callbacks[obj1.obj_type]
   if obj1_callbacks then
      local cb = obj1_callbacks[obj2.obj_type]
      if cb then cb(obj1, obj2, contact) end

      local any_cb = obj1_callbacks["any"]
      if any_cb then any_cb(obj1, obj2, contact) end
   end

   local obj2_callbacks = collision_enter_callbacks[obj2.obj_type]
   if obj2_callbacks then
      local cb = obj2_callbacks[obj1.obj_type]
      if cb then cb(obj2, obj1, contact) end

      local any_cb = obj2_callbacks["any"]
      if any_cb then any_cb(obj2, obj1, contact) end
   end
end

local function end_contact(fixture1, fixture2, contact)
   local obj1 = fixture1:getUserData()
   local obj2 = fixture2:getUserData()
   if not obj1 then return end
   if not obj2 then return end

   local obj1_callbacks = collision_exit_callbacks[obj1.obj_type]
   if obj1_callbacks then
      local cb = obj1_callbacks[obj2.obj_type]
      if cb then cb(obj1, obj2, contact) end

      local any_cb = obj1_callbacks["any"]
      if any_cb then any_cb(obj1, obj2, contact) end
   end

   local obj2_callbacks = collision_exit_callbacks[obj2.obj_type]
   if obj2_callbacks then
      local cb = obj2_callbacks[obj1.obj_type]
      if cb then cb(obj2, obj1, contact) end

      local any_cb = obj2_callbacks["any"]
      if any_cb then any_cb(obj2, obj1, contact) end
   end
end

return {
   begin_contact = begin_contact,
   end_contact = end_contact,
   -- NOTE: not used
   -- pre_solve = pre_solve,
   -- post_solve = post_solve,
}

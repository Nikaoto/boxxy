local state_machine = {}

function state_machine.force_set_state(obj, new_state)
   obj.state = nil
   if new_state then
      obj:set_state(new_state)
   end
end

function state_machine.set_state(obj, new_state)
   local old_state = obj.state
   if old_state == new_state then return end

   -- Leave callback
   local leave = obj.states[new_state].leave
   if leave then leave(obj, old_state) end

   -- Transition callback
   local can_transition = true
   if old_state and obj.states[old_state].transitions then
      local trans_fn = obj.states[old_state].transitions[new_state]
      if trans_fn then
         local result = trans_fn(obj)
         if result == false then
            can_transition = false
         else
            can_transition = true
         end
      end
   end

   if not can_transition then return end

   obj.state = new_state

   -- Global callback when any state changes
   if obj.on_state_change then
      obj.on_state_change(obj, old_state, new_state)
   end

   -- Init callback
   local init = obj.states[new_state].init
   if init then init(obj, old_state) end
end

function state_machine.update_state_machine(obj, dt, ...)
   local s = obj.states[obj.state]
   if not s then return end

   if s.update then
      s.update(obj, dt, ...)
   end
end

return state_machine

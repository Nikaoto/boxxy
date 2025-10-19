local physics = {
   masks = {
      collide_with_nothing = {
         1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
      }
   }
}

function physics.add_mock_physics(obj)
   -- Add methods
   obj.get_tc_point = physics.get_mock_tc_point
   obj.get_bc_point = physics.get_mock_bc_point
   obj.get_cc_point = physics.get_mock_cc_point
   obj.get_mock_rect_bounds = physics.get_mock_mock_rect_bounds
   obj.get_rotation = physics.get_mock_rotation
   obj.set_position = physics.set_mock_position
end

function physics.add_physics(obj, world)
   assert(obj.spawn_x and obj.spawn_y)
   assert(obj.collider_r or
         (obj.collider_w and obj.collider_h) or
         obj.collider_polygon)
   assert(obj.obj_type)

   obj.body = love.physics.newBody(
      world,
      obj.spawn_x,
      obj.spawn_y,
      obj.collider_type or "dynamic"
   )
   if obj.collider_fixed_rotation == true then
      obj.body:setFixedRotation(true)
   else
      obj.body:setFixedRotation(false)
   end
   obj.body:setLinearDamping(obj.linear_damping or 0.9)
   obj.body:setAngularDamping(obj.angular_damping or 0.3)

   if obj.collider_polygon then
      obj.shape = love.physics.newPolygonShape(
         unpack(obj.collider_polygon)
      )
   elseif obj.collider_r then
      obj.shape  = love.physics.newCircleShape(
         obj.collider_r * (obj.scale or 1)
      )
      -- NOTE: this might screw some things up with repooling
      obj.collider_w = obj.collider_r * 2
      obj.collider_h = obj.collider_r * 2
   elseif obj.collider_w and obj.collider_h then
      obj.shape = love.physics.newRectangleShape(
         obj.collider_w * (obj.sx or 1),
         obj.collider_h * (obj.sy or 1)
      )
   end

   if obj.collider_gravity_scale then
      obj.body:setGravityScale(obj.collider_gravity_scale)
   end

   obj.fixture = love.physics.newFixture(obj.body, obj.shape)

   -- Who we are for the physics engine
   if obj.collision_categories then
      obj.fixture:setCategory(
         obj.obj_type, unpack(obj.collision_categories))
   else
      obj.fixture:setCategory(obj.obj_type)
   end

   -- Who we don't collide with
   if obj.collision_mask then
      obj.fixture:setMask(unpack(obj.collision_mask))
   end

   if obj.collider_restitution then
      obj.fixture:setRestitution(obj.collider_restitution)
   else
      obj.fixture:setRestitution(0.2)
   end

   obj.fixture:setUserData(obj)
   obj.fixture:setSensor(obj.collider_sensor or false)
   if obj.collider_mass then
      obj.body:setMass(obj.collider_mass)
   end
   if obj.collider_density then
      obj.fixture:setDensity(obj.collider_density)
      obj.body:resetMassData()
   end

   -- Methods
   obj.get_tc_point = physics.get_tc_point
   obj.get_bc_point = physics.get_bc_point
   obj.get_cc_point = physics.get_cc_point
   obj.get_rotation = physics.get_rotation
   obj.set_position = physics.set_position
   obj.get_rect_bounds = physics.get_rect_bounds
end

function physics.get_rect_bounds(obj)
   local x, y = obj:get_cc_point()
   return x - obj.collider_w/2, y - obj.collider_h/2,
          x + obj.collider_w/2, y + obj.collider_h/2
end

function physics.get_tc_point(obj)
   local x, y = obj.body:getPosition()
   return x, y - obj.collider_h / 2
end

function physics.get_bc_point(obj)
   local x, y = obj.body:getPosition()
   return x, y + obj.collider_h / 2
end

function physics.get_cc_point(obj)
   return obj.body:getPosition()
end

function physics.get_rotation(obj)
   return obj.body:getAngle()
end

function physics.set_position(obj, x, y)
   obj.body:setPosition(x or obj.body:getX(), y or obj.body:getY())
end

function physics.set_mock_position(obj)
end

function physics.get_mock_tc_point(obj)
   return obj.spawn_x, obj.spawn_y - obj.collider_h
end

function physics.get_mock_bc_point(obj)
   return obj.spawn_x, obj.spawn_y + obj.collider_h
end

function physics.get_mock_cc_point(obj)
   return obj.spawn_x, obj.spawn_y
end

function physics.get_mock_rect_bounds(obj)
   return physics.get_rect_bounds(obj)
end

function physics.get_mock_rotation(obj)
   return obj.r or 0
end

return physics

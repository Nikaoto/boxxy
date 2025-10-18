-- Extensions for the math namespace

math.inf = 1/0
math.nan = 0/0

function math.normrad(rad)
   if rad < 0 then
      return (2*math.pi) - ((-rad) % (2*math.pi))
   else
      return rad % (2*math.pi)
   end
end

function math.sq(n)
   return n * n
end

function math.round(n)
   return math.floor(n + 0.5)
end

function math.round_to_pow_2(n)
   local p = math.floor(math.log(n) / math.log(2))

   local lv = 2 ^ p
   local uv = 2 ^ (p + 1)

   if (n - lv) < (uv - n) then
      return lv
   else
      return uv
   end
end

function math.floor_to_pow_2(n)
   local p = math.floor(math.log(n) / math.log(2))
   return 2 ^ p
end

function math.trunc(n)
   return n >= 0 and n-n%1 or n-n%-1
end

function math.floor_towards_zero(n)
   return math.trunc(n)
end

function math.frac(n)
   return n < 0 and (n%(-1)) or (n%1)
end

function math.ceil_away_from_zero(n)
   return n >= 0 and n-n%-1 or n-n%1
end

function math.sign(n)
   if n > 0 then
      return 1
   elseif n < 0 then
      return -1
   else
      return 0
   end
end

-- 9-point string to x-y lerp.
-- Returns 2 numbers in the range [0, 1] based on input 9-point string. The
-- returned values are relative to top-left. For example, "bc" (bottom-center)
-- returns 0.5 and 1, "tr" (top-right) returns 1 and 0 and so on.
function math.nps2xyl(str)
   -- Determine y lerp
   local char_y = str:sub(1, 1)
   local y = 0
   if char_y == "t" then
      y = 0
   elseif char_y == "c" then
      y = 0.5
   elseif char_y == "b" then
      y = 1
   end

   -- Determine x lerp
   local char_x = str:sub(2, 2)
   local x = 0
   if char_x == "l" then
      x = 0
   elseif char_x == "c" then
      x = 0.5
   elseif char_x == "r" then
      x = 1
   end

   return x, y
end

-- 9-point-generic-to-x-y-lerp.
-- Returns lerped x and y just like nps2xyl but can take both a table or a string.
function math.npg2xyl(str_or_tbl)
   if type(str_or_tbl) == "string" then
      return math.nps2xyl(str_or_tbl)
   elseif type(str_or_tbl) == "table" then
      return str_or_tbl[1], str_or_tbl[2]
   else
      return nil, nil
   end
end

function math.soft_clamp(value, min_val, max_val, softness)
   if value < min_val then
      local dist = min_val - value
      return min_val - dist / (1 + dist * softness)
   elseif value > max_val then
      local dist = value - max_val
      return max_val + dist / (1 + dist * softness)
   else
      return value
   end
end

function math.clamp(x, min, max)
   if x < min then return min end
   if x > max then return max end
   return x
end

function math.clamp_wrap(x, min, max)
   if x < min then return max end
   if x > max then return min end
   return x
end

-- The same as pingpong
function math.snap(x, min, max)
   local d1 = math.abs(x - min)
   local d2 = math.abs(x - max)

   if d1 < d2 then
      return min
   else
      return max
   end
end

function math.dampen(x, damping, deadzone)
   deadzone = deadzone or 0

   local damp_x = x * (1 - damping)

   if math.abs(damp_x) - deadzone <= 0 then
      return 0
   else
      return damp_x
   end
end

function math.lerp(from, to, amount)
   return from + (to - from) * amount
end

-- Inverse lerp
function math.ilerp(from, to, value)
   return (value - from) / (to - from)
end

-- Smooth lerp
function math.slerp(from, to, amount)
   local smooth_amount = amount * amount * (3 - 2 * amount)
   return from + (to - from) * smooth_amount
end

function math.aabb(x1, y1, w1, h1, x2, y2, w2, h2)
   return x1 < x2 + w2 and x2 < x1 + w1 and y1 < y2 + h2 and y2 < y1 + h1
end

function math.aabb_tbl(r1, r2)
   return
      r1.x < r2.x + r2.w and r2.x < r1.x + r1.w and
      r1.y < r2.y + r2.h and r2.y < r1.y + r1.h
end

function math.aabb_point(px, py, x, y, w, h)
   return px >= x and px <= x + w and
          py >= y and py <= y + h
end

function math.magnitude(x, y)
   return math.sqrt(x * x + y * y)
end

function math.normalize(x, y)
   local m = math.magnitude(x, y)
   return x/m, y/m
end

-- Given coordinates of a polygon {x1, y1, x2, y2, x3, y3 ...}
-- Finds its bounding box and returns it {minx, miny, maxx, maxy}
function math.find_polygon_bb(polygon)
   local maxx, maxy = -math.inf, -math.inf
   local minx, miny =  math.inf,   math.inf

   for i, v in ipairs(polygon) do
      if i % 2 == 0 then
         if v > maxy then maxy = v end
         if v < miny then miny = v end
      else
         if v > maxx then maxx = v end
         if v < minx then minx = v end
      end
   end

   return {minx, miny, maxx, maxy}
end

function math.numhash(x)
   if type(x) == "number" then return x end
   if type(x) == "table" then return #x end

   local sum = 0
   for i=1, #x do
      sum = sum + x:byte(i)
   end
   return sum
end

-- Takes a table of value => weight, the value key and the percent amount to
-- increase the chance of given value by. Calculates percentages and then adds
-- weight to the chosen value to increase its percentage.
-- Also takes a limit beyond which the percentage won't increase (1.0 by default).
-- Returns a new table with the changed weight.
function math.rechance(weights, key, pct_inc, limit)
   local copy = {}
   local sum = 0
   for k, v in pairs(weights) do
      sum = sum + v
      copy[k] = v
   end
   local fold = weights[key]/sum
   if fold > limit then return copy end
   local j = pct_inc/100
   if fold + j > (limit or 1) then j = limit - fold end
   if j > 0 then
      local k = (j*sum)/(1 - j- weights[key]/sum)
      copy[key] = copy[key] + k
   end
   return copy
end

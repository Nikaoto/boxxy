rand = rand or {}

local rfn = math.random
if love and love.math and love.math.random then
   rfn = love.math.random
end

function rand.set_seed(seed)
   if seed < 0 then seed = -seed end
   seed = seed % ((2^53)-1)

   if rfn == love.math.random then
      love.math.setRandomSeed(seed)
   end
   math.randomseed(seed)
end

function rand.int(min, max)
   return rfn(min, max)
end

-- The approximate amplitude is 6*stddev
function rand.normal(stddev, mean)
   return love.math.randomNormal(stddev, mean)
end

-- TODO: test this function with different flatness values
-- 'flatness' adjusts the flatness of the normal distribution curve and ranges
-- between [0,1].
-- * Values higher than 0.5 flatten the curve.
-- * Values lower than 0.5 make the curve pointier.
-- * 1 uses a uniform distribution.
-- * 0.5 uses a normal distribution.
-- * 0 uses a normal distribution with double the stddev.
function rand.normalf(stddev, mean, flatness)
   local adj_stddev = stddev * (2 - 2 * flatness)
   local n = rand.normal(stddev, mean)
   local u = rand.float(mean - 3*stddev, mean + 3*stddev)
   return (1-flatness)*n + flatness*u
end

-- NOTE: Generates in range [min, max)
function rand.float(min, max)
   -- if type(min) == "table" then
   --    min, max = min[1], min[2]
   -- end
   return min + rfn() * (max - min)
end

function rand.float_tbl(tbl)
   return rand.float(tbl[1], tbl[2])
end

function rand.sign()
   return rfn() < 0.5 and -1 or 1
end

function rand.bool()
   return rfn() < 0.5
end

function rand.roll(chance)
   return rfn() < chance
end

function rand.choice(arr)
   local idx = rand.int(1, #arr)
   return arr[idx], idx
end

-- tbl is an array/table of objects each of which has a weight field.
-- obj[weight_field] has the weight for that object.
-- If weight_field is nil, it is counted as 0.
function rand.weighted_choice_by_field(tbl, weight_field)
   local sum = 0
   for k, v in pairs(tbl) do
      sum = sum + (v[weight_field] or 0)
   end
   assert(sum ~= 0, "all weights are zero")
   local rnd = rand.float(0, sum)
   for k, v in pairs(tbl)do
      local w = v[weight_field] or 0
      if rnd < w then return k end
      rnd = rnd - w
   end
end

-- Uses iparis so only works with arrays
function rand.det_weighted_choice_by_field(tbl, weight_field)
   local sum = 0
   for k, v in ipairs(tbl) do
      sum = sum + (v[weight_field] or 0)
   end
   assert(sum ~= 0, "all weights are zero")
   local rnd = rand.float(0, sum)
   for k, v in pairs(tbl)do
      local w = v[weight_field] or 0
      if rnd < w then return k end
      rnd = rnd - w
   end
end

-- choice => wieght mapping.
-- NOTE: non-deterministic because of pairs()
function rand.fast_weighted_choice(tbl)
   local sum = 0
   for _, v in pairs(tbl) do
      assert(v >= 0, "weight value less than zero")
      sum = sum + v
   end
   assert(sum ~= 0, "all weights are zero")
   local rnd = rand.float(0, sum)
   for k, v in pairs(tbl) do
      if rnd < v then return k end
      rnd = rnd - v
   end
end

local function numhash(x)
   if type(x) == "number" then return x end
   if type(x) == "table" then return #x end

   local sum = 0
   for i=1, #x do
      sum = sum + x:byte(i)
   end
   return sum
end

-- choice => wieght mapping.
-- NOTE: Mostly deterministic, but slower because we sort.
-- NOTE: Not deterministic for weight tables which have tables as keys, so just
--       don't use them here. Prefer rand.det_weighted_choice for determinism.
function rand.weighted_choice(tbl)
   local weights = tbl
   local choices = table.keys(tbl)
   table.sort(choices, function(a, b)
      if weights[a] == weights[b] then
         return numhash(a) < numhash(b)
      else
         return weights[a] < weights[b]
      end
   end)

   return rand.det_weighted_choice(choices, weights)
end

-- choices is an array and weights is choice => weight
function rand.det_weighted_choice(choices, weights)
   local sum = 0
   for k, ch in ipairs(choices) do
      local v = weights[ch] or 1
      sum = sum + v
   end
   assert(sum ~= 0, "all weights are zero")
   local rnd = rand.float(0, sum)
   for k, ch in ipairs(choices) do
      local v = weights[ch] or 1
      if rnd < v then return ch end
      rnd = rnd - v
   end
end

-- Takes an array of touples {choice, weight} and based on the weights, randomly
-- returns one "choice" and its index. Basically the same as
-- rand.weighted_choice, but this is faster and deterministic because it takes
-- an array (which will always have the same iter order due to ipairs)
function rand.roulette(arr)
   local sum = 0
   for i in ipairs(arr) do
      sum = sum + (arr[i][2] or 1)
   end

   if sum <= 0 then return rand.choice(arr) end

   local r = rand.float(0, sum)
   for i in ipairs(arr) do
      local w = arr[i][2]
      if r < w then return arr[i][1], i end
      r = r - w
   end
end

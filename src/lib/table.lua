-- Functions for the table namespace

table.default_sort = table.sort
function table.sort(t, fn)
   table.default_sort(t, fn)
   return t
end

function table.stable_sort(t, comp)
  local n = #t
  if n < 2 then return t end
  local aux = {}

  comp = comp or function(a, b) return a < b end

  local function merge(low, mid, high)
    for i = low, high do
      aux[i] = t[i]
    end

    local i, j = low, mid + 1
    for k = low, high do
      if i > mid then
        t[k] = aux[j]
        j = j + 1
      elseif j > high then
        t[k] = aux[i]
        i = i + 1
      elseif comp(aux[j], aux[i]) then
        t[k] = aux[j]
        j = j + 1
      else
        t[k] = aux[i]
        i = i + 1
      end
    end
  end

  local function merge_sort(low, high)
    if high <= low then return end
    local mid = math.floor((low + high) / 2)
    merge_sort(low, mid)
    merge_sort(mid + 1, high)
    merge(low, mid, high)
  end

  merge_sort(1, n)
  return t
end

function table.remove_n(tbl, start_idx, count)
   if not start_idx then return tbl end

   local count = count or 1
   for i = start_idx, #tbl - count do
      tbl[i] = tbl[i + count]
   end
   for i = 1, count do
      tbl[#tbl] = nil
   end

   return tbl
end

function table.minn(tbl)
   local min = nil

   for k in pairs(tbl) do
     if
        type(k) == "number" and
        k % 1 == 0 and
        (min == nil or k < min)
     then
        min = k
     end
   end

   return min
end

-- Return k,v of the minimum VALUE in the table
function table.min(tbl)
   local min_val = math.inf
   local min_key = nil

   for k, v in pairs(tbl) do
      if min_val > v then
         min_val = v
         min_key = k
      end
   end

   return min_key, min_val
end

function table.avg(tbl)
   local avg = 0
   local count = 0
   for _, v in pairs(tbl) do
      avg = avg + v
      count = count + 1
   end
   return avg / count
end

function table.is_empty(tbl)
   if not tbl then return true end

   local k = next(tbl)
   return k == nil
end

-- Return next value from the table and cycle if last
function table.cycle_fwd(tbl, cur)
   if not tbl then return nil end

   local idx = table.find(tbl, cur)

   if not idx or idx == #tbl then -- loop forwards
      return tbl[1]
   else
      return tbl[idx+1]
   end
end

-- Return previous value from the table and cycle if first
function table.cycle_bwd(tbl, cur)
   if not tbl then return nil end

   local idx = table.find(tbl, cur)

   if not idx or idx == 1 then -- loop backwards
      return tbl[#tbl]
   else
      return tbl[idx-1]
   end
end

-- Shuffles in-place
function table.shuffle(arr)
   local shuf_count = #arr-1
   for i=1, shuf_count do
      local j = rand.int(i, #arr)
      arr[i], arr[j] = arr[j], arr[i]
   end

   return arr
end

function table.wrap_get(tbl, idx)
   local idx = table.wrap_idx(tbl, idx)
   return tbl[idx]
end

function table.wrap_idx(tbl, idx)
   local sz = #tbl
   local i = idx % sz
   return i == 0 and sz or i
end

function table.assign(into, from, ...)
   if not from or type(from) ~= "table" then return into end
   if not into or type(into) ~= "table" then return from end

   for k, v in pairs(from) do
      into[k] = v
   end

   for i, tbl in ipairs({...}) do
      for k, v in pairs(tbl) do
         into[k] = v
      end
   end
   return into
end

function table.reverse(arr)
   local len = #arr
   for i=1, math.floor(len/2) do
      arr[i], arr[len-i+1] = arr[len-i+1], arr[i]
   end
   return arr
end

-- Fills in the holes in an array, but disregards the ordering
function table.quick_squash(arr, len)
   local i = 1
   while true do
      if i >= len then break end
      if arr[i] == nil then
         arr[i] = arr[len]
         arr[len] = nil
         len = len - 1
      end
      i = i + 1
   end

   return arr, len
end

function table.shallow_copy(t, except)
   except = except or {}
   local newt = {}
   for k, v in pairs(t) do
      if not except[k] then
         newt[k] = v
      end
   end
   return newt
end

-- Copies the table deeply, INCLUDING metatables
function table.deep_copy(t)
   if type(t) ~= "table" then return t end

   local ret = {}
   for k, v in pairs(t) do
      ret[table.deep_copy(k)] = table.deep_copy(v)
   end
   setmetatable(ret, table.deep_copy(getmetatable(t)))
   return ret
end

-- Copies only POLTs (plain old lua tables), meaning tables with a metatable
-- will be completely ignored from copying. This reduces the chances of there
-- being a stack overflow
function table.deep_copy_polo(t)
   if type(t) ~= "table" then return t end
   if getmetatable(t) then return nil end

   local ret = {}
   for k, v in pairs(t) do
      local ck = table.deep_copy_polo(k)
      if ck then
         ret[ck] = table.deep_copy_polo(v)
      end
   end
   return ret
end

-- Copies the table deeply, EXCLUDING metatables
function table.deep_copy_no_mt(t)
   if type(t) ~= "table" then return t end

   local ret = {}
   for k, v in pairs(t) do
      ret[table.deep_copy(k)] = table.deep_copy(v)
   end
   return ret
end

-- Merge t1 <- t2. Fields in t2 overwrite those in t1.
function table.deep_merge(t1, t2)
   if t1 == nil then t1 = {} end
   if t2 == nil then return t1 end

   for k, v in pairs(t2) do
      if type(v) == "table" and type(t1[k]) == "table" then
         table.deep_merge(t1[k], v)
      else
         t1[k] = v
      end
   end

   return t1
end

function table.deep_equals(tbl1, tbl2)
   if type(tbl1) ~= "table" or type(tbl2) ~= "table" then
      return false
   end

   -- Check tbl1 subset of tbl2
   for k, v1 in pairs(tbl1) do
      local v2 = tbl2[k]

      -- Call comparison function if values are tables
      if type(v1) == "table" then
         if not table.deep_equals(v1, v2) then
            return false
         end
      else
         if v1 ~= v2 then
            return false
         end
      end
   end

   -- Check tbl2 subset of tbl1
   -- Here we only need to check if keys that tbl2 has exist in tbl1
   -- because if we reached this line, that means each value at `key`
   -- in tbl1 was also present in tbl2 in the same location
   for k, _ in pairs(tbl2) do
      if tbl1[k] == nil then
         return false
      end

      -- No need to check for table comparison, because if v1 and v2
      -- are tables, that means they were compared in the previous
      -- loop and ended up equal
   end

   return true
end

function table.foreach(arr, fn)
   for i, v in ipairs(arr) do
      fn(v, i, arr)
   end
   return arr
end

function table.find_fn(tbl, fn)
   if not tbl then return nil end
   if not fn then return nil end

   for k, v in pairs(tbl) do
      if fn(v, k) then
         return k, v
      end
   end

   return nil
end

function table.ifind_fn(tbl, fn)
   if not tbl then return nil end
   if not fn then return nil end

   for k, v in ipairs(tbl) do
      if fn(v, k) then
         return k, v
      end
   end

   return nil
end

function table.find(tbl, val)
   if not tbl then return nil end
   if not val then return nil end

   for k, v in pairs(tbl) do
      if v == val then
         return k, v
      end
   end

   return nil
end

function table.contains(tbl, val)
   if table.find(tbl, val) then
      return true
   else
      return false
   end
end

-- Like Array.prototype.filter in js
function table.filter_arr(tbl, fn)
   if not tbl then return nil end

   local filtered = {}

   for k, v in ipairs(tbl) do
      if fn(v, k, tbl) then
         table.insert(filtered, v)
      end
   end

   return filtered
end

-- Main difference is the use of 'pairs' instead of 'ipairs'
function table.filter(tbl, fn)
   if not tbl then return nil end

   local filtered = {}

   for k, v in pairs(tbl) do
      if fn(v, k, tbl) then
         table.insert(filtered, v)
      end
   end

   return filtered
end
table.filter_fn = table.filter

-- Return copy of arr1 with values from arr2 removed
function table.sub(arr1, arr2)
   local ret = {}
   for i in ipairs(arr1) do
      if not table.find(arr2, arr1[i]) then
         table.insert(ret, arr1[i])
      end
   end
   return ret
end

function table.keys(tbl)
   local keys = {}

   for k in pairs(tbl) do
      table.insert(keys, k)
   end

   return keys
end

function table.values(tbl)
   local values = {}

   for _, v in pairs(tbl) do
      table.insert(values, v)
   end

   return values
end

function table.shallow_append(arr1, arr2)
   for i in ipairs(arr2) do
      table.insert(arr1, arr2[i])
   end

   return arr1
end

function table.map(tbl, fn)
   local ret = {}

   for k, v in pairs(tbl) do
      ret[k] = fn(v, k, tbl)
   end

   return ret
end

-- Flattens array in-place recursively.
-- Absolutely guts all of the existing subtables.
-- Naiive and slow.
function table.flatten(arr, except)
   local len = #arr
   local i = 1
   while i < len do
      local v = arr[i]

      if not v or (except and except[v]) then
         i = i + 1
         goto continue
      end

      if type(v) == "table" then
         -- Empty subtable, shift elements backward
         if #v == 0 then
            table.remove(arr, i)
            len = len - 1
            goto continue
         end

         -- Flatten recursively
         local subarr = table.flatten(v, except)
         arr[i] = subarr[1]
         for j=#subarr, 2, -1 do
            table.insert(arr, i+1, subarr[j])
         end
         i = i + #subarr - 1
         len = len + #subarr - 1
      else
         i = i + 1
      end

      ::continue::
   end

   return arr
end

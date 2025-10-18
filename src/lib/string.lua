-- Functions for the string namespace

local fmt = string.format

function string.gen(pat, repeat_count)
   if repeat_count < 1 then return "" end
   local ret = pat

   for i=1, repeat_count do
      ret = ret .. pat
   end

   return ret
end

function string.join(arr, sep)
   local ret = ""
   if not arr[1] then return ret end
   if #arr == 1 then return arr[1] end

   ret = arr[1] .. sep

   for i=2, #arr-1 do
      ret = ret .. arr[i] .. sep
   end

   ret = ret .. arr[#arr]
   return ret
end

function string.split(str, delimiter)
  local result = {}
  local pattern = string.format("([^%s]+)", delimiter)

  if string.match(str, "^" .. delimiter) then
     table.insert(result, "")
  end

  for word in string.gmatch(str, pattern) do
    table.insert(result, word)
  end

  if string.match(str, delimiter .. "$") then
     table.insert(result, "")
  end

  return result
end

function string.trim(str, spc)
   spc = spc or "[%s]"
  return str:match("^" .. spc .. "*(.-)" .. spc .. "*$")
end

-- Take integer seconds and return in mm:ss format
-- where mm is minutes and ss is seconds.
function string.fmt_time_mm_ss(total_seconds)
   local minutes = math.floor(total_seconds / 60)
   local seconds = math.floor(total_seconds - minutes * 60)

   local mm = minutes > 9 and
      tostring(minutes) or ("0"..tostring(minutes))
   local ss = seconds > 9 and
      tostring(seconds) or ("0"..tostring(seconds))
   return mm .. ":" .. ss
end

-- Take float (seconds.milliseconds) and return hh:mm:ss.xxx format
-- where hh=hours mm=minutes ss=seconds xxx=milliseconds
function string.fmt_time(total_seconds)
   local millis = total_seconds - math.floor(total_seconds)
   total_seconds = total_seconds - millis

   local hrs = math.floor(total_seconds / 3600)
   total_seconds = total_seconds - hrs * 3600

   local mins = math.floor(total_seconds / 60)
   total_seconds = total_seconds - mins * 60

   local secs = total_seconds

   local xxx = fmt("%.3f", millis):sub(-3, -1)
   local ss = secs > 9 and tostring(secs) or ("0"..tostring(secs))
   local mm = mins > 9 and tostring(mins) or ("0"..tostring(mins))
   local hh = hrs  > 9 and tostring(hrs)  or ("0"..tostring(hrs))

   return fmt("%s:%s:%s.%s", hh, mm, ss, xxx)
end

-- Adds commas between the thousands
function string.fmt_big_number(num)
   local num = tostring(num)
   local ret = ""

   for i=#num, 1, -3 do
      if i-2 > 1 then
         ret = "," .. num:sub(i-2, i) .. ret
      else
         ret = num:sub(1, i) .. ret
      end
   end

   return ret
end

function string.emacs_delete_last_word(str)
   if string.match(str, "%w$") then
      return string.gsub(str, "[%s]*[%w]+$", "")
   else
      return string.gsub(str, "([%s%p]*)[%w]*[%p%s]*$", "%1")
   end
end

function string.delete_last_char(str)
   return string.sub(str, 1, -2)
end

function string.nmatch(str, sub)
   local _, count = string.gsub(str, sub, "")
   return count
end

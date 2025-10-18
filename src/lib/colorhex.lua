-- Take hex color and return table

local zero_ascii = string.byte("0")
local A_ascii = string.byte("A")

-- Takes 1-char string, returns decimal value
local function hex2dec(str)
   local ascii = str:byte()
   if ascii >= A_ascii then
      return 10 + (ascii - A_ascii)
   elseif ascii >= zero_ascii then
      return ascii - zero_ascii
   else
      return 0
   end
end

local colorhex = function(str, alpha)
   alpha = alpha or 1

   -- Remove hash
   if str:sub(1,1) == "#" then
      str = str:sub(2, -1)
   end

   str = string.upper(str)

   local red = hex2dec(str:sub(1, 1)) * 16 + hex2dec(str:sub(2, 2))
   local green = hex2dec(str:sub(3, 3)) * 16 + hex2dec(str:sub(4, 4))
   local blue = hex2dec(str:sub(5, 5)) * 16 + hex2dec(str:sub(6, 6))

   return {red/255, green/255, blue/255, alpha}
end

return colorhex

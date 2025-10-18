local colorlib = {}

-- Return 1,2,3 or 4 based on channel (r/g/b/a)
colorlib.channel_map = {
   [1] = 1,   [2] = 2,   [3] = 3,   [4] = 4,
   ['r'] = 1, ['g'] = 2, ['b'] = 3, ['a'] = 4,
   ['R'] = 1, ['G'] = 2, ['B'] = 3, ['A'] = 4,
}
function colorlib.map_chan(chan)
   return colorlib.channel_map[chan]
end

function colorlib.mod(color, chan, val)
   local c = table.shallow_copy(color)
   local chan = colorlib.map_chan(chan) or 1
   c[chan] = val
   return c
end

function colorlib.mix(cout, c1, c2, amount)
   cout[1] = math.lerp(c1[1], c2[1], amount)
   cout[2] = math.lerp(c1[2], c2[2], amount)
   cout[3] = math.lerp(c1[3], c2[3], amount)
   cout[4] = math.lerp(c1[4], c2[4], amount)
   return cout
end

return colorlib

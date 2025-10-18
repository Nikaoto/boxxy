local Stack = Class:extend({
   arr = {}
})

function Stack:init()
   self.arr = {}
end

function Stack:top()
   return self.arr[#self.arr]
end

function Stack:pop_middle(idx)
   if #self.arr == 0 then return nil end

   local item = self.arr[idx]
   table.remove(self.arr, idx)
   return item
end

function Stack:pop()
   if #self.arr == 0 then return nil end

   local item = self.arr[#self.arr]
   table.remove(self.arr, #self.arr)
   return item
end

function Stack:pop_all()
   local out = {}

   while self:size() > 0 do
      table.insert(out, self:pop())
   end

   return out
end

function Stack:push(item)
   table.insert(self.arr, item)
   return item
end

function Stack:size()
   return #self.arr
end

return Stack

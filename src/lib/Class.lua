local Class = {}

function Class:extend(o)
   local subclass = o or {}
   subclass.super = self
   subclass.__index = self
   setmetatable(subclass, subclass)
   return subclass
end

function Class:extends(o)
   return (self.super and self.super == o)
end

function Class:instance_of(o)
   return (self.__index and self.__index == o)
end

function Class:new(o)
   local instance = o or {}
   instance.super = self.super
   instance.__index = self
   setmetatable(instance, instance)

   instance:init()
   return instance
end

function Class:init()
end

return Class

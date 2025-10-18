-- uuid.lua

local uuids = {
   default = 0
}

local function uuid(tag)
   local tag = tag or "default"
   uuids[tag] = (uuids[tag] or 0) + 1
   return uuids[tag]
end

return uuid

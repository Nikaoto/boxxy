local filelib = {}

-- Returns status, error
function filelib.save_level(path, level)
   local f, err = io.open(path, "w+")
   if not f then
      return false, err
   end

   f:write("return " .. inspect(level, {refs=false}))
   f:close()
   return true, nil
end

function filelib.exists(path)
   local f, err = io.open(path, "r")
   if not f then
      return false
   end
   f:close()
   return true
end

function filelib.load_raw(path)
   local f, err = io.open(path, "rb")
   if not f then
      return nil, err
   end

   local contents = f:read("*a")
   f:close()

   return contents, err
end

function filelib.dump_raw(data, path)
   local f, err = io.open(path, "w+b")
   if not f then
      return false, err
   end

   f:write(data)
   f:close()
   return true, nil
end

-- Returns table, error.
-- If path begins with "/", load from absolute path, but can't access game directory. Otherwise, loads from game directories (save dir, .love, .exe)
function filelib.load_level(path)
   if not path then return nil, "path is nil" end

   local file_exists = false
   local loadfile_fn = nil
   if path:sub(1, 1) == "/" then
      file_exists = filelib.exists(path)
      loadfile_fn = loadfile
   else
      path = path:gsub("\\", "/")
      file_exists = love.filesystem.getInfo(path)
      loadfile_fn = love.filesystem.load
   end

   if not file_exists then
      return nil, fmt("File at \"%s\" doesn't exist.", path)
   end

   -- Load file
   local fn, load_err = loadfile_fn(path)
   if not fn then
      local str = fmt(
         "Error loading file at \"%s\": %s", path, load_err)
      return nil, str
   end

   -- Run file
   local succ, call_res = pcall(fn)
   if not succ then
      local str = fmt(
         "Error running file at \"%s\": %s", path, call_res)
      return nil, str
   end

   return call_res, nil
end

function filelib.dirlist(path, caller_dir)
   -- Use love.filesystem
   if love and love.filesystem and love.filesystem.getDirectoryItems then
      return love.filesystem.getDirectoryItems(path)
   end

   -- Use luafilesystem
   local lfs = lfs or lfs_ffi
   if lfs then
      local path_for_lfs = nil
      if path:sub(1, 1) == "/" or path == "" then
         path_for_lfs = lfs.currentdir() .. path
      elseif path == "." then
         path_for_lfs = lfs.currentdir() .. caller_dir
      end

      local dirlisting = {}
      local iter, dir_obj = lfs.dir(path_for_lfs)
      local dir = iter(dir_obj)
      while dir do
         if dir ~= "." and dir ~= ".." then
            table.insert(dirlisting, dir)
         end
         dir = iter(dir_obj)
      end
      return dirlisting
   end

   error("Neither love.filesystem nor lfs found.")
end

return filelib

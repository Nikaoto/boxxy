-- Extensions for the os namespace

function os.is_windows()
   local os_name = os.getenv("OS") or ""
   return os_name:match("Windows") or package.config:sub(1,1) == '\\'
end

function os.is_osx()
   if os.is_windows() then return false end

   local os_name = os.getenv("OS") or io.popen("uname"):read("*l")
   return os_name and os_name:match("Darwin") or false
end

function os.is_macos()
   return os.is_osx()
end

function os.is_linux()
   if os.is_windows() then return false end

   local os_name = os.getenv("OS") or io.popen("uname"):read("*l")
   if (os_name and os_name:match("Linux")) or
      os.getenv("XDG_CURRENT_DESKTOP") then
      return true
   else
      return false
   end
end

function os.open_explorer(path)
   if os.is_windows() then
      os.execute(string.format('start "" "%s"', path))
   elseif os.is_linux() then
      os.execute(string.format('xdg-open "%s"', path))
   elseif os.is_macos() then
      os.execute(string.format('open "%s"', path))
   end
end

function os.capture(cmd)
   local f = assert(io.popen(cmd, "r"))
   local s = assert(f:read("*a"))
   f:close()
   return s
end

function os.cpu_word_size()
   if os.is_windows() then
      local arch = os.getenv("PROCESSOR_ARCHITECTURE")
      if arch == "x86" or arch == "ARM" then
         return 32
      else
         return 64
      end
   end

   -- Macos and linux
   local arch = io.popen("uname -m"):read("*a")
   if arch:match("64") then
      return 64
   else
      return 32
   end
end

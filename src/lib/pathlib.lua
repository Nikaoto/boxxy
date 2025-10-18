local pathlib = {}

function pathlib.ext(path)
   return path:match("%.[^.]*$")
end

function pathlib.full_ext(path)
   return path:match("%..*$")
end

function pathlib.strip_ext(path)
   return path:match("([^%.]+)")
end

function pathlib.filename(path)
   local up = path:gsub("\\", "/")
   local fn = up:match("^.+/(.+)$") or up
   return fn
end

function pathlib.to_unix(path)
   return path:gsub("\\", "/")
end

function pathlib.get_dir_separator()
   if os.is_windows() then return "\\" else  return "/" end
end

function pathlib.to_native(path)
   local sep = pathlib.get_dir_separator()
   return path:gsub("/", sep):gsub("\\", sep)
end

function pathlib.determine_dir_sep_by_path(path)
   if path:match("\\") then
      return "\\"
   else
      return "/"
   end
end

function pathlib.dirname(path, up_count)
   up_count = up_count or 1 -- how many dirs to go up by
   local sep = pathlib.determine_dir_sep_by_path(path)
   local parts = string.split(path, sep)
   for i=1, up_count do
      table.remove(parts, #parts)
   end
   return string.join(parts, sep)
end

function pathlib.append(p1, p2)
   if not p1 or #p1 == 0 then return p2 end
   if not p2 or #p2 == 0 then return p1 end

   local sep = pathlib.get_dir_separator()

   local updir = ".." .. sep
   if p2:sub(1, string.len(updir)) == updir then
      -- Find number of consecutive updir patterns
      local consecutive = 1
      local idx = string.len(updir) + 1
      while true do
         local i1, i2 = string.find(p2, updir, idx, true)
         if not i1 then break end
         consecutive = consecutive + 1
         idx = i2 + 1
      end

      -- Go up that many dirs in p1
      p1 = pathlib.dirname(p1, consecutive)

      -- Slice off the updirs
      p2 = p2:sub(idx)
   end

   return p1:gsub(sep.. "$", "") .. sep .. p2:gsub("^" .. sep, "")
end

function pathlib.join(...)
   local final = nil

   for i, v in ipairs({...}) do
      final = pathlib.append(final, pathlib.to_native(v))
   end

   return final
end

function pathlib.get_desktop_path()
   local home_path = os.getenv("HOME") or os.getenv("USERPROFILE") or ""

   if os.is_windows() then
      return home_path .. "\\Desktop"
   elseif os.is_linux() then
      return home_path .. "/Desktop"
   else -- macos and others
      return home_path .. "/Desktop"
   end
end

function pathlib.relpath(path1, path2)
    -- Determine path separator
    local is_windows = os.is_windows()
    local sep = is_windows and '\\' or '/'
    local pattern = is_windows and '\\\\+' or '/+'
    local dot_sep = is_windows and '.\\' or './'

    -- Remove trailing slashes
    path1 = path1:gsub(pattern .. '$', '')
    path2 = path2:gsub(pattern .. '$', '')

    -- Splits path into components
    local function split_path(path)
        local parts = {}
        for part in path:gmatch("[^" .. sep .. "]+") do
            table.insert(parts, part)
        end
        return parts
    end

    local parts1 = split_path(path1)
    local parts2 = split_path(path2)
    
    -- Find the common root and index of divergence
    local i = 1
    while parts1[i] and parts2[i] and parts1[i]:lower() == parts2[i]:lower() do
        i = i + 1
    end

    -- Construct the relative path
    local rel_parts = {}
    for j = i, #parts1 do
        table.insert(rel_parts, '..')
    end
    for j = i, #parts2 do
        table.insert(rel_parts, parts2[j])
    end

    -- If the relative path is empty, it means path2 is the same as path1
    if #rel_parts == 0 then
        return dot_sep
    end

    local relative_path = table.concat(rel_parts, sep)
    -- Ensure the relative path starts with ".\" or "./" if it's a direct subdirectory or file
    if not relative_path:find('^%.%\\') and not relative_path:find('^%./') then
        relative_path = dot_sep .. relative_path
    end

    return relative_path
end

return pathlib

--- MiniFS is a minimal file system module for Lua, licensed under MIT.
-- It depends on LFS and provides easy access to functions such as copying files, checking the type of a file or working with temporary files.
fs = {}
require "lfs"
math.randomseed(os.time())

bool = (value) -> not not value

choice = (...) ->
  table = {...}
  assert(#table > 0, "table is empty")
  return (table[math.random(1, #table)])

defaults = {
  randomstring: {
    length: 6
  }
  tmpname: {
    prefix: ""
    suffix: ""
  }
}

--- Write data to a file, overwriting the previous contents (and creating the file if needed).
-- @param file The file to write to.
-- @param data The data that will be written to the file.
-- @return boolean 
fs.write = (file, data) ->
  filehandle = assert(io.open(file, "wb"))
  ret = filehandle\write(data)
  filehandle\close()
  return(bool(ret))

--- Append data to a file (similiar to write, but will not overwrite the data inside the file).
-- @param file The file to append to.
-- @param data The data that will be appended to the file.
-- @return boolean
fs.append = (file, data) ->
  filehandle = assert(io.open(file, "ab"))
  ret = filehandle\write(data)
  filehandle\close()
  return(bool(ret))

--- Read all data from a file.
-- @param file The file to be read.
-- @return string 
fs.read = (file) ->
  filehandle = assert(io.open(file, "rb"))
  data = assert(filehandle\read("*a"))
  filehandle\close()
  return (data)

--- Copy a file to a destination.
-- @param fromfile The file to be copied.
-- @param tofile The target path.
-- @return boolean
fs.copy = (fromfile, tofile) ->
  fromfilehandle = assert(io.open(fromfile, "rb"))
  tofilehandle = assert(io.open(tofile, "wb"))
  ret = tofilehandle\write(assert(fromfilehandle\read("*a")))
  tofilehandle\close()
  fromfilehandle\close()
  return(bool(ret))

--- Move a file. Similiar to copying, but will remove the original file after copying.
-- @param fromfile The file to be moved.
-- @param tofile The destination of the file.
-- @return nil
fs.move = (fromfile, tofile) ->
  assert(fs.copy(fromfile, tofile)) -- we don't want accidents where it'll fail
  fs.remove(fromfile)

--- Append a copy of a file to another file. Like copying, but if the target file already exists the contents will not be overwritten but instead added after the existing data.
-- @param fromfile The file to be copied.
-- @param tofile The target file.
-- @return boolean
fs.appendcopy = (fromfile, tofile) ->
  fromfilehandle = assert(io.open(fromfile, "rb"))
  tofilehandle = assert(io.open(tofile, "ab"))
  ret = tofilehandle\write(assert(fromfilehandle\read("*a")))
  tofilehandle\close()
  fromfilehandle\close()
  return(bool(ret))

--- Move and append a file. As opposed to the normal move function, the contents of the moved file will be appended to the target file instead of overwriting it.
-- @param fromfile The file to be moved.
-- @param tofile The destination of the file.
-- @return nil
fs.appendmove = (fromfile, tofile) ->
  assert(fs.appendcopy(fromfile, tofile)) -- we don't want accidents where it'll fail
  fs.remove(fromfile)
  
--- Remove a file.
-- @param file The file to be removed.
-- @return boolean
fs.remove = (file) ->
  return(os.remove(file))
  
--- Get the size of a file.
-- @param file The file to get the size of.
-- @return number
fs.size = (file) ->
  filehandle = assert(io.open(file, "rb"))
  size = assert(filehandle\seek("end"))
  filehandle\close()
  return (size)
  
--- Update the access/modification time of a file.
-- @param file The file to be updated.
-- @param accesstime The access time to set, if nil will be set to the current time.
-- @param modificationtime The modification time to set, if nil will be set to the accesstime, and if accesstime is nil, will be set to the current time.
-- @return boolean, string [error message]
fs.update = (file, accesstime, modificationtime) ->
  return(lfs.touch(file, accesstime, modificationtime))

--- Create an empty, zero byte file.
-- @param file The file to be created.
-- @return boolean
fs.create = (file) ->
  return(fs.write(file, ""))
  
--- Rename a file.
-- @param file The name of the file.
-- @param newname The new name of the file.
-- @return boolean
fs.rename = (file, newname) ->
  return(os.rename(file, newname))

--- Check if a file exists.
-- @param file The path to be checked.
-- @return boolean [whether the file exists]
fs.exists = (file) -> bool(lfs.attributes(file))

--- Create a new directory.
-- @param dir The path to the directory.
-- @return boolean, string [error message]
fs.mkdir = (dir) -> lfs.mkdir(dir)
  
--- Remove a directory.
-- @param dir The path to the directory.
-- @param recursive If true, the directory will be recursively removed. If false, the function will error on non-empty directories.
-- @return boolean, string [error message]
fs.rmdir = (dir, recursive) ->
  if recursive
    for file in fs.files(dir, true) do
      if fs.type(file) == "directory"
        assert(fs.rmdir(file))
      else
        assert(fs.remove(file))
  return(lfs.rmdir(dir))
  
--- Get the device of the file. On Linux, this will be the inode. On Windows, this will be the drive number.
-- @param file The path to the file.
-- @return number (string on Windows?)
fs.device = (file) -> lfs.attributes(file, "dev")
  
--- Get the type of the file. This can be 'file', 'directory', 'link', 'socket', 'named pipe', 'char device', 'block device' or 'other'.
-- @param file The path to the file.
-- @return string
fs.type = (file) -> lfs.attributes(file, "mode")
  
--- Get the user ID of the file. Always 0 on Windows.
-- @param file The path to the file.
-- @return number
fs.uid = (file) -> lfs.attributes(file, "uid")

--- Get the group ID of the file. Always 0 on Windows.
-- @param file The path to the file.
-- @return number
fs.gid = (file) -> lfs.attributes(file, "gid")

--- Get the last access time of the file.
-- @param file The path to the file.
-- @return number
fs.accesstime = (file) -> lfs.attributes(file, "access")

--- Get the last modification time of the file.
-- @param file The path to the file.
-- @return number
fs.modificationtime = (file) -> lfs.attributes(file, "modification")

--- Get the last status change time of the file.
-- @param file The path to the file.
-- @return number
fs.changetime = (file) -> lfs.attributes(file, "change")

--- Get the directory separator that the system uses. Forward slash on Unix-likes, Backward slash on Windows.
-- @return string
fs.separator = -> package.config\sub(1, 1)

--- Get the operating system the script is running on (Mac/Linux/Windows).
-- @param unixtype If set to true, the type of the Unix-like will be detected. Note that this uses an io.popen call and might be more expensive.
-- @return string
fs.system = (unixtype) ->
  separator = fs.separator()
  if separator == "/"
    if unixtype
      uname = assert(fs.call("uname"))\gsub("^%s+", "")\gsub("%s+$", "")\gsub("[\n\r]+", " ")
      return uname
    else
      return "Unix"
  elseif separator == "\\"
    return "Windows"
  else
    return "Unkown"

--- Create a random string containing lowercase, uppercase letters and numbers.
-- @param length Length of the name, 6 by default.
-- @return string
fs.randomstring = (length) ->
  length = length or defaults.randomstring.length
  name = ""
  for i = 1, length do
    symbol = choice("lowercase", "uppercase", "number")
    if symbol == "lowercase"
      name = name .. string.char(math.random(97, 122))
    elseif symbol == "uppercase"
      name = name .. string.char(math.random(65, 90))
    elseif symbol == "number"
      name = name .. string.char(math.random(48, 57))
  return (name)

--- Create a valid path to a temporary file name in the default temporary directory of the operating system.
-- @param length Length of the filename.
-- @param prefix Prefix of the filename, does not count for length.
-- @param suffix Suffix of the filename, does not count for length.
-- @return string
fs.tmpname = (length, prefix, suffix) ->
  prefix = prefix or defaults.tmpname.prefix
  suffix = suffix or defaults.tmpname.suffix
  tmpdir = ""
  system = fs.system()
  if system == "Windows"
    tmpdir = assert(os.getenv("temp"))
  elseif system == "Unix"
    tmpdir = "/tmp"
  else
    error("This operating system is not supported by this function")
  filename = tmpdir .. fs.separator() .. prefix .. fs.randomstring(length) .. suffix
  return (filename)
  
--- Create a temporary file, then call a defined function and remove the file afterwards.
-- Note that you can also provide only one argument, the callback, and keep the rest of the values as defaults.
-- @param length Length of the filename.
-- @param prefix Prefix of the filename
-- @param suffix Suffix of the filename.
-- @param call The callback function to call inbetween creating a temporary file and removing the file. One argument, the path to the file, is provided to the function.
-- @param dir If this is true, then the temporary file will be a temporary directory. See {fs.usetmpdir}.
fs.usetmp = (length, prefix, suffix, call, dir) -> 
  if not prefix and not suffix and not call and not dir and type(length) == "function"
    call = length
    length = nil --
  assert(call and type(call) == "function", "argument #4 or the only argument must be a function")
  path = ""
  fileexists = true --
  while fileexists do
    path = fs.tmpname(length, prefix, suffix)
    fileexists = fs.exists(path)
  if dir
    fs.mkdir(path)
  else
    fs.create(path)
  call(path)
  if dir
    fs.rmdir(path, true)
  else
    fs.remove(path)
  
--- Create a temporary directory, then call a defined function and recursively remove the directory afterwards.
-- Note that you can also provide only one argument, the callback, and keep the rest of the values as defaults.
-- @param length Length of the filename.
-- @param prefix Prefix of the filename
-- @param suffix Suffix of the filename.
-- @param call The callback function to call inbetween creating a temporary file and removing the file. One argument, the path to the file, is provided to the function.
fs.usetmpdir = (length, prefix, suffix, call) ->
  if not prefix and not suffix and not call and type(length) == "function"
    call = length
    length = nil --
  fs.usetmp(length, prefix, suffix, call, true)

--- Basic iterator over files in a directory.
-- @param dir The directory to iterate through.
-- @param fullpath If this is set to true, then the entries returned by the iterator will contain the directory name along with the file name.
-- @return function [iterator returns: string]
fs.files = (dir, fullpath) ->
  iter, dirobj = lfs.dir(dir)
  return ->
    entry = nil --
    nopass = true --
    while nopass do
      entry = iter(dirobj)
      nopass = (entry == ".") or (entry == "..")
    if fullpath and entry
      return dir .. fs.separator() .. entry
    else
      return entry

--- Create a hardlink to a file.
-- @param file The file to be linked to.
-- @param link The path to the link.
fs.link = (file, link) -> lfs.link(file, link)

--- Create a symlink to a file or directory.
-- @param file The file to be linked to.
-- @param link The path to the link.
fs.symlink = (file, link) -> lfs.link(file, link, true)

--- Run a console comand.
-- @param command The command to be ran.
-- @param ... Additional arguments.
fs.run = (command, ...) ->
  assert(type command == "string", "argument #1 (command) must be a string")
  args = {...}
  commandargs = ""
  if #args > 0
    commandargs = "\"" .. table.concat(args, "\" \"") .. "\""
  os.execute("\"" .. command .. "\" " .. commandargs)

--- Call a command and return all of its results.
-- @param command The command to be called.
-- @param ... Additional arguments.
fs.call = (command, ...) ->
  assert(type command == "string", "argument #1 (command) must be a string")
  args = {...}
  commandargs = ""
  if #args > 0
    commandargs = "\"" .. table.concat(args, "\" \"") .. "\""
  handle = assert(io.popen("\"" .. command .. "\" " .. commandargs, "r"))
  return (assert(handle\read("*a")))

return fs

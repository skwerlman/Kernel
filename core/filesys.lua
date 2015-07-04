--[[
The MIT License (MIT)

Copyright (c) 2014-2015 the TARDIX team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]

local oldfs = (function(tab)
  local a={}for b,c in pairs(tab)do a[b]=c end;return a
end)(getfenv(2).fs)
oldfs.id = 'oldfilesystem'
_unique = {}

_unique._registers = {}
--[[
Register a file system.
@param n the name of the file system
@param t a table representing the file system.
Optimally, the t parameter should contain all operations in the fs table and a getOwner function. The getOwner function should return true when the file system is going to take care of a path.
]]
function _unique.register(n, t)
  _unique._registers[n] = t
end
--[[
Unregister a file system.
@param n the name of the file system.
]]
function _unique.unregister(n)
  _unique._registers[n] = nil
end
--[[
Get the owner file system for a path.
@param path the path.
]]
function _unique.getOwnerFor(path)
  if path then
    for k, v in pairs(_unique._registers) do
      if v.isOwnerOf and v:isOwnerOf(path) then

      return v
      end
    end

    if oldfs.exists(path) then
      return oldfs
    end
  end
end

--[[
Call a file system function in the owner for a path
@param path the path
@param fn the function's name
@param ... the arguments to the function.
]]
function _unique.callFunctionInOwnerFor(path, fn, ...)
  local owner = _unique.getOwnerFor(path)
  if owner and owner[fn] then
    if owner == oldfs then
      return owner[fn](path, ...)
    else
      return owner[fn](owner, path, ...)
    end
  elseif not owner and oldfs[fn] then
    return oldfs[fn](path, ...)
  end
end

local virtuals = {}
--[[
Check if a path is virtual.
@param p the path
]]
function _unique.isVirtual(p)
  if not p then
    return false
  else
    if virtuals[p] ~= nil then
      return true
    elseif virtuals['/' .. p] ~= nil then
      return true
    elseif virtuals['/' .. p .. '/'] ~= nil then
      return true
    elseif virtuals[p:sub(1, 1) == '/' and p:sub(2, #p)] ~= nil then
      return true
    else
      return false
    end
  end
end
--[[
Get the virtual object for a path.
@param p the path.
]]
function _unique.getVirtual(p)
  if virtuals[p] ~= nil then
    return virtuals[p]
  elseif virtuals['/' .. p] ~= nil then
    return virtuals['/' .. p]
  elseif virtuals['/' .. p .. '/'] ~= nil then
    return virtuals['/' .. p .. '/']
  elseif virtuals[p:sub(1, 1) == '/' and p:sub(2, #p)] ~= nil then
    return virtuals[p:sub(1, 1) == '/' and p:sub(2, #p)]
  end
end
--[[
Add a virtual object.
@param p the path of the object to add.
@param n the object.
]]
function _unique.addVirtual(p, n)
  if not virtuals[p] then
    virtuals[p] = n
  end
end
--[[
Call a function in the virtual object for a path.
@param p the path
@parma f the function's name
@param ... the parameters to path to a function.
]]
function _unique.callVirtual(p, f, ...)
  if _unique.getVirtual(p) and _unique.getVirtual(p)[f] then
    return _unique.getVirtual(p)[f](_unique.getVirtual(p), p, ...)
  else
    return nil
  end
end
--[[
Remove a virtual object.
@param p the path of the virtual object.
]]
function _unique.removeVirtual(p)
  if virtuals[p] then virtuals[p] = nil end
end

--[[
List a directory.
Takes into consideration virtual objects and file system owners.

@param path the path of the directory to list.
]]
function _unique.list(path)
  local ret = {}
  if path == '' then
    path = '/'
  end
  for k, v in pairs(virtuals) do
    local dir = _unique.getDir(k) == '' and '/' or _unique.getDir(k)
    if dir == path then
      table.insert(ret, ({k:gsub(dir, '')})[1])
    elseif '/' .. dir == path then
      table.insert(ret, ({k:gsub(dir, '')})[1])
    end
  end

  if not fs.isVirtual(path) then
    for k, v in pairs(_unique.callFunctionInOwnerFor(path, 'list')) do
      if oldfs.getDir(v) == path then
        v = v:gsub(oldfs.getDir(v), '')
      end
      table.insert(ret, v)
    end
  else
    if _unique.getVirtual(path) and _unique.getVirtual(path).list then
      for k, v in pairs(_unique.callVirtual(path, 'list')) do
        if oldfs.getDir(v) == path then
          v = v:gsub(oldfs.getDir(v), '')
        end
        table.insert(ret, v)
      end
    end
  end

  return ret
end
--[[
Check if a file exists.
@param p the path of file.

Takes into consideration virtual objects and file system owners.
]]
function _unique.exists(p)
  if _unique.isVirtual(p) then
    return true
  end
  return _unique.callFunctionInOwnerFor(p, 'exists')
end
--[[
Check if a file is a directory.
@param p the path of the file

Takes into consideration virtual objects and file system owners.
]]
function _unique.isDir(p)
  if _unique.isVirtual(p) then
    if _unique.getVirtual(p).isDir ~= nil then
      if type(_unique.getVirtual(p).isDir) == 'function' then
        return _unique.callVirtual(p, 'isDir')
      elseif type(_unique.getVirtual(p).isDir) == 'boolean' then
        return _unique.getVirtual(p).isDir
      else
        return false
      end
    else
      return false
    end
  end
  return _unique.callFunctionInOwnerFor(p, 'isDir')
end

--[[
Check if a file is read only.
@param p the path of the file

Takes into consideration virtual objects and file system owners.
]]
function _unique.isReadOnly(p)
  if _unique.isVirtual(p) then
    if type(_unique.getVirtual(p).isReadOnly) == 'function' then
      return _unique.callVirtual(p, 'isReadOnly')
    elseif type(_unique.getVirtual(p).isReadOnly) == 'boolean' then
      return _unique.getVirtual(p).isReadOnly
    else
      return false
    end
  end
  if p == 'kernel' or fs.getDir(p) == 'kernel' then
    return true
  end
  return _unique.callFunctionInOwnerFor(p, 'isReadOnly') or false
end

local function split(inputstr, sep)
  sep = sep or "%s"
  local t={} ; i=1
  for str in string.gmatch(inputstr, '([^'..sep..']+)') do
    t[i] = str
    i = i + 1
  end
  return t
end

--[[
Get the name of a path. This returns the last component of the path when tokenized on '/'.
@param p the path
]]
function _unique.getName(p)
  return split(p, '/')[#(split(p, '/'))]
end
--[[
Get the size of a file.
@param p the file

Takes into consideration virtual objects and file system owners.
]]
function _unique.getSize(p)
  if _unique.isVirtual(p) then
    return 0
  end

  if not _unique.isVirtual(p) then
    return _unique.callFunctionInOwnerFor(p, 'getSize')
  else
    return 0
  end
end
--[[
Get free space in a path.
@param p the path

Takes into consideration virtual objects and file system owners.
]]
function _unique.getFreeSpace(p)
  if _unique.isVirtual(p) then
    return _unique.callVirtual(p, 'getFreeSpace')
  end

  return _unique.callFunctionInOwnerFor(p, 'getFreeSpace')
end
--[[
Make a directory.
@param p the path.

Takes into consideration virtual objects and file system owners.
]]
function _unique.makeDir(p)
  if _unique.isReadOnly(p) then
    error(p .. ' is read only.')
  end

  if _unique.isVirtual(fs.getDir(p)) then
    _unique.callVirtual(fs.getDir(p), 'makeDir', p)
  end

  if not _unique.exists(p) then
    return _unique.callFunctionInOwnerFor(p, 'makeDir')
  end
end
--[[
Move a file.
@param p the source file
@param e the destination file

Takes into consideration virtual objects and file system owners.
]]
function _unique.move(p, e)
  if _unique.isVirtual(p) and not _unique.exists(e) then
    return _unique.callVirtual(p, 'move', e)
  end

  return _unique.callFunctionInOwnerFor(p, 'move', e)
end

--[[
Move a file.
@param p the source file
@param e the destination file

Takes into consideration virtual objects and file system owners.
]]
function _unique.copy(p, e)
  if _unique.isVirtual(p) and not _unique.exists(e) then
    return _unique.callVirtual(p, 'copy', e)
  end

  return _unique.callFunctionInOwnerFor(p, 'copy', e)
end
--[[
Delete a file.
@param p the path.

Takes into consideration virtual objects and file system owners.
]]
function _unique.delete(p)
  if _unique.isVirtual(p) then
    return _unique.callVirtual(p, 'delete')
  end

  if _unique.exists(p) and not _unique.isReadOnly(p) then
    return _unique.callFunctionInOwnerFor(p, 'delete')
  end
end

--[[
Compine two paths.
@param p1 one path
@param p2 the other path
]]
function _unique.combine(p1, p2)
  return oldfs.combine(p1, p2)
end
--[[
Open a file, returning a handle.
@param path the path of the file to open
@param mode the mode to open the file in. This can be 'r', 'w', 'a', 'rb', 'wb' and 'ab'.

Takes into consideration virtual objects and file system owners.
]]
function _unique.open(path, mode)
  assert(type(path) == 'string', 'expected string for path, got ' .. type(path))
  assert(type(mode) == 'string', 'expected string for mode, got ' .. type(mode))

  if path and mode then
    if _unique.isVirtual(fs.getDir(path)) then
      if _unique.getVirtual(fs.getDir(path)).open_child then
        return _unique.callVirtual(fs.getDir(path), 'open_child', path, mode)
      end
    end

    if _unique.isVirtual(path) then
      return _unique.callVirtual(path, 'open', mode)
    end

    return _unique.callFunctionInOwnerFor(path, 'open', mode)
  else
    error('missing required argument path or mode.')
  end
end

--[[
Find a file using a wildcard.
@param wild the wildcard to use.
]]
function _unique.find(wild)
  return oldfs.find(wild)
end
--[[
Get the directory of a path.
@param p the path
]]
function _unique.getDir(p)
  return oldfs.getDir(p)
end
--[[
Get the drive of a path.
@param p the path
]]
function _unique.getDrive(p)
  return oldfs.getDrive(p)
end

--[[
Control the input and output of a special device. This is used when communicating to a kernel driver.
@param p the path
@param r the request
@param ... the parameters to the request.
]]
function _unique.ioctl(p, r, ...)
  if _unique.isVirtual(p) then
    return _unique.callVirtual(p, 'ioctl', r, ...)
  end

  local ownerOfP = _unique.getOwnerFor(p)
  if ownerOfP == oldfs then
    return
  else
    if ownerOfP.ioctl then
      return ownerOfP:ioctl(p, r, ...)
    else
      return
    end
  end
end

local _vmounts = {}
--[[
Add virtual files in a batch.
@param root the root
@param files a table of virtual objects
]]
function _unique.mount(root, files)
  fs.addVirtual(root, files.rootn or {isDir=true})
  if not _vmounts[root] then
    for k, v in pairs(files) do
      if k ~= 'rootn' then
        _unique.addVirtual(fs.combine(root, k), v)
      end
    end
    _vmounts[root] = files
  end
end

--[[
Remove mounted virtual files
@param root the root
]]
function _unique.umount(root)
  fs.removeVirtual(root)
  if _vmounts[root] then
    for k, v in pairs(_vmounts[root]) do
      _unique.removeVirtual(fs.combine(root, k), v)
    end
    _vmounts[root] = nil
  end
end
--[[
Pipe a read-mode file handle into a write-mode one.
@param r a read-mode file handle
@param w the write-mode file handle.
]]
function _unique.pipe(r, w)
  if r and r.readAll and w and w.writeLine then
    w.writeLine(r.readAll())
    r.close()
    w.close()
  end
end
-- documentation to be done.
function _unique.makeVirtualIO(path)
  local watcher = {}


  local object = {
    isDir = false,
    isReadOnly = false,
  }

  function object:ioctl(path, req, ...)
    if watcher.onIOControl then
      watcher.onIOControl(self, path, req, ...)
    else
      return false, 'not yet implemented'
    end
  end

  function object:open(path, mode)
    local ret = {}
    if mode == 'r' then
      local closed = false

      function ret.readLine()
        if not closed then
          if watcher.onRead then
            return watcher.onRead(self)
          else
            return nil
          end
        else
          return nil
        end
      end

      function ret.readAll()
        if not closed then
          if watcher.onReadAll then
            return watcher.onReadAll(self)
          else
            return nil
          end
        else
          return nil
        end
      end

      function ret.close()
        if watcher.onClose then
          return watcher.onClose(self)
        end
        closed = true
      end
    elseif mode == 'w' then
      local closed = false

      function ret.writeLine(...)
        if not closed then
          if watcher.onWriteLine then
            return watcher.onWriteLine(self, ...)
          else
            return nil
          end
        else
          return nil
        end
      end

      function ret.write(...)
        if not closed then
          if watcher.onWrite then
            return watcher.onWrite(self, ...)
          else
            return nil
          end
        else
          return nil
        end
      end

      function ret.close()
        if watcher.onClose then
          return watcher.onClose(self)
        end
        closed = true
      end

      function ret.flush()
        if watcher.onFlush then
          return watcher.onFlush(self)
        end
      end
    elseif mode == 'a' then
      local closed = false

      function ret.writeLine(...)
        if not closed then
          if watcher.onWriteLineA then
            return watcher.onWriteLineA(self, ...)
          else
            return nil
          end
        else
          return nil
        end
      end

      function ret.write(...)
        if not closed then
          if watcher.onWriteA then
            return watcher.onWriteA(self, ...)
          else
            return nil
          end
        else
          return nil
        end
      end

      function ret.close()
        if watcher.onClose then
          return watcher.onClose(self)
        end
        closed = true
      end

      function ret.flush()
        if watcher.onFlush then
          return watcher.onFlushA(self)
        end
      end
    end
    return ret
  end
  fs.addVirtual(path, object)

  return watcher
end

return _unique

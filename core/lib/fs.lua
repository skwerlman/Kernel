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
function _unique.register(n, t)
  _unique._registers[n] = t
end

function _unique.unregister(n, t)
  _unique._registers[n] = t
end

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

function _unique.isVirtual(p)
  if not p then
    return false
  else
    if p:sub(1,1) == '/' then
      return virtuals[p] ~= nil
    else
      return virtuals['/' .. p] ~= nil
    end
  end
end

function _unique.getVirtual(p)
  if p:sub(1,1) == '/' then
    return virtuals[p]
  elseif virtuals[p] then
    return virtuals[p]
  else
    return virtuals['/' .. p]
  end
end

function _unique.addVirtual(p, n)
  if not virtuals[p] then
    virtuals[p] = n
  end
end

function _unique.callVirtual(p, f, ...)
  if _unique.getVirtual(p) and _unique.getVirtual(p)[f] then
    return _unique.getVirtual(p)[f](_unique.getVirtual(p), p, ...)
  else
    return {}
  end
end

function _unique.removeVirtual(p)
  if virtuals[p] then virtuals[p] = nil end
end

function _unique.list(path)
  local ret = {}
  if path == '' then
    path = '/'
  end
  for k, v in pairs(virtuals) do
    local dir = _unique.getDir(k) == '' and '/' or _unique.getDir(k)
    if dir == path then
      if oldfs.getDir(k) == dir then
        k = k:gsub(oldfs.getDir(k), '')
      end
      table.insert(ret, k)
    end
  end

  if not fs.isVirtual(path) then
    for k, v in pairs(_unique.callFunctionInOwnerFor(path, 'list')) do
      table.insert(ret, v)
    end
  else
    if _unique.getVirtual(path).list then
      for k, v in pairs(_unique.callVirtual(path, 'list')) do
        table.insert(ret, v)
      end
    end
  end

  return ret
end

function _unique.exists(p)
  if _unique.isVirtual(p) then
    return true
  end
  return _unique.callFunctionInOwnerFor(p, 'exists')
end

function _unique.isDir(p)
  if _unique.isVirtual(p) then
    if type(_unique.getVirtual(p).isDir) == 'function' then
      return _unique.callVirtual(p, 'isDir')
    elseif type(_unique.getVirtual(p).isDir) == 'boolean' then
      return _unique.getVirtual(p).isDir
    end
  end
  return _unique.callFunctionInOwnerFor(p, 'isDir')
end

function _unique.isReadOnly(p)
  if _unique.isVirtual(p) then
    if type(_unique.getVirtual(p).isReadOnly) == 'function' then
      return _unique.callVirtual(p, 'isReadOnly')
    elseif type(_unique.getVirtual(p).isReadOnly) == 'boolean' then
      return _unique.getVirtual(p).isReadOnly
    end
  end
  if p == 'kernel' then
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

function _unique.getName(p)
  return split(p, '/')[#(split(p, '/'))]
end

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

function _unique.getFreeSpace(p)
  if _unique.isVirtual(p) then
    return _unique.callVirtual(p, 'getFreeSpace')
  end

  return _unique.callFunctionInOwnerFor(p, 'getFreeSpace')
end

function _unique.makeDir(p)
  if not _unique.exists(p) then
    return _unique.callFunctionInOwnerFor(p, 'makeDir')
  end
end

function _unique.move(p, e)
  if _unique.isVirtual(p) and not _unique.exists(e) then
    return _unique.callVirtual(p, 'move', e)
  end

  return _unique.callFunctionInOwnerFor(p, 'move', e)
end

function _unique.copy(p, e)
  if _unique.isVirtual(p) and not _unique.exists(e) then
    return _unique.callVirtual(p, 'copy', e)
  end

  return _unique.callFunctionInOwnerFor(p, 'copy', e)
end

function _unique.delete(p)
  if _unique.isVirtual(p) then
    return _unique.callVirtual(p, 'delete')
  end

  if not _unique.exists(p) and not _unique.isReadOnly(p) then
    return _unique.callFunctionInOwnerFor(p, 'delete')
  end
end

function _unique.combine(p1, p2)
  return oldfs.combine(p1, p2)
end

function _unique.open(path, mode)
  if _unique.isVirtual(path) then
    return _unique.callVirtual(path, 'open', mode)
  end

  if _unique.exists(path) then
    return _unique.callFunctionInOwnerFor(path, 'open', mode)
  else
    printError('vfs: file ' .. path .. ' does not exist.')
  end
end

function _unique.find(wild)
  return oldfs.find(wild)
end

function _unique.getDir(p)
  return oldfs.getDir(p)
end

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

local fs = setmetatable({}, {
  ['__index'] = function(_, k)
    return rawget(_unique, k) or oldfs[k]
  end
})


return fs

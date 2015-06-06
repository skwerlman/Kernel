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

_unique = {}

_unique._registers = {}

function _unique.register(n, t)
  rawget(_unique, '_registers')[n] = t
end

function _unique.unregister(n, t)
  rawget(_unique, '_registers')[n] = t
end

function _unique.list(p)
  for k, v in pairs(_unique._registers) do
    if v.isOwnerOf and v.list then
      if v:isOwnerOf(p) then
        return v:list(p)
      end
    end
  end

  return oldfs.list(p) -- fallback to ccfs
end

function _unique.exists(p)
  for k, v in pairs(_unique._registers) do
    if v.isOwnerOf and v.exists then
      if v:isOwnerOf(p) then
        return v:exists(p)
      end
    end
  end

  return oldfs.exists(p) -- fallback to ccfs
end

function _unique.isDir(p)
  for k, v in pairs(_unique._registers) do
    if v.isOwnerOf and v.isDir then
      if v:isOwnerOf(p) then
        return v:isDir(p)
      end
    end
  end

  return oldfs.isDir(p) -- fallback to ccfs
end

function _unique.isReadOnly(p)
  for k, v in pairs(_unique._registers) do
    if v.isOwnerOf and v.isReadOnly then
      if v:isOwnerOf(p) then
        return v:isReadOnly(p)
      end
    end
  end

  return oldfs.isReadOnly(p) -- fallback to ccfs
end

function _unique.getName(p)
  for k, v in pairs(_unique._registers) do
    if v.isOwnerOf and v.getName then
      if v:isOwnerOf(p) then
        return v:getName(p)
      end
    end
  end

  return oldfs.getName(p)
end

function _unique.getDrive(p)
  for k, v in pairs(_unique._registers) do
    if v.isOwnerOf and v.getDrive then
      if v:isOwnerOf(p) then
        return v:getDrive(p)
      end
    end
  end

  return oldfs.getDrive(p)
end

function _unique.getSize(p)
  for k, v in pairs(_unique._registers) do
    if v.isOwnerOf and v.getSize then
      if v:isOwnerOf(p) then
        return v:getSize(p)
      end
    end
  end

  return oldfs.getSize(p)
end

function _unique.getFreeSpace(p)
  for k, v in pairs(_unique._registers) do
    if v.isOwnerOf and v.getFreeSpace then
      if v:getFreeSpace(p) then
        return v:getFreeSpace(p)
      end
    end
  end

  return oldfs.getFreeSpace(p)
end

function _unique.makeDir(p)
  for k, v in pairs(_unique._registers) do
    if v.canMakeDir and v.makeDir then
      if v:canMakeDir(p) then
        return v:makeDir(p)
      end
    end
  end

  return oldfs.makeDir(p)
end

function _unique.move(s, t)
  for k, v in pairs(_unique._registers) do
    if v.isOwnerOf and v.canMoveTo and v.move then
      if v:isOwnerOf(s) and v:canMoveTo(t) then
        return v:move(s, t)
      end
    end
  end

  return oldfs.move(s, t)
end

function _unique.copy(s, t)
  for k, v in pairs(_unique._registers) do
    if v.isOwnerOf and v.canCopyTo and v.move then
      if v:isOwnerOf(s) and v:canCopyTo(t) then
        return v:canCopyTo(s, t)
      end
    end
  end

  return oldfs.move(s, t)
end

function _unique.delete(s)
  for k, v in pairs(_unique._registers) do
    if v.isOwnerOf and v.delete then
      if v:isOwnerOf(s) and v.delete then
        return v:delete(s)
      end
    end
  end

  return oldfs.delete(s)
end

function _unique.combine(s, t)
  if s:sub(#s, #s) == '/' then
    return s .. t
  else
    return s .. '/' .. t
  end
end

function _unique.open(p, m)
  for k, v in pairs(_unique._registers) do
    if v.isOwnerOf and v.open then
      if v:isOwnerOf(p) then
        return v:open(p, m)
      end
    end
  end

  return oldfs.open(p, m)
end

function _unique.find(wild)
  for k, v in pairs(_unique._registers) do
    if v.find then
      return v:find(wild)
    end
  end

  return oldfs.find(wild)
end

function _unique.getDir(wild)
  for k, v in pairs(_unique._registers) do
    if v.getDir then
      return v:getDir(wild)
    end
  end

  return oldfs.getDir(wild)
end

local fs = setmetatable({}, {
  ['__index'] = function(_, k)
    return rawget(_unique, k)
  end
})

return fs

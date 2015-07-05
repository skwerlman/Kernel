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

local lambda = {}

-- character table string
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- encoding
function enc(data)
    return ((data:gsub('.', function(x)
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

-- decoding
function dec(data)
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

lambda.magic = {
  200, 76, 65, 77, 66, 68, 65, 10
}
lambda.sep = 255
lambda.startSectHead = 230
lambda.endSectHead = 231
lambda.endSectData = 232

local function equ(ta, tb)
  for i = 1, #ta do
    if ta[i] ~= tb[i] then
      return false
    end
  end
  return true
end

function lambda.isLambda(path)
  local file = fs.open(path, 'rb')
  if file then
    local d = lambda.readTable(file, #lambda.magic)
    if equ(lambda.magic, d) then
      return true
    else
      return false
    end
  else
    return false
  end
end

function lambda.readUntil(handle, byt)
  local ret = ''

  local byte = handle.read()
  repeat
    if byte then
      if byte <= 127 and byte ~= byt then
        ret = ret .. string.char(byte)
      elseif byte == byt then
        return ret
      end

      byte = handle.read()
    end
  until byte == nil

  return ret
end

function lambda.writeMagic(handle)
  for i = 1, #lambda.magic do
    handle.write(lambda.magic[i])
  end
end

function lambda.writeString(handle, s)
  for i = 1, #s do
    handle.write(s:sub(i, i):byte())
  end
end

function lambda.readString(handle, len, off)
  local ret = ''
  if off then
    for i = 1, off do
      handle.read()
    end
  end

  for i = 1, len do
    local byte = handle.read()
    if byte <= 127 and byte ~= ter then
      ret = ret .. string.char(byte)
    elseif i <= 127 and byte ~= ter then
      ret = '' .. ret
    elseif byte == ter then
      break
    end
  end

  return ret
end

function lambda.readTable(handle, len, off)
  local ret = {}
  if off then
    for i = 1, off do
      handle.read()
    end
  end

  for i = 1, len do
    local byte = handle.read()
    if byte == ter then
      break
    else
      ret[i] = byte
    end
  end

  return ret
end

function lambda.writeTable(handle, dat)
  for i = 1, #dat do
    handle.write(dat[i])
  end
end

function lambda.writeSection(handle, name, content)
  local data = {
    lambda.startSectHead,
    string.byte('.')
  }
  for i = 1, #name do
    table.insert(data, name:sub(i, i):byte())
  end
  table.insert(data, lambda.endSectHead)

  for i = 1, #content do
    table.insert(data, content:sub(i, i):byte())
  end

  table.insert(data, lambda.endSectData)
  table.insert(data, string.byte('\n'))

  lambda.writeTable(handle, data)
end

function lambda.readSection(handle)
  lambda.readUntil(handle, lambda.startSectHead)
  local name = lambda.readUntil(handle, lambda.endSectHead)
  local data = lambda.readUntil(handle, lambda.endSectData)

  return name:sub(2, #name), data
end

function lambda.writeHeader(handle)
  lambda.writeTable(handle, lambda.magic)
  lambda.writeSection(handle, 'lambda.version', '0.1')
  lambda.writeSection(handle, 'lambda.emitter', 'tardix')
end

function lambda.writeFunction(handle, nam, fn)
  lambda.writeSection(handle, 'text.' .. nam, enc(string.dump(fn)))
end

function lambda.readFunction(handle)
  local nam, fn = lambda.readSection(handle)
  if nam:sub(1, #('text.')) == 'text.' then
    return loadstring(dec(fn)), nam:sub(#('text.'), #nam)
  end
end

local olfile = loadfile

function loadfile(file)
  if lambda.isLambda(file) then
    local d = fs.open(file, 'rb')
    local _, __, ___, ____ = lambda.readSection(d), lambda.readSection(d)
    local fn, nam = lambda.readFunction(d)
    if nam == '.start' then
      return fn
    else
      repeat
        fn, nam = lambda.readFunction(d)
      until nam == '.start'
      return fn
    end
  else
    local ok = olfile(file)
    setfenv(ok, _G)
    return ok
  end
end

return lambda

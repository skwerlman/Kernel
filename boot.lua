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
--[[
Set up an environment for the kernel,
dynamic link it into memory,
run it.
]]


local kcmdline = table.concat({...}, ' ')

local function split(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t={} ; i=1
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    t[i] = str
    i = i + 1
  end
  return t
end

local _cmdlin1 = split(kcmdline, ' ')
local pcmdline = {}

for k, v in pairs(_cmdlin1) do
  if #split(v, '=') == 2 then
    local i, j = unpack(split(v, '='))
    if #split(j, ',') >= 2 then
      local x = split(j, ',')
      pcmdline[i] = x
    else
      pcmdline[i] = j
    end
  else
    pcmdline[v] = true
  end
end

function string.randomize(template)
	return string.gsub(template, '[xy]', function (c)
	local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
		return string.format('%x', v)
	end)
end


----------------------------------------------------------------------------------------------------------

local kRoot = pcmdline['kernel_root']

if fs.exists(fs.combine(kRoot, '/core/lib')) then
  for k,v in pairs(fs.list(fs.combine(kRoot, '/core/lib'))) do
    local ok, err = loadfile(fs.combine(fs.combine(kRoot, '/core/lib'), v))

    if not ok then
      printError(err)
    else
      _G[({v:gsub('.lua', '')})[1]] = ok()
    end
  end
end

if fs.exists(fs.combine(kRoot, '/core/mod')) then
  if not pcmdline['nomods'] and module and fs.exists(fs.combine(kRoot, '/core/mod')) then
    for k,v in pairs(fs.list(fs.combine(kRoot, '/core/mod'))) do
      loadfile(fs.combine(fs.combine(kRoot, '/core/mod'), v))()
    end
    module.probeAll('load')
  elseif pcmdline['nomods'] and pcmdline['loadmods'] and module and fs.exists(fs.combine(kRoot, '/core/mod')) then
    for k,v in pairs(fs.list(fs.combine(kRoot, '/core/mod'))) do
      loadfile(fs.combine(fs.combine(kRoot, '/core/mod'), v))()
    end
    for k, v in pairs(pcmdline['loadmods']) do
      module.probe(v, 'load')
    end
  end
end

function kreq(path)
  return loadfile(fs.combine(kRoot, path))()
end


if exec then
  local inits = {
    '/init',
    '/sbin/init',
    '/bin/init',
    '/lib/init',
    '/usr/init',
    '/usr/sbin/init',
    '/usr/bin/init',
    '/usr/lib/init',
    '/init.lua',
    '/sbin/init.lua',
    '/bin/init.lua',
    '/lib/init.lua',
    '/usr/init.lua',
    '/usr/sbin/init.lua',
    '/usr/bin/init.lua',
    '/usr/lib/init.lua',
  }

  for i = 1, #inits do
    if fs.exists(inits[i]) then
      spawn(inits[i])
      break
    end
  end
else
  local inits = {
    '/init',
    '/sbin/init',
    '/bin/init',
    '/lib/init',
    '/usr/init',
    '/usr/sbin/init',
    '/usr/bin/init',
    '/usr/lib/init',
    '/init.lua',
    '/sbin/init.lua',
    '/bin/init.lua',
    '/lib/init.lua',
    '/usr/init.lua',
    '/usr/sbin/init.lua',
    '/usr/bin/init.lua',
    '/usr/lib/init.lua',
  }


  for i = 1, #inits do
    if fs.exists(inits[i]) then
      dofile(inits[i])
      break
    end
  end
end


exec(fs.combine(kRoot, '/core/kthread.lua'))

if fs.exists(fs.combine(kRoot, '/core/events')) then
  for k, v in pairs(fs.list(fs.combine(kRoot, '/core/events'))) do
    kthread.addFile(fs.combine(fs.combine(kRoot,'/core/events'), v))
  end
end

while true do
  if threading then
    local data = {coroutine.yield()}
    if data[1] == 'terminate' then
      error()
    end
    threading.scheduler:update(unpack(data))
  end
end

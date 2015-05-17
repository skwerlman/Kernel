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

term.setCursorPos(1,1)
term.clear()

local kcmdline = table.concat({...}, ' ')

local function split(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t={} ; i=1
  for str in string.gmatch(inputstr, '([^'..sep..']+)') do
    t[i] = str
    i = i + 1
  end
  return t
end

local _cmdlin1 = split(kcmdline, ' ')
_G.kernelcmd = {}

for k, v in pairs(_cmdlin1) do
  if #split(v, '=') == 2 then
    local i, j = unpack(split(v, '='))
    if #split(j, ',') >= 2 then
      local x = split(j, ',')
      kernelcmd[i] = x
    else
      kernelcmd[i] = j
    end
  else
    kernelcmd[v] = true
  end
end

function string.randomize(template)
	return string.gsub(template, '[xy]', function (c)
	local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
		return string.format('%x', v)
	end)
end

function table.size(tab)
  local ret = 0
  for k, v in pairs(tab) do ret = ret + 1 end
  return ret
end

----------------------------------------------------------------------------------------------------------
_G.kRoot = kernelcmd['kernel_root']

if fs.exists(fs.combine(kRoot, '/core/lib')) then
  for k, v in pairs(fs.list(fs.combine(kRoot, '/core/lib'))) do
    if not fs.isDir(fs.combine(fs.combine(kRoot, '/core/lib'), v)) then
      local ok, err = loadfile(fs.combine(fs.combine(kRoot, '/core/lib'), v))

      if not ok then
        printError(err)
      else
        _G[({v:gsub('.lua', '')})[1]] = ok()
      end
    end
  end
end

if fs.exists(fs.combine(kRoot, '/core/lib/init')) then
  _G.init = {}
  for k, v in pairs(fs.list(fs.combine(kRoot, '/core/lib/init'))) do
    local ok, err = loadfile(fs.combine(fs.combine(kRoot, '/core/lib/init'), v))
    if not ok then
      printError(err)
    else
      _G.init[({v:gsub('.lua', '')})[1]] = ok()
    end
  end
end

if fs.exists(fs.combine(kRoot, '/core/mod')) then
  if not kernelcmd['nomods'] and module and fs.exists(fs.combine(kRoot, '/core/mod')) then
    for k, v  in pairs(fs.list(fs.combine(kRoot, '/core/mod'))) do
      loadfile(fs.combine(fs.combine(kRoot, '/core/mod'), v))()
    end
    module.probeAll('load')
  elseif kernelcmd['nomods'] and kernelcmd['loadmods'] and module and fs.exists(fs.combine(kRoot, '/core/mod')) then
    for k, v in pairs(fs.list(fs.combine(kRoot, '/core/mod'))) do
      loadfile(fs.combine(fs.combine(kRoot, '/core/mod'), v))()
    end
    for k, v in pairs(kernelcmd['loadmods']) do
      module.probe(v, 'load')
    end
  end
end

function kreq(path)
  return loadfile(fs.combine(kRoot, path))()
end


if run.exec then
  if kernelcmd['initrfs'] then
    local initf = init.initrfs.loadinitrfs(kernelcmd['initrfs'])
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
      if initf.files and initf.files[inits[i]] then
        run.spawn(init.initrfs.loadfileFrom(initf, inits[i]))
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
        run.spawn(inits[i])
        break
      end
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

_G.kthread = {
  ['hans'] = {}
}

function kthread.addFunctions(tab)
  assert(type(tab) == 'table', 'kthread.addFunctions expects a table of functions')
  for k, v in pairs(tab) do
    assert(type(v) == 'function', 'kthread.addFunctions expects a table of functions')
    table.insert(kthread.hans, v)
  end
end

function kthread.getHandlers()
  return kthread.hans
end


function kthread.addFile(file)
  local ok, err = loadfile(file)
  if not ok then
    error(err)
  end
  kthread.addFunctions(run.dailin.link(ok))
end

run.exec(fs.combine(kRoot, '/core/kthread.lua'))

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

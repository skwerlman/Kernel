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


local function split(inputstr, sep)
  sep = sep or "%s"
  local t={} ; i=1
  for str in string.gmatch(inputstr, '([^'..sep..']+)') do
    t[i] = str
    i = i + 1
  end
  return t
end

local _cmdlin1 = split(table.concat({...}, ' '), ' ')
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

function table.from(tab, start)
  local ret = {}
  for i = start, #tab do
    ret[#ret + 1] = tab[i]
  end
  return ret
end

function table.filter(tab, fun)
  local ret = {}

  for k, v in pairs(tab) do
    if fun(k, v) == true then
      table.insert(ret, v)
    end
  end

  return ret
end

function table.foreach(tab, fun)
  local ret = {}

  for k, v in pairs(tab) do
    ret[k] = fun(k, v)
  end

  return ret
end

function table.join(...)
  local ret = {}

  for i, j in ipairs({...}) do
    if type(j) == 'table' then
      for k, v in pairs(j) do
        ret[k] = v
      end
    else
      ret[i] = j
    end
  end

  return ret
end


----------------------------------------------------------------------------------------------------------
_G.kRoot = kernelcmd['kernel_root']


local ok, err = loadfile(fs.combine(kRoot, '/core/kmessage.lua'))
if not ok then
  printError(err)
  while true do
    coroutine.yield()
  end
end

_G.kmsg = ok()

local ok, err = loadfile(fs.combine(kRoot, '/core/filesys.lua'))
if not ok then
  printError(err)
  while true do
    coroutine.yield()
  end
end

_G.fs = ok()


kmsg.post('core', 'tardix kernel attempting initialization now')

if fs.exists(fs.combine(kRoot, '/core/lib')) then
  for k, v in ipairs(fs.list(fs.combine(kRoot, '/core/lib'))) do
    if not fs.isDir(fs.combine(fs.combine(kRoot, '/core/lib'), v)) then
      local ok, err = loadfile(fs.combine(fs.combine(kRoot, '/core/lib'), v))
      kmsg.post('core', 'loaded library %s.', v)
      if not ok then
        printError(err)
      else
        local ok, val = pcall(ok)
        if ok then
          _G[({string.gsub(v, '.lua', '')})[1]] = val
        else
          printError('failed to load library ' .. v .. ': ' .. val)
          while true do
            sleep(0)
          end
        end
      end
    end
  end
end

if fs.exists(fs.combine(kRoot, '/core/filesys')) then
  for k, v in ipairs(fs.list(fs.combine(kRoot, '/core/filesys'))) do
    if not fs.isDir(fs.combine(fs.combine(kRoot, '/core/filesys'), v)) then
      local ok, err = loadfile(fs.combine(fs.combine(kRoot, '/core/filesys'), v))
      kmsg.post('core', 'loaded filesystem %s.', v)
      if not ok then
        printError(err)
      else
        local ok, val = pcall(ok)
        if ok then
          fs.register(({string.gsub(v, '.lua', '')})[1], val)
        else
          printError('failed to load library ' .. v .. ': ' .. val)
          while true do
            sleep(0)
          end
        end
      end
    end
  end
end

if fs.exists(fs.combine(kRoot, '/core/mount')) then
  for k, v in ipairs(fs.list(fs.combine(kRoot, '/core/mount'))) do
    if not fs.isDir(fs.combine(fs.combine(kRoot, '/core/mount'), v)) then
      local ok, err = loadfile(fs.combine(fs.combine(kRoot, '/core/mount'), v))
      kmsg.post('core', 'loaded mount %s.', v)
      if not ok then
        printError(err)
      else
        local ok, val = pcall(ok)
        if ok then
          fs.mount(({string.gsub(v, '.lua', '')})[1], val)
        else
          printError('failed to load mount ' .. v .. ': ' .. val)
          kmsg.post('core', 'failed to load mount ' .. v .. ': ' .. val)
          while true do
            sleep(0)
          end
        end
      end
    end
  end
end


if fs.exists(fs.combine(kRoot, '/core/lib/init')) then
  _G.init = {}
  for k, v in ipairs(fs.list(fs.combine(kRoot, '/core/lib/init'))) do
    local ok, err = loadfile(fs.combine(fs.combine(kRoot, '/core/lib/init'), v))
    if not ok then
      printError(err)
    else
      kmsg.post('core', 'loaded initialization library %s', v)
      _G.init[({v:gsub('.lua', '')})[1]] = ok()
    end
  end
end

if fs.exists(fs.combine(kRoot, '/core/mod')) then
  if not kernelcmd['nomods'] and module and fs.exists(fs.combine(kRoot, '/core/mod')) then
    for k, v  in ipairs(fs.list(fs.combine(kRoot, '/core/mod'))) do
      loadfile(fs.combine(fs.combine(kRoot, '/core/mod'), v))()
    end
    module.probeAll('load')
  elseif kernelcmd['nomods'] and kernelcmd['loadmods'] and module and fs.exists(fs.combine(kRoot, '/core/mod')) then
    for k, v in ipairs(fs.list(fs.combine(kRoot, '/core/mod'))) do
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

kmsg.post('init', 'searching for init')
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
        kmsg.post('init', 'found init %s in a initrfs %s', kernelcmd['initrfs'], inits[i])
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
        kmsg.post('init', 'found init %s in root', inits[i])
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
      kmsg.post('init', 'found init %s, initialized sequencially', inits[i])
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
kmsg.post('kthread', 'starting kernel thread')
run.exec(fs.combine(kRoot, '/core/kthread.lua'))

if fs.exists(fs.combine(kRoot, '/core/events')) then
  for k, v in ipairs(fs.list(fs.combine(kRoot, '/core/events'))) do
    kmsg.post('kthread', 'added event handler %s', v)
    kthread.addFile(fs.combine(fs.combine(kRoot,'/core/events'), v))
  end
end

kmsg.post('core', 'completed initialization; starting main loop.')

while true do
  if threading then
    local data = {coroutine.yield()}
    threading.scheduler:update(unpack(data))
  end
end

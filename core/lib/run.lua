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

local run = {}

run.dailin = {}
local function doFindFncs(fnc)
  local env = {}
  setmetatable(env, {['__index'] = _G})

  setfenv(fnc, env)
  local ok, val = pcall(fnc)
  if ok then
    if not val then
      local ret = {}
      for k, v in pairs(env) do
        if type(v) == 'function' then
          ret[k] = v
        end
      end
      return ret
    else
      return val
    end
  else
    error(err)
  end
end

function run.dailin.link(fof)
  return doFindFncs((type(fof) == 'string' and
    loadfile(fof) or (type(fof) == 'function' and fof or function() end)))
end


local function doExec(src, fn, ...)
  local env = {}
  local renv = setmetatable( {}, {
    __index = function( _, k )
      return env[k] and env[k] or getfenv(2)[k]
    end,
    __newindex = function( _, k, v )
      env[k] = v
    end
  } )

  if threading then
    if getfenv(2).threading.this then
      env.threading.this = getfenv(2).threading.this:spawnSubprocess(src)
    elseif threading.scheduler then
      env.threading = threading
      env.threading.this = threading.scheduler:spawnSubprocess(src)
    end
  end

  env._FILE = src

  setfenv(fn, renv)
  local ret, err = pcall(fn, ...)

  if not ret then
    error(err, 2)
  end
end

local function doLoad(fil)
  return loadfile(fil)
end

function run.exec(file, ...)
  return doExec(file, run.dailin.link(file)['main'], ...) or false
end

function run.spawn(fileOrFunc)
  if threading then -- spawn a thread
    if type(fileOrFunc) == 'string' then
      if getfenv(2).threading and getfenv(2).threading.this then
        return getfenv(2).threading.this:spawnThread(run.dailin.link(fileOrFunc)['main'] or error('failed ' .. fileOrFunc), fileOrFunc)
      else
        return threading.scheduler:spawnThread(run.dailin.link(fileOrFunc)['main'] or error('failed ' .. fileOrFunc), fileOrFunc)
      end
    elseif type(fileOrFunc) == 'function' then
      if getfenv(2).threading and getfenv(2).threading.this then
        return getfenv(2).threading.this:spawnThread(fileOrFunc, fileOrFunc)
      else
        return threading.scheduler:spawnThread(fileOrFunc, fileOrFunc)
      end
    end
  else -- run directly one time
    local toRun = (type(fileOrFunc) == 'string' and loadfile(fileOrFunc) or fileOrFunc)
    local wrap = coroutine.wrap(toRun)
    wrap()
  end
end

function run.spawnp(fof)
  local toRun = (type(fof) == 'string' and
    loadfile(fof) or (type(fof) == 'function' and fof or function() end))

  if threading then
    local newp = (((getfenv(2).threading and getfenv(2).threading.this) and
      getfenv(2).threading.this:spawnSubprocess(tostring(fof)) or threading.scheduler:spawnSubprocess(tostring(fof))))
    local thread = newp:spawnThread(toRun, tostring(toRun))

    if getfenv(2).threading.this then
      thread.environment.threading.this = getfenv(2).threading.this:spawnSubprocess(src)
    elseif threading.scheduler then
      thread.environment.threading = threading
      thread.environment.threading.this = threading.scheduler:spawnSubprocess(src)
    end

    return newp
  else
    return false
  end
end

function run.require(file)
  for k, v in pairs({'/usr/lib/', '/lib/', getfenv(2)._FILE and fs.getDir(getfenv(2)._FILE) or '/usr/lib'}) do
    if fs.exists(fs.combine(v, file)) then
      return run.dailin.link(fs.combine(v, file))
    elseif fs.exists(fs.combine(v, file) .. '.lua') then
      return run.dailin.link(fs.combine(v, file) .. '.lua')
    end
  end
end

--_G.require = run.require


return run

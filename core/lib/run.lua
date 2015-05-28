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
local function doFindFncs(fnc, envars)
  local env = {}
  local oenv = envars

  setmetatable(env, {['__index'] = function( _, k )
    if oenv and oenv[k] then
      return oenv[k]
    elseif envars and envars[k] then
      return envars[k]
    else
      return getfenv(2)[k]
    end
  end})

  setfenv(fnc, env)
  local ok, val = pcall(fnc)
  if not ok then
    error(val, 4)
  end
  if ok then
    if not val then
      local ret = {}
      for k, v in pairs(env) do
        ret[k] = v
      end
      return ret
    else
      return val
    end
  else
    error(val)
  end
end

function run.dailin.link(fof, env)
  if type(fof) == 'string' then
    local ok, err = loadfile(fof)
    if not ok then
      printError(err)
      return
    end
    return doFindFncs(ok, env)
  elseif type(fof) == 'function' then
    return doFindFncs(fof, env)
  else
    return
  end
end


local function doExec(envars, src, fn, ...)
  local env = {}
  local renv = setmetatable( {}, {
    __index = function( _, k )
      return env[k] and env[k] or envars[k] and envars[k] or getfenv(2)[k]
    end,
    __newindex = function( _, k, v )
      env[k] = v
    end
  } )

  if threading then
    if getfenv(2).threading.this then
      env.threading = getfenv(2).threading
      env.threading.this = getfenv(2).threading.this:spawnSubprocess(src)
    elseif threading.scheduler then
      env.threading = getfenv(2).threading
      env.threading.this = threading.scheduler:spawnSubprocess(src)
    end
  end

  env._FILE = src

  setfenv(fn, renv)
  local data, val = pcall(fn, ...)

  if not data then
    printError(val)
  end

  return val
end

local function doLoad(fil)
  return loadfile(fil)
end

function run.exec(file, ...)
  if fs.exists(file) then
    local mFn = run.dailin.link(file)
    if not mFn['main'] then
      printError('in file ' .. file .. ': failed to execute. no public main function. Existing functions are:')
    else
      return doExec(mFn, file, mFn['main'], ...) or false
    end
  end
end

function run.exece(env, file, ...)
  if fs.exists(file) then
    local mFn = run.dailin.link(file, env)
    if not mFn or not mFn['main'] then
      printError('in file ' .. file .. ': failed to execute. no public main function. Existing functions are:')
    else
      local p = setmetatable({}, {
        ['__index'] = function(_, k)
          return (rawget(mFn, k) or
          rawget(env, k))
        end
      })

      return doExec(p, file, mFn['main'], ...) or false
    end
  end
end

function run.spawn(fileOrFunc)
  if threading then -- spawn a thread
    if type(fileOrFunc) == 'string' then
      if getfenv(2).threading and getfenv(2).threading.this then
        return getfenv(2).threading.this:spawnThread(run.dailin.link(fileOrFunc)['main'] or error('failed to start ' .. fileOrFunc .. ' because there is no public main function.'), fileOrFunc)
      else
        return threading.scheduler:spawnThread(run.dailin.link(fileOrFunc)['main'] or error('failed to start ' .. fileOrFunc .. ' because there is no public main function.'), fileOrFunc)
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
    elseif fs.exists(fs.combine(v, 'lib' .. file)) then
      return run.dailin.link(fs.combine(v, 'lib' .. file))
    elseif fs.exists(fs.combine(v, 'lib' .. file .. '.lua')) then
      return run.dailin.link(fs.combine(v, 'lib' .. file .. '.lua'))
    end
  end
  if fs.exists(fs.combine('/', file)) then
    return run.dailin.link(fs.combine('/', file))
  elseif fs.exists(fs.combine('/', file) .. '.lua') then
    return run.dailin.link(fs.combine('/', file) .. '.lua')
  end
end

--_G.require = run.require


return run

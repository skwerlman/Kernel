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

local function doFindMain(src, fnc)
  local env = {}
  setmetatable(env, {["__index"] = _G})

  setfenv(fnc, env)
  pcall(fnc)

  if not env.main or not type(env.main) == 'function' then
    error('no public main function ' .. src, 2)
  else
    return env.main
  end
end

return function(file, ...)
  doExec(file, doFindMain(file, doLoad(file)), ...)
end
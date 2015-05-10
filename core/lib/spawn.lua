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
local function doFindMain(fnc)
  local env = {}
  setmetatable(env, {["__index"] = _G})

  setfenv(fnc, env)
  pcall(fnc)

  if not env.main or not type(env.main) == 'function' then
    error('no public main function', 2)
  else
    return env.main
  end
end

return function(fileOrFunc)
  if threading then -- spawn a thread
    if type(fileOrFunc) == 'string' then
      if getfenv(2).threading and getfenv(2).threading.this then
        return getfenv(2).threading.this:spawnThread(doFindMain(loadfile(fileOrFunc)), fileOrFunc)
      else
        return threading.scheduler:spawnThread(doFindMain(loadfile(fileOrFunc)), fileOrFunc)
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
end

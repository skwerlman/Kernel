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
local kthread = {
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

local function doFindFncs(fnc)
  local env = {}
  setmetatable(env, {['__index'] = _G})

  setfenv(fnc, env)
  pcall(fnc)
  local ret = {}
  for k, v in pairs(env) do
    if type(v) == 'function' then
      table.insert(ret, v)
    end
  end
  return ret
end

function kthread.addFile(file)
  local ok, err = loadfile(file)
  if not ok then
    error(err)
  end
  kthread.addFunctions(doFindFncs(ok))
end

return kthread

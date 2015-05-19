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

local syscalls = {}

for k,v in pairs(fs.list(fs.combine(kRoot, '/core/syscalls'))) do
  local ok, err = loadfile(fs.combine(fs.combine(kRoot, '/core/syscalls'), v))

  if not ok then
    printError(err)
  else
    syscalls[({v:gsub('.lua', '')})[1]] = ok
  end
end

function catch(event, name, ...)
  if event == 'syscall' then
    if _G['tardix_sys_'..name] then
      _G['tardix_sys_'..name](...)
    elseif syscalls['sys_'..name] then
      syscalls['sys_'..name](...)
    elseif syscalls[name] then
      syscalls[name](...)
    else
      os.queueEvent('failure', {['emitter'] = 'syscall_kernel', msg = {'unknown', name}})
      printError('unknown ' .. name)
    end
  end
end

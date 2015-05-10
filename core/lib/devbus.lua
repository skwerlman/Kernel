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

local devbus = {}

function devbus.assign(name, fun)
  assert(type(name) == 'string', 'expected string, got ' .. type(name))
  assert(type(name) == 'table', 'expected table, got ' .. type(name))
  if not devbus.assigned then
    devbus.assigned = {
      [name] = devn
    }
    return true
  elseif devbus.assigned[name] then
    return false, 'already exists'
  elseif not devbus.assigned[name] then
    devbus.assigned[name] = devn
    return true
  end
end

function devbus.wrap(side)
  local name = peripheral.getType(side)
  if devbus.assigned and devbus.assigned[side] then
    return devbus.assigned[side]()
  else
    return peripheral.wrap(side)
  end
end

function devbus.call(side, fn, ...)
  local wrapd = devbus.wrap(side)
  wrapd[fn](wrapd, ...)
end

function devbus.getMethods(side)
  local wrapd = devbus.wrap(side)
  local ret = {}
  for k, v in pairs(wrapd) do
    table.insert(ret, k)
  end

  return ret
end

function devbus.hasDriver(side)
  return devbus.assigned and devbus.assigned[side]
end

function devbus.discover()
  local ret = {}
  for k, v in pairs(peripheral.getNames()) do
    ret[v] = {
      ['handle'] = devbus.wrap(v),
      ['methods'] = devbus.getMethods(v),
      ['hasDriver'] = devbus.hasDriver(v),
      ['call'] = function(fn, ...)
        return devbus.call(v, fn, ...)
      end
    }
  end

  return ret
end

return devbus

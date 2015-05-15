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
  return devbus.assigned ~= nil and
    devbus.assigned[side] ~= nil
end

function devbus.can(side, thing)
  for k, v in pairs(devbus.getMethods(side)) do
    if v == thing then
      return true
    end
  end
  return false
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
      end,
      ['can'] = function(thing)
        return devbus.can(v, thing)
      end,
      ['id'] = string.randomize and string.randomize('xxyy:xxyy-xxxx@xxyy') or 0
    }
  end

  return ret
end

local counts = {['chr'] = 0, ['cmp'] = 0, ['blk'] = 0}
local regist = {}

function devbus.populate()
  if fs.exists('/dev') then
    fs.delete('/dev')
  end

  local devices = devbus.discover()
  print('discovered ' .. table.size(devices) .. ' devices')
  local count = 0
  local function findDeviceType(side)
    return (peripheral.getType(side) == 'modem' or peripheral.getType(side) == 'monitor' or peripheral.getType(side) == 'printer') and 'chr' or
    (peripheral.getType(side) == 'turtle' or peripheral.getType(side) == 'computer') and 'cmp' or
    (peripheral.getType(side) == 'drive') and 'blk' or
    (peripheral.getType(side):sub(1, #"openperipheral") == "openperipheral") and 'opp' or
    ('unknown_type_' .. peripheral.getType(side))
  end


  for k, v in pairs(devices) do
    local nam = findDeviceType(k) .. tostring(count)
    local typ = findDeviceType(k)
    local dev_node = fs.open('/dev/' .. nam, 'w') do
      dev_node.write(('--@type=%s\n--@name=%s\n--@side=%s'):format(peripheral.getType(k), string.randomize('xxyy:xxyy-xxxx@xxyy'), k))
      devices[k].meta = {
        ['node_name'] = nam,
        ['raw_type'] = peripheral.getType(k),
        ['pro_type'] = typ,
        ['type_hum'] = (typ == 'chr' and 'Character Device')
          or (typ == 'cmp' and 'Computer Device')
          or (typ == 'blk' and 'Block Device')
          or (typ == 'opp' and 'OpenPeripherals Device')
          or 'Unrecognized Device'
       }
    end dev_node.close()
    count = count + 1
  end

  return devices
end

devbus.devices = devbus.populate()


return devbus

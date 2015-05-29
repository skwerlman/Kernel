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

local devbus = {assigned = {}}
local _peripheral = (function(tab)
  local ret = {}
  for k, v in pairs(tab) do
    ret[k] = v
  end

  return ret end)(getfenv(1).peripheral)


function devbus.assign(name, fun)
  os.queueEvent('devbus', 'assign', name, fun)

  assert(type(name) == 'string', 'expected string, got ' .. type(name))
  assert(type(fun) == 'function', 'expected function, got ' .. type(fun))
  devbus.assigned[name] = fun

  if devbus.update then
    devbus.update()
  end
end

function devbus.wrap(side)
  os.queueEvent('devbus', 'wrap', side)
  local name = _peripheral.getType(side)
  if devbus.assigned and devbus.assigned[name] then
    return devbus.assigned[name](side)
  else
    return _peripheral.wrap(side)
  end

end

function devbus.call(side, fn, ...)
  os.queueEvent('devbus', 'call', side, fn, {...})
  local wrapd = devbus.wrap(side)
  wrapd[fn](wrapd, ...)
end

function devbus.getMethods(side)
  os.queueEvent('devbus', 'getmethods', side)
  local wrapd = devbus.wrap(side)
  local ret = {}
  for k, v in pairs(wrapd) do
    table.insert(ret, k)
  end

  return ret
end

function devbus.getType(side)
  os.queueEvent('devbus', 'gettype', side)
  return _peripheral.getType(side)
end

function devbus.hasDriver(side)
  os.queueEvent('devbus', 'hasdriver', side)
  return devbus.assigned ~= nil and
    devbus.assigned[_peripheral.getType(side)] ~= nil
end

function devbus.can(side, thing)
  os.queueEvent('devbus', 'can', side, thing)
  for k, v in pairs(devbus.getMethods(side)) do
    if v == thing then
      return true
    end
  end
  return false
end

function devbus.discover()
  os.queueEvent('devbus', 'discover')

  local ret = {}
  for k, v in pairs(_peripheral.getNames()) do
    ret[v] = {
      ['side'] = v,
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

local regist = {}

function devbus.populate()
  os.queueEvent('devbus', 'populate')

  if fs.exists('/dev') then
    fs.delete('/dev')
  end
  local counts = {['chr'] = 0, ['cmp'] = 0, ['blk'] = 0, ['opp'] = 0, ['utp'] = 0}

  local devices = devbus.discover()
  local count = 0

  local function findDeviceType(side)
    return (_peripheral.getType(side) == 'modem' or _peripheral.getType(side) == 'monitor' or _peripheral.getType(side) == 'printer') and 'chr' or
    (_peripheral.getType(side) == 'turtle' or _peripheral.getType(side) == 'computer') and 'cmp' or
    (_peripheral.getType(side) == 'drive') and 'blk' or
    (_peripheral.getType(side):sub(1, #"openperipheral") == "openperipheral") and 'opp' or
    ('utp')
  end


  for k, v in pairs(devices) do
    local typ = findDeviceType(k)
    local nam = findDeviceType(k) .. tostring(counts[typ])

    local dev_node = fs.open('/dev/' .. nam, 'w') do
      dev_node.write(('--@type=%s\n--@name=%s\n--@side=%s\n\n--<<EOF>>\n\n'):format(_peripheral.getType(k), string.randomize('xxyy:xxyy-xxxx@xxyy'), k))
      dev_node.write('return devbus.device.byName(\''.. nam ..'\')')
      devices[k].meta = {
        ['node_name'] = nam,
        ['raw_type'] = _peripheral.getType(k),
        ['pro_type'] = typ,
        ['type_hum'] = ((typ == 'chr' and 'Character Device: ')
          or (typ == 'cmp' and 'Computer Device :')
          or (typ == 'blk' and 'Block Device: ')
          or (typ == 'opp' and 'OpenPeripherals Device: ')
          or 'Unrecognized Device: ') .. _peripheral.getType(k)
       }
      if _peripheral.getType(k) == 'modem' then
        if rednet and not rednet.isOpen() then
          rednet.open(k)
        end
      end
    end dev_node.close()
    counts[typ] = counts[typ] + 1
  end

  return devices
end

function devbus.isPresent(side)
  os.queueEvent('devbus', 'ispresent', side)
  if devbus.update then
    devbus.update()
  end
  return _peripheral.isPresent(side)
end

devbus.devices = devbus.populate()

devbus.device = {}

function devbus.device.byName(devn)
  if devbus.update then
    devbus.update()
  end
  for k, v in pairs(devbus.devices) do
    if v.meta.node_name == devn then
      return v
    end
  end
end

local function first(tab)
  for k, v in pairs(tab) do return v end
end

local function size(tab)
  local ret = 0; for k, v in pairs(tab) do ret = ret + 1 end; return ret
end


function devbus.device.allByType(typ)
  if devbus.update then
    devbus.update()
  end

  local ret = {}
  for k, v in pairs(devbus.devices) do
    if v.meta.pro_type == typ then
        ret[k] = v
    end
  end
  return ret
end

function devbus.device.firstByType(typ)
  if devbus.update then
    devbus.update()
  end
  return type(devbus.device.allByType(typ)) == 'table' and first(devbus.device.allByType(typ)).side or false
end

function devbus.device.allByRawType(typ)
  if devbus.update then
    devbus.update()
  end

  local ret = {}
  for k, v in pairs(devbus.devices) do
    if v.meta.raw_type == typ then
      ret[k] = v
    end
  end
  return ret
end

function devbus.device.firstByRawType(typ)
  if devbus.update then
    devbus.update()
  end

  return type(devbus.device.allByRawType(typ)) == 'table' and first(devbus.device.allByRawType(typ)).side or false
end

function devbus.update()
  if size(devbus.devices) ~= size(peripheral.getNames()) then
    devbus.devices = devbus.populate()
  end
end

function devbus.find(type, func)
  if devbus.update then
    devbus.update()
  end

  local ret = {}

  if func then
    for k, v in pairs(devbus.device.allByRawType(type)) do
      if func(v, devbus.wrap(v.side)) then
        table.insert(ret, v)
      end
    end
    return ret
  else
    for k, v in pairs(devbus.device.allByRawType(type)) do
      table.insert(ret, v)
    end
    return ret
  end
end

setmetatable(devbus, {
  ['__index'] = function(t, k)
    if not rawget(t, k) then
      return first(devbus.device.allByRawType(k))
    else
      return rawget(t, k)
    end
  end,
  ['__newindex'] = function(t, k, v) return end
})


return devbus

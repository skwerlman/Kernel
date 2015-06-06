--[[
The MIT License (MIT)

Copyright (c) 2014-2015 the TARDIX team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the 'Software'), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]

local tty = {}

local function _ttyopen(vobj, path, mode)
  local ret = {}
  if mode == 'w' then
    local buf = {}

    function ret.write(...)
      table.insert(buf, table.concat({...}))
    end

    function ret.writeLine(...)
      table.insert(buf, table.concat({..., '\n'}))
    end

    function ret.flush()
      for k, v in ipairs(buf) do
        vobj.obj.write(v)
      end
      buf = {}
    end

    function ret.close()
      ret.flush()
    end
  end
  return ret
end


local function _ttyioctl(vobj, path, request, ...)
  local params = {...}
  if request == 'getCursorPos' then
    return vobj.obj.getCursorPos()
  elseif request == 'setCursorPos' then
    return vobj.obj.setCursorPos(params[1], params[2])
  elseif request == 'clear' then
    return vobj.obj.clear()
  elseif request == 'setColors' then
    vobj.obj.setTextColor(params[1])
    vobj.obj.setBackgroundColor(params[2])
  end
end

function tty.mktty(id, obj)
  if not fs.exists('/dev/') then
    fs.addVirtual('/dev', {isDir=true})
  end

  fs.addVirtual('/dev/tty'..id, {
    isReadOnly = false,
    isDir = false,
    open = _ttyopen,
    ioctl = _ttyioctl,
    obj = obj,
    dir = '/dev'
  })
end

tty.mktty(0, term)

return tty

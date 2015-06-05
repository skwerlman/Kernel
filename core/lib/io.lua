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

-- basic standard input, output and error-put driver.


local oldio = (function(tab)
  local ret = {}
  for k, v in pairs(tab) do
    ret[k] = v
  end

  return ret
end)(getfenv(2).io)

local newio = {}
local streams = {}

setmetatable(newio, {
  ['__index'] = function(_, k)
    local s;
    if getfenv(2).threading and getfenv(2).threading.this then
      s = streams[getfenv(2).threading.this.rID] or {
        ['input'] = fs.exists(fs.combine(getfenv(2).threading.this.stdstreams_dir, 'stdin')) and
          io.open(fs.combine(getfenv(2).threading.this.stdstreams_dir, 'stdin'), 'r') or nil,
        ['outpu'] = io.open(fs.combine(getfenv(2).threading.this.stdstreams_dir, 'stdout'), 'a'),
        ['error'] = io.open(fs.combine(getfenv(2).threading.this.stdstreams_dir, 'stderr'), 'a'),
      }
      local this = getfenv(2).threading.this
      function this:onUpdate()
        for k, v in pairs(s) do
          if v.flush then
            v:flush()
          end
        end
      end
    end
    if k == 'stdin' then
      if getfenv(2).threading and getfenv(2).threading.this then
        if not s or not s.input then
          if s then
            s.input = io.open(fs.combine(getfenv(2).threading.this.stdstreams_dir, 'stdin'), 'r')
          else
            s = {
              ['input'] = io.open(fs.combine(getfenv(2).threading.this.stdstreams_dir, 'stdin'), 'r')
            }
          end
        end

        return s.input
      end
    elseif k == 'stdout' then
      if getfenv(2).threading and getfenv(2).threading.this then
        if not s or not s.outpu then
          if s then
            s.outpu = io.open(fs.combine(getfenv(2).threading.this.stdstreams_dir, 'stdout'), 'a')
          else
            s = {
              ['outpu'] = io.open(fs.combine(getfenv(2).threading.this.stdstreams_dir, 'stdout'), 'a')
            }
          end
        end

        return s.outpu
      end
    elseif k == 'stderr' then
      if getfenv(2).threading and getfenv(2).threading.this then
        if not s or not s.error then
          print('not existing')
          if s then
            s.error = io.open(fs.combine(getfenv(2).threading.this.stdstreams_dir, 'stderr'), 'a')
          else
            s = {
              ['error'] = io.open(fs.combine(getfenv(2).threading.this.stdstreams_dir, 'stderr'), 'a')
            }
          end
        end

        return s.error
      end
    else
      return nil
    end
  end
})

return setmetatable({}, {
  ['__index'] = function(_, k)
    if oldio[k] then
      return oldio[k]
    elseif newio[k] then
      return newio[k]
    else
      return nil
    end
  end
})

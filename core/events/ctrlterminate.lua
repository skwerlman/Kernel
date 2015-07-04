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
local lastkey

local function keyIsControl(byte)
  return byte == keys.leftCtrl or byte == keys.rightCtrl
end

local ret = {}

function ret.ctrlc(event, byte)
  if event == 'key' then
    if keyIsControl(lastkey) then
      if byte == keys.c or byte == keys.C then
        os.queueEvent('terminate', '^C')
      end
    end
    lastkey = byte
  end
end

local oldError = error
function error(d, l)
  if type(d) == 'number' and not l then
    oldError(nil, l)
  else
    oldError(d, l)
  end
end

local oldPrintError = printError
function printError(data)
  if data ~= '' then
    oldPrintError(data)
  end
end

function os.pullEvent()
  local data = {os.pullEventRaw()}
  if data[1] == 'terminate' then
    if data[2] and data[2] == '^C' then
      error(data[2], 0)
    else
      error('Terminated', 0)
    end
  end
  return unpack(data)
end


return ret

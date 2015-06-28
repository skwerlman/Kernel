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
local ret = {count = 0}

function ret:onFound(side, object)
  kmsg.post('discovery', 'discovered modem on: ' .. side or 'w0t?')
  local activeChannel, activeReplyChannel = 65535, 65535

  local obj = fs.makeVirtualIO('/sys/dev/chrM' .. ret.count)
  function obj:onRead()
    local event, side, frequency,
      replyFrequency, message, distance = coroutine.yield('modem_message')
    return message['message']
  end

  function obj:onReadAll()
    local event, side, frequency,
      replyFrequency, message, distance = coroutine.yield('modem_message')

    return message['message']
  end

  function obj:onWrite(data)
    if not object.handle.isOpen(activeChannel) then
      object.handle.open(activeChannel)
    end
    object.handle.transmit(activeChannel, activeReplyChannel, data)
  end

  function obj:onWriteLine(data)
    if not object.handle.isOpen(activeChannel) then
      object.handle.open(activeChannel)
    end
    object.handle.transmit(activeChannel, activeReplyChannel, data)
  end

  function obj:onIOControl(req, para)
    if req == 0xf1 then
      self.activeChannel = tonumber(para)
    elseif req == 0xf2 then
      self.activeReplyChannel = tonumber(para)
    end
  end

  ret.count = ret.count + 1
end

return ret

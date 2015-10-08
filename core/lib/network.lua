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

local ret = {}

function ret.openVirtualIO(channel, reply, object)
  kmsg.post('discovery', 'opening virtual network IO for ID %d', channel)

  local obj = fs.makeVirtualIO('/sys/netsock-' .. channel)

  function obj:onReadAll()
    local event, side, frequency,
      replyFrequency, message, distance = coroutine.yield('modem_message')

    if frequency == reply and replyFrequency == channel then
      return type(message) == 'table' and message.tnet_meta and
        message.tnet_meta.msg or message.message and message.message or
        'nope'
    else
      return 'dropped.'
    end
  end

  function obj:onRead()
    local event, side, frequency,
      replyFrequency, message, distance = coroutine.yield('modem_message')

    if frequency == reply and replyFrequency == channel then
      return type(message) == 'table' and message.tnet_meta and
        message.tnet_meta.msg or message.message and message.message or
        'nope'
    else
      return 'dropped.'
    end
  end

  function obj:onWrite(data)
    kmsg.post('network', 'writing \'%s\' to a stream to %d', data, channel)
    if not object.isOpen(channel) then
      object.open(channel)
    end
    object.transmit(channel, reply,  {
      nMessageID = math.random(1, 2^16),
      nRecipient = id,
      message = data,
      sProtocol = 'TARDIX-networking',
      tnet_meta = {
        msg = data
      }
    })
  end

  function obj:onWriteLine(data)
    kmsg.post('network', 'writing \'%s\' to a stream to %d', data, channel)
    if not object.isOpen(channel) then
      object.open(channel)
    end
    object.transmit(channel, reply,  {
      nMessageID = math.random(1, 2^16),
      nRecipient = id,
      message = data,
      sProtocol = 'TARDIX-networking',
      tnet_meta = {
        msg = data
      }
    })
  end

  function obj:onIOControl(req, para)
    if req == 0xf1 then
      self.channel = tonumber(para)
    elseif req == 0xf2 then
      self.reply = tonumber(para)
    end
  end
end

function ret.connect(id)
  local modem = devbus.device.firstByRawType('modem')
  if not modem then
    error('no modem found', 2)
  else
    kmsg.post('network', 'found modem on side', modem.side)
  end

  if not modem.handle.isOpen(os.getComputerID()) then
    modem.handle.open(os.getComputerID())
  end

  kmsg.post('network', 'attempting connection to ' .. id)
  modem.handle.transmit(id, os.getComputerID(), {
    nMessageID = math.random(1, 2^16),
    nRecipient = id,
    message = 'connect',
    sProtocol = 'TARDIX-networking',
    tnet_meta = {
      msg = 'connect'
    }
  })
end


run.spawn(function()
  local modem = devbus.device.firstByRawType('modem')

  if modem and modem.handle then
    modem = modem.handle
  else
		return
	end

  while true do
    local ev, side, chan, repChan,
      message, distance = coroutine.yield('modem_message')

    if chan == os.getComputerID() then -- this is mine!
      kmsg.post('network', 'message from %d: %s', repChan,
        textutils.serialize(message))

      if message and type(message) == 'table' and message.tnet_meta then
        local msg = message.tnet_meta.msg
        if msg == 'connect' then
          modem.transmit(repChan, os.getComputerID(), {
            nMessageID = math.random(1, 2^16),
            nRecipient = repChan,
            message = 'accept-connect',
            sProtocol = 'TARDIX-networking',
            tnet_meta = {
              msg = 'accept-connect'
            }
          })
          ret.openVirtualIO(repChan, os.getComputerID(), modem)
        elseif msg == 'accept-connect' then
          ret.openVirtualIO(repChan, os.getComputerID(), modem)
        end

        os.queueEvent('tnet-message', repChan, message.tnet_meta.msg)
        if not fs.exists('/sys/netsock-'..repChan) then
          ret.openVirtualIO(repChan, os.getComputerID(), modem)
        end
      end
    else
      kmsg.post('network', 'message from %d (not to us, to %d): %s', repChan,
        chan, textutils.serialize(message))
    end
  end
end)


function ret.transmit(to, message)
  if not fs.exists('/sys/netsock-' .. to) then
    ret.connect(to)
  end

  if fs.exists('/sys/netsock-' .. to) then
    local stream = fs.open('/sys/netsock-' .. to, 'w')
    stream.writeLine(message)
    stream.close()
  end
end

function ret.receive(from)
  if not fs.exists('/sys/netsock-' .. to) then
    ret.connect(to)
  end

  local data

  if fs.exists('/sys/netsock-' .. to) then
    local stream = fs.open('/sys/netsock-' .. to, 'r')
    data = stream.readAll()
    stream.close()
  end

  return data
end
return ret

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


local select , setmetatable = select , setmetatable
local print = print

local fifo = {}
local fifo_mt = {
	__index = fifo ;
	__newindex = function ( f , k , v )
		if type (k) ~= "number" then
			error ( "Tried to set value in fifo" )
		else
			return rawset ( f , k , v )
		end
	end ;
}

local empty_default = function ( self ) return 'reached end of kernel messaging queue' end

function fifo.new ( ... )
	return setmetatable ( { empty = empty_default , head = 1 , tail = select("#",...) , ... } , fifo_mt )
end

function fifo:length ( )
	return self.tail - self.head + 1
end

function fifo:peek ( n )
	return self [ self.head ]
end

function fifo:push ( v )
	self.tail = self.tail + 1
	self [ self.tail ] = v
end

function fifo:pop ( )
	local head , tail = self.head , self.tail
	if head > tail then return self:empty() end

	local v = self [ head ]
	self [ head ] = nil
	self.head = head + 1
	return v
end

function fifo:insert ( n , v )
	local head , tail = self.head , self.tail

	local p = head + n - 1
	if p <= (head + tail)/2 then
		for i = head , p do
			self [ i - 1 ] = self [ i ]
		end
		self [ p - 1 ] = v
		self.head = head - 1
	else
		for i = tail , p , -1 do
			self [ i + 1 ] = self [ i ]
		end
		self [ p ] = v
		self.tail = tail + 1
	end
end

function fifo:remove ( n )
	local head , tail = self.head , self.tail

	if head + n > tail then return self:empty() end

	local p = head + n - 1
	local v = self [ p ]

	if p <= (head + tail)/2 then
		for i = p , head , -1 do
			self [ i ] = self [ i - 1 ]
		end
		self.head = head + 1
	else
		for i = p , tail do
			self [ i ] = self [ i + 1 ]
		end
		self.tail = tail - 1
	end

	return v
end

function fifo:setempty ( func )
	self.empty = func
end

local iter_helper = function ( f , last )
	local nexti = f.head+last
	if nexti > f.tail then return nil end
	return last+1 , f[nexti]
end

function fifo:iter ( )
	return iter_helper , self , 0
end

function fifo:foreach ( func )
	for k,v in self:iter() do
		func(k,v)
	end
end

fifo_mt.__len = fifo.length

local stack = fifo.new()
local msg = {}

local backup = {}
--[[
Post a message onto the kernel messaging system
This is useful when no terminal is avaiable and the kernel still has to do logging.

@param sender the sender of the message to post
@param text the format of the text to send, in string.format format.
@param ... the arguments to format the text with (optional).
]]
function msg.post(sender, text, ...)
	stack:push({
		['time'] = os.clock(),
		['sender'] = sender,
		['text'] = (...) and text:format(...) or text,
	})
	table.insert(backup, 1, {
		['time'] = os.clock(),
		['sender'] = sender,
		['text'] = (...) and text:format(...) or text
	})
	os.queueEvent('kernel_message', ('[%s] [%s]: %s'):format(tostring(os.clock()), sender, text))
end
--[[
Return the last message in the kernel messaging system.
]]
function msg.getLast()
	local e = stack:pop()
	if e then
		return e
	else
		return 'reached end of kmsg'
	end
end
--[[
Get all messages of the kernel messaging system currently on the stack.
@param s return strings in the default format.
]]
function msg.getAll(s)
	local ret = {}
	local oret = {}
	for i = 1, #stack._et do
		table.insert(ret, ('[%s] [%s]: %s'):format(textutils.formatTime(stack._et[i].time, true), stack._et[i].sender, stack._et[i].text))
		table.insert(oret, stack._et[i])
	end

	if s then
		return ret -- return strings
	else
		return oret
	end
end
--[[
Clear the kernel messaging system.
]]
function msg.clear()
	stack:pop(#stack._et)
end

msg.queue = stack
--[[
A backup of all messages in the system.
]]
msg.backup = backup
return msg

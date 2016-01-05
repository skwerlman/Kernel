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

local unsafe = {
	['queue'] = {
		['lifo'] = {
			['_et'] = {}
		}
	},
	['regis'] = {
		['a'] = {},
		['b'] = {},
		['c'] = {},
		['d'] = {},
		['e'] = {},
	},
	['registers'] = {},
}

-- LIFO STACK --
unsafe.stack = unsafe.queue.lifo

function unsafe.queue.lifo:push(...)
	if ... then
		local targs = {...}
		if type(targs[1]) == 'table' then
			for _, v in ipairs(targs[1]) do
				table.insert(self._et, v)
			end
		else
			-- add values
			for _,v in ipairs(targs) do
				table.insert(self._et, v)
			end
		end
	end
end

function unsafe.queue.lifo:pop(num)
	local num = num or 1

	local entries = {}

	for i = 1, num do
		if #self._et ~= 0 then
			table.insert(entries, self._et[#self._et])
			table.remove(self._et)
		else
			break
		end
	end

	return unpack(entries)
end

setmetatable(unsafe.queue.lifo, {
	['__index'] = function(t, k)
		if not rawget(t, k) and #rawget(t, '_et') > 0 then
			return unsafe.queue.lifo:pop()
		elseif rawget(t, k) then
			return rawget(t, k)
		elseif k == '_et' then
			return nil
		else
			return nil
		end
	end,
	['__newindex'] = function(t, k, v)
		unsafe.queue.lifo:push(v)
	end
})

setmetatable(unsafe.stack,{
	['__index'] = function(t, k)
		if not rawget(t, k) and #rawget(t, '_et') > 0 then
			return unsafe.queue.lifo:pop()
		elseif rawget(t, k) then
			return rawget(t, k)
		elseif k == '_et' then
			return nil
		else
			return nil
		end
	end,
	['__newindex'] = function(t, k, v)
		unsafe.queue.lifo:push(v)
	end
})

-- REGISTERS --

function unsafe.registers:set(r, v)
	if unsafe.regis[r] then
		unsafe.regis[r] = v
	else
		error('unknown register ' .. r, 2)
	end
end

function unsafe.registers:get(r)
	if unsafe.regis[r] then
		return unsafe.regis[r]
	else
		error('unknown register ' .. r, 2)
	end
end

function unsafe.registers:move(r)
	return function(t)
		unsafe.registers:set(r, t[1] and t[1] or nil)
	end
end

-- CALL --

function unsafe.call(t)
	local fn = t[1]
	local na = t[2] or #unsafe.stack._et

	fn(unsafe.stack:pop(na))
end

return unsafe

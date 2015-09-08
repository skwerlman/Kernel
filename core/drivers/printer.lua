--[[
The MIT License (MIT)

Copyright (c) 2015 the TARDIX team

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

local printer = {count = 0}

function printer:onFound(side, object)
	kmsg.post('discovery', 'found printer on side %s', side)

	local obj = fs.makeVirtualIO('/sys/dev/chrP' .. printer.count)
	printer.count = printer.count + 1

	function obj:onIOControl(path, req, ...)
		if req == 1 then
			return object.handle.getInkLevel()
		elseif req == 2 then
			return object.handle.getCursorPos()
		elseif req == 3 then
			return object.handle.getPaperLevel()
		elseif req == 4 then
			return object.handle.getPageSize()
		elseif req == 5 then
			return object.handle.newPage()
		elseif req == 6 then
			return object.handle.setPageTitle(...)
		elseif req == 7 then
			return object.handle.endPage()
		end
	end

	function obj:onWrite(...)
		return object.handle.write(...)
	end

	function obj:onWriteLine(w)
		return object.handle.write(w .. '\n')
	end

	function obj:onClose()
		object.handle.endPage()
	end

	function obj:onFlush()
		object.handle.endPage()
	end
end

return printer


local function linewrap( str, w )
	if str:sub( 1, w + 1 ):find "\n" then
		return str:match "(.-)\n(.+)"
	end
	if str:sub( 1, w + 1 ):find "%s" then
		local pos = w - str:sub( 1, w + 1 ):reverse():find "%s" + 1
		return str:sub( 1, pos), str:sub( pos + 2 ):gsub( "^%s+", "" )
	end
	return str:sub( 1, w ), str:sub( w + 1 )
end

local function wordwrap( str, w, h )
	local s1, s2 = linewrap( str, w )
	local lines = { s1 }
	while #s2 > 0 do
		s1, s2 = linewrap( s2, w )
		lines[#lines + 1] = s1
	end
	while h and #lines > h do
		lines[#lines] = nil
	end
	return lines
end

local graphics = {}

function graphics:mixin( element ) -- graphics:mixin( buffer )  buffer:drawRectangle()
	for k, v in pairs( self ) do
		if k ~= "mixin" and not element[k] then
			element[k] = v
		end
	end
end

function graphics:drawPixel( x, y, char )
	if self.stencil then
		if not self.stencil:withinBounds( x, y ) then
			return false
		end
	end
	local bc, tc = self:getColours()
	return self:setPixel( x, y, bc, tc, char or " " )
end

function graphics:drawRectangle( x, y, w, h, char )
	local x2, y2 = x + w - 1, y + h - 1
	for _x = x, x2 do
		graphics.drawPixel( self, _x, y, char )
		graphics.drawPixel( self, _x, y2, char )
	end
	for _y = y + 1, y2 - 1 do
		graphics.drawPixel( self, x, _y, char )
		graphics.drawPixel( self, x2, _y, char )
	end
end

function graphics:drawFilledRectangle( x, y, w, h, char )
	for _x = x, x + w - 1 do
		for _y = y, y + h - 1 do
			graphics.drawPixel( self, _x, _y, char )
		end
	end
end

function graphics:drawCircle( x, y, r, char )
	local function pixel( x, y )
		graphics.drawPixel( self, x, y, char )
	end

	local c = 2 * math.pi * r
	local n = 2 * math.pi * 2 / c
	local c8 = c / 8
	for i = 0, c8 do
		local _x, _y = math.sin( i * n ) * r, math.cos( i * n ) * r
		pixel( x + _x, y + _y )
		pixel( x + _x, y - _y )
		pixel( x - _x, y + _y )
		pixel( x - _x, y - _y )
		pixel( x + _y, y + _x )
		pixel( x - _y, y + _x )
		pixel( x + _y, y - _x )
		pixel( x - _y, y - _x )
	end
end

function graphics:drawFilledCircle( x, y, r, char, correction )
	local r2 = r ^ 2
	for _x = -r, r do
		for _y = -r, r do
			if _x ^ 2 + ( _y ^ 2 ) * ( correction or 1 ) < r2 then
				graphics.drawPixel( self, x + _x, y + _y, char )
			end
		end
	end
end

function graphics:drawVerticalLine( x, y, height, char )
	for i = y, y + height - 1 do
		grpahics.drawPixel( self, x, i, char )
	end
end

function graphics:drawHorizontalLine( x, y, width, char )
	for i = x, x + width - 1 do
		grpahics.drawPixel( self, i, y, char )
	end
end

function graphics:drawLine( x1, y1, x2, y2, char )
	if x1 > x2 then
		x2, x1 = x1, x2
		y2, y1 = y1, y2
	end
	if x1 == x2 then
		for i = math.min( y1, y2 ), math.max( y1, y2 ) do
			graphics.drawPixel( self, x1, i, char )
		end
		return
	elseif y1 == y2 then
		for i = math.min( x1, x2 ), math.max( x1, x2 ) do
			graphics.drawPixel( self, i, y1, char )
		end
		return
	end
	local dx, dy = x2 - x1, y2 - y1
	local m = dy / dx
	local c = y1 - m * x1

	for x = x1, x2, math.min( 1 / m, 1 ) do
		local y = m * x + c
		graphics.drawPixel( self, x, y, char )
	end
end

function graphics:drawPolygon( ... )
	local points, char = { ... }, nil
	if #points % 2 == 0 then
		char = " "
	else
		char = points[#points]
		points[#points] = nil
	end
	if #points < 6 then
		return error "expected at least 6 parameters (3 x,y pairs)"
	end
	for i = 1, #points / 2 do
		graphics.drawLine( self, points[2 * i - 1], points[2 * i], points[2 * ( i + 1 ) - 1], points[2 * ( i + 1 )], char )
	end
	graphics.drawLine( self, points[#points - 1], points[#points], points[1], points[2], char )
end

function graphics:drawTextLine( x, y, text )
	for i = 1, #text do
		graphics.drawPixel( self, x, y, text:sub( i, i ) )
		x = x + 1
	end
end

function graphics:drawTextWrapped( x, y, w, h, text )
	self:drawFilledRectangle( x, y, w, h )
	local lines = wordwrap( text, w, h )
	for i = 1, #lines do
		self:drawTextLine( x, y, lines[i] )
		y = y + 1
	end
end

function graphics:drawTextFormatted( x, y, w, h, formatted_text ) -- formatted_text is a table of lines containing an offset, colours, and the actual text
	local bc, tc = self:getColours()
	local obc, otc = bc, tc
	self:setColours( formatted_text.bc, formatted_text.tc )
	self:drawFilledRectangle( x, y, w, h )
	y = y + ( formatted_text.offset.y or 0 )
	for l = 1, #formatted_text.lines do
		local text = formatted_text.lines[l].text
		local colour = formatted_text.lines[l].colour or {}
		local x = x + ( formatted_text.offset[l] or 0 )
		for c = 1, #text do
			colour[c] = colour[c] or {}
			local _bc, _tc = colour[c].bc or formatted_text.bc, colour[c].tc or formatted_text.tc
			if _bc ~= bc or _tc ~= tc then
				self:setColours( _bc, _tc )
				bc, tc = _bc, _tc
			end
			local char = text:sub( c, c )
			if char == "\t" then
				char = "    "
			end
			if char ~= "\n" then
				graphics.drawPixel( self, x, y, char )
				x = x + #char
			end
		end
		y = y + 1
	end
	self:setColours( obc, otc )
end

function graphics:setColours( bc, tc )
	self.graphics_bc = bc or self.graphics_bc
	self.graphics_tc = tc or self.graphics_tc
end

function graphics:getColours()
	return self.graphics_bc or 1, self.graphics_tc or 32768
end

return graphics

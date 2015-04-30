
local function hasChanged( p1, p2 )
	return p1.bc ~= p2.bc or p1.char ~= p2.char or ( p1.tc ~= p2.tc and p1.char ~= " " )
end
local function drawCurrent( state )
	local t = state.target
	if state.text ~= "" then
		t.setCursorPos( state.x, state.y )
		local bc = state.bc
		bc = ( type( bc ) == "function" and bc() ) or ( bc == 0 and state.buffer.bc ) or bc
		local tc = state.tc
		tc = ( type( tc ) == "function" and tc() ) or ( tc == 0 and state.buffer.tc ) or tc
		t.setBackgroundColour( bc )
		t.setTextColour( tc )
		t.write( state.text )
		state.x = state.x + #state.text
		state.text = ""
	end
end
local function px( buffer, state, x, y )
	local px = buffer.pixels[y][x]
	if not hasChanged( px, buffer.last[y][x] ) and not state.all then
		drawCurrent( state )
		state.x = state.x + 1
		state.bc = nil
		return
	end
	if not state.bc then
		state.bc = px.bc
		state.tc = px.tc
		state.text = px.char
		return
	end
	if state.bc ~= px.bc or ( state.tc ~= px.tc and px.char ~= " " ) then
		drawCurrent( state )
		state.bc = px.bc
		state.tc = px.tc
		state.text = px.char
	else
		state.text = state.text .. px.char
	end
end

local col_lookup = {
	[0] = " ";
	[1] = "0";
	[2] = "1";
	[4] = "2";
	[8] = "3";
	[16] = "4";
	[32] = "5";
	[64] = "6";
	[128] = "7";
	[256] = "8";
	[512] = "9";
	[1024] = "A";
	[2048] = "B";
	[4096] = "C";
	[8192] = "D";
	[16382] = "E";
	[32768] = "F";
}

local function toHex( c )
	return col_lookup[c] or " "
end

local function blitline( line )
	local s, b, t = "", "", ""
	for i = 1, #line do
		s = s .. line[i].char:sub( 1, 1 )
		if line[i].char == "" then s = s .. " " end
		b = b .. toHex( line[i].bc )
		t = t .. toHex( line[i].tc )
	end
	term.blit( s, b, t )
end

local buffer = {}
local main

function buffer:new( width, height, bc, tc, char )
	local b = {}

	b.allowInvisiblePixels = false

	b.width = width
	b.height = height

	b.bc = bc or 1
	b.tc = tc or 32768
	b.char = char or " "

	b.pixels = {}
	b.last = {}

	b.cb = false

	for y = 1, height do
		b.pixels[y] = {}
		b.last[y] = {}
		for x = 1, width do
			b.pixels[y][x] = { bc = b.bc, tc = b.tc, char = b.char }
			b.last[y][x] = {}
		end
	end

	setmetatable( b, { __index = self, __type = "buffer" } )

	return b
end

function buffer:setPixel( x, y, bc, tc, char )
	if self.pixels[y] and self.pixels[y][x] then
		local px = self.pixels[y][x]
		px.bc = ( bc == 0 and not self.allowInvisiblePixels and px.bc ) or bc
		px.tc = ( tc == 0 and not self.allowInvisiblePixels and px.tc ) or tc
		px.char = ( tc == 0 and px.char ) or ( char == "" and px.char ) or char
	end
end

function buffer:getPixel( x, y )
	if self.pixels[y] and self.pixels[y][x] then
		local px = self.pixels[y][x]
		return px.bc, px.tc, px.char
	end
end

function buffer:clear()
	for y = 1, self.height do
		for x = 1, self.width do
			self.pixels[y][x] = { bc = self.bc, tc = self.tc, char = self.char }
		end
	end
end

function buffer:foreach( f )
	local new = {}
	for x = 1, self.width do
		new[x] = {}
		for y = 1, self.height do
			local bc, tc, char = self:getPixel( x, y )
			local _bc, _tc, _char = f( x, y, bc, tc, char )
			local c = false
			if _bc and _bc ~= bc then c = true end
			if _tc and _tc ~= tc then c = true end
			if _char and _char ~= char then c = true end
			if c then
				new[x][y] = { bc = _bc or bc, tc = _tc or tc, char = _char or char }
			end
		end
	end
	for x = 1, self.width do
		for y = 1, self.height do
			local px = new[x][y]
			if px then
				self:setPixel( x, y, px.bc, px.tc, px.char )
			end
		end
	end
end

function buffer:resize( width, height )
	while self.height < height do
		local t = {}
		for i = 1, self.width do
			t[i] = { bc = self.bc, tc = self.tc, char = self.char }
		end
		self.pixels[#self.pixels + 1] = t
		self.last[#self.last + 1] = {}
		self.height = self.height + 1
	end
	while self.height > height do
		self.pixels[#self.pixels] = nil
		self.last[#self.last] = nil
		self.height = self.height - 1
	end
	while self.width < width do
		for i = 1, self.height do
			self.pixels[i][#self.pixels[i] + 1] = { bc = self.bc, tc = self.tc, char = self.char }
		end
		self.width = self.width + 1
	end
	while self.width > width do
		for i = 1, self.height do
			self.pixels[i][#self.pixels[i]] = nil
		end
		self.width = self.width - 1
	end
end

function buffer:setCursorBlink( x, y, tc )
	if x then
		self.cb = { x = x, y = y, tc = tc }
	else
		self.cb = false
	end
end

function buffer:getCursorBlink()
	if self.cb then
		return self.cb.x, self.cb.y, self.cb.tc
	end
end

local function drawToBuffer( buffer, target, _x, _y )
	buffer:foreach( function( x, y, bc, tc, char )
		target:setPixel( x + _x - 1, y + _y - 1, bc, tc, char )
	end )
end

function buffer:draw( target, x, y, all )
	target = target or term.current()

	if pcall( function()
		if getmetatable( target ).__type ~= "buffer" then
			error ""
		end
	end ) then
		return drawToBuffer( self, target, x, y )
	end

	x = x or 1
	y = y or 1
	if target.blit then
		for i = 1, self.height do
			term.setCursorPos( x, y + i - 1 )
			blitline( self.pixels[i] )
		end
	else
		for i = 1, self.height do
			local state = {
				x = x;
				y = y;
				target = target;
				text = "";
				all = all;
				buffer = self;
			}
			for x = 1, self.width do
				px( self, state, x, i )
			end
			drawCurrent( state )
			y = y + 1
		end
	end
end

function buffer:redirect()
	main = self
end

function buffer.current()
	return main
end

return buffer

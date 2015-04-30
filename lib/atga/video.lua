
local image = krequire "lib.atga.image"

local colour = {}

colour.lookup = {
	["0"] = colours.white;
	["1"] = colours.orange;
	["2"] = colours.magenta;
	["3"] = colours.lightBlue;
	["4"] = colours.yellow;
	["5"] = colours.lime;
	["6"] = colours.pink;
	["7"] = colours.grey;
	["8"] = colours.lightGrey;
	["9"] = colours.cyan;
	["A"] = colours.purple;
	["B"] = colours.blue;
	["C"] = colours.brown;
	["D"] = colours.green;
	["E"] = colours.red;
	["F"] = colours.black;
	[" "] = 0;
}

colour.save = {}
for k, v in pairs( colour.lookup ) do
	colour.save[v] = k
end

local function clone( im )
	local f = image:new( im.width, im.height )
	for x = 1, im.width do
		for y = 1, im.height do
			f:setPixel( x, y, im:getPixel( x, y ) )
		end
	end
	return f
end

local function changed( f1, f2, x, y )
	local bc1, tc1, char1 = f1:getPixel( x, y )
	local bc2, tc2, char2 = f2:getPixel( x, y )
	return bc1 ~= bc2 or tc1 ~= tc2 or char1 ~= char2
end

local function px( x, y, width )
	return ( y - 1 ) * width + x - 1
end
local function pad( n, w )
	n = tostring( n )
	return (" "):rep( math.max( w - #n, 0 ) ) .. n
end
local function pxstr( bc, tc, char )
	if char == "" then
		bc = 0
		char = " "
	end
	return colour.save[bc] .. colour.save[tc] .. char
end
local function upx( s, w )
	s = s:gsub( "^%s*", "" )
	local n = tonumber( s )
	return n % w + 1, math.floor( n / w ) + 1
end

local video = {}

function video.save( frames )
	local frame = frames[1]
	local w, h = frame.width, frame.height
	local output = w .. "," .. h .. "\n"
	output = output .. frame:save() .. "\n"
	local pxwidth = #tostring( px( w, h, w ) )
	for i = 2, #frames do
		local nframe = frames[i]
		for x = 1, w do
			for y = 1, h do
				if changed( frame, nframe, x, y ) then
					output = output .. pad( px( x, y, w ), pxwidth ) .. pxstr( nframe:getPixel( x, y ) )
				end
			end
		end
		frame = nframe
		output = output .. "\n"
	end
	return output:sub( 1, -2 )
end

function video.load( str )
	local width, height = str:match "(%d+),(%d+)\n"
	str = str:sub( #width + #height + 3 )
	width, height = tonumber( width ), tonumber( height )
	local is = ( ( width * 3 ) + 1 ) * height
	local frames = { image.load( str:sub( 1, is - 1 ) ) }
	frames[2] = clone( frames[1] )
	str = str:sub( is + 1 )
	local pxwidth = #tostring( px( width, height, width ) )
	while #str > 0 do
		if str:sub( 1, 1 ) == "\n" then
			frames[#frames+1] = clone( frames[#frames] )
			str = str:sub( 2 )
		else
			local x, y = upx( str:sub( 1, pxwidth ), width )
			local bc, tc, char = str:sub( pxwidth + 1, pxwidth + 1 ), str:sub( pxwidth + 2, pxwidth + 2 ), str:sub( pxwidth + 3, pxwidth + 3 )
			bc = colour.lookup[bc]
			tc = colour.lookup[tc]
			frames[#frames]:setPixel( x, y, bc, tc, char )
			str = str:sub( pxwidth + 4 )
		end
	end
	return frames
end

return video


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

local image = {}

image.colour = colour

function image:new( width, height )

	local i = {}

	i.width = width or 0
	i.height = height or 0

	i.pixels = {}

	for y = 1, height or 0 do
		i.pixels[y] = {}
		for x = 1, width or 0 do
			i.pixels[y][x] = { bc = 0, tc = 0, char = "" }
		end
	end

	setmetatable( i, { __index = self, __type = "image" } )
	return i

end

function image:setPixel( x, y, bc, tc, char )
	if self.pixels[y] and self.pixels[y][x] then
		self.pixels[y][x] = {
			bc = bc;
			tc = tc;
			char = char;
		}
	end
end

function image:getPixel( x, y )
	if self.pixels[y] and self.pixels[y][x] then
		return self.pixels[y][x].bc, self.pixels[y][x].tc, self.pixels[y][x].char
	end
end

function image:save()
	local str = ""
	for y = 1, self.height do
		for x = 1, self.width do
			local bc, tc, char = self:getPixel( x, y )
			bc = colour.save[bc]
			tc = colour.save[tc]
			if #char == 0 then
				char = " "
				bc = colours.save[0]
			end
			str = str .. bc .. tc .. char
		end
		str = str .. "\n"
	end
	return str:sub( 1, -2 )
end

function image.load( str )
	local lines = {}
	local last = 1
	for i = 1, #str do
		if str:sub( i, i ) == "\n" then
			table.insert( lines, str:sub( last, i - 1 ) )
			last = i + 1
		end
	end
	table.insert( lines, str:sub( last ) )
	local width = #lines[1] / 3
	local height = #lines
	local frame = image:new( width, height )
	for i = 1, #lines do
		local x = 1
		for pixel in lines[i]:gmatch( "[0123456789ABCDEF ][0123456789ABCDEF ]." ) do
			local bc = colour.lookup[pixel:sub( 1, 1 )]
			local tc = colour.lookup[pixel:sub( 2, 2 )]
			local ch = pixel:sub( 3, 3 )
			frame:setPixel( x, i, bc, tc, ch )
			x = x + 1
		end
	end
	return frame
end

return image

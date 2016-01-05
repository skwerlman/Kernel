
local function bbox( x1, y1, w1, h1, x2, y2, w2, h2 )
	local x = math.max( x1, x2 )
	local y = math.max( y1, y2 )
	local w = math.min( x1 + w1, x2 + w2 ) - x
	local h = math.min( y1 + h1, y2 + h2 ) - y
	if w < 1 or h < 1 then return false end
	return x, y, w, h
end

local stencil = {}

function stencil:new()

	local s = {}

	s.bounds = false
	s.layers = {}

	setmetatable( s, { __index = self, __type = "stencil" } )
	return s

end

function stencil:newLayer( x, y, w, h )
	if self.bounds then
		if self.bounds.x then
			local t = self.bounds
			local _x, _y, _w, _h = bbox( x, y, w, h, t.x, t.y, t.width, t.height )
			if _x then
				self.bounds = {
					x = _x;
					y = _y;
					width = _w;
					height = _h;
				}
			else
				self.bounds = {}
			end
		end
	else
		self.bounds = {
			x = x;
			y = y;
			width = w;
			height = h;
		}
	end
	local id = {}
	self.layers[#self.layers + 1] = {
		x = x;
		y = y;
		width = w;
		height = h;
		id = id;
	}
	return id
end

function stencil:removeLayer( l )
	for i = 1, #self.layers do
		if self.layers[i].id == l then
			while self.layers[i] do
				table.remove( self.layers, i )
			end
		end
	end
	local t = self.layers
	self.bounds = false
	self.layers = {}
	if #t > 0 then
		for i = 1, #t do
			self:newLayer( t[i].x, t[i].y, t[i].width, t[i].height )
			self.layers[#self.layers].id = t[i].id
			if not self.bounds.x then
				break
			end
		end
	end
end

function stencil:getBounds( x, y, w, h )
	if self.bounds then
		if self.bounds.x then
			return self.bounds.x, self.bounds.y, self.bounds.width, self.bounds.height
		end
		return false
	end
	return x or true, y, w, h
end

function stencil:clearLayers()
	self.layers = {}
	self.bounds = false
end

function stencil:withinBounds( px, py )
	local x, y, w, h = self:getBounds()
	if x == true then return true end
	if x == false then return false end
	return px >= x and px < x + w and py >= y and py < y + h
end

return stencil

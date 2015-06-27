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

-- graphics interface


local frame = {}

local vector = {}

local vector_mt = {
  ['__index'] = function(_, k)
    if rawget(_, k) then
      return rawget(_, k)
    elseif vector[k] then
      return vector[k]
    end
  end,
  ['__add'] = vector.add,
  ['__sub'] = vector.sub,
  ['__mul'] = vector.mul,
  ['__div'] = vector.div,
  ['__pow'] = vector.pow,
}

function vector.new(x, y)
  if type(x) ~= 'number' then
    error('expected number for x, got ' .. type(x), 2)
  end

  if type(y) ~= 'number' then
    error('expected number for y, got ' .. type(x), 2)
  end

  local ret = {['x'] = x, ['y'] = y}
  setmetatable(ret, vector_mt)
  return ret
end

function vector:inBounds(sX, sY, eX, eY)
  if not sX or not sY or not eX or not eY then
    error('stuff..',2)
  end
  return self.x == eX and self.y == eY -- of course it's in, it's the bottom-left-most pixel!
  or self.x == 1 and self.y == 1 -- top-right-most
  or not (self.x < sX or self.x > eX or self.y < sY or self.y > eY) -- is it in?
end

function vector:serialize()
  return ('[%d, %d]'):format(self.x, self.y)
end

function vector:add(other)
  return vector.new(self.x + other.x, self.y + other.y)
end

function vector:sub(other)
  return vector.new(self.x - other.x, self.y - other.y)
end
function vector:mul(other)
  return vector.new(self.x * other.x, self.y * other.y)
end
function vector:div(other)
  return vector.new(math.floor(self.x / other.x), math.floor(self.y / other.y))
end
function vector:pow(other)
  return vector.new(self.x ^ other, self.y ^ other)
end

local frame_mt = {
  ['__index'] = function(_, k)
    if rawget(_, k) then
      return rawget(_, k)
    elseif frame[k] then
      return frame[k]
    end
  end
}

local function make_area(size_x, size_y)
  local ret = {}

  for i = 1, size_x do
    ret[i] = {}
    for j = 1, size_y do
      ret[i][j] = {}
    end
  end
  return ret
end

local function stt(data)
  local t = {}
  data:gsub(".",function(c) table.insert(t,c) end)
  return t
end

function frame.new(sx, sy, ex, ey)
  if type(sx) == 'table' then
    error('call new with . not :', 2)
  end
  local ret = {
    ['start_x'] = sx,
    ['start_y'] = sy,
    ['end_x'] = ex,
    ['end_y'] = ey,
    ['area'] = make_area(ex, ey)
  }
  setmetatable(ret, frame_mt)
  return ret
end

function frame:setPixel(x, y, cb, cf, c)
  if vector.new(x, y):inBounds(self.start_x, self.start_y, self.end_x, self.end_y) then
    if self.area and self.area[x] then
      self.area[x][y] = {['d'] = c or ' ', ['cb'] = cb, ['cf'] = cf or colors.white}
    else
      error('area is nil', 2)
    end
  else
    error(('point %s is out of bounds. max is %s'):format(vector.new(x, y):serialize(),
      vector.new(self.end_x, self.end_y):serialize()), 2)
  end
end

function frame:setPixelV(v, cb, cf, c)
  if not self then
    error('call with :', 2)
  end
  if v:inBounds(self.start_x, self.start_y, self.end_x, self.end_y) then
    if self.area and self.area[v.x] then
      self.area[v.x][v.y] = {['d'] = c or ' ', ['cb'] = cb, ['cf'] = cf or colors.white}
    else
      error('area is nil', 2)
    end
  else
    error(('point %s is out of bounds. max is %s'):format(v:serialize(),
      vector.new(self.end_x, self.end_y):serialize()), 2)
  end
end

function frame:map(obj)
  for x = 1, #self.area do
    for y = 1, #self.area[x] do
      if self.area[x] and self.area[x][y] and self.area[x][y].d then
        obj.setCursorPos((self.start_x == 1 and 0 or self.start_x) + x,
          (self.start_y == 1 and 0 or self.start_y) + y)
        obj.setTextColor(self.area[x][y].cf or colors.white)
        obj.setBackgroundColor(self.area[x][y].cb or colors.black)
        for k, v in pairs(stt(self.area[x][y].d or ' ')) do
          obj.write(v)
        end
      end
    end
  end
  if self.onMap then
    self:onMap(obj)
  end
end

function frame:forEach(fn)
  for x = 1, #self.area do
    for y = 1, #self.area[x] do
      if self.area[x][y].d then
        fn(x, y, self.area[x][y])
      end
    end
  end
  if self.onDraw then
    self:onDraw()
  end
end

function frame:apply(fn)
  for x = 1, #self.area do
    for y = 1, #self.area[x] do
      if self.area[x][y].d then
        self.area[x][y] = fn(x, y, self.area[x][y])
      end
    end
  end
  if self.onDraw then
    self:onDraw()
  end
end

function frame:move(nx, ny)
  self.start_x = nx
  self.start_y = ny
end

function frame:moveV(v)
  self.start_x = v.x
  self.start_y = v.y
end

function frame:fill(sx, sy, ex, ey, co)
  if vector.new(ex, ey):inBounds(self.start_x, self.start_y, self.end_x, self.end_y) then
    for x = sx, ex do
      for y = sy, ey do
        self.area[x][y] = {d = ' ', cb = co, cf = colors.white}
      end
    end
    if self.onDraw then
      self:onDraw()
    end
  else
    error(('point %s is out of bounds. max is %s'):format(vector.new(ex, ey):serialize(),
      vector.new(self.end_x, self.end_y):serialize()), 2)
  end
end

function frame:fillV(sv, se, co)
  if se:inBounds(self.start_x, self.start_y, self.end_x, self.end_y) then
    for x = sv.x, se.x do
      for y = sv.y, se.y do
        self.area[x][y] = {d = ' ', cb = co, cf = colors.white}
      end
    end
    if self.onDraw then
      self:onDraw()
    end
  else
    error(('point %s is out of bounds. max is %s'):format(se:serialize(),
      vector.new(self.end_x, self.end_y):serialize()), 2)
  end
end

function frame:line(x1, y1, x2, y2, back, char, fore)
  local delta_x = x2 - x1
  local ix = delta_x > 0 and 1 or -1
  delta_x = 2 * math.abs(delta_x)

  local delta_y = y2 - y1
  local iy = delta_y > 0 and 1 or -1
  delta_y = 2 * math.abs(delta_y)

  if not char then char = ' ' end
  if not fore then fore = colors.white end

  self:setPixel(x1, y1, back, char, fore)
  if delta_x >= delta_y then
    local error = delta_y - delta_x / 2
    while x1 ~= x2 do
      if (error >= 0) and ((error ~= 0) or (ix > 0)) then
        error = error - delta_x
        y1 = y1 + iy
      end
      error = error + delta_y
      x1 = x1 + ix
      self:setPixel(x1, y1, back, char, fore)
    end
  else
    local error = delta_x - delta_y / 2
    while y1 ~= y2 do
      if (error >= 0) and ((error ~= 0) or (iy > 0)) then
        error = error - delta_y
        x1 = x1 + ix
      end
      error = error + delta_x
      y1 = y1 + iy
      self:setPixel(x1, y1, back, char, fore)
    end
  end
  if self.onDraw then
    self:onDraw()
  end
end

function frame:fillLine(l, b, c, f)
  local x, y = self.end_x, self.end_y
  self:line(x, l, 1, l, b, c, f)
  if self.onDraw then
    self:onDraw()
  end
end

function frame:empty()
  for x = 1, self.end_x do
    for y = 1, self.end_y do
      self.area[x][y] = {}
    end
  end
end

function frame:drawString(x, y, s, b, f)
  if self:pointInBounds(x, y) then
    local t = (function(str)
      local ret = {}
      str:gsub('.', function(c) ret[#ret + 1] = c end)
      return ret
    end)(s)

    for i = 1, #t do
      self:setPixel((x + i) - 1, y, b or colors.black, f or colors.white, t[i])
    end

    if self.onDraw then
      self:onDraw()
    end
  end
end


function frame:copy()
  local ret = frame.new(self.start_x, self.start_y, self.end_x, self.end_y)
  ret.area = (function(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
      copy = {}
      for orig_key, orig_value in next, orig, nil do
          copy[deepcopy(orig_key)] = deepcopy(orig_value)
      end
      setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
      copy = orig
    end
    return copy
  end)(self.area)
  return ret
end

function frame:clear()
  if self.onClear then
    self:onClear()
  else
    self.area = (function(size_x, size_y)
      local ret = {}

      for i = 1, size_x do
        ret[i] = {}
        for j = 1, size_y do
          ret[i][j] = {cb = colors.black, cf = colors.white, d = ' '}
        end
      end
      return ret
    end)(self.end_x, self.end_y)
    self.cursorPos = {1,1}
    if self.onDraw then
      self:onDraw()
    end
  end
end

function frame:pointInBounds(x, y)
  return vector.new(x, y):inBounds(self.start_x, self.start_y, self.end_x, self.end_y)
end

function frame:vectorInBounds(v)
  return v:inBounds(self.start_x, self.start_y, self.end_x, self.end_y)
end

return {
  ['frame'] = frame,
  ['vector'] = vector,
  ['term'] = (function()
    local ret = frame.new(1, 1, term.getSize())
    function ret:onDraw()
      if self then
        self:map(term)
      else
        ret:map(term)
      end
    end

    function ret:onClear()
      term.setCursorPos(1,1)
      term.clear()
    end
    return ret
  end)()
}

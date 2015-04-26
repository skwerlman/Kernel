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
 THE SOFTWARE. ]]


--[[
  The Advanced Tardix Graphics Architecture (ATGA) defines the Intermediate Graphics Representation (IGR).
  Each IGR object is composed of a table of IGR elements. Each element has a position (rows,cols), a color (background, foreground) and a value (character or string).
  For each IGR element, the cursor position is set to the one given, the colors are updated and the character printed.
]]

term.color = {colors.black, colors.white}
local _oldsetcol = term.setTextColor

function term.setTextColor(color)
  term.color[2] = color
  _oldsetcol(term.color[2])
end

function term.getTextColor()
  return term.color[2]
end

local _oldbgcol = term.setBackgroundColor

function term.setBackgroundColor(color)
  term.color[1] = color
  _oldsetcol(term.color[1])
end

function term.getBackgroundColor()
  return term.color[1]
end

function term.getColors()
  return unpack(term.color)
end

_G.atga = {
  ["colors"] = {
    [1] = colors.white,
    [2] = colors.orange,
    [3] = colors.magenta,
    [4] = colors.lightBlue,
    [5] = colors.yellow,
    [6] = colors.lime,
    [7] = colors.pink,
    [8] = colors.gray,
    [9] = colors.lightGray,
    [10] = colors.cyan,
    [11] = colors.purple,
    [12] = colors.blue,
    [13] = colors.brown,
    [14] = colors.green,
    [15] = colors.red,
    [0] = colors.black
  },
  ["vbufs"] = {term.native()}
}

if term.native() ~= term.current() then
  table.insert(atga.vbufs, term.current())
end

function atga.color(ind)
  return atga.colors[ind]
end


function atga.makeElement(x, y, bg, fg, val)
  local elem = {
    ["pos"] = {x,y},
    ["col"] = {bg,fg},
    ["val"] = val,
  }
  return elem
end

function atga.printElementTo(vbuf, elem)
  vbuf.setCursorPos(unpack(elem.pos))

  if vbuf.isColor and vbuf.isColor() then
    if elem.col and atga.colors[elem.col[1]] and atga.colors[elem.col[2]] then
      vbuf.setTextColor(atga.colors[elem.col[2]])
      vbuf.setBackgroundColor(atga.colors[elem.col[1]])
    end
  end

  vbuf.write(elem.val)
  local x, y = vbuf.getCursorPos()
  vbuf.setCursorPos(1, y+1)
end

function atga.printObjTo(vbuf, e)
  for k, v in pairs(e) do
    atga.printElementTo(vbuf, e)
  end
end

function atga.writeElementTo(vbuf, elem)
  vbuf.setCursorPos(unpack(elem.pos))
  if vbuf.isColor and vbuf.isColor() then
    if elem.col and atga.colors[elem.col[1]] and atga.colors[elem.col[2]] then
      print(atga.colors[elem.col[2]])
      print(atga.colors[elem.col[1]])

      vbuf.setTextColor(atga.colors[elem.col[2]])
      vbuf.setBackgroundColor(atga.colors[elem.col[1]])
    end
  end

  vbuf.write(elem.val)
end

function atga.writeObjectTo(vbuf, e)
  for k, v in pairs(e) do
    atga.writeElementTo(vbuf, e)
  end
end

function atga.makeVbuf(vbuf)
  vbuf.color = {colors.black, colors.white}

  local _oldsetcol = vbuf.setTextColor

  function vbuf.setTextColor(color)
    vbuf.color[2] = color
    _oldsetcol(vbuf.color[2])
  end

  function vbuf.getTextColor()
    return vbuf.color[2]
  end

  local _oldbgcol = vbuf.setBackgroundColor

  function vbuf.setBackgroundColor(color)
    vbuf.color[1] = color
    _oldbgcol(vbuf.color[1])
  end

  function vbuf.getBackgroundColor()
    return vbuf.color[1]
  end

  function vbuf.getColors()
    return unpack(vbuf.color)
  end
end

function atga.print(val)
  for k, v in pairs(atga.vbufs) do
    atga.makeVbuf(v)
  end

  for k, v in pairs(atga.vbufs) do
    local a = v.color and v.color[2] or 0
    local b = v.color and v.color[1] or 1

    local x, y = v.getCursorPos()
    atga.printElementTo(v, atga.makeElement(x, y, a, b, val))
  end
end


function atga.write(val)
  for k, v in pairs(atga.vbufs) do
    atga.makeVbuf(v)
  end
  for k, v in pairs(atga.vbufs) do
    local a = v.color and v.color[2] or 0
    local b = v.color and v.color[1] or 1

    local x, y = v.getCursorPos()
    atga.writeElementTo(v, atga.makeElement(x, y, a, b, val))
  end
end

function atga.clear()
  for k, v in pairs(atga.vbufs) do
    v.setTextColor(colors.white)
    v.setBackgroundColor(colors.black)
    v.setCursorPos(1,1)
    v.clear()
  end
end

function atga.setTextColor(col)
  for k, v in pairs(atga.vbufs) do
    atga.makeVbuf(v)
    v.setTextColor(col)
  end
end

function atga.setBackgroundColor(col)
  for k, v in pairs(atga.vbufs) do
    atga.makeVbuf(v)
    v.setBackgroundColor(col)
  end
end

function atga.printElem(elem)
  for k, vbuf in pairs(atga.vbufs) do
    print('h')
    vbuf.setCursorPos(unpack(elem.pos))

    if vbuf.isColor and vbuf.isColor() then
      if elem.col and atga.colors[elem.col[1]] and atga.colors[elem.col[2]] then
        vbuf.setTextColor(atga.colors[elem.col[2]])
        vbuf.setBackgroundColor(atga.colors[elem.col[1]])
      end
    end

    vbuf.write(elem.val)
    local x, y = vbuf.getCursorPos and vbuf.getCursorPos() or 1,1
    vbuf.setCursorPos(1, y+1)
  end
end


function atga.writeElem(elem)
  for k, vbuf in pairs(atga.vbufs) do
    print('h')
    vbuf.setCursorPos(unpack(elem.pos))

    if vbuf.isColor and vbuf.isColor() then
      if elem.col and atga.colors[elem.col[1]] and atga.colors[elem.col[2]] then
        vbuf.setTextColor(atga.colors[elem.col[2]])
        vbuf.setBackgroundColor(atga.colors[elem.col[1]])
      end
    end

    vbuf.write(elem.val)
  end
end

function atga.printe(x, y, b, f, v)
  atga.printElem(atga.makeElement(x, y, b, f, v))
end


function atga.addMonitor(side)
  local mon = peripheral.wrap(side)
  atga.makeVbuf(mon)
  table.insert(atga.vbufs, mon)
end

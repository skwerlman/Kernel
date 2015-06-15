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

local kobj = {}

local tree = {}

fs.addVirtual('/sys', {
  isDir = true
})

setmetatable(kobj, {
  ['__index'] = function(_, k)
    if rawget(_, k) then
      return rawget(_, k)
    elseif tree[k] then
      return tree[k]
    end
  end
})

function kobj.add(path, category, obj)
  if not fs.exists(('/sys/%s'):format(category)) then
    fs.addVirtual(('/sys/%s'):format(category), {
      isDir = true
    })
  end
  fs.addVirtual(('/sys/%s/%s'):format(category, path ), obj)
  tree[category .. '.' .. path] = obj
end

function kobj.remove(path, category)
  fs.removeVirtual(('/sys/%s/%s'):format(category, path))
  tree[category .. '.' .. path] = nil
end

return kobj

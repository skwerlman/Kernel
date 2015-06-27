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

--http filesystem implementation

local httpfs = {}

function httpfs:isOwnerOf(p)
  return p:sub(1, #('http://')) == 'http://' or p:sub(1, #('https://')) == 'https://'
end

function httpfs:open(path, m)
  if m == 'r' then
    local handle = {
      _data = 0
    }

    local d = http.get(path, {
      ['User-Agent'] = 'fs.httpfs (tardix)'
    })

    if not d then
      error('file not found', 2)
    else
      handle._data = d.readAll()
    end

    setmetatable(handle, {
      ['__index'] = function(_, k)
        if k:sub(1, 1) == '_' then
          return
        else
          return rawget(_, k)
        end
      end
    })

    function handle.readAll()
      local ret = handle._data
      handle._data = nil
      return ret
    end

    local line = 1
    local splat = string.split(handle._data, '\n')
    function handle.readLine()
      if line >= #splat then
        error('reached end of httpfs input buffer',2)
        return
      end
      local ret = splat[line]
      line = line + 1
      return ret
    end

    function handle.lines()
      line = #splat
      return splat
    end

    function handle.close()
      handle._data = nil
    end
    return handle
  elseif mode == 'w' then
    local handle = {_url = path}
    setmetatable(handle, {
      ['__index'] = function(_, k)
        if k:sub(1, 1) == '_' then
          return
        else
          return rawget(_, k)
        end
      end
    })
    function handle.writeLine(...)
      return http.post(handle._url, ..., {
        ['User-Agent'] = 'fs.httpfs'
      })
    end
    function handle.write(...)
      return http.post(handle._url, ..., {
        ['User-Agent'] = 'fs.httpfs'
      })
    end

    function handle.close()
      handle._url = nil
    end
    return handle
  elseif mode == 'u' then --universal mode.
    local handle = {
      _data = http.get(path, {
        ['User-Agent'] = 'fs.httpfs (tardix)'
      }).readAll(),
      _url = path
    }

    setmetatable(handle, {
      ['__index'] = function(_, k)
        if k:sub(1, 1) == '_' then
          return
        else
          return rawget(_, k)
        end
      end
    })

    function handle.readAll()
      local ret = handle._data
      handle._data = nil
      return ret
    end

    local line = 1
    local splat = string.split(handle._data, '\n')
    function handle.read()
      if line >= #splat then
        error('reached end of httpfs input buffer',2)
        return
      end
      local ret = splat[line]
      line = line + 1
      return ret
    end

    function handle.lines()
      line = #splat
      return splat
    end

    function handle.writeLine(...)
      return http.post(handle._url, ..., {
        ['User-Agent'] = 'fs.httpfs'
      })
    end
    function handle.write(...)
      return http.post(handle._url, ..., {
        ['User-Agent'] = 'fs.httpfs'
      })
    end

    function handle.close()
      handle._url = nil
    end

    return handle
  end
end

function httpfs:getDrive(path)
  return (string.split(path, '/'))[3]
end

function httpfs:getDir(path)
  return (string.split(path, '/'))[#(string.split(path, '/')) - 1]
end

function httpfs:exists()
  return true
end

httpfs.id = 'httpfs'

return httpfs

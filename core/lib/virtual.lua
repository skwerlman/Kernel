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

-- Sockets!
local virt = {}

function virt.makeVirtualIO(path)
  local watcher = {}


  local object = {
    isDir = false,
    isReadOnly = false,
  }

  function object:ioctl(path, req, ...)
    if watcher.onIOControl then
      watcher.onIOControl(self, path, req, ...)
    else
      return false, 'not yet implemented'
    end
  end

  function object:open(path, mode)
    local ret = {}
    if mode == 'r' then
      local closed = false

      function ret.readLine()
        if not closed then
          if watcher.onRead then
            return watcher.onRead(self)
          else
            return nil
          end
        else
          return nil
        end
      end

      function ret.readAll()
        if not closed then
          if watcher.onReadAll then
            return watcher.onReadAll(self)
          else
            return nil
          end
        else
          return nil
        end
      end

      function ret.close()
        if watcher.onClose then
          return watcher.onClose(self)
        end
        closed = true
      end
    elseif mode == 'w' then
      local closed = false

      function ret.writeLine(...)
        if not closed then
          if watcher.onWriteLine then
            return watcher.onWriteLine(self, ...)
          else
            return nil
          end
        else
          return nil
        end
      end

      function ret.write(...)
        if not closed then
          if watcher.onWrite then
            return watcher.onWrite(self, ...)
          else
            return nil
          end
        else
          return nil
        end
      end

      function ret.close()
        if watcher.onClose then
          return watcher.onClose(self)
        end
        closed = true
      end

      function ret.flush()
        if watcher.onFlush then
          return watcher.onFlush(self)
        end
      end
    elseif mode == 'a' then
      local closed = false

      function ret.writeLine(...)
        if not closed then
          if watcher.onWriteLineA then
            return watcher.onWriteLineA(self, ...)
          else
            return nil
          end
        else
          return nil
        end
      end

      function ret.write(...)
        if not closed then
          if watcher.onWriteA then
            return watcher.onWriteA(self, ...)
          else
            return nil
          end
        else
          return nil
        end
      end

      function ret.close()
        if watcher.onClose then
          return watcher.onClose(self)
        end
        closed = true
      end

      function ret.flush()
        if watcher.onFlush then
          return watcher.onFlushA(self)
        end
      end
    end
    return ret
  end
  fs.addVirtual(path, object)

  return watcher
end
return virt

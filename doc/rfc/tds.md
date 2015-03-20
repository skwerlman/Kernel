Tardix Driver Standard
======================

A driver is a computer program that _operates_ or _controls_ a specific type of device that is connected to the computer. Device drivers provide a _software interface_ to hardware devices, where other programs can use it without knowing it`s design.

In TARDIX, drivers serve a similar purpose, proving a _hardware abstraction layer_ between a wrapped peripheral or virtual device and programs designed for _libtardix_.


#####Drivers and Libtardix

Libtardix is the main library for doing anything within the TARDIX operating system. It is a `import`able collection of lower-level libraries and modules, such as _loop_ and _tvfs_.

#####The VFS and Libtardix

The VFS is an abstraction layer that resides atop the device drivers, providing a unified way to access all virtual devices trough one simple and powerful call, `vfs.open`.

###What should a driver implement?

<p align="center">
  <i>
    A driver should implement the bare minimum for devices to be usable.
  </i>
</p>

That is, drivers should implement, to be compliant with the TDS,

  - `open` </br>
    Should return a handle with atleast, `:pipe(string, handle)`, `:write(all, offset)`, `:read(size, offset)`, `:opts()`, `:flush()` and `:close()`.
    All off those functions should return self, except for `:close()`
  - `register` </br>
    Register a path to a file system.
    Needs atleast one string argument, path.
    Returns nothing.

  - `get_data` </br>
    Should return a table containing
    1. A pointer to `open`, keyed `drv_open`.
    2. A pointer to `register`, keyed
    `drv_register`
    3. A `info` table, defined as:
    ```lua
      {
        ["name"] = "<driver's name>",
        ["desc"] = "<driver's desc>",
        ["auth"] = "<your name>",
        ["license"] = "<the license>"
      }
    ```

    The info table is used by `get_drvinfo(name)`. The name passed as an argument must match the name parameter in the info table.

###Simple Driver Implementation

The following snippet defines a printer driver.

```lua

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

local info = {
  ['name'] = 'printer',
  ['desc'] = 'simple tardix printer driver',
  ['auth'] = 'Matheus de Alcantara',
  ['license'] = 'mit'
}


local _open(side, ...)
  return {
    _options = {...},
    _inp = make_buffer(),
    _out = make_buffer(),
    write = function(self, data)
      self._out.append('WRITE', data)
      return self
    end,
    read = function(self, size, offset)
      self._inp.append('READ', size, offset)
      return self
    end,
    pipe = function(self, key, buff)
      if key == 'out' then
        self._out.pipe(buff)
      elseif key == 'in' then
        self._in.pipe(buff)
      end
      return self
    end,
    opts = function(self, ...)
      self._options = {...}
      return self
    end
    flush = function(self)
      _inp.flush()
      _out.flush()
      return self
    end,
    close = function(self)
      _out.flush()
      return _inp
    end,

    _inp.flush = function()
      _builtin_printer_flush(_inp, side, 'in')
    end,

    _out.flush = function()
      _builtin_printer_flush(_out, side, 'out')
    end
  }

```

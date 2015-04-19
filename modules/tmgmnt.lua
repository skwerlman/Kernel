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
local tardixi = {}
tardixi.vmm = {
  ["allow"] = function(k, ...)
    return true
  end,
  ["sysc"] = function(k, ...)
    return false
  end,
  ["def"] = true
}

local tardix = {}

function tardix.setVmm(vmm)
  if tardixi.vmm.def == true then
    tardixi.vmm = vmm
  else
    error("Can not override currently-running VMM.")
  end
end

function tardix.runSystem(k, ...)
  if tardixi.vmm.allow(k, ...) then
    return tardixi.vmm.sysc(k, ...)
  end
end

modules.module "tardix-management" {
  ["text"] = {
    ["load"] = function()
      _G.tardix = tardix
    end,
    ["unload"] = function()
      _G.tardix = nil
    end
  }
}
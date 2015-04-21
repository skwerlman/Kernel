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
term.clear()
term.setCursorPos(1,1)

local _starttime = os.clock()
fs.delete('/kernel.log')

_G.params = {
  ["nocolor"] = not (
    (term.isColor and term.isColor()) or (term.isColour and term.isColour() ) ),
  ["root"] = ({...})[1] and ({...})[1] or '/',
  ["init"] = ({...})[2] and ({...})[2] or 'def',
  ["kms"]  = ({...})[3] and ({...})[3] or false
}

print("pre-init")
print("kernel: " .. _G.params.root)
print("libk: ".. fs.combine(_G.params.root,'/lib/libk.lua'))
loadfile(fs.combine(_G.params.root,'/lib/libk.lua'))()

logf('Starting the kernel (branch=next)')

logf('TARDIX-NEXT snapshot 2015-APRIL')

local function listAll(_path, _files)
  local path = _path or ""
  local files = _files or {}
  if #path > 1 then table.insert(files, path) end
  for _, file in ipairs(fs.list(path)) do
    local path = fs.combine(path, file)
    if fs.isDir(path) then
      listAll(path, files)
    else
      table.insert(files, path)
    end
  end
  return files
end

--logf('module worker starting')
local list = (listAll( fs.combine(_G.params.root, '/modules')))

for k, v in pairs(list) do
  if not fs.isDir(v) then
    dofile(v)
  end
end

modules.loadAllModules()


-- pass control to userland
-- hardcoded
if params.init == 'def' then
  local inits = {
    '/init',
    '/sbin/init',
    '/bin/init',
    '/lib/init',
    '/usr/init',
    '/usr/sbin/init',
    '/usr/bin/init',
    '/usr/lib/init',
  }

  for i = 1, #inits do
    if fs.exists(inits[i]) then
      print(exec(inits[i], 'next'))
      break
    end
  end
else
  if fs.exists(params.init) then
    print(exec(params.init, 'next'))
  else
    term.clear()
    term.setCursorPos(1,1)
    print("----- CRITICAL -----")
    print("FAILED TO LOAD INIT!")
    print("FILE NOT FOUND ERROR")
    while true do
      coroutine.yield("die")
    end
  end
end

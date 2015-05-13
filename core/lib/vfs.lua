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
local vfs = {}

vfs.masterNodeTable   = {}
vfs.masterIndexTable  = {}
vfs.root              = {}
vfs.masterOpenedTable = {}

function vfs.open(file, mode)
  if vfs.masterNodeTable
    [vfs.masterIndexTable[file]] and vfs.masterNodeTable
    [vfs.masterIndexTable[file]].open then

  vfs.masterOpenedTable[vfs.masterIndexTable[file]] = vfs.masterNodeTable
    [vfs.masterIndexTable[file]].open(file, mode)

  return vfs.masterIndexTable[file]
end

function vfs.getHandle(number)
  return type(vfs.masterOpenedTable[number]) == 'table' and vfs.masterOpenedTable[number] or {}
end

function vfs.isWritable(number)
  return vfs.getHandle(number).write ~= nil
end

function vfs.isReadable(number)
  return vfs.getHandle(number).read ~= nil
end

function vfs.write(handle, data)
  if vfs.isWritable(handle)
    vfs.getHandle(handle).write(data)
  end
end

function vfs.read(handle, off)
  if vfs.isReadable(handle) then
    for i = 1, off do
      vfs.getHandle(handle).readLine()
    end

    return vfs.getHandle(handle).readLine()
  end
end

function vfs.bind(path, node)
  local index = #vfs.masterNodeTable + 1
  vfs.masterNodeTable[index] = node
  vfs.masterIndexTable[path] = index

  return index
end


local vfs.ccfs = {}

function vfs.populateCCFS()
  local function listAll(_path, _files)
    local path = _path or ''
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

  local list = listAll('/')
  local trul = {}

  for k, v in pairs(list) do
    if not fs.isDir(v) then
      trul[k] = v
    end
  end

  remaining = #trul
  do
    vfs.bind(trul[remaining], fs.open)
    remaining = remaining - 1
  while remaining ~= 1

  vfs.ccfs = trul
end

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

local ino_mt = {["__index"] = ino_mt}
local inodes = {}

function ino_mt:open(mode)
	if self.link.is then
		return self.link.to:open(mode)
	end

	return fs.open(self.path, mode)
end


function ino_mt:getSize()
	if self.link.is then
		return self.link.to:getSize()
	end

	return self.size
end


function inodes.inode(file)
	if fs.exists(file) and not fs.isDir(file) then
		local handle = fs.open(file, 'r')
		local data   = handle.readAll()
		local size   = fs.getSize(file)

		handle.close()

		local link = {["is"] = false, ["to"] = 0}

		local ino = {
			["data"] = data,
			["size"] = size,
			["path"] = file,
			["link"] = link
	 	}

		setmetatable(ino, ino_mt)
		return ino
	else
		return {
			["data"] = "nodata",
			["size"] = 0,
			["path"] = 0,
			["link"] = {["is"] = false, ["to"] = 0},
			["perms"] = {
				[-255] = { -- root
					true, true, true
				},
				[0] = { -- group
					true, true, false
				},
				[1] = { -- normal
					true, true, false
				}
			}
		}
	end
end
function inodes.createInodeTable(dir)
	-- serialize a directory into an inode table
	local ret = {}
	for k, v in pairs(listAll(dir)) do
		ret[k] = (inode(v))
	end
	return ret
end

function inodes.link(path, sourceino)
	local ino = {
		["data"] = path..':LINK:'..sourceino.data,
		["size"] = 4,
		["path"] = path,
		["link"] = {
			["is"] = true,
			["to"] = sourceino
		},
		["perms"] = {
			[-255] = { -- root
				true, true, true
			},
			[0] = { -- group
				true, true, false
			},
			[1] = { -- normal
				true, true, false
			}
		}
	}
	setmetatable(ino, ino_mt)
	return ino
end


local vfs = {}

function vfs.open(pat, mod)
	if not vfs.mounts then
		if fs.exists(pat) then
			os.queueEvent('ccfs_open',pat,mod)
			return fs.open(pat, mod)
		end
	else
		for k, v in pairs(vfs.mounts) do
			if v:exists(pat) then
				os.queueEvent('vfs_open',pat,mod)
				return v:open(pat, mod)
			end
		end
	end
	return false
end

function vfs.mount(pat, fsi)
	table.insert(vfs.mounts, fsi)
	fs.makeDir(pat)
	os.queueEvent('vfs_mount', pat, fsi)

	for k, v in pairs(fsi.files) do
		local fh = v:open('w')
		fh.write(v.data)
	end
end

function vfs.list(dir)
	if not vfs.mounts then
		os.queueEvent('ccfs_list', dir)

		if fs.exists(dir) and fs.isDir(dir) then
			return fs.list(dir)
		end
	else
		for k, v in pairs(vfs.mounts) do
			if v.exists and v:exists(dir) and v.isDir and v:isDir(dir) then
				os.queueEvent('vfs_list', v, dir)
				return v:list(dir)
			end
		end
	end
end


function vfs.exists(dir)
	if not vfs.mounts then
		os.queueEvent('ccfs_exists', dir)
		return fs.exists(dir)
	else
		for k, v in pairs(vfs.mounts) do
			os.queueEvent('vfs_exists', v, dir)
			return v:exists(dir)
		end
	end
end

function vfs.isDir(dir)
	if not vfs.mounts then
		os.queueEvent('ccfs_isDir', dir)
		return fs.exsits(dir)
	else
		for k, v in pairs(vfs.mounts) do
			if v.exists and v:exists(dir) then
				os.queueEvent('vfs_exists', v, dir)
				return true
			end
		end
	end
end

function vfs.isReadOnly(dir)
	if not vfs.mounts then
		os.queueEvent('ccfs_isro', dir)
		return fs.isReadOnly(dir)
	else
		for k, v in pairs(vfs.mounts) do
			os.queueEvent('vfs_isro', v, dir)
			return v:isReadOnly(dir)
		end
	end
end

function vfs.getName(dir)
	if not vfs.mounts then
		os.queueEvent('ccfs_getname', dir)
		fs.getName(dir)
	else
		for k, v in pairs(vfs.mounts) do
			os.queueEvent('vfs_getname', v, dir)
			return v:getName(dir)
		end
	end
end

function vfs.getDrive(dir)
	if not vfs.mounts then
		os.queueEvent('ccfs_getdrive', dir)
		fs.getDrive(dir)
	else
		for k, v in pairs(vfs.mounts) do
			os.queueEvent('vfs_getdrive', v, dir)
			return v:getDrive(dir)
		end
	end
end

function vfs.getSize(dir)
	if not vfs.mounts then
		os.queueEvent('ccfs_getsize', dir)
		if fs.exists(dir) then
			return fs.getSize(dir)
		end
	else
		for k, v in pairs(vfs.mounts) do
			if v.exists and v:exists(dir) then
				os.queueEvent('vfs_getsize', v, dir)
				return v:getSize(dir)
			end
		end
	end
end

function vfs.getFreeSize(dir)
	if not vfs.mounts then
		os.queueEvent('ccfs_getfree', dir)
		if fs.exists(dir)  then
			return fs.getFreeSize(dir)
		end
	else
		for k, v in pairs(vfs.mounts) do
			if v.exists and v:exists(dir) then
				os.queueEvent('vfs_getfree', v, dir)
				return v:getFreeSize(dir)
			end
		end
	end
end

function vfs.makeDir(dir)
	if not vfs.mounts then
		os.queueEvent('ccfs_mkdir', dir)
		if not fs.exists(dir)  then
			return fs.makeDir(dir)
		end
	else
		for k, v in pairs(vfs.mounts) do
			if v.exists and not v:exists(dir) then
				os.queueEvent('vfs_mkdir', v, dir)
				return v:makeDir(dir)
			end
		end
	end
end


function vfs.move(a, b)
	if not vfs.mounts then
		os.queueEvent('ccfs_move', a, b)
		if fs.exists(a) and not fs.exists(b)  then
			return fs.move(a, b)
		end
	else
		for k, v in pairs(vfs.mounts) do
			if v.exists and v:exists(a) and not v:exists(b) then
				os.queueEvent('vfs', v, a, b)
				return v:move(a, b)
			end
		end
	end
end

function vfs.copy(a, b)
	if not vfs.mounts then
		os.queueEvent('ccfs_copy', a, b)
		if fs.exists(a) and not fs.exists(b)  then
			return fs.copy(a, b)
		end
	else
		for k, v in pairs(vfs.mounts) do
			if v.exists and v:exists(a) and not v:exists(b) then
				os.queueEvent('vfs_copy', v, a, b)
				return v:copy(a, b)
			end
		end
	end
end

function vfs.delete(dir)
	if not vfs.mounts then
		os.queueEvent('ccfs_delete', dir)
		if fs.exists(dir) then
			return fs.delete(dir)
		end
	else
		for k, v in pairs(vfs.mounts) do
			if v.exists and not v:exists(dir) then
				os.queueEvent('vfs_delete', v, dir)
				return v:delete(dir)
			end
		end
	end
end

function vfs.combine(dir)
	if not vfs.mounts then
		os.queueEvent('ccfs_combine', dir)
		if fs.exists(dir) then
			return fs.combine(dir)
		end
	else
		for k, v in pairs(vfs.mounts) do
			os.queueEvent('vfs_combine', v, dir)
			return v:combine(dir)
		end
	end
end

function vfs.find(dir)
	if not vfs.mounts then
		os.queueEvent('ccfs_find', dir)
		return fs.find(dir)
	else
		for k, v in pairs(vfs.mounts) do
			os.queueEvent('vfs_find', v, dir)
			return v:find(dir)
		end
	end
end

function vfs.getDir(dir)
	if not vfs.mounts then
		os.queueEvent('ccfs_getdir', dir)
		if fs.exists(dir) then
			return fs.getDir(dir)
		end
	else
		for k, v in pairs(vfs.mounts) do
			os.queueEvent('vfs_getdir', v, dir)
			return v:getDir(dir)
		end
	end
end

modules.module "vfs" {
	["text"] = {
		["load"] = function()
			_G.tfs = vfs
			_G.tfs.inodes = inodes
		end,
		["unload"] = function()
			_G.tfs = nil
		end
	}
}

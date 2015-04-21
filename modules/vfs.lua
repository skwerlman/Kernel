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
	return fs.open(self.path, mode)
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

function inodes.link(path, from)
	local ino = {
		["data"] = path..':LINK:'..from,
		["size"] = 4,
		["path"] = path,
		["link"] = {
			["is"] = true,
			["to"] = from
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

modules.module "inodes" {
	["text"] = {
		["load"] = function()
			if not _G.vfs then
				_G.vfs = {
					["inodes"] = inodes
				}
			else
				_G.vfs.inodes = inodes
			end
		end,
		["unload"] = function()
			if _G.vfs and _G.vfs.inodes then
				_G.vfs.inodes = nil
			end
		end
	}
}

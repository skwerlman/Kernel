local ccfs = fs
local bcfs = {}

local File = Class(
	function(self, path)
		self.path = 	 path
		self.size = 	 (ccfs.exists(path) and ccfs.getSize(path) or 0)
		self.buffers = {['inp'] = {}, ['out'] = {}, ['gen'] = {} }
		self.ops =		 {}
		self.append =  false
	end
)

function File:setAppend()
	self.append = true
	return self
end

function File:addOperationHandler(op, func)
	if not self.ops[op] then self.ops[op] = func end
	return self
end

function File:queue(buf, op, data)
	if not self.buffers then return end
	table.insert(self.buffers[buf],{['op'] = op, ["data"] = data})
	return self
end

function File:flush(buf)
	if buf == 'in' then
		local ret = {}
		local han = fs.open(self.path, 'r')
		for k, v in pairs(self.buffers.inp) do
			table.insert(ret, han.readLine())
		end
		han.close()
		return ret
	elseif buf == 'out' then
		local han = fs.open(self.path, (self.append and 'a' or 'w'))
		for k, v in pairs(self.buffers.out) do
			han.writeLine(v['data'])
		end
		han.close()
		return 0
	elseif buf == 'gen' then
		for k, v in pairs(self.buffers.gen) do
			self.ops[v[1]](table.from(v[1]))
		end
		return
	end
end

function File:read()
	self:queue('inp', 'read', 0)
	return self
end

function File:write(data)
	self:queue('out', 'write', data)
	return self
end

function bcfs.open(path)
	return File(path)
end

local _vfs = modules.module 'vfs' {
	['text'] = {
		['load'] = function()
			_G.File = File
		end,
		['unload'] = function()
			_G.File = nil
		end
	}
}

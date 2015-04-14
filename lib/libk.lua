function _G.printf(fmt, ...)
  print(fmt:format(...))
end

function _G.logf(fmt, ...)
  local x = fs.open('/kernel.log', 'a')
  x.write(('[%d] :: ' .. fmt .. '\n'):format(os.clock(), ...))
  x.close()

  if _G.params.nocolor then
    print(('[%d] :: ' .. fmt):format(os.clock(), ...))
  else
    io.write('[')
    term.setTextColor(colors.blue)
    io.write(tostring(math.floor(os.clock())))
    term.setTextColor(colors.white)
    io.write(']')
    term.setTextColor(colors.red)
    io.write(' :: ')
    term.setTextColor(colors.white)

    print((fmt):format(...))
  end
end

function _G.dofiles(data)
  for i = 1, #data do
    if not fs.exists(data[i]) then
      logf('[error] :: %s doesn\'t exist.', data[i])
    elseif fs.isDir(data[i]) then
      logf('[error] :: %s is a directory.', data[i])
    else
      logf('Successfully loaded %s.', data[i])
      dofile(data[i])
    end
  end
end

_G.arch = {}

function _G.arch.getComputerType()
  local ret = ''

  if pocket then
    ret = ret .. 'pocket-'
  elseif turtle then
    ret = ret .. 'turtle-'
  else
    ret = ret .. 'computer-'
  end

  if term.isColor and term.isColor() then
    ret = ret .. 'color'
  else
    ret = ret .. 'regular'
  end

  return ret
end

function _G.arch.getTriplet()
  return arch.getComputerType() .. '-tardix-tabi'
end

function getopt(optstring, ...)
	local opts = { }
	local args = { ... }

	for optc, optv in optstring:gmatch'(%a)(:?)' do
		opts[optc] = { hasarg = optv == ':' }
	end

	return coroutine.wrap(function()
		local yield = coroutine.yield
		local i = 1

		while i <= #args do
			local arg = args[i]

			i = i + 1

			if arg == '--' then
				break
			elseif arg:sub(1, 1) == '-' then
				for j = 2, #arg do
					local opt = arg:sub(j, j)

					if opts[opt] then
						if opts[opt].hasarg then
							if j == #arg then
								if args[i] then
									yield(opt, args[i])
									i = i + 1
								elseif optstring:sub(1, 1) == ':' then
									yield(':', opt)
								else
									yield('?', opt)
								end
							else
								yield(opt, arg:sub(j + 1))
							end

							break
						else
							yield(opt, false)
						end
					else
						yield('?', opt)
					end
				end
			else
				yield(false, arg)
			end
		end

		for i = i, #args do
			yield(false, args[i])
		end
	end)
end



------ LIB LOOP

function _G.Class(base, init)
  local c = {}    -- a new class instance
  if not init and type(base) == 'function' then
    init = base
    base = nil
  elseif type(base) == 'table' then
    -- our new class is a shallow copy of the base class!
    for i,v in pairs(base) do
      c[i] = v
    end
    c._base = base
  end
  -- the class will be the metatable for all its objects,
  -- and they will look up their methods in it.
  c.__index = c
  -- expose a constructor which can be called by <classname>(<args>)
  local mt = {}
  mt.__consumed = {}
  mt.__consumed.mixins = {}
  mt.__call = function(class_tbl, ...)
    local obj = {}
    setmetatable(obj,c)
    function obj:equals (otherObject)
      if not otherObject:isSubclassOf(self) then
        return false
      else
        for i = 1, #otherObject do
          if not otherObject[i] == self[i] then
            return false
          end
        end
      end
      return true
    end

    function obj:clone ()
      return obj
    end

    function obj:toString ()
      local mt = getmetatable(self)
      if mt.__tostring then
        return mt.__tostring()
      end
      return tostring(self)
    end
    if init then
      init(obj,...)
    else
      -- make sure that any stuff from the base class is initialized!
      if base and base.__init then
        base.__init(obj, ...)
      end
    end
    return obj
  end

  c.__init = init
  c.isSubclassOf = function(self, klass)
    local m = getmetatable(self)
    while m do
      if m == klass then return true end
      m = m._base
    end
    return false
  end

  function c:new(...)
    local obj = {}
    setmetatable(obj,c)
    function obj:equals (otherObject)
      if not otherObject:isSubclassOf(self) then
        return false
      else
        for i = 1, #otherObject do
          if not otherObject[i] == self[i] then
            return false
          end
        end
      end
      return true
    end

    function obj:clone ()
      return obj
    end

    function obj:toString ()
      local mt = getmetatable(self)
      if mt.__tostring then
        return mt.__tostring()
      end
      return tostring(self)
    end
    if init then
      init(obj,...)
    else
      -- make sure that any stuff from the base class is initialized!
      if base and base.__init then
        base.__init(obj, ...)
      end
    end
    return obj
  end

  function c:mix ( mixin )
    if getmetatable(mixin).__name then
      table.insert(getmetatable(self).__consumed, getmetatable(mixin).__name)
    end

    table.insert(getmetatable(self).__consumed.mixins, mixin)

    for k,v in pairs(mixin) do
      if k == 'init' then else
        self[k] = mixin[k]
      end
    end
  end

  function c:consume( file )
    local ret, err = loadfile(file)
    if not ret then error(err) end
    local data = ret()
    setmetatable(data, {__name = file})

    self:mix(data)
  end

  function c:can( selector )
    return self[selector] and type(self[selector]) == 'function'
  end

  function c:includes ( name )
    for k, v in pairs(getmetatable(self).__consumed) do
      if v == name then return v end
    end

    return false, 'No matches'
  end

  setmetatable(c, mt)
  return c
end

_G.class = _G.Class

-- LIBMOD (-lmod)

-- bootstraps the module system

local _modules = {}

local function module(name)
  return function(data)
    _modules[name] = data
  end
end

local function loadModule(name)
  logf('Trying to load \'%s\'', name)
  if _modules[name] then
    _modules[name].text.load()
  end
end

local function unloadModule(name)
  logf('Trying to unload \'%s\'', name)
  if _modules[name] then
    _modules[name].text.unload()
  end
end

local function stateModule(name, state)
  logf('Trying to state \'%s\': %s', name, state)

  if _modules[name] and _modules[name].text.states
      and _modules[name].text.states[state] then
    _modules[name].text.states[name]()
  end
end

local function getModuleByName(name)

   if _modules[name] then
      return _modules[name]
   end
end

local function loadAllModules()
  for k, v in pairs(_modules) do
    loadModule(k)
  end
end

local function unloadAllModules()
  for k, v in pairs(_modules) do
    unloadModule(k)
  end
end

local function stateAllModules(state)
  for k, v in pairs(_modules) do
    stateModule(k, state)
  end
end


local function reloadAllModules()
  unloadAllModules()
  local list = (listAll( fs.combine(_G.params.root, '/modules')))

  for k, v in pairs(list) do
    if not fs.isDir(v) then
      dofile(v)
    end
  end

  loadAllModules()
end

_G.modules =  {
  ['module'] = module,
  ['loadModule'] = loadModule,
  ['loadAllModules'] = loadAllModules,
  ['unloadModule'] = unloadModule,
  ['unloadallmods'] = unloadallmods,
  ['stateModule'] = stateModule,
  ['stateAllModules'] = stateAllModules,
  ['reloadAllModules'] = reloadAllModules
}

function listAll(_path, _files)
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

function _G.string:split(delimiter)
  local result = { }
  local from  = 1
  local delim_from, delim_to = string.find( self, delimiter, from  )
  while delim_from do
    table.insert( result, string.sub( self, from , delim_from-1 ) )
    from  = delim_to + 1
    delim_from, delim_to = string.find( self, delimiter, from  )
  end
  table.insert( result, string.sub( self, from  ) )
  return result
end

function table.from(tab, index)
  local ret = {}
  for i = index, #tab do
    ret[i-index] = tab[i]
  end
  return ret
end

function kassert(exp)
  if (not exp) then
    printf('Kernel assertion failed at %d!', os.clock())
    while true do
      coroutine.yield 'die' -- kassert from a thread should destroy itself.
    end
  end
end


function readEncodedTable(path)
	local x = fs.open(path, read)
	kassert(x)
	local data = x.readAll()
	x.close()


	data = textutils.unserialize(base64.decode(data))

	return data
end


function table.dump(tab, prefix, key)
  if not prefix then prefix = '' end
  if not key then key = 'root' end
  print((('%s[%s] = {'):format(prefix, key)))
  for k, v in pairs(tab) do
    if type(v) == 'table' then
      table.dump(v, prefix..'\t', k)
    else
      print((prefix ..'\t[%s] = %s,'):format(tostring(k), tostring(v)))
    end
  end
  print(prefix.. '}')
end

function readfile(file)
  local x = fs.open(file, 'r')
  if not x then
    error("Can not open file "..file,2)
  end
  local ret = x.readAll()
  x.close()
  return ret
end

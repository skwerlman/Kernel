local lambda = Class(
  function(self, path)
    self.path = (path and path or "")
  end
)

function lambda:load(file)
  if self.path == "" then
    self.path = file
  end

  if not fs.exists(self.path) then
    error(("File [%s] doesn't exist."):format(self.path))
  end

  local e = fs.open(self.path, 'r')
  if not e then print("File not found: ", self.path) error() end
  local data = textutils.unserialize( base64.decode(  e.readAll()))
  if not data then return end
  e.close()

  local sections = data.sections
  local exec, err = loadstring(base64.decode(data.sections.text))

  self.exec = exec
  self.error = err

  self.sects = sections
  return self
end

function lambda:run(...)
  if not self.exec then
    error("Not loaded.")
  end
  local tEnv = {
    ["_LAMBDA"] = true,
    ["_HELIOS"] = true
  }
  setmetatable(tEnv, {["__index"] = _G})
  setfenv(self.exec, tEnv)
  if self.sects.preload then
    for k, v in pairs(self.sects.preload) do
      local preload = loadstring(base64.decode(v))
      setfenv(preload, tEnv)
      preload()
    end
  end
  return pcall(self.exec, ...)
end

function lambda.isLambda(file)
  local e = lambda(file):load()
  if not e then
    return false
  else
    return (e.sects.head == "Lambda (HELIOS)" and true or false)
  end
end

function lambda.write(fnc, file)
  local data = {}
  data.sections = {}
  data.sections.text = base64.encode(string.dump(fnc))
  data.sections.head = {
    ["HEAD"] = "Lambda (HELIOS)",
    ["MAGIC"] = 0xbadb00b
  }

  local toWrite = base64.encode(textutils.serialize(data))

  local e = fs.open(file, 'w')
  for k, v in pairs(tt(toWrite, 50)) do
    e.writeLine(v)
  end
  e.close()
end

local lambdawrite = Class(
  function(self, path)
    self.path = path
  end
)

function lambdawrite:addPreloadFunction(func)
  if not self.preloads then
    self.preloads = {}
  end

  table.insert(self.preloads, func)
  return self
end

function lambdawrite:addVar(key, val)
  if not self.preloads then
    self.preloads = {}
  end

  table.insert(self.preloads, function()
    _G[key] = val
  end)
end

function lambdawrite:addMainFunction(func)
  if self.main then
    error("You can only add 1 main function.")
  end

  self.main = func
  return self
end

function lambdawrite:write()
  local data = {}
  data.sections = {}
  data.sections.text = base64.encode(string.dump(self.main))
  data.sections.head = {
    ["HEAD"] = "Lambda (HELIOS)",
    ["MAGIC"] = 0xbadb00b
  }
  data.sections.preload = {}
  for k, v in pairs(self.preloads) do
    table.insert(data.sections.preload, base64.encode(string.dump(v)))
  end

  local e = fs.open(self.path, 'w')
  for k, v in pairs(tt(base64.encode(textutils.serialize(data)), 50)) do
    e.writeLine(v)
  end
  e.close()
end


modules.module "executable" {
    ["text"] = {
        ["load"] = function()
          _G.Executable = lambda
          _G.ExecutableWriter = lambdawrite
        end,
        ["unload"] = function()
          _G.Executable, _G.ExecutableWriter = nil, nil
        end
     }
}
DefaultEnvironment = {
  ["HELIOS"] = true
}
setmetatable(DefaultEnvironment, {
  ["__index"] = function(t, k)
    return _G[k]
  end
})

function execl(file, ...)
  if not fs.exists(file) then
    return false, file .. " doesn't exist"
  elseif lambda.isLambda(file) then
    return lambda:new(file):load():run(...)
  else
    local fnc = loadfile(file)
    return pcall(fnc, ...)
  end
end

function execv(file, args)
  return execl(file, unpack(args))
end

function execle(file, env, ...)
  local func;
  local preload;
  local err;

  if not fs.exists(file) then
    return false, file .. " doesn't exist"
  elseif lambda.isLambda(file) then
    func = lambda:new(file):load().exec
    err = lambda:new(file):load().error
    preload = lambda:new(file):load().sects.preload
  else
    func = loadfile(file)
  end

  if preload and type(preload) == 'table' then
    for k, v in pairs(preload) do
      local preload = loadstring(base64.decode(v))
      setfenv(preload, env)
      preload()
    end
  end
  if not func then
    return false, err
  end
  setfenv(func, env)
  return pcall(func, ...)
end
--[[
  execve:
    execute vector environment
    Executes a file (@param file),
      with the environment as specified by a HCEnvironment (@param env),
      and with the arguments as specified by a table (@param arg)
  @param file the file to read
    The file may be normal lua or a lambda
    (@see: HCExecutable) (@see: HCExecutableWriter)
  @param env the environment to apply
    The environment needs to be an instance, or subclass, of HCEnvironment,
    that exposes the method :apply.
  @param arg the arguments to pass
    The arguments can be raw tables.
  @return Anything the program ran returned.
]]
function execve(file, env, arg)
  return execle(file, env, unpack(arg))
end

local thread = {}

function thread:new( f )

  local t = {}

  t.state = "running"
  t.environment = setmetatable( {}, { __index = getfenv( 2 ) } )

  t.filter = nil

  t.raw_environment = setmetatable( {}, {
    __index = function( _, k )
      return t.environment[k]
    end,
    __newindex = function( _, k, v )
      t.environment[k] = v
    end
  } )

  setfenv( f, t.raw_environment )
  t.func = f
  t.co = coroutine.create( f )

  setmetatable( t, {
    __index = self;
    __type = function( self )
      return self:type()
    end;
  } )

  return t
end

function thread:stop()
  if self.state ~= "dead" then
    self.state = "stopped"
  end
end

function thread:pause()
  if self.state == "running" then
    self.state = "paused"
  end
end

function thread:resume()
  if self.state == "paused" then
    self.state = "running"
  end
end

function thread:restart()
  self.state = "running"
  self.co = coroutine.create( self.func )
end

function thread:update( event, ... )
  if self.state ~= "running" then return true, self.state end -- if not running, don't update
  if self.filter ~= nil and self.filter ~= event then return true, self.filter end -- if filtering an event, don't update
  local ok, data = coroutine.resume( self.co, event, ... )
  if not ok then
    self.state = "stopped"
    return false, data
  end
  if coroutine.status( self.co ) == "dead" then
    self.state = "stopped"
    return true, "die"
  end
  self.filter = data
  return true, data
end

function thread:type()
  return "thread"
end

local process = {}

function process:new( name )
  local p = {}

  p.name = name
  p.children = {}

  setmetatable( p, {
    __index = self;
    __type = function( self )
      return self:type()
    end;
  } )

  return p
end

function process:spawnThread( f )
  local t = thread:new( f )
  table.insert( self.children, 1, t )
  return t
end

function process:spawnSubProcess( name )
  local p = process:new( name )
  table.insert( self.children, 1, p )
  return p
end

function process:update( event, ... )
  for i = #self.children, 1, -1 do
    local ok, data = self.children[i]:update( event, ... )
    if not ok then
      if self.exceptionHandler then
        self:exceptionHandler( self.children[i], data )
      else
        return false, data
      end
    end
    if data == "die" or self.children[i].state == "stopped" then
      self.children[i].state = "dead"
      table.remove( self.children, i )
    end
  end
  return true, #self.children == 0 and "die"
end

function process:stop()
  for i = 1, #self.children do
    self.children[i]:stop()
  end
end

function process:pause()
  for i = 1, #self.children do
    self.children[i]:pause()
  end
end

function process:resume()
  for i = 1, #self.children do
    self.children[i]:resume()
  end
end

function process:restart()
  for i = 1, #self.children do
    self.children[i]:restart()
  end
end

function process:list( deep )
  local t = {}
  for i = #self.children, 1, -1 do
    if self.children[i]:type() == "process" then
      if deep then
        local c = self.children[i]:list( true )
        c.name = self.children[i].name
        t[#t + 1] = c
      else
        t[#t + 1] = self.children[i]
      end
    elseif self.children[i]:type() == "thread" then
      t[#t + 1] = self.children[i]
    end
  end
  return t
end

function process:type()
  return "process"
end

process.main = process:new "main"

local function _doload(id)

  local pid = id:gsub(':', '/')

  if not string.sub(pid, -4) == '.lua' then
    if not fs.exists(pid) then
      pid = pid..'.lua'
    end
  end


  local ret, err = loadfile(pid)
  if not ret then
    error()
  end

  return ret()
end


local _thread = modules.module 'threads' {
  text = {
    load = function()
      _G.Thread = Thread
      _G.Task = Task
    end,
    unload = function()
      _G.newThread = nil
    end
  }
}


local _load = modules.module 'load' {
  text = {
    load = function()
      _G.load = _doload
    end,
    unload = function()
      _G.load = nil
    end
  }
}

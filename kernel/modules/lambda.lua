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


local running = {}

local Thread = class(
  function (self, func)
    self.state = "running"
    self.func = func
    self.co = coroutine.create(func)

    table.insert(running, 1, self)
  end
)

function Thread:stop()
  self.state = "stopped"
end

function Thread:pause()
  if self.state == "running" then
    self.state = "paused"
  end
end

function Thread:resume()
  if self.state == "paused" then
    self.state = "running"
  end
end

function Thread:restart()
  self.state = "running"
  self.co = coroutine.create(self.func)
end

function Thread:update( ... )
  if self.state ~= "running" then return end
  local ok, err = coroutine.resume( self.co, ... )
  if not ok then
    self.state = "stopped"
    if type( self.onException ) == "function" then
      self:onException( err )
    end
  end
  if coroutine.status( self.co ) == "dead" then
    self.state = "stopped"
    if type( self.onFinish ) == "function" then
      self:onFinish()
    end
  end
end

local Task = class(
  function(self)
    self.threads = {}
  end
)

function Task:newThread(f)
  local thread = Thread( f )
  function thread.onException( t, err )
    if type( self.onException ) == "function" then
      self.onException( t, err )
    end
  end
  function thread.onFinish( t, err )
    if type( self.onFinish ) == "function" then
      self.onFinish( t, err )
    end
  end
  table.insert( self.threads, thread )
  return thread
end

function Task:stop()
  for i = #self.threads, 1, -1 do
    self.threads[i]:stop()
  end
end

function Task:pause()
  for i = #self.threads, 1, -1 do
    self.threads[i]:pause()
  end
end

function Task:resume()
  for i = #self.threads, 1, -1 do
    self.threads[i]:resume()
  end
end

function Task:restart()
  for i = #self.threads, 1, -1 do
    self.threads[i]:restart()
  end
end

function Task:update( ... )
  for i = #self.threads, 1, -1 do
    self.threads[i]:update( ... )
  end
end

function Task:removeDeadThreads()
  for i = #self.threads, 1, -1 do
    if self.threads[i].state == "dead" then
      table.remove( self.threads, i )
    end
  end
end

function Task:count()
  return #self.threads
end

function Task:list()
  local t = {}
  for i = 1, #self.threads do
    t[i] = self.threads[i]
  end
  return t
end

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

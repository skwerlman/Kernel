local lambda = Class(
  function(self, path)
    self.path = (path and path or '')
  end
)

function lambda:load(file)
  if self.path == '' then
    self.path = file
  end

  if not fs.exists(self.path) then
    error(('File [%s] doesn\'t exist.'):format(self.path))
  end

  local e = fs.open(self.path, 'r')
  if not e then print('File not found: ', self.path) error() end
  local data = textutils.unserialize( base64.decode(  e.readAll()))
  if not data then return end
  e.close()

  local sections = data.sections
  local exec, err = loadstring(base64.decode(data.sections.text))
  self.exec = exec
  self.error = err

  self.sects = sections

  self.runThisFunc = function()
    if self.sects.preload then
      for k, v in pairs(self.sects.preload) do
        v()
      end
    end
    self.exec()
  end
  return self
end

function lambda:run(...)
  if not self.exec then
    error('Not loaded.')
  end
  local tEnv = {
    ['_LAMBDA'] = true,
    ['_HELIOS'] = true,
    ['_FILE']   = self.path
  }
  setmetatable(tEnv, {['__index'] = _G})
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
  if not fs.exists(file) then
    return false
  else
    local tab = textutils.unserialize(readfile(file))
    local ok, ret = pcall(function()
      return tab.sections.head ~= nil
    end)
    if not ok then return false else return true end
  end
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

function lambdawrite:linkLambda(obj)
  if not self.preloads then
    self.preloads = {}
  end

  table.insert(self.preloads, obj.exec)
  if obj.preloads then
    for k, v in pairs(obj.preloads) do
      table.insert(self.preloads, v)
    end
  end
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
    error('You can only add 1 main function.')
  end

  self.main = func
  return self
end

function lambdawrite:write(file)
  if not self.path and file then
    self.path = file
  end
  local data = {}
  data.sections = {}
  data.sections.text = base64.encode(string.dump(self.main))
  data.sections.head = {
    ['magicstr'] = 'Lambda (HELIOS)',
    ['magicnum'] = 0xbadb00b
  }
  data.sections.preload = {}
  if self.preloads then
    for k, v in pairs(self.preloads) do
      table.insert(data.sections.preload, base64.encode(string.dump(v)))
    end
  end

  local e = fs.open(self.path, 'w')
  for k, v in pairs(tt(base64.encode(textutils.serialize(data)), 50)) do
    e.writeLine(v)
  end
  e.close()
end


modules.module 'executable' {
    ['text'] = {
        ['load'] = function()
          _G.Executable = lambda
          _G.ExecutableWriter = lambdawrite
        end,
        ['unload'] = function()
          _G.Executable, _G.ExecutableWriter = nil, nil
        end
     }
}
DefaultEnvironment = {
  ['HELIOS'] = true
}
setmetatable(DefaultEnvironment, {
  ['__index'] = function(t, k)
    return _G[k]
  end
})



local thread = {}

function thread:new( f, p )

  local t = {}
  t.tid = getRandomTardixID()
  t.state = 'running'
  t.environment = setmetatable( {}, { __index = getfenv( 2 ) } )
  if p then
    if t.environment.process then
      t.environment.process.this = p
    else
      t.environment.process = {
        ['this'] = p
      }
    end
  end
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
  os.queueEvent('thread_construct, ', t.tid)
  return t
end

function thread:stop()
  os.queueEvent('thread_stop', t.tid)
  if self.state ~= 'dead' then
    self.state = 'stopped'
  end
end

function thread:pause()
  os.queueEvent('thread_pause', t.tid)
  if self.state == 'running' then
    self.state = 'paused'
  end
end

function thread:resume()
  os.queueEvent('thread_resume', t.tid)
  if self.state == 'paused' then
    self.state = 'running'
  end
end

function thread:restart()
  os.queueEvent('thread_restart', t.tid)
  self.state = 'running'
  self.co = coroutine.create( self.func )
end

function thread:update( event, ... )
  --os.queueEvent('thread_update', self.tid, {event, ...})
  if self.state ~= 'running' then return true, self.state end -- if not running, don't update
  if self.filter ~= nil and self.filter ~= event then return true, self.filter end -- if filtering an event, don't update

  local ok, data = coroutine.resume( self.co, event, ... )
  if not ok then
    self.state = 'stopped'
    return false, data
  end

  if coroutine.status( self.co ) == 'dead' then
    self.state = 'stopped'
    return true, 'die'
  end

  self.filter = data
  return true, data
end

function thread:type()
  return 'thread'
end

local process = {}

function process:new( name )
  local rID = getRandomTardixID()
  local p = {}

  p.tid = rID
  p.name = name or rID
  p.children = {}

  setmetatable( p, {
    __index = self;
    __type = function( self )
      return self:type()
    end;
  } )
  os.queueEvent('process_construct', name or rID  )
  return p
end

function process:spawnThread( f, name )
  os.queueEvent('thread_spawn', f, self.tid)
  local t = thread:new( f, self )
  if name then
    t.name = name
  else
    t.name = getRandomTardixID()
  end
  table.insert( self.children, 1, t )
  return t
end


function process:spawnSubprocess( name )
  local p = process:new( name )
  table.insert( self.children, 1, p )
  os.queueEvent('process_spawn', self.tid, p.tid)
  return p
end

function process:update( event, ... )
  --os.queueEvent('process_update', self.tid, {event, ...})
  for i = #self.children, 1, -1 do
    local ok, data = self.children[i]:update( event, ... )
    if not ok then
      if self.exceptionHandler then
        self:exceptionHandler( self.children[i], data )
      else
        return false, data
      end
    end
    if data == 'die' or self.children[i].state == 'stopped' then
      self.children[i].state = 'dead'
      table.remove( self.children, i )
    end
  end
  return true, #self.children == 0 and 'die'
end

function process:stop()
  os.queueEvent('process_stop', self.tid)
  for i = 1, #self.children do
    self.children[i]:stop()
  end
end

function process:pause()
  os.queueEvent('process_pause', self.tid)
  for i = 1, #self.children do
    self.children[i]:pause()
  end
end

function process:resume()
  os.queueEvent('process_resume', self.tid)
  for i = 1, #self.children do
    self.children[i]:resume()
  end
end

function process:restart()
  os.queueEvent('process_restart', self.tid)
  for i = 1, #self.children do
    self.children[i]:restart()
  end
end

function process:list( deep )
  local t = {}
  for i = #self.children, 1, -1 do
    if self.children[i]:type() == 'process' then
      if deep then
        local c = self.children[i]:list( true )
        c.name = self.children[i].name
        t[#t + 1] = c
      else
        t[#t + 1] = self.children[i]
      end
    elseif self.children[i]:type() == 'thread' then
      t[#t + 1] = self.children[i]
    end
  end
  return t
end

function process:type()
  return 'process'
end

process.main = process:new('scheduler')

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
      _G.process = process
      _G.thread = thread
    end,
    unload = function()
      _G.process, _G.thread = nil, nil
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


local execHandles = {}
_G.ExecutableManager = {}

function ExecutableManager.addHandle(name, isfunc, dofunc)
  execHandles[name] = ({isfunc, dofunc})
end

function ExecutableManager.removeHandle(name)
  execHandles[name] = nil
end

function ExecutableManager.getIfIs(file)
  for k, v in pairs(execHandles) do
      if v[1](file) then return v[2] end
  end
  return false
end
function ExecutableManager.open(file)
  if not type(file) == 'string' then
    print(file .. ' is not of type string. It is of type '..type(file))
    error()
  end
  if not fs.exists(tostring(file)) then
    error('File doesn\'t exist.')
  end

  if lambda.isLambda(file) then
    return lambda:new(file):load().runThisFunc, lambda:new(file):load().error
  elseif ExecutableManager.getIfIs(file) then
    return ExecutableManager.getIfIs(file)
  else
    return loadfile(file)
  end
end

function exec(file, ...)
  local fnc, err = ExecutableManager.open(file)
  if not fnc then
    error(err)
  end
  local _env = {
    ['_FILE'] = file,
    ['process'] = {
      ['this'] = (getfenv(2).process.this and getfenv(2).process.this or process.main):spawnSubprocess(file),
    }
  }

  _env.process.this.source = file
  --_env.process.this.cmdline = file .. ' ' .. table.concat({...}, ' ')

  os.queueEvent('exec', file, file .. ' ' .. table.concat({...}, ' '), _env.process.this)

  setmetatable(_env, {['__index'] = function(t, k)
      if not rawget(t, k) then
        return rawget(_G, k)
      else
        return rawget(t, k)
      end
    end
  })

  setfenv(fnc, _env)
  return pcall(fnc, ...)
end


function sexec(file, ...)
  local fnc, err = ExecutableManager.open(file)
  if not fnc then
    error(err)
  end
  local _env = {
    ['_FILE'] = file,
    ['process'] = {
      ['this'] = (getfenv(2).process.this and getfenv(2).process.this or process.main):spawnSubprocess(file),
    }
  }

  _env.process.this.source = file
  --_env.process.this.cmdline = file .. ' ' .. table.concat({...}, ' ')


  setmetatable(_env, {['__index'] = function(t, k)
      if not rawget(t, k) then
        return rawget(_G, k)
      else
        return rawget(t, k)
      end
    end
  })

  setfenv(fnc, _env)
  return pcall(fnc, ...)
end
modules.module 'threads/compat' {
  ['text'] = {
    ['load'] = function()
      function exit()
        coroutine.yield('die')
        error()
      end

      coroutine.fire = os.queueEvent
    end,
    ['unload'] = function()end
  }
}

local function httpWorker(file)
  return function()
    while true do
      local data = {coroutine.yield()}
      if data[1] == 'http_success' then
        local h = fs.open(file, 'w')
        if not h then
          error('could not open file')
        end
        h.write(data[3].readAll())
        h.close()
        break
      elseif data[1] == 'http_failure' then
        os.queueEvent('fail','thttpt', unpack(table.from(data,1)))
        break
      end
    end
  end
end
modules.module 'threads/util' {
  ['text'] = {
    ['load'] = function()
      function http.save(url, file)
        local x = http.get(url)
        local h = fs.open(file, 'w')

        h.write(x.readAll())
        h.close()
      end

      function http.saveAsync(url, file)
        http.request(url)

        if getfenv(2).process.this then
          getfenv(2).process.this:spawnThread(httpWorker(file))
        else
          process.main:spawnThread(httpWorker(file))
        end
      end
    end,
  ['unload'] = function()end
  }
}

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

  if not ends(pid, '.lua') then
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
      _G.unload = nil
    end
  }
}

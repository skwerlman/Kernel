local function newThread(f)
  local thread = {
    ['coro'] = coroutine.create(f)
  }

  function thread:start(...)
    return coroutine.resume(self.coro, ...)
  end

  function thread:stop()
    self.coro = nil -- should force lua to garbace collect
  end

  function thread:args(...)
    return coroutine.resume(self.coro, ...)
  end

  return thread
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
      _G.newThread = newThread
      _G.runfile = function(file)
        local ok, err = newThread(loadfile(file)):start()

        if not ok then
          logf('[critical] failed to load \'%s\'. \n\t error : %s', file,  err)
          while true do end
        end
      end
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

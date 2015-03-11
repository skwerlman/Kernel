local function readfile(s)
  local x = fs.open(s, 'r')
  local data = x.readAll()
  x.close()

  return data
end

logf('starting system worker.')



local data = string.split(readfile('/kernel/etc/tasks.list'), '\n')

local function _newThread(f)
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


for i = 1, #data do
  local ok, err =  _newThread(loadfile(data[i])):start()

  if not ok then
    logf('[critical] failed to load system worker. \n\t error : %s', err)
    while true do
      sleep(1)
    end
  end
end

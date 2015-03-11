term.clear()
term.setCursorPos(1,1)

logf('starting the kernel')
_G.modules = loadfile('/kernel/lib/module.lua')()

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

function string:split(delimiter)
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


local ok, err =  _newThread(loadfile('/kernel/workers/sysw.lua')):start()

if not ok then
  logf('[critical] failed to load system worker. \n\t error : %s', err)
  while true do
    sleep(1)
  end
end

logf('CCL/2 version 0x%X', 3405691582)

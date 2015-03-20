term.clear()
term.setCursorPos(1,1)

local _starttime = os.clock()

_G.params = {
  ["nocolor"] = not (
    (term.isColor and term.isColor()) or (term.isColour and term.isColour() ) ),
  ["root"] = ({...})[1] and ({...})[1] or '/'
}

fs.delete(fs.combine(_G.params.root, '/kernel.log'))



_G.modules = loadfile(fs.combine(_G.params.root, '/lib/module.lua'))()
loadfile(fs.combine(_G.params.root,'/lib/libk.lua'))()
loadfile(fs.combine(_G.params.root, '/lib/loop.lua'))()
logf('Starting the kernel')



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

logf('TARDIX kernel version 2015-MARCH')

local ok, err =  _newThread(loadfile(fs.combine(_G.params.root, '/workers/sysw.lua'))):start()


local _elapsed = math.floor(os.clock() - _starttime)

logf('[critical] Systemw exited!\nPress any key to reboot.')
os.pullEvent()
os.reboot()

if not ok then
  logf('[critical] error on system worker. \n\t error : %s', err)
  while true do
    sleep(1)
  end
end

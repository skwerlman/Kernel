term.clear()
term.setCursorPos(1,1)

local _starttime = os.clock()

fs.delete('/kernel.log')

_G.params = {
  ["nocolor"] = not (
    (term.isColor and term.isColor()) or (term.isColour and term.isColour() ) ),
  ["root"] = ({...})[1] and ({...})[1] or '/'
}

loadfile(fs.combine(_G.params.root,'/lib/libk.lua'))()
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

logf('TARDIX kernel version 2015-MARCH')

local function listAll(_path, _files)
  local path = _path or ""
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

--logf('module worker starting')
local list = (listAll( fs.combine(_G.params.root, '/modules')))

for k, v in pairs(list) do
  if not fs.isDir(v) then
    dofile(v)
  end
end

modules.loadAllModules()
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


-- pass control to userland
-- hardcoded

function _run(init)
  local __ok, err =  loadfile(init)
  if not __ok then
    logf('[critical] failed to load init \'%s\'. \n\t error : %s', init, err)
    while true do
      coroutine.yield('die')
    end
  end

  local ok, err = _newThread(__ok):start()
end

local inits = {
  '/init',
  '/sbin/init',
  '/bin/init',
  '/lib/init',
  '/usr/init',
  '/usr/sbin/init',
  '/usr/bin/init',
  '/usr/lib/init',
}

for i = 1, #inits do
  if fs.exists(inits[i]) then
    _run(inits[i])
    break
  end
end

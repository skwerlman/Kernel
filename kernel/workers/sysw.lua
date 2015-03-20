local function readfile(s)
  local x = fs.open(s, 'r')
  local data = x.readAll()
  x.close()

  return data
end

logf('starting system worker.')



local data = string.split(readfile(_G.params.root .. '/etc/tasks.list'), '\n')

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
  local __ok, err =  loadfile(fs.combine(_G.params.root, data[i]))
  if not __ok then
    logf('[critical] failed to load system worker. \n\t error : %s', err)
  end

  local ok, err = _newThread(__ok):start()

  if not ok then
    logf('[critical] failed to load system worker. \n\t error : %s', err)
    while true do
      sleep(1)
    end
  end
end

-- pass control to userland
-- hardcoded

function _run(init)
  local __ok, err =  loadfile(init)
  if not __ok then
    logf('[critical] failed to load init \'%s\'. \n\t error : %s', init, err)
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
logf('[critical] no init found!\nYour distro is borked. Press any key (or click) to reboot.')
os.pullEvent()
os.reboot()
